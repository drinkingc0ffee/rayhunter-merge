#!/bin/bash
# Script to deploy release versions of rayhunter-daemon and gps_jwt_pin to the device
# Using /tmp directory and rootshell for final placement

# Define paths
DAEMON_BINARY="target/armv7-unknown-linux-musleabihf/release/rayhunter-daemon"
GPS_JWT_PIN_BINARY="target/armv7-unknown-linux-musleabihf/release/gps_jwt_pin"
DAEMON_DEST="/data/rayhunter/rayhunter-daemon"
GPS_JWT_PIN_DEST="/data/rayhunter/gps_jwt_pin"  # Changed from /data/rayhunter/tools/gps_jwt_pin

# Check if binaries exist
if [ ! -f "$DAEMON_BINARY" ]; then
    echo "Error: Daemon binary not found at $DAEMON_BINARY"
    exit 1
fi

if [ ! -f "$GPS_JWT_PIN_BINARY" ]; then
    echo "Error: GPS JWT PIN binary not found at $GPS_JWT_PIN_BINARY"
    exit 1
fi

# Push binaries to /tmp on device
echo "Pushing rayhunter-daemon to /tmp..."
adb push "$DAEMON_BINARY" /tmp/rayhunter-daemon
echo "Pushing gps_jwt_pin to /tmp..."
adb push "$GPS_JWT_PIN_BINARY" /tmp/gps_jwt_pin

# Move binaries to final destinations using rootshell
echo "Moving binaries to final destinations..."
adb shell "rootshell cp /tmp/rayhunter-daemon $DAEMON_DEST"
adb shell "rootshell cp /tmp/gps_jwt_pin $GPS_JWT_PIN_DEST"

# Set executable permissions
echo "Setting executable permissions..."
adb shell "rootshell chmod 755 $DAEMON_DEST"
adb shell "rootshell chmod 755 $GPS_JWT_PIN_DEST"

# Clean up /tmp
echo "Cleaning up /tmp..."
adb shell "rm /tmp/rayhunter-daemon"
adb shell "rm /tmp/gps_jwt_pin"

echo "Deployment complete!"
echo "rayhunter-daemon is now available at: $DAEMON_DEST"
echo "gps_jwt_pin is now available at: $GPS_JWT_PIN_DEST"
