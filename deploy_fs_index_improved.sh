http://localhost:8080/fs/debug_sse_minimal_with_map.html#!/bin/bash
# Script to deploy the modified index.html to the device's filesystem

echo "Checking device connection..."
ADB_PATH="/Users/beisenmann/Library/Android/sdk/platform-tools/adb"

# Check if device is connected
if ! $ADB_PATH devices | grep -q "device$"; then
    echo "No device connected. Please connect your device and try again."
    exit 1
fi

echo "Device connected. Deploying modified index.html to device filesystem..."

# First, ensure the fs directory exists
$ADB_PATH shell rootshell -c "'mkdir -p /data/rayhunter/web/fs'"

# Push the file to the device's temporary directory
$ADB_PATH push index_modified.html /tmp/index.html

# Move the file to the correct location using rootshell
$ADB_PATH shell rootshell -c "'cp /tmp/index.html /data/rayhunter/web/fs/index.html'"

# Verify the file exists
if $ADB_PATH shell rootshell -c "'ls -la /data/rayhunter/web/fs/index.html'"; then
    echo "File successfully deployed."
    echo "You can access the modified index.html at http://localhost:8080/fs/index.html"
else
    echo "Failed to deploy the file. Please check the device connection and permissions."
fi

