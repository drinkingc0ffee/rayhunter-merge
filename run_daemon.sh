#!/bin/bash

echo "Building and running Rayhunter daemon..."

# Navigate to the daemon directory
cd daemon

# Build the daemon
echo "Building daemon..."
cargo build

# Check if build was successful
if [ $? -ne 0 ]; then
    echo "Build failed. Exiting."
    exit 1
fi

# Create a basic config file if it doesn't exist
CONFIG_FILE="/tmp/rayhunter_config.toml"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Creating default config file at $CONFIG_FILE"
    cat > "$CONFIG_FILE" << EOL
qmdl_store_path = "/tmp/rayhunter/qmdl"
port = 8080
debug_mode = true
device = "Orbic"
ui_level = 1
colorblind_mode = false
key_input_mode = 0

[gps]
gps_logging_enabled = true
gps_log_format = "Simple"

[alerts]
browser_notifications = true
max_alerts = 100
EOL
fi

# Create QMDL directory if it doesn't exist
mkdir -p /tmp/rayhunter/qmdl

# Kill any existing daemon
echo "Stopping any existing daemon..."
pkill -f rayhunter-daemon || true

# Run the daemon with debug logging
echo "Starting daemon with config $CONFIG_FILE..."
RUST_LOG=debug ../target/debug/rayhunter-daemon "$CONFIG_FILE"
