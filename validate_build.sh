#!/bin/bash

# Script to validate the rayhunter-daemon build
# This script builds the daemon in Docker and checks the MD5 checksum

echo "Rayhunter Daemon Build Validation"
echo "================================="

# Build the daemon using Docker
echo "Building daemon in Docker container..."
docker exec -it orbic-aug-25-25-container cargo build --release --target="armv7-unknown-linux-musleabihf" --bin rayhunter-daemon
if [ $? -ne 0 ]; then
    echo "Build failed. Exiting."
    exit 1
fi

# Copy binary from Docker container
echo "Copying binary from Docker container..."
docker cp orbic-aug-25-25-container:/workdir/target/armv7-unknown-linux-musleabihf/release/rayhunter-daemon ./rayhunter-daemon
if [ $? -ne 0 ]; then
    echo "Failed to copy binary from Docker container. Exiting."
    exit 1
fi

# Calculate MD5 of the local binary
echo "Calculating MD5 of local binary..."
LOCAL_MD5=$(md5sum ./rayhunter-daemon | awk '{print $1}')
echo "Local binary MD5: $LOCAL_MD5"

# Check if device is connected
echo "Checking device connection..."
if ! adb devices | grep -q "device$"; then
    echo "Error: No device connected or device not authorized"
    echo "Please connect a device and ensure it's authorized for ADB"
    exit 1
fi

# Calculate MD5 of the device binary
echo "Calculating MD5 of device binary..."
DEVICE_MD5=$(adb shell rootshell -c "'md5sum /data/rayhunter/rayhunter-daemon'" | awk '{print $1}')
echo "Device binary MD5: $DEVICE_MD5"

# Compare MD5 checksums
if [ "$LOCAL_MD5" = "$DEVICE_MD5" ]; then
    echo "✅ Validation successful: MD5 checksums match"
else
    echo "❌ Validation failed: MD5 checksums do not match"
    echo "Local:  $LOCAL_MD5"
    echo "Device: $DEVICE_MD5"
fi

# Clean up
echo "Cleaning up..."
rm ./rayhunter-daemon

echo "Validation complete."
