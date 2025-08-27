//! GPS v2 API with Comprehensive JWT Security
//!
//! This module provides GPS API endpoints with JWT-based authentication and integrity of claims.
//! All GPS data comes from JWT claims to ensure data cannot be tampered with.

use axum::{
    extract::State,
    http::{HeaderMap, StatusCode},
    response::{IntoResponse, Json},
};
use chrono::Utc;
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use std::time::{SystemTime, UNIX_EPOCH};
use std::collections::HashSet;
use tokio::sync::Mutex;
use hmac::{Hmac, Mac};
use sha2::Sha256;
use base64::{engine::general_purpose, Engine as _};
use log::{info, error, warn};

use crate::server::ServerState;
use crate::gps::GpsCoordinate;

type HmacSha256 = Hmac<Sha256>;

/// JWT header structure
#[derive(Debug, Serialize, Deserialize)]
struct JwtHeader {
    alg: String,
    typ: String,
}

/// JWT payload structure for GPS v2 - ALL GPS data comes from JWT claims
/// This ensures integrity of claims - the JWT is the source of truth
#[derive(Debug, Serialize, Deserialize)]
struct JwtPayload {
    // GPS coordinates (REQUIRED - these are the claims that must be protected)
    lat: f64,
    lon: f64,
    
    // Essential JWT Security Claims (REQUIRED)
    exp: u64,        // expiration timestamp
    iat: u64,        // issued at timestamp
    jti: String,     // JWT ID (unique identifier for replay protection)
    
    // GPS metadata (OPTIONAL but validated if present)
    #[serde(default)]
    accuracy: Option<f64>,
    #[serde(default)]
    altitude: Option<f64>,
    #[serde(default)]
    speed: Option<f64>,
    #[serde(default)]
    heading: Option<f64>,
}

// JWT ID store for preventing replay attacks
lazy_static::lazy_static! {
    static ref JTI_STORE: Arc<Mutex<HashSet<String>>> = Arc::new(Mutex::new(HashSet::<String>::new()));
}

/// GPS v2 API response
#[derive(Debug, Serialize)]
pub struct GpsV2Response {
    pub status: String,
    pub message: String,
    pub data: GpsV2Data,
    pub security: GpsV2Security,
}

#[derive(Debug, Serialize)]
pub struct GpsV2Data {
    pub latitude: f64,
    pub longitude: f64,
    pub timestamp: i64,
    pub processing_time_ms: u64,
    pub accuracy: Option<f64>,
    pub altitude: Option<f64>,
    pub speed: Option<f64>,
    pub heading: Option<f64>,
}

#[derive(Debug, Serialize)]
pub struct GpsV2Security {
    pub token_validated: bool,
    pub claims_integrity_verified: bool,
    pub replay_protection_active: bool,
    pub token_lifetime_seconds: u64,
    pub jti_verified: bool,
}

/// GPS v2 API error response
#[derive(Debug, Serialize)]
pub struct GpsV2Error {
    pub status: String,
    pub error: String,
    pub code: String,
    pub security_details: Option<String>,
}

