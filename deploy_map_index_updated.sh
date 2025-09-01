#!/bin/bash
# Script to deploy the enhanced map-enabled index page

echo "Deploying Enhanced Map-Enabled Index Page"
echo "========================================"
echo ""

# Define paths
ADB_PATH="/Users/beisenmann/Library/Android/sdk/platform-tools/adb"

# Check if device is connected
echo "Checking for connected device..."
$ADB_PATH devices | grep -v "List" | grep -v "^$" > /dev/null
if [ $? -ne 0 ]; then
    echo "Error: No device connected. Please connect your device and try again."
    exit 1
fi

# Push the file to the device's /tmp directory first
echo "Pushing index_with_map.html to device..."
$ADB_PATH push index_with_map.html /tmp/

# Copy from /tmp to the web directory using rootshell
echo "Copying to web directory..."
$ADB_PATH shell rootshell -c "'cp /tmp/index_with_map.html /data/rayhunter/web/index.html'"

echo ""
echo "Deployment complete!"
echo "You can access the enhanced map-enabled index page at:"
echo "http://localhost:8080/fs/index.html"
echo "========================================"


