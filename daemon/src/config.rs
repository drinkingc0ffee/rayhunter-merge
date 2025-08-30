use log::warn;
use serde::{Deserialize, Serialize};

use rayhunter::Device;
use rayhunter::analysis::analyzer::AnalyzerConfig;

use crate::error::RayhunterError;

#[derive(Debug, Clone, Deserialize, Serialize)]
#[serde(default)]
pub struct Config {
    pub qmdl_store_path: String,
    pub port: u16,
    pub debug_mode: bool,
    pub device: Device,
    pub ui_level: u8,
    pub colorblind_mode: bool,
    pub key_input_mode: u8,
    pub ntfy_url: Option<String>,
    pub jwt_secret: Option<String>,
    pub jwt_key_file: Option<String>,
    pub analyzers: AnalyzerConfig,
    // GPS Configuration
    #[serde(default)]
    pub gps: GpsConfig,
    // Attack Alert Configuration
    #[serde(default)]
    pub alerts: AlertConfig,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
#[serde(default)]
pub struct GpsConfig {
    pub gps_logging_enabled: bool,
    pub gps_log_format: GpsLogFormat,
}

impl Default for GpsConfig {
    fn default() -> Self {
        Self {
            gps_logging_enabled: true,
            gps_log_format: GpsLogFormat::Simple,
        }
    }
}

#[derive(Debug, Clone, Deserialize, Serialize)]
#[serde(rename_all = "lowercase")]
pub enum GpsLogFormat {
    Json,
    Csv,
    Raw,
    Simple,
}

impl Default for GpsLogFormat {
    fn default() -> Self {
        GpsLogFormat::Json
    }
}

#[derive(Debug, Clone, Deserialize, Serialize)]
#[serde(default)]
pub struct AlertConfig {
    pub browser_notifications: bool,
    pub max_alerts: usize,
}

impl Default for AlertConfig {
    fn default() -> Self {
        Self {
            browser_notifications: true,
            max_alerts: 100,
        }
    }
}

impl Default for Config {
    fn default() -> Self {
        Config {
            qmdl_store_path: "/data/rayhunter/qmdl".to_string(),
            port: 8080,
            debug_mode: false,
            device: Device::Orbic,
            ui_level: 1,
            colorblind_mode: false,
            key_input_mode: 0,
            analyzers: AnalyzerConfig::default(),
            ntfy_url: None,
            jwt_secret: None,
            jwt_key_file: None,
            gps: GpsConfig::default(),
            alerts: AlertConfig::default(),
        }
    }
}

pub async fn parse_config<P>(path: P) -> Result<Config, RayhunterError>
where
    P: AsRef<std::path::Path>,
{
    if let Ok(config_file) = tokio::fs::read_to_string(&path).await {
        Ok(toml::from_str(&config_file).map_err(RayhunterError::ConfigFileParsingError)?)
    } else {
        warn!("unable to read config file, using default config");
        Ok(Config::default())
    }
}

pub struct Args {
    pub config_path: String,
}

pub fn parse_args() -> Args {
    let args: Vec<String> = std::env::args().collect();
    if args.len() != 2 {
        println!("Usage: {} /path/to/config/file", args[0]);
        std::process::exit(1);
    }
    Args {
        config_path: args[1].clone(),
    }
}