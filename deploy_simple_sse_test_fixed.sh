#!/bin/bash
# Script to deploy the simple SSE test HTML file

echo "Deploying Simple SSE Test HTML"
echo "============================="
echo ""

# Define paths
ADB_PATH="/Users/beisenmann/Library/Android/sdk/platform-tools/adb"

# Push the file to the device's /tmp directory first
echo "Pushing simple_sse_test.html to device..."
$ADB_PATH push simple_sse_test.html /tmp/

# Copy from /tmp to the web directory using rootshell
echo "Copying to web fs directory..."
$ADB_PATH shell rootshell -c "'cp /tmp/simple_sse_test.html /data/rayhunter/web/fs/'"

echo ""
echo "Deployment complete!"
echo "You can access the simple SSE test page at:"
echo "http://localhost:8080/fs/simple_sse_test.html"
echo "============================="


