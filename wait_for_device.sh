#!/bin/bash

# Script to wait for device to come back online after reboot

echo "Waiting for device to come back online..."
echo "This may take a minute or two..."

# Wait for device to be available
adb wait-for-device

echo "Device is back online!"
echo "Setting up port forwarding..."
adb forward tcp:8080 tcp:8080

echo "Waiting for daemon to start..."
sleep 10

# Check if daemon is running
echo "Checking if daemon is running..."
PROCESS_INFO=$(adb shell rootshell -c "'ps | grep rayhunter-daemon | grep -v grep'")

if [[ -z "$PROCESS_INFO" ]]; then
    echo "❌ rayhunter-daemon is NOT running on the device"
    echo "There might be an issue with the daemon startup."
    
    # Check logs for errors
    echo "Checking logs for errors..."
    adb shell rootshell -c "'logcat -d | grep -i rayhunter'" | grep -i error
else
    echo "✅ rayhunter-daemon is running on the device"
    echo "You should now be able to access http://localhost:8080/index.html"
fi
