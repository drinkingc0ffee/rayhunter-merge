#!/bin/bash

# Script to enable debug logging for the rayhunter-daemon on the embedded Linux device
# This script modifies the config file to enable debug mode and then reboots the device

echo "Enabling debug logging for rayhunter-daemon"
echo "========================================"

# Check if ADB is available
if ! command -v adb &> /dev/null; then
    echo "Error: ADB is required but not installed"
    exit 1
fi

# Check if device is connected
echo "Checking device connection..."
if ! adb devices | grep -q "device$"; then
    echo "Error: No device connected or device not authorized"
    echo "Please connect a device and ensure it's authorized for ADB"
    exit 1
fi

# Create a temporary config file with debug mode enabled
echo "Creating config file with debug logging enabled..."
cat > /tmp/rayhunter_config.toml << EOL
qmdl_store_path = "/data/rayhunter/qmdl"
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

# Copy config to device
echo "Copying config to device..."
adb push /tmp/rayhunter_config.toml /tmp/rayhunter_config.toml
adb shell rootshell -c "'cp /tmp/rayhunter_config.toml /data/rayhunter/config.toml'"
adb shell rootshell -c "'chmod 644 /data/rayhunter/config.toml'"
adb shell rootshell -c "'rm /tmp/rayhunter_config.toml'"

# Clean up local temp file
rm /tmp/rayhunter_config.toml

# Set environment variable for debug logging
echo "Setting RUST_LOG environment variable..."
adb shell rootshell -c "'echo \"export RUST_LOG=debug\" > /data/rayhunter/env.sh'"
adb shell rootshell -c "'chmod 755 /data/rayhunter/env.sh'"

# Add environment loading to init script if possible
echo "Attempting to configure system to load debug environment..."
adb shell rootshell -c "'if [ -f /etc/init.d/rayhunter ]; then grep -q \"env.sh\" /etc/init.d/rayhunter || sed -i \"s|/data/rayhunter/rayhunter-daemon|. /data/rayhunter/env.sh \\&\\& /data/rayhunter/rayhunter-daemon|\" /etc/init.d/rayhunter; fi'"

# Reboot the device
echo "Rebooting device to apply changes..."
adb shell rootshell -c "'reboot'"

echo "Device is rebooting with debug logging enabled."
echo "After reboot, you can check logs with: ./check_daemon_status.sh"
