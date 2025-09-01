#!/bin/bash
# Script to deploy the enhanced index.html file with alert functionality

echo "Deploying Enhanced Index.html with Alert Functionality"
echo "===================================================="
echo ""

# Define paths
ADB_PATH="adb"

# Push the file to the device's /tmp directory first
echo "Pushing index_with_alerts.html to device..."
$ADB_PATH push index_with_alerts.html /tmp/

# Copy from /tmp to the web directory using rootshell
echo "Copying to web fs directory..."
$ADB_PATH shell rootshell -c "'cp /tmp/index_with_alerts.html /data/rayhunter/web/fs/index.html'"

echo ""
echo "Deployment complete!"
echo "You can access the enhanced index page at:"
echo "http://localhost:8080/fs/index.html"
echo "===================================================="


