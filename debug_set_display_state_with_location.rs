use axum::{
    extract::{Json, State},
    http::StatusCode,
};
use std::sync::Arc;
use tokio::sync::broadcast;
use chrono::Utc;

use crate::server::AlertEvent;
use crate::display::DisplayState;

/// Extended version of DisplayState that includes location data
#[derive(serde::Deserialize)]
struct DebugDisplayStateWithLocation {
    WarningDetected: WarningDetectedData,
}

#[derive(serde::Deserialize)]
struct WarningDetectedData {
    event_type: String,
    location: Option<(f64, f64)>,
}

/// Debug endpoint for setting display state with location data
pub async fn debug_set_display_state_with_location(
    State(state): State<Arc<crate::server::ServerState>>,
    Json(debug_state): Json<DebugDisplayStateWithLocation>,
) -> Result<(StatusCode, String), (StatusCode, String)> {
    // Extract data
    let event_type_str = debug_state.WarningDetected.event_type.clone();
    let location = debug_state.WarningDetected.location;
    
    // Parse event type
    let event_type = match event_type_str.as_str() {
        "High" => rayhunter::analysis::analyzer::EventType::High,
        "Medium" => rayhunter::analysis::analyzer::EventType::Medium,
        "Low" => rayhunter::analysis::analyzer::EventType::Low,
        _ => return Err((StatusCode::BAD_REQUEST, "Invalid event type".to_string())),
    };
    
    // Create display state
    let display_state = DisplayState::WarningDetected { event_type };
    
    // Send display state update
    if let Some(ui_sender) = &state.ui_update_sender {
        ui_sender.send(display_state).await.map_err(|_| {
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                "failed to send display state update".to_string(),
            )
        })?;
    } else {
        return Err((
            StatusCode::SERVICE_UNAVAILABLE,
            "display system not available".to_string(),
        ));
    }
    
    // Create and send alert event directly with the provided location
    let alert = AlertEvent {
        timestamp: Utc::now(),
        event_type: event_type_str,
        message: format!("Rayhunter has detected a {} severity event", event_type_str),
        location,
    };
    
    // Send alert event
    let _ = state.alert_event_sender.send(alert);
    
    Ok((
        StatusCode::OK,
        "display state updated successfully".to_string(),
    ))
}