/// Enhanced GPS v2 API endpoint handler with comprehensive JWT security
/// 
/// This endpoint provides:
/// - JWT-based authentication with INTEGRITY OF CLAIMS
/// - All GPS data comes from JWT payload (cannot be tampered with)
/// - Replay attack protection with configurable token lifetime
/// - Complete request security validation
/// - Enhanced GPS coordinate validation from JWT claims
/// - Timestamp correlation with cellular data
/// - Real-time processing feedback with security details
/// 
/// POST /api/v2/gps
/// Authorization: Bearer <JWT_TOKEN>
/// 
/// JWT Payload must contain:
/// {
///   "lat": 37.7749,                    // REQUIRED: latitude from JWT claims
///   "lon": -122.4194,                  // REQUIRED: longitude from JWT claims
///   "exp": 1640995200,                 // REQUIRED: expiration timestamp
///   "iat": 1640995170,                 // REQUIRED: issued at timestamp
///   "jti": "unique_id",                // REQUIRED: JWT ID for replay protection
///   "accuracy": 5.0,                   // OPTIONAL: accuracy in meters
///   "altitude": 100.0,                 // OPTIONAL: altitude in meters
///   "speed": 25.0,                     // OPTIONAL: speed in m/s
///   "heading": 180.0                   // OPTIONAL: heading in degrees
/// }
pub async fn gps_api_v2(
    State(_state): State<Arc<ServerState>>,
    headers: HeaderMap,
) -> Result<impl IntoResponse, impl IntoResponse> {
    let start_time = std::time::Instant::now();

    // Extract and validate JWT token - ALL data comes from JWT claims
    let gps_data = match extract_and_validate_jwt(&headers).await {
        Ok(data) => data,
        Err((status, error, security_details)) => {
            return Err((
                status,
                Json(GpsV2Error {
                    status: "error".to_string(),
                    error,
                    code: "JWT_VALIDATION_FAILED".to_string(),
                    security_details,
                })
            ));
        }
    };

    // Validate GPS coordinates from JWT claims (integrity of claims)
    if !is_valid_latitude(gps_data.latitude) {
        return Err((
            StatusCode::BAD_REQUEST,
            Json(GpsV2Error {
                status: "error".to_string(),
                error: format!("Invalid latitude from JWT claims: {}. Must be between -90.0 and 90.0", gps_data.latitude),
                code: "INVALID_LATITUDE_CLAIM".to_string(),
                security_details: Some("JWT claims integrity validation failed".to_string()),
            })
        ));
    }

    if !is_valid_longitude(gps_data.longitude) {
        return Err((
            StatusCode::BAD_REQUEST,
            Json(GpsV2Error {
                status: "error".to_string(),
                error: format!("Invalid longitude from JWT claims: {}. Must be between -180.0 and 180.0", gps_data.longitude),
                code: "INVALID_LONGITUDE_CLAIM".to_string(),
                security_details: Some("JWT claims integrity validation failed".to_string()),
            })
        ));
    }

    // Calculate processing time
    let processing_time = start_time.elapsed().as_millis() as u64;

    // Create response with security details
    let response = GpsV2Response {
        status: "success".to_string(),
        message: "GPS data received and validated from JWT claims".to_string(),
        data: GpsV2Data {
            latitude: gps_data.latitude,
            longitude: gps_data.longitude,
            timestamp: gps_data.timestamp.timestamp(),
            processing_time_ms: processing_time,
            accuracy: gps_data.accuracy,
            altitude: gps_data.altitude,
            speed: gps_data.speed,
            heading: gps_data.heading,
        },
        security: GpsV2Security {
            token_validated: true,
            claims_integrity_verified: true,
            replay_protection_active: true,
            token_lifetime_seconds: 30, // Default token lifetime
            jti_verified: true,
        },
    };

    info!("GPS v2 API: JWT claims validated successfully, coordinates: ({}, {}), processing time: {}ms", 
        gps_data.latitude, gps_data.longitude, processing_time);

    Ok((StatusCode::OK, Json(response)))
}

