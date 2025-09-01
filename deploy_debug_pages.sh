#!/bin/bash
# Script to deploy all updated debug HTML files to the device

echo "Deploying updated debug HTML files to device..."

# Check device connection
ADB_PATH="/Users/beisenmann/Library/Android/sdk/platform-tools/adb"

# Check if device is connected
if ! $ADB_PATH devices | grep -q "device$"; then
    echo "No device connected. Please connect your device and try again."
    exit 1
fi

# Ensure the web directory exists
$ADB_PATH shell rootshell -c "'mkdir -p /data/rayhunter/web'"

# Deploy the map-enabled debug page
echo "Deploying debug_sse_minimal_with_map.html..."
$ADB_PATH push debug_sse_minimal_with_map_fixed.html /tmp/debug_sse_minimal_with_map.html
$ADB_PATH shell rootshell -c "'cp /tmp/debug_sse_minimal_with_map.html /data/rayhunter/web/debug_sse_minimal_with_map.html'"

# Deploy the minimal debug page
echo "Deploying debug_sse_minimal.html..."
$ADB_PATH push debug_sse_minimal_fixed.html /tmp/debug_sse_minimal.html
$ADB_PATH shell rootshell -c "'cp /tmp/debug_sse_minimal.html /data/rayhunter/web/debug_sse_minimal.html'"

# Deploy the modified index.html to the fs directory
echo "Deploying index.html to fs directory..."
$ADB_PATH shell rootshell -c "'mkdir -p /data/rayhunter/web/fs'"
$ADB_PATH push index_modified.html /tmp/index.html
$ADB_PATH shell rootshell -c "'cp /tmp/index.html /data/rayhunter/web/fs/index.html'"

# Verify the files exist
echo "Verifying deployed files..."
$ADB_PATH shell rootshell -c "'ls -la /data/rayhunter/web/debug_sse_minimal_with_map.html /data/rayhunter/web/debug_sse_minimal.html /data/rayhunter/web/fs/index.html'"

echo "Deployment complete."
echo "You can access the debug pages at:"
echo "  http://localhost:8080/fs/debug_sse_minimal_with_map.html"
echo "  http://localhost:8080/fs/debug_sse_minimal.html"
echo "  http://localhost:8080/fs/index.html"


