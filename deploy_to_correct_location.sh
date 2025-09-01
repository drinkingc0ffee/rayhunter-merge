#!/bin/bash
# Script to deploy HTML files to the correct location

echo "Deploying HTML Files to Correct Location"
echo "========================================"
echo ""

# Define paths
ADB_PATH="/Users/beisenmann/Library/Android/sdk/platform-tools/adb"

# Function to deploy a file
deploy_file() {
    local file=$1
    echo "Deploying $file..."
    
    # Push the file to the device's /tmp directory first
    echo "  Pushing to device..."
    $ADB_PATH push $file /tmp/
    
    # Copy from /tmp to the web directory using rootshell
    echo "  Copying to web directory..."
    $ADB_PATH shell rootshell -c "'cp /tmp/$file /data/rayhunter/web/'"
    
    echo "  $file deployed successfully"
    echo ""
}

# Deploy files
deploy_file "index_with_alerts.html"
deploy_file "simple_sse_test.html"

# Rename index_with_alerts.html to index.html on the device
echo "Renaming index_with_alerts.html to index.html..."
$ADB_PATH shell rootshell -c "'mv /data/rayhunter/web/index_with_alerts.html /data/rayhunter/web/index.html'"

echo ""
echo "Deployment complete!"
echo "You can access the files at:"
echo "http://localhost:8080/fs/index.html"
echo "http://localhost:8080/fs/simple_sse_test.html"
echo "========================================"