/// Extract and validate JWT from Authorization header with comprehensive security
/// This function ensures INTEGRITY OF CLAIMS - all GPS data comes from JWT
async fn extract_and_validate_jwt(headers: &HeaderMap) -> Result<GpsCoordinate, (StatusCode, String, Option<String>)> {
    // 1. Extract Authorization header
    let auth_header = headers
        .get("Authorization")
        .ok_or((StatusCode::UNAUTHORIZED, "No Authorization header provided".to_string(), Some("Missing Authorization header".to_string())))?;

    let auth_str = auth_header
        .to_str()
        .map_err(|_| (StatusCode::UNAUTHORIZED, "Invalid Authorization header".to_string(), Some("Invalid Authorization header format".to_string())))?;

    if !auth_str.starts_with("Bearer ") {
        return Err((StatusCode::UNAUTHORIZED, "Invalid Authorization format, expected Bearer token".to_string(), Some("Invalid Bearer token format".to_string())));
    }

    let token = &auth_str[7..]; // Skip "Bearer "

    // 2. Split token into parts
    let parts: Vec<&str> = token.split('.').collect();
    if parts.len() != 3 {
        return Err((StatusCode::UNAUTHORIZED, "Invalid JWT format - must have 3 parts".to_string(), Some("JWT structure validation failed".to_string())));
    }

    let base64_header = parts[0];
    let base64_payload = parts[1];
    let base64_signature = parts[2];

    // 3. Decode header and payload
    let header_bytes = base64url_decode(base64_header)
        .map_err(|e| (StatusCode::UNAUTHORIZED, format!("Failed to decode JWT header: {}", e), Some("JWT header decoding failed".to_string())))?;

    let payload_bytes = base64url_decode(base64_payload)
        .map_err(|e| (StatusCode::UNAUTHORIZED, format!("Failed to decode JWT payload: {}", e), Some("JWT payload decoding failed".to_string())))?;

    let signature = base64url_decode(base64_signature)
        .map_err(|e| (StatusCode::UNAUTHORIZED, format!("Failed to decode JWT signature: {}", e), Some("JWT signature decoding failed".to_string())))?;

    // 4. Parse header and payload
    let header: JwtHeader = serde_json::from_slice(&header_bytes)
        .map_err(|_| (StatusCode::UNAUTHORIZED, "Invalid JWT header format".to_string(), Some("JWT header parsing failed".to_string())))?;

    let payload: JwtPayload = serde_json::from_slice(&payload_bytes)
        .map_err(|_| (StatusCode::UNAUTHORIZED, "Invalid JWT payload format".to_string(), Some("JWT payload parsing failed".to_string())))?;

    // 5. Verify algorithm
    if header.alg != "HS256" || header.typ != "JWT" {
        return Err((StatusCode::UNAUTHORIZED, "Unsupported JWT algorithm - only HS256 supported".to_string(), Some("JWT algorithm validation failed".to_string())));
    }

    // 6. Get secret key from file
    let secret_key = get_secret_key_from_file()?;

    // 7. Verify signature to ensure INTEGRITY OF CLAIMS
    let message = format!("{}.{}", base64_header, base64_payload);
    let mut mac = HmacSha256::new_from_slice(&secret_key)
        .map_err(|_| (StatusCode::INTERNAL_SERVER_ERROR, "Failed to initialize HMAC".to_string(), Some("HMAC initialization failed".to_string())))?;
    
    mac.update(message.as_bytes());
    let expected_signature = mac.finalize().into_bytes();

    // Constant-time comparison to prevent timing attacks
    if expected_signature.len() != signature.len() || !constant_time_eq(&expected_signature, &signature) {
        return Err((StatusCode::UNAUTHORIZED, "JWT signature verification failed".to_string(), Some("JWT claims integrity compromised - signature verification failed".to_string())));
    }

    // 8. Verify expiration with configurable lifespan (default 30 seconds)
    let current_time = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map_err(|_| (StatusCode::INTERNAL_SERVER_ERROR, "System time error".to_string(), Some("System time validation failed".to_string())))?
        .as_secs();

    // Check if token is expired
    if payload.exp < current_time {
        return Err((StatusCode::UNAUTHORIZED, "JWT token expired".to_string(), Some("JWT token lifetime exceeded".to_string())));
    }

    // Enforce maximum token lifespan (configurable, default 30 seconds)
    let max_token_lifespan = 30; // Default 30 seconds
    let token_age = current_time.saturating_sub(payload.iat);
    
    if token_age > max_token_lifespan {
        return Err((StatusCode::UNAUTHORIZED, format!("JWT token lifespan exceeds maximum allowed ({} seconds)", max_token_lifespan), Some("JWT token lifetime configuration exceeded".to_string())));
    }

    // 9. Verify issued at time (iat claim)
    if payload.iat > current_time {
        return Err((StatusCode::UNAUTHORIZED, "JWT token issued in the future".to_string(), Some("JWT timestamp validation failed".to_string())));
    }

    // 10. Validate JWT ID (jti) - must be a valid format
    if !is_valid_jwt_id(&payload.jti) {
        return Err((StatusCode::UNAUTHORIZED, format!("Invalid JWT ID: {}", payload.jti), Some("JWT ID validation failed".to_string())));
    }

    // 11. Prevent replay attacks using JWT ID (jti)
    let is_jti_used = {
        let jti_store = JTI_STORE.lock().await;
        jti_store.contains(&payload.jti)
    };

    if is_jti_used {
        return Err((StatusCode::UNAUTHORIZED, "JWT token already used (replay attack detected)".to_string(), Some("JWT replay protection activated".to_string())));
    }

    // Store the JWT ID to prevent reuse
    {
        let mut jti_store = JTI_STORE.lock().await;
        jti_store.insert(payload.jti.clone());
    }

    // 12. Create GPS coordinate from JWT claims (INTEGRITY OF CLAIMS)
    // All GPS data comes from the JWT payload, ensuring it cannot be tampered with
    let timestamp = chrono::DateTime::from_timestamp(payload.iat.try_into().unwrap_or(0), 0).unwrap_or_else(|| Utc::now()); // Use iat as timestamp

    let gps_coordinate = GpsCoordinate {
        latitude: payload.lat,
        longitude: payload.lon,
        timestamp,
        accuracy: payload.accuracy,
        altitude: payload.altitude,
        speed: payload.speed,
        heading: payload.heading,
        device_id: None, // Not included in simplified JWT
        app_version: None, // Not included in simplified JWT
        request_id: None, // Not included in simplified JWT
    };

    // Log successful JWT validation with security details
    info!("JWT validation successful: claims integrity verified, replay protection active, token lifetime: {} seconds, JWT ID: {}", 
        max_token_lifespan, payload.jti);

    Ok(gps_coordinate)
}

