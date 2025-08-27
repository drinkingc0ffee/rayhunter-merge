#!/bin/bash
# Script to deploy rayhunter-daemon to the device

# Define target directory on the device
TARGET_DIR="/data/rayhunter"
BINARY_PATH="target/armv7-unknown-linux-musleabihf/debug/rayhunter-daemon"

# Check if binary exists
if [ ! -f "$BINARY_PATH" ]; then
    echo "Error: Binary not found at $BINARY_PATH"
    echo "Please build the daemon first with: cargo build --target=armv7-unknown-linux-musleabihf --bin rayhunter-daemon"
    exit 1
fi

# Create target directory if it doesn't exist
echo "Creating target directory on device: $TARGET_DIR"
adb shell "mkdir -p $TARGET_DIR"

# Copy binary to device
echo "Copying rayhunter-daemon to device..."
adb push "$BINARY_PATH" "$TARGET_DIR/"

# Set executable permissions
echo "Setting executable permissions..."
adb shell "chmod 755 $TARGET_DIR/rayhunter-daemon"

echo "Deployment complete!"
echo "The daemon is now available at: $TARGET_DIR/rayhunter-daemon"
