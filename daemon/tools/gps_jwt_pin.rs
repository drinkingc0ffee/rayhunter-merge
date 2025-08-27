use clap::{Parser, ValueEnum};
use serde::{Deserialize, Serialize};
use std::env;
use std::fs;
use std::io::{self, Write};
use std::path::Path;
use std::process;
use pbkdf2::pbkdf2_hmac;
use sha2::Sha256;
use hex;
use serde_json;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum GpsJwtPinError {
    #[error("PIN validation failed: {0}")]
    PinValidation(String),
    #[error("Key derivation failed: {0}")]
    KeyDerivation(String),
    #[error("File I/O error: {0}")]
    FileIo(#[from] std::io::Error),
    #[error("Configuration error: {0}")]
    Config(String),
    #[error("Daemon configuration error: {0}")]
    DaemonConfig(String),
    #[error("Permission error: {0}")]
    Permission(String),
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Config {
    pub salt: String,
    pub iterations: u32,
    pub key_length: usize,
    pub key_file_path: String,
    pub daemon_config_path: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Status {
    pub success: bool,
    pub message: String,
    pub details: Option<String>,
    pub error: Option<String>,
}

#[derive(ValueEnum, Clone, Debug)]
pub enum InputMethod {
    CommandLine,
    Stdin,
    Environment,
}

#[derive(Parser, Debug)]
#[command(name = "gps_jwt_pin")]
#[command(about = "Generate JWT encryption key from PIN using PBKDF2")]
#[command(version)]
pub struct Args {
    /// 8-digit PIN code
    #[arg(short, long, value_name = "PIN")]
    pin: Option<String>,

    /// Input method for PIN
    #[arg(short, long, value_enum, default_value = "command-line")]
    input_method: InputMethod,

    /// Configuration file path
    #[arg(short, long, default_value = "/etc/gps_jwt_pin/config.toml")]
    config: String,

    /// Generate new salt and save to config
    #[arg(long)]
    generate_salt: bool,

    /// Check daemon configuration
    #[arg(long)]
    check_daemon: bool,

    /// Validate existing key
    #[arg(long)]
    validate_key: bool,

    /// Verbose output
    #[arg(short, long)]
    verbose: bool,
}

impl Default for Config {
    fn default() -> Self {
        // Convert default salt text to hex
        let default_salt_text = "rayhunter_enhanced_default_salt_2024";
        let default_salt_hex = hex::encode(default_salt_text.as_bytes());
        
        Self {
            salt: default_salt_hex,
            iterations: 100_000,
            key_length: 64,
            key_file_path: "/etc/keys/jwt-key.txt".to_string(),
            daemon_config_path: "/etc/rayhunter/daemon.toml".to_string(),
        }
    }
}

impl Config {
    fn load_from_file(path: &str) -> Result<Self, GpsJwtPinError> {
        if Path::new(path).exists() {
            let content = fs::read_to_string(path)?;
            let config: Config = toml::from_str(&content)
                .map_err(|e| GpsJwtPinError::Config(format!("Failed to parse config: {}", e)))?;
            Ok(config)
        } else {
            Ok(Config::default())
        }
    }

    fn save_to_file(&self, path: &str) -> Result<(), GpsJwtPinError> {
        let content = toml::to_string_pretty(self)
            .map_err(|e| GpsJwtPinError::Config(format!("Failed to serialize config: {}", e)))?;
        
        // Ensure directory exists
        if let Some(parent) = Path::new(path).parent() {
            if !parent.exists() {
                fs::create_dir_all(parent)?;
            }
        }
        
        fs::write(path, content)?;
        Ok(())
    }

    fn generate_new_salt(&mut self) -> Result<(), GpsJwtPinError> {
        let salt_bytes: Vec<u8> = (0..32).map(|_| rand::random::<u8>()).collect();
        self.salt = hex::encode(salt_bytes);
        Ok(())
    }
}

fn validate_pin(pin: &str) -> Result<(), GpsJwtPinError> {
    if pin.len() != 8 {
        return Err(GpsJwtPinError::PinValidation("PIN must be exactly 8 digits".to_string()));
    }

    if !pin.chars().all(|c| c.is_ascii_digit()) {
        return Err(GpsJwtPinError::PinValidation("PIN must contain only digits (0-9)".to_string()));
    }

    // Check for weak PINs
    match pin {
        "00000000" | "11111111" | "22222222" | "33333333" | 
        "44444444" | "55555555" | "66666666" | "77777777" | 
        "88888888" | "99999999" => {
            return Err(GpsJwtPinError::PinValidation("PIN is too weak - all digits are the same".to_string()));
        }
        "12345678" | "87654321" | "01234567" | "76543210" => {
            return Err(GpsJwtPinError::PinValidation("PIN is too weak - avoid simple sequential patterns".to_string()));
        }
        _ => {}
    }

    Ok(())
}

fn derive_key_from_pin(pin: &str, config: &Config) -> Result<String, GpsJwtPinError> {
    let salt_bytes = hex::decode(&config.salt)
        .map_err(|e| GpsJwtPinError::KeyDerivation(format!("Invalid salt format: {}", e)))?;

    let mut key = vec![0u8; config.key_length];
    
    pbkdf2_hmac::<Sha256>(
        pin.as_bytes(),
        &salt_bytes,
        config.iterations,
        &mut key,
    );

    Ok(hex::encode(key))
}

fn save_key_to_file(key: &str, config: &Config) -> Result<(), GpsJwtPinError> {
    // Ensure directory exists
    if let Some(parent) = Path::new(&config.key_file_path).parent() {
        if !parent.exists() {
            fs::create_dir_all(parent)
                .map_err(|e| GpsJwtPinError::FileIo(e))?;
        }
    }

    // Write key to file
    fs::write(&config.key_file_path, key)
        .map_err(|e| GpsJwtPinError::FileIo(e))?;

    // Set secure permissions (600 - owner read/write only)
    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        let mut perms = fs::metadata(&config.key_file_path)?.permissions();
        perms.set_mode(0o600);
        fs::set_permissions(&config.key_file_path, perms)?;
    }

    Ok(())
}

fn check_daemon_config(config: &Config) -> Result<Status, GpsJwtPinError> {
    let mut status = Status {
        success: true,
        message: "Daemon configuration check completed".to_string(),
        details: None,
        error: None,
    };

    // Check if key file exists and is readable
    if !Path::new(&config.key_file_path).exists() {
        status.success = false;
        status.error = Some(format!("JWT key file not found: {}", config.key_file_path));
        return Ok(status);
    }

    // Check key file permissions
    let metadata = fs::metadata(&config.key_file_path)?;
    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        let mode = metadata.permissions().mode();
        if (mode & 0o777) != 0o600 {
            status.success = false;
            status.error = Some(format!("Key file has insecure permissions: {:o}", mode & 0o777));
            return Ok(status);
        }
    }

    // Check if daemon config file exists
    if Path::new(&config.daemon_config_path).exists() {
        let daemon_content = fs::read_to_string(&config.daemon_config_path)?;
        if daemon_content.contains("RAYHUNTER_JWT_KEY_FILE") {
            status.details = Some("Daemon configuration includes JWT key file path".to_string());
        } else {
            status.details = Some("Daemon configuration does not specify JWT key file path".to_string());
        }
    } else {
        status.details = Some("Daemon configuration file not found".to_string());
    }

    // Check environment variable
    if let Ok(jwt_path) = env::var("RAYHUNTER_JWT_KEY_FILE") {
        if jwt_path == config.key_file_path {
            status.details = Some(format!("Environment variable RAYHUNTER_JWT_KEY_FILE is set to: {}", jwt_path));
        } else {
            status.details = Some(format!("Environment variable RAYHUNTER_JWT_KEY_FILE is set to: {} (expected: {})", jwt_path, config.key_file_path));
        }
    } else {
        status.details = Some("Environment variable RAYHUNTER_JWT_KEY_FILE is not set".to_string());
    }

    Ok(status)
}

fn get_pin_from_input(args: &Args) -> Result<String, GpsJwtPinError> {
    match &args.input_method {
        InputMethod::CommandLine => {
            if let Some(pin) = &args.pin {
                Ok(pin.clone())
            } else {
                Err(GpsJwtPinError::PinValidation("PIN required when using command line input method".to_string()))
            }
        }
        InputMethod::Stdin => {
            print!("Enter 8-digit PIN: ");
            io::stdout().flush()?;
            
            let mut pin = String::new();
            io::stdin().read_line(&mut pin)?;
            
            let pin = pin.trim();
            if pin.is_empty() {
                Err(GpsJwtPinError::PinValidation("No PIN entered".to_string()))
            } else {
                Ok(pin.to_string())
            }
        }
        InputMethod::Environment => {
            env::var("GPS_JWT_PIN")
                .map_err(|_| GpsJwtPinError::PinValidation("Environment variable GPS_JWT_PIN not set".to_string()))
        }
    }
}

fn print_status(status: &Status, verbose: bool) {
    if verbose {
        println!("{}", serde_json::to_string_pretty(status).unwrap());
    } else {
        if status.success {
            println!("✅ {}", status.message);
            if let Some(details) = &status.details {
                println!("   {}", details);
            }
        } else {
            eprintln!("❌ {}", status.message);
            if let Some(error) = &status.error {
                eprintln!("   Error: {}", error);
            }
        }
    }
}

fn main() -> Result<(), GpsJwtPinError> {
    let args = Args::parse();
    
    // Load configuration
    let mut config = Config::load_from_file(&args.config)?;
    
    if args.verbose {
        eprintln!("Configuration loaded: {:?}", config);
    }

    // Handle salt generation
    if args.generate_salt {
        config.generate_new_salt()?;
        config.save_to_file(&args.config)?;
        
        let status = Status {
            success: true,
            message: "New salt generated and saved".to_string(),
            details: Some(format!("Salt: {}", config.salt)),
            error: None,
        };
        print_status(&status, args.verbose);
        return Ok(());
    }

    // Handle daemon configuration check
    if args.check_daemon {
        let status = check_daemon_config(&config)?;
        print_status(&status, args.verbose);
        return Ok(());
    }

    // Handle key validation
    if args.validate_key {
        if Path::new(&config.key_file_path).exists() {
            let key_content = fs::read_to_string(&config.key_file_path)?;
            let key_content = key_content.trim();
            
            if key_content.len() == config.key_length * 2 { // hex encoding doubles length
                let status = Status {
                    success: true,
                    message: "Key validation successful".to_string(),
                    details: Some(format!("Key file: {}, Length: {} bytes", config.key_file_path, config.key_length)),
                    error: None,
                };
                print_status(&status, args.verbose);
            } else {
                let status = Status {
                    success: false,
                    message: "Key validation failed".to_string(),
                    error: Some(format!("Invalid key length: expected {} hex chars, got {}", config.key_length * 2, key_content.len())),
                    details: None,
                };
                print_status(&status, args.verbose);
                process::exit(1);
            }
        } else {
            let status = Status {
                success: false,
                message: "Key validation failed".to_string(),
                error: Some(format!("Key file not found: {}", config.key_file_path)),
                details: None,
            };
            print_status(&status, args.verbose);
            process::exit(1);
        }
        return Ok(());
    }

    // Get PIN from input
    let pin = get_pin_from_input(&args)?;
    
    if args.verbose {
        eprintln!("PIN received: {}", pin);
    }

    // Validate PIN
    validate_pin(&pin)?;
    
    if args.verbose {
        eprintln!("PIN validation passed");
    }

    // Derive key from PIN
    let key = derive_key_from_pin(&pin, &config)?;
    
    if args.verbose {
        eprintln!("Key derivation successful, length: {} bytes", key.len() / 2);
    }

    // Save key to file
    save_key_to_file(&key, &config)?;
    
    if args.verbose {
        eprintln!("Key saved to: {}", config.key_file_path);
    }

    // Check daemon configuration
    let daemon_status = check_daemon_config(&config)?;
    
    // Print final status
    let final_status = Status {
        success: true,
        message: "JWT key generated and saved successfully".to_string(),
        details: Some(format!("Key file: {}, Daemon config: {}", 
            if daemon_status.success { "✅ OK" } else { "❌ Issues found" },
            if daemon_status.success { "✅ OK" } else { "⚠️  Check required" }
        )),
        error: None,
    };
    
    print_status(&final_status, args.verbose);
    
    // If daemon config has issues, print them
    if !daemon_status.success {
        eprintln!("⚠️  Daemon configuration issues detected:");
        if let Some(error) = daemon_status.error {
            eprintln!("   {}", error);
        }
        if let Some(details) = daemon_status.details {
            eprintln!("   {}", details);
        }
    }

    Ok(())
}
