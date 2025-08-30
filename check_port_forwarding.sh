#!/bin/bash

# Script to check and set up port forwarding for the rayhunter-daemon

echo "Checking and setting up port forwarding"
echo "===================================="

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

# Check if daemon is running
echo "Checking if daemon is running..."
PROCESS_INFO=$(adb shell rootshell -c "'ps | grep rayhunter-daemon | grep -v grep'")

if [[ -z "$PROCESS_INFO" ]]; then
    echo "❌ rayhunter-daemon is NOT running on the device"
    echo "You need to reboot the device to start the daemon."
    echo "Use: adb shell rootshell -c \"'reboot'\""
    exit 1
else
    echo "✅ rayhunter-daemon is running on the device"
fi

# Check current port forwarding
echo "Checking current port forwarding..."
CURRENT_FORWARDING=$(adb forward --list | grep "tcp:8080")

if [[ -z "$CURRENT_FORWARDING" ]]; then
    echo "Setting up port forwarding..."
    adb forward tcp:8080 tcp:8080
    echo "✅ Port forwarding set up: localhost:8080 -> device:8080"
else
    echo "✅ Port forwarding already set up: $CURRENT_FORWARDING"
fi

# Check if port is accessible
echo "Testing connection to port 8080..."
if command -v curl &> /dev/null; then
    # Use curl if available
    curl -s -I http://localhost:8080 > /dev/null
    if [ $? -eq 0 ]; then
        echo "✅ Connection successful! You should be able to access http://localhost:8080/index.html"
    else
        echo "❌ Connection failed. Port 8080 is not accessible."
    fi
elif command -v wget &> /dev/null; then
    # Use wget if curl is not available
    wget -q --spider http://localhost:8080
    if [ $? -eq 0 ]; then
        echo "✅ Connection successful! You should be able to access http://localhost:8080/index.html"
    else
        echo "❌ Connection failed. Port 8080 is not accessible."
    fi
else
    echo "⚠️ Cannot test connection (neither curl nor wget is available)"
    echo "Try accessing http://localhost:8080/index.html in your browser"
fi

# Check device IP address for direct access
echo ""
echo "Device IP address (for direct access):"
adb shell rootshell -c "'ifconfig | grep -A 1 wlan0'" | grep -o "inet addr:[0-9.]*" | cut -d: -f2

echo ""
echo "If port forwarding doesn't work, try accessing http://DEVICE_IP:8080/index.html directly"
