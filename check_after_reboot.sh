#!/bin/bash

# Script to check daemon status after reboot

echo "Waiting for device to come back online..."
adb wait-for-device

echo "Device is back online."
echo "Setting up port forwarding..."
adb forward tcp:8080 tcp:8080

echo "Checking if daemon is running..."
PROCESS_INFO=$(adb shell rootshell -c "'ps | grep rayhunter-daemon | grep -v grep'")

if [[ -z "$PROCESS_INFO" ]]; then
    echo "❌ rayhunter-daemon is NOT running"
    echo "Checking logs for errors..."
    adb shell rootshell -c "'cat /data/rayhunter/rayhunter.log'"
else
    echo "✅ rayhunter-daemon is running:"
    echo "$PROCESS_INFO"
fi
