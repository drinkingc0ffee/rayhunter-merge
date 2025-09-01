use std::path::Path;
use std::sync::Arc;
use axum::{
    extract::State,
    http::StatusCode,
    Json,
};
use chrono::Utc;
use log::{debug, info};
use serde::{Deserialize, Serialize};
use tokio::fs::{File, OpenOptions};
use tokio::io::AsyncWriteExt;

use crate::ServerState;
use crate::display::DisplayState;
use rayhunter::analysis::analyzer::EventType;

#[derive(Debug, Deserialize)]
pub struct TestAlertRequest {
    pub severity: String,
    pub message: Option<String>,
    pub location: Option<(f64, f64)>,
}

#[derive(Debug, Serialize)]
struct GpsEntry {
    timestamp: String,
    latitude: f64,
    longitude: f64,
}

#[derive(Debug, Serialize)]
struct NdjsonEntry {
    timestamp: String,
    event_type: String,
    message: String,
    analyzer: String,
    details: String,
}

/// Endpoint to create test alerts that update both NDJSON and GPS files
///
/// This endpoint:
/// 1. Finds an appropriate recording entry to use (current or most recent)
/// 2. Updates or creates the NDJSON file for that entry with the alert
/// 3. Updates or creates the GPS file with the location data if provided
/// 4. Sends a display state update to trigger the UI alert system
///
/// Note: Recording starts automatically when the daemon launches. QMDL files are created first,
/// followed by NDJSON files. GPS logs have the same timestamp filename as QMDL logs but are
/// only created when GPS data is received.
pub async fn create_test_alert(
    State(state): State<Arc<ServerState>>,
    Json(request): Json<TestAlertRequest>,
) -> Result<(StatusCode, String), (StatusCode, String)> {
    // Convert severity string to EventType
    let event_type = match request.severity.to_lowercase().as_str() {
        "high" => EventType::High,
        "medium" => EventType::Medium,
        "low" => EventType::Low,
        _ => return Err((StatusCode::BAD_REQUEST, "Invalid severity level".to_string())),
    };
    
    // Get current recording entry
    let qmdl_store = state.qmdl_store_lock.read().await;
    let current_entry = match qmdl_store.current_entry {
        Some(idx) => {
            match qmdl_store.manifest.entries.get(idx) {
                Some(entry) => entry.name.clone(),
                None => {
                    // If the entry is not in the manifest but current_entry is set,
                    // we'll use the most recent entry from the manifest
                    if let Some(last_entry) = qmdl_store.manifest.entries.last() {
                        info!("Current entry not found in manifest, using most recent entry: {}", last_entry.name);
                        last_entry.name.clone()
                    } else {
                        return Err((StatusCode::INTERNAL_SERVER_ERROR, "Failed to get current entry and no entries in manifest".to_string()))
                    }
                },
            }
        },
        None => {
            // If no current entry, use the most recent entry from the manifest
            if let Some(last_entry) = qmdl_store.manifest.entries.last() {
                info!("No current entry, using most recent entry: {}", last_entry.name);
                last_entry.name.clone()
            } else {
                return Err((StatusCode::BAD_REQUEST, "No recordings available".to_string()))
            }
        },
    };
    
    // Paths for NDJSON and GPS files
    let ndjson_path = qmdl_store.path.join(format!("{}.ndjson", current_entry));
    let gps_path = qmdl_store.path.join(format!("{}.gps", current_entry));
    
    // Current timestamp in ISO format
    let timestamp = Utc::now().to_rfc3339();
    
    // Create message if not provided
    let message = request.message.unwrap_or_else(|| 
        format!("Test {:?} severity event", event_type)
    );
    
    // Update NDJSON file with alert
    if let Err(e) = append_to_ndjson(&ndjson_path, &timestamp, &format!("{:?}", event_type), &message).await {
        return Err((StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to update NDJSON file: {}", e)));
    }
    
    // Update or create GPS file if location is provided
    if let Some(location) = request.location {
        if let Err(e) = append_to_gps(&gps_path, &timestamp, location.0, location.1).await {
            return Err((StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to update GPS file: {}", e)));
        }
    }
    
    // Send display state update
    if let Some(ui_sender) = &state.ui_update_sender {
        let display_state = DisplayState::WarningDetected { event_type };
        if let Err(_) = ui_sender.send(display_state).await {
            return Err((StatusCode::INTERNAL_SERVER_ERROR, "Failed to send display state update".to_string()));
        }
    }
    
    info!("Test alert created: {:?} severity", event_type);
    Ok((StatusCode::OK, "Test alert created successfully".to_string()))
}

/// Append an entry to the NDJSON file or create it if it doesn't exist
/// 
/// Note: NDJSON files are typically created after QMDL files, but they may exist
/// even if no warnings have been detected yet. This function will create the file
/// with a basic structure if it doesn't exist.
async fn append_to_ndjson(
    path: &Path, 
    timestamp: &str, 
    severity: &str, 
    message: &str
) -> Result<(), String> {
    // Create NDJSON entry
    let entry = NdjsonEntry {
        timestamp: timestamp.to_string(),
        event_type: severity.to_string(),
        message: message.to_string(),
        analyzer: "Test Alert".to_string(),
        details: format!("Test alert with {} severity", severity),
    };
    
    // Serialize to JSON
    let json = serde_json::to_string(&entry)
        .map_err(|e| format!("Failed to serialize NDJSON entry: {}", e))?;
    
    // Check if file exists
    let file_exists = Path::new(path).exists();
    
    // Create or append to file
    let mut file = if file_exists {
        debug!("NDJSON file exists, appending to it: {}", path.display());
        OpenOptions::new()
            .append(true)
            .open(path)
            .await
            .map_err(|e| format!("Failed to open NDJSON file: {}", e))?
    } else {
        // If file doesn't exist, create it with initial content
        debug!("NDJSON file doesn't exist, creating it: {}", path.display());
        
        // Create a basic analyzer info for the NDJSON file
        let initial_content = r#"{"analyzers":[{"name":"Test Alert System","description":"System for testing alerts with different severity levels","version":1}],"rayhunter":{"rayhunter_version":"0.6.2","system_os":"Linux","arch":"unknown"},"report_version":2}"#;
        
        let mut new_file = File::create(path)
            .await
            .map_err(|e| format!("Failed to create NDJSON file: {}", e))?;
            
        new_file.write_all(initial_content.as_bytes())
            .await
            .map_err(|e| format!("Failed to write initial content to NDJSON file: {}", e))?;
            
        // Reopen in append mode
        OpenOptions::new()
            .append(true)
            .open(path)
            .await
            .map_err(|e| format!("Failed to reopen NDJSON file for appending: {}", e))?
    };
    
    // Append the entry
    file.write_all(format!("\n{}", json).as_bytes())
        .await
        .map_err(|e| format!("Failed to write to NDJSON file: {}", e))?;
    
    debug!("Added entry to NDJSON file: {}", path.display());
    Ok(())
}

/// Append an entry to the GPS file or create it if it doesn't exist
async fn append_to_gps(
    path: &Path, 
    timestamp: &str, 
    latitude: f64, 
    longitude: f64
) -> Result<(), String> {
    // Create GPS entry
    let entry = GpsEntry {
        timestamp: timestamp.to_string(),
        latitude,
        longitude,
    };
    
    // Serialize to JSON
    let json = serde_json::to_string(&entry)
        .map_err(|e| format!("Failed to serialize GPS entry: {}", e))?;
    
    // Check if file exists and create/append as needed
    let file_exists = Path::new(path).exists();
    
    let mut file = if file_exists {
        OpenOptions::new()
            .append(true)
            .open(path)
            .await
            .map_err(|e| format!("Failed to open GPS file: {}", e))?
    } else {
        File::create(path)
            .await
            .map_err(|e| format!("Failed to create GPS file: {}", e))?
    };
    
    // Write entry
    if file_exists {
        file.write_all(format!("\n{}", json).as_bytes())
            .await
            .map_err(|e| format!("Failed to write to GPS file: {}", e))?;
    } else {
        file.write_all(json.as_bytes())
            .await
            .map_err(|e| format!("Failed to write to GPS file: {}", e))?;
    }
    
    debug!("Added entry to GPS file: {}", path.display());
    Ok(())
}
