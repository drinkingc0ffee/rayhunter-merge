use std::path::Path;
use tokio::fs::File;
use tokio::io::{AsyncBufReadExt, BufReader};
use log::{debug, warn};

use crate::gps::GpsCoordinate;

/// Get the most recent GPS coordinates from a GPS log file
pub async fn get_most_recent_gps(gps_file_path: &Path) -> Option<(f64, f64)> {
    // Check if GPS file exists
    if !gps_file_path.exists() {
        debug!("GPS file does not exist: {:?}", gps_file_path);
        return None;
    }
    
    // Open and read the GPS file
    match File::open(gps_file_path).await {
        Ok(file) => {
            let reader = BufReader::new(file);
            let mut lines = reader.lines();
            
            // Read all lines to get to the most recent one
            let mut last_line = None;
            while let Ok(Some(line)) = lines.next_line().await {
                last_line = Some(line);
            }
            
            // Parse the last line as a GpsCoordinate
            if let Some(line) = last_line {
                match serde_json::from_str::<GpsCoordinate>(&line) {
                    Ok(coord) => {
                        debug!("Found GPS coordinates: {}, {}", coord.latitude, coord.longitude);
                        return Some((coord.latitude, coord.longitude));
                    }
                    Err(e) => {
                        // Try parsing as simple format (timestamp,lat,lon)
                        let parts: Vec<&str> = line.split(',').collect();
                        if parts.len() >= 3 {
                            if let (Ok(lat), Ok(lon)) = (parts[1].trim().parse::<f64>(), parts[2].trim().parse::<f64>()) {
                                debug!("Found GPS coordinates from simple format: {}, {}", lat, lon);
                                return Some((lat, lon));
                            }
                        }
                        warn!("Failed to parse GPS coordinate: {}", e);
                    }
                }
            }
            None
        }
        Err(e) => {
            warn!("Failed to open GPS file: {}", e);
            None
        }
    }
}
