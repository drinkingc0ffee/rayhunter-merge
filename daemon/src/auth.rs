use axum::{
    extract::State,
    http::StatusCode,
    response::{IntoResponse, Json},
};
use serde_json::Value;
use std::sync::Arc;
use crate::server::ServerState;

pub async fn gps_api_v2(
    State(_state): State<Arc<ServerState>>,
) -> impl IntoResponse {
    // Simple GPS endpoint without JWT for now
    let response = serde_json::json!({
        "status": "success",
        "message": "GPS endpoint working!",
        "data": {
            "latitude": 0.0,
            "longitude": 0.0,
            "timestamp": "2025-08-26T03:30:00Z"
        }
    });
    
    (StatusCode::OK, Json(response))
}
