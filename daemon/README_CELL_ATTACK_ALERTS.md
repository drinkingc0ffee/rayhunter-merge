# Cell Attack Alert System

This feature adds real-time cell attack detection and alerting to Rayhunter. When potential attacks are detected, alerts are displayed in the web UI and can be sent as notifications.

## Features

- Real-time detection of cell network attacks
- Multiple severity levels (High, Medium, Low)
- GPS location tracking for attack events
- Browser notifications for immediate awareness
- Persistent alert history in the web UI

## Implementation Details

The implementation leverages existing components in the Rayhunter codebase:

1. **Display State Monitoring**: Uses the existing `DisplayState::WarningDetected` events
2. **GPS Integration**: Correlates attack events with GPS coordinates
3. **Server-Sent Events (SSE)**: Provides real-time alerts to web clients
4. **Web UI Component**: Displays alerts with severity-based styling

## Configuration

In your Rayhunter config file:

```toml
[alerts]
browser_notifications = true  # Enable/disable browser notifications
max_alerts = 100              # Maximum number of alerts to store in memory
```

## Testing

A test script is provided to verify the alert system functionality:

```bash
./test_attack_alert.sh
```

This will send test alerts of different severity levels to the running Rayhunter daemon.

## Technical Details

### Backend Components

1. **AlertEvent Structure** (server.rs):
   ```rust
   pub struct AlertEvent {
       pub timestamp: chrono::DateTime<chrono::Utc>,
       pub event_type: String,
       pub message: String,
       pub location: Option<(f64, f64)>,
   }
   ```

2. **SSE Endpoint** (server.rs):
   ```rust
   pub async fn get_attack_alerts_sse(
       State(state): State<Arc<ServerState>>,
   ) -> Sse<impl Stream<Item = Result<Event, std::io::Error>>>
   ```

3. **GPS Lookup** (gps_lookup.rs):
   ```rust
   pub async fn get_most_recent_gps(gps_file_path: &Path) -> Option<(f64, f64)>
   ```

4. **Alert Monitoring** (main.rs):
   ```rust
   fn setup_attack_alert_monitoring(
       task_tracker: &TaskTracker,
       alert_event_tx: broadcast::Sender<AlertEvent>,
       qmdl_store_lock: Arc<RwLock<RecordingStore>>,
   ) -> mpsc::Sender<display::DisplayState>
   ```

### Frontend Components

1. **AttackAlertSystem.svelte**: Main component for displaying alerts
2. **Browser Notifications**: Uses the Web Notifications API

## Integration

The alert system is integrated into the main page of the web UI, positioned at the top for high visibility.

## Future Enhancements

Possible future enhancements include:

1. More detailed GPS correlation with configurable time windows
2. Persistent storage of alerts across sessions
3. Enhanced filtering and sorting of alerts
4. Integration with external notification systems
