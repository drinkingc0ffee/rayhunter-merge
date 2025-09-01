#!/bin/bash
# Script to deploy the test alerts HTML file to the device

echo "Deploying Test Alerts HTML File"
echo "=============================="
echo ""

# Check if adb is available
ADB_PATH="/Users/beisenmann/Library/Android/sdk/platform-tools/adb"
if [ ! -f "$ADB_PATH" ]; then
    echo "Error: adb not found at $ADB_PATH"
    exit 1
fi

# Push the file to the device's /tmp directory first
echo "Pushing debug_test_alerts.html to device..."
$ADB_PATH push debug_test_alerts.html /tmp/

# Copy from /tmp to the web directory using rootshell
echo "Copying to web directory..."
$ADB_PATH shell rootshell -c "'mkdir -p /data/rayhunter/web/ && cp /tmp/debug_test_alerts.html /data/rayhunter/web/'"

echo ""
echo "Deployment complete!"
echo "You can access the test page at:"
echo "http://localhost:8080/fs/debug_test_alerts.html"
echo "=============================="


