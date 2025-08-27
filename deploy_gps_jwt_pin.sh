#!/bin/bash
# Script to deploy gps_jwt_pin tool to the device

# Define target directory on the device
TARGET_DIR="/data/rayhunter/tools"
BINARY_PATH="target/armv7-unknown-linux-musleabihf/debug/gps_jwt_pin"

# Check if binary exists
if [ ! -f "$BINARY_PATH" ]; then
    echo "Error: Binary not found at $BINARY_PATH"
    echo "Please build the tool first with: cargo build --target=armv7-unknown-linux-musleabihf --bin gps_jwt_pin"
    exit 1
fi

# Create target directory if it doesn't exist
echo "Creating target directory on device: $TARGET_DIR"
adb shell "mkdir -p $TARGET_DIR"

# Copy binary to device
echo "Copying gps_jwt_pin to device..."
adb push "$BINARY_PATH" "$TARGET_DIR/"

# Set executable permissions
echo "Setting executable permissions..."
adb shell "chmod 755 $TARGET_DIR/gps_jwt_pin"

echo "Deployment complete!"
echo "The tool is now available at: $TARGET_DIR/gps_jwt_pin"
