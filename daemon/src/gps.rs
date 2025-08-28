//! GPS data handling module
//! 
//! This module provides functionality to receive GPS coordinates via REST API
//! and save them to per-scan GPS files for tracking location data.

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

/// GPS coordinate data structure
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GpsCoordinate {
    pub timestamp: DateTime<Utc>,
    pub latitude: f64,
    pub longitude: f64,
    #[serde(default)]
    pub accuracy: Option<f64>,
    #[serde(default)]
    pub altitude: Option<f64>,
    #[serde(default)]
    pub speed: Option<f64>,
    #[serde(default)]
    pub heading: Option<f64>,
    #[serde(default)]
    pub device_id: Option<String>,
    #[serde(default)]
    pub app_version: Option<String>,
    #[serde(default)]
    pub request_id: Option<String>,
}
