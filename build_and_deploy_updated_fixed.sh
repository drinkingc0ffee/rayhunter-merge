#!/bin/bash
# Script to build and deploy the daemon with the updated test alert functionality

echo "Building and Deploying Updated Rayhunter Daemon"
echo "=============================================="
echo ""

# Define paths
ADB_PATH="adb"
DOCKER_CONTAINER="orbic-aug-25-25-container"

# Build the daemon in Docker
echo "Building daemon in Docker container..."
docker exec -it $DOCKER_CONTAINER cargo build --release --target="armv7-unknown-linux-musleabihf" --bin rayhunter-daemon

# Check if build was successful
if [ $? -ne 0 ]; then
    echo "Error: Build failed"
    exit 1
fi

# Push the binary to the device
echo "Pushing binary to device..."
$ADB_PATH push ./target/armv7-unknown-linux-musleabihf/release/rayhunter-daemon /tmp/

# Install the binary on the device
echo "Installing binary on device..."
$ADB_PATH shell rootshell -c "'cp /tmp/rayhunter-daemon /data/rayhunter/rayhunter-daemon && chmod 755 /data/rayhunter/rayhunter-daemon'"

# Reboot the device
echo "Rebooting device to apply changes..."
$ADB_PATH shell rootshell -c "'reboot'"

echo ""
echo "Deployment initiated. The device is rebooting."
echo "Wait for the device to come back online, then set up port forwarding:"
echo "adb forward tcp:8080 tcp:8080"
echo ""
echo "Then you can access the test page at:"
echo "http://localhost:8080/fs/debug_test_alerts.html"
echo "=============================================="


