#!/bin/bash
# Script to deploy the new index.html to the device

echo "Deploying new index.html to device..."
echo "======================================"

# Push the new index.html to /tmp on the device
echo "Pushing new_index.html to /tmp on device..."
adb push new_index.html /tmp/index.html

if [ $? -ne 0 ]; then
    echo "Error: Failed to push index.html to device"
    exit 1
fi

# Copy from /tmp to /data/rayhunter/web using rootshell
echo "Copying from /tmp to /data/rayhunter/web..."
adb shell rootshell -c "'cp /tmp/index.html /data/rayhunter/web/index.html'"

if [ $? -ne 0 ]; then
    echo "Error: Failed to copy index.html to /data/rayhunter/web/"
    exit 1
fi

echo "Setting permissions..."
adb shell rootshell -c "'chmod 644 /data/rayhunter/web/index.html'"

echo ""
echo "Deployment complete!"
echo "You can now access the new index at http://localhost:8080/fs/index.html"
echo "======================================"