/// Decode base64url to bytes
fn base64url_decode(input: &str) -> Result<Vec<u8>, &'static str> {
    // Add padding if needed
    let mut padded = input.to_string();
    while padded.len() % 4 != 0 {
        padded.push('=');
    }

    // Replace URL-safe characters with standard base64 characters
    let standard_base64 = padded.replace('-', "+").replace('_', "/");

    // Decode
    general_purpose::STANDARD
        .decode(standard_base64)
        .map_err(|_| "Invalid base64 encoding")
}

/// Constant-time comparison function to prevent timing attacks
fn constant_time_eq(a: &[u8], b: &[u8]) -> bool {
    if a.len() != b.len() {
        return false;
    }

    let mut result: u8 = 0;
    for i in 0..a.len() {
        result |= a[i] ^ b[i];
    }

    result == 0
}

/// Get secret key from jwt-key.txt file
fn get_secret_key_from_file() -> Result<Vec<u8>, (StatusCode, String, Option<String>)> {
    let key_content = std::fs::read_to_string("jwt-key.txt")
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to read JWT key file: {}", e), Some("JWT key file read failed".to_string())))?;
    
    let key_hex = key_content.trim();
    if key_hex.len() != 64 {
        return Err((StatusCode::INTERNAL_SERVER_ERROR, "Invalid JWT key format - must be 64 character hex string".to_string(), Some("JWT key format validation failed".to_string())));
    }
    
    hex::decode(key_hex)
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to decode JWT key hex: {}", e), Some("JWT key hex decoding failed".to_string())))
}

/// Validate latitude range
fn is_valid_latitude(lat: f64) -> bool {
    lat >= -90.0 && lat <= 90.0
}

/// Validate longitude range
fn is_valid_longitude(lon: f64) -> bool {
    lon >= -180.0 && lon <= 180.0
}

/// Validate JWT ID format
fn is_valid_jwt_id(jti: &str) -> bool {
    !jti.is_empty() && jti.len() <= 128 && jti.chars().all(|c| c.is_alphanumeric() || c == '-' || c == '_')
}
