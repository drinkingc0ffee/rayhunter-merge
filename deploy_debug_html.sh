#!/bin/bash

# Script to deploy the debug HTML file to the device
echo "Deploying debug HTML file to device..."

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

# Create directory on device if it doesn't exist
echo "Creating web directory on device..."
adb shell rootshell -c "'mkdir -p /data/rayhunter/web'"

# Push debug HTML file to device
echo "Copying debug HTML file to device..."
adb push debug_sse_minimal.html /tmp/debug_sse_minimal.html
adb shell rootshell -c "'cp /tmp/debug_sse_minimal.html /data/rayhunter/web/debug_sse_minimal.html'"
adb shell rootshell -c "'chmod 644 /data/rayhunter/web/debug_sse_minimal.html'"
adb shell rootshell -c "'rm /tmp/debug_sse_minimal.html'"

echo "Debug HTML file deployed successfully."
echo "You can access it at: http://DEVICE_IP:8080/fs/debug_sse_minimal.html"
