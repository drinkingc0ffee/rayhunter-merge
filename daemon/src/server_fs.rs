use axum::extract::Path;
use axum::http::header::{self, HeaderValue};
use axum::http::StatusCode;
use axum::response::IntoResponse;
use log::{debug, warn};
use std::path::PathBuf;
use tokio::fs::File;
use tokio_util::io::ReaderStream;

// Serve static files from filesystem
pub async fn serve_fs_static(Path(path): Path<String>) -> impl IntoResponse {
    let path = path.trim_start_matches('/');
    let fs_path = PathBuf::from("/data/rayhunter/web").join(path);
    
    debug!("Attempting to serve file from filesystem: {:?}", fs_path);
    
    match File::open(&fs_path).await {
        Ok(file) => {
            let stream = ReaderStream::new(file);
            let body = axum::body::Body::from_stream(stream);
            
            // Determine content type based on file extension
            let content_type = match path.split('.').last() {
                Some("html") => "text/html",
                Some("css") => "text/css",
                Some("js") => "application/javascript",
                Some("png") => "image/png",
                Some("jpg") | Some("jpeg") => "image/jpeg",
                Some("gif") => "image/gif",
                Some("svg") => "image/svg+xml",
                Some("json") => "application/json",
                _ => "application/octet-stream",
            };
            
            debug!("Serving file from filesystem: {:?} as {}", fs_path, content_type);
            
            ([(header::CONTENT_TYPE, HeaderValue::from_static(content_type))], body).into_response()
        },
        Err(err) => {
            warn!("Failed to open file from filesystem: {:?} - {}", fs_path, err);
            StatusCode::NOT_FOUND.into_response()
        }
    }
}
