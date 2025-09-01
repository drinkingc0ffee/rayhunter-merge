#!/bin/bash
# Script to deploy the fixed debug HTML file with map to the device

echo "Deploying debug HTML file with map support to device..."

# Check device connection
ADB_PATH="/Users/beisenmann/Library/Android/sdk/platform-tools/adb"

# Check if device is connected
if ! $ADB_PATH devices | grep -q "device$"; then
    echo "No device connected. Please connect your device and try again."
    exit 1
fi

# Ensure the web directory exists
$ADB_PATH shell rootshell -c "'mkdir -p /data/rayhunter/web'"

# Copy the debug HTML file to the device
$ADB_PATH push debug_sse_minimal_with_map_fixed.html /tmp/debug_sse_minimal_with_map.html
$ADB_PATH shell rootshell -c "'cp /tmp/debug_sse_minimal_with_map.html /data/rayhunter/web/debug_sse_minimal_with_map.html'"

# Verify the file exists
if $ADB_PATH shell rootshell -c "'ls -la /data/rayhunter/web/debug_sse_minimal_with_map.html'"; then
    echo "Debug HTML file with map deployed successfully."
    echo "You can access it at: http://localhost:8080/fs/debug_sse_minimal_with_map.html"
else
    echo "Failed to deploy the debug HTML file."
fi

