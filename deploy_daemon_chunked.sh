#!/bin/bash
# Script to deploy rayhunter-daemon to the device using smaller chunks
# This approach helps when /tmp has limited space

# Define paths
DAEMON_BINARY="target/armv7-unknown-linux-musleabihf/debug/rayhunter-daemon"
DAEMON_DEST="/data/rayhunter/rayhunter-daemon"
CHUNK_SIZE=10M  # Split into 10MB chunks

# Check if binary exists
if [ ! -f "$DAEMON_BINARY" ]; then
    echo "Error: Daemon binary not found at $DAEMON_BINARY"
    exit 1
fi

# Create a temporary directory
TEMP_DIR=$(mktemp -d)
echo "Created temporary directory: $TEMP_DIR"

# Split the binary into chunks
echo "Splitting daemon binary into chunks..."
split -b $CHUNK_SIZE "$DAEMON_BINARY" "$TEMP_DIR/daemon_chunk_"

# Push chunks to device
echo "Pushing chunks to device..."
for chunk in "$TEMP_DIR"/daemon_chunk_*; do
    chunk_name=$(basename "$chunk")
    echo "Pushing chunk $chunk_name..."
    adb push "$chunk" "/tmp/$chunk_name"
done

# Combine chunks on device
echo "Combining chunks on device..."
adb shell "cat /tmp/daemon_chunk_* > /tmp/rayhunter-daemon"

# Create destination directory using rootshell
echo "Creating destination directory..."
adb shell "rootshell mkdir -p /data/rayhunter"

# Move binary to final destination using rootshell
echo "Moving binary to final destination..."
adb shell "rootshell cp /tmp/rayhunter-daemon $DAEMON_DEST"

# Set executable permissions
echo "Setting executable permissions..."
adb shell "rootshell chmod 755 $DAEMON_DEST"

# Clean up /tmp
echo "Cleaning up /tmp..."
adb shell "rm /tmp/daemon_chunk_*"
adb shell "rm /tmp/rayhunter-daemon"

# Clean up local temp directory
echo "Cleaning up local temp directory..."
rm -rf "$TEMP_DIR"

echo "Deployment complete!"
echo "rayhunter-daemon is now available at: $DAEMON_DEST"
