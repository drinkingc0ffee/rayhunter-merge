use rayhunter::analysis::analyzer::EventType;
use serde::{Deserialize, Serialize};

/// Extended version of DisplayState that includes location data
/// This is used only for debugging purposes
#[derive(Clone, PartialEq, Serialize, Deserialize, Debug)]
pub enum DebugDisplayState {
    /// We're recording but no warning has been found yet.
    Recording,
    /// We're not recording.
    Paused,
    /// A non-informational event has been detected.
    ///
    /// Note that EventType::Informational is never sent through this. If it is, it's the same as
    /// Recording
    WarningDetected { 
        event_type: EventType,
        /// Optional GPS coordinates [latitude, longitude]
        location: Option<(f64, f64)>,
    },
}

/// Convert DebugDisplayState to regular DisplayState
impl From<DebugDisplayState> for crate::display::DisplayState {
    fn from(debug_state: DebugDisplayState) -> Self {
        match debug_state {
            DebugDisplayState::Recording => crate::display::DisplayState::Recording,
            DebugDisplayState::Paused => crate::display::DisplayState::Paused,
            DebugDisplayState::WarningDetected { event_type, .. } => {
                crate::display::DisplayState::WarningDetected { event_type }
            }
        }
    }
}


