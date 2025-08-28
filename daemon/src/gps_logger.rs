//! GPS Logging Module
//! 
//! This module handles writing GPS coordinates to log files in the QMDL directory.
//! It integrates with the existing recording system to ensure GPS logs are created
//! at the same time as QMDL and NDJSON logs with the same timestamp filenames.

use std::sync::Arc;
use tokio::fs::OpenOptions;
use tokio::io::{AsyncWriteExt, BufWriter};
use tokio::sync::RwLock;
use log::debug;
use serde::Serialize;

use crate::gps::GpsCoordinate;
use crate::qmdl_store::RecordingStore;

#[derive(Debug, thiserror::Error)]
pub enum GpsLoggerError {
    #[error("Failed to create GPS log file: {0}")]
    FileCreationError(String),
    #[error("Failed to write GPS data: {0}")]
    WriteError(String),
    #[error("Failed to serialize GPS data: {0}")]
    SerializationError(String),
    #[error("No current recording entry available")]
    NoCurrentEntry,
    #[error("GPS logging is disabled")]
    LoggingDisabled,
}

pub struct GpsLogger {
    qmdl_store: Arc<RwLock<RecordingStore>>,
    logging_enabled: bool,
    log_format: crate::config::GpsLogFormat,
}

impl GpsLogger {
    pub fn new(
        qmdl_store: Arc<RwLock<RecordingStore>>,
        gps_logging_enabled: bool,
        gps_log_format: crate::config::GpsLogFormat,
    ) -> Self {
        Self {
            qmdl_store,
            logging_enabled: gps_logging_enabled,
            log_format: gps_log_format,
        }
    }

    /// Log GPS coordinates to the current recording session
    /// GPS logs are stored in the same directory as QMDL logs with the same timestamp filename
    pub async fn log_gps_coordinates(&self, coordinates: &GpsCoordinate) -> Result<(), GpsLoggerError> {
        if !self.logging_enabled {
            debug!("GPS logging is disabled, skipping coordinates: ({}, {})", 
                coordinates.latitude, coordinates.longitude);
            return Err(GpsLoggerError::LoggingDisabled);
        }

        // Get the current recording entry to determine the filename
        let (current_entry_name, qmdl_directory) = {
            let qmdl_store = self.qmdl_store.read().await;
            if let Some(current_idx) = qmdl_store.current_entry {
                if let Some(entry) = qmdl_store.manifest.entries.get(current_idx) {
                    (entry.name.clone(), qmdl_store.path.clone())
                } else {
                    return Err(GpsLoggerError::NoCurrentEntry);
                }
            } else {
                return Err(GpsLoggerError::NoCurrentEntry);
            }
        };

        // Create the GPS log file path in the QMDL directory with the same timestamp filename
        let gps_file_path = qmdl_directory.join(format!("{}.gps", current_entry_name));

        // Open or create the GPS log file
        let gps_file = OpenOptions::new()
            .create(true)
            .append(true)
            .open(&gps_file_path)
            .await
            .map_err(|e| GpsLoggerError::FileCreationError(e.to_string()))?;

        let mut writer = BufWriter::new(gps_file);

        // Write GPS data according to the configured format
        match self.log_format {
            crate::config::GpsLogFormat::Json => {
                self.write_json_format(&mut writer, coordinates).await?;
            }
            crate::config::GpsLogFormat::Csv => {
                self.write_csv_format(&mut writer, coordinates).await?;
            }
            crate::config::GpsLogFormat::Raw => {
                self.write_raw_format(&mut writer, coordinates).await?;
            }
            crate::config::GpsLogFormat::Simple => {
                self.write_simple_format(&mut writer, coordinates).await?;
            }
        }

        // Flush the writer to ensure data is written to disk
        writer.flush().await
            .map_err(|e| GpsLoggerError::WriteError(e.to_string()))?;

        debug!("GPS coordinates logged to {}: ({}, {})", 
            gps_file_path.display(), coordinates.latitude, coordinates.longitude);

        Ok(())
    }

    /// Write GPS coordinates in JSON format
    async fn write_json_format<W: AsyncWriteExt + Unpin>(
        &self,
        writer: &mut BufWriter<W>,
        coordinates: &GpsCoordinate,
    ) -> Result<(), GpsLoggerError> {
        #[derive(Serialize)]
        struct GpsLogEntry {
            timestamp: String,
            latitude: f64,
            longitude: f64,
            accuracy: Option<f64>,
            altitude: Option<f64>,
            speed: Option<f64>,
            heading: Option<f64>,
            device_id: Option<String>,
            app_version: Option<String>,
            request_id: Option<String>,
        }

        let log_entry = GpsLogEntry {
            timestamp: coordinates.timestamp.to_rfc3339(),
            latitude: coordinates.latitude,
            longitude: coordinates.longitude,
            accuracy: coordinates.accuracy,
            altitude: coordinates.altitude,
            speed: coordinates.speed,
            heading: coordinates.heading,
            device_id: coordinates.device_id.clone(),
            app_version: coordinates.app_version.clone(),
            request_id: coordinates.request_id.clone(),
        };

        let json_line = serde_json::to_string(&log_entry)
            .map_err(|e| GpsLoggerError::SerializationError(e.to_string()))?;
        
        writer.write_all((json_line + "\n").as_bytes()).await
            .map_err(|e| GpsLoggerError::WriteError(e.to_string()))?;

        Ok(())
    }

    /// Write GPS coordinates in CSV format (simplified)
    async fn write_csv_format<W: AsyncWriteExt + Unpin>(
        &self,
        writer: &mut BufWriter<W>,
        coordinates: &GpsCoordinate,
    ) -> Result<(), GpsLoggerError> {
        let csv_line = format!(
            "{},{},{}\n",
            coordinates.timestamp.timestamp(),
            coordinates.latitude,
            coordinates.longitude,
        );

        writer.write_all(csv_line.as_bytes()).await
            .map_err(|e| GpsLoggerError::WriteError(e.to_string()))?;

        Ok(())
    }

    /// Write GPS coordinates in raw format (simple text)
    /// Format: unix_timestamp, latitude, longitude
    async fn write_raw_format<W: AsyncWriteExt + Unpin>(
        &self,
        writer: &mut BufWriter<W>,
        coordinates: &GpsCoordinate,
    ) -> Result<(), GpsLoggerError> {
        let raw_line = format!(
            "{}, {}, {}\n",
            coordinates.timestamp.timestamp(),
            coordinates.latitude,
            coordinates.longitude,
        );

        writer.write_all(raw_line.as_bytes()).await
            .map_err(|e| GpsLoggerError::WriteError(e.to_string()))?;

        Ok(())
    }

    /// Write GPS coordinates in simple format (unix_timestamp, latitude, longitude)
    async fn write_simple_format<W: AsyncWriteExt + Unpin>(
        &self,
        writer: &mut BufWriter<W>,
        coordinates: &GpsCoordinate,
    ) -> Result<(), GpsLoggerError> {
        let simple_line = format!(
            "{},{},{}\n",
            coordinates.timestamp.timestamp(),
            coordinates.latitude,
            coordinates.longitude,
        );

        writer.write_all(simple_line.as_bytes()).await
            .map_err(|e| GpsLoggerError::WriteError(e.to_string()))?;

        Ok(())
    }
}
