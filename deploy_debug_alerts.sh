#!/bin/bash
# Script to deploy the debug alerts HTML file with automatic version incrementing

# Set the full path to adb
ADB_PATH="/Users/beisenmann/Library/Android/sdk/platform-tools/adb"

# Version file to track the current version
VERSION_FILE="debug_version.txt"

echo "Debug Alerts Deployment with Auto-Versioning"
echo "============================================"

# Initialize version file if it doesn't exist
if [ ! -f "$VERSION_FILE" ]; then
    echo "1.0" > "$VERSION_FILE"
    echo "Initialized version file with v1.0"
fi

# Read current version and increment
CURRENT_VERSION=$(cat "$VERSION_FILE")
echo "Current version: $CURRENT_VERSION"

# Parse version components
MAJOR=$(echo "$CURRENT_VERSION" | cut -d. -f1)
MINOR=$(echo "$CURRENT_VERSION" | cut -d. -f2)

# Increment minor version
NEW_MINOR=$((MINOR + 1))
NEW_VERSION="${MAJOR}.${NEW_MINOR}"

echo "Incrementing to version: $NEW_VERSION"

# Update version file
echo "$NEW_VERSION" > "$VERSION_FILE"

# Update version number in the debug_alerts.html file
echo "Updating version number in debug_alerts.html..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS (BSD) - use simpler, more reliable pattern
    sed -i '' "s/Debug Alerts v[0-9]*\.[0-9]*/Debug Alerts v${NEW_VERSION}/g" debug_alerts.html
else
    # Linux (GNU)
    sed -i "s/Debug Alerts v[0-9]*\.[0-9]*/Debug Alerts v${NEW_VERSION}/g" debug_alerts.html
fi

echo "Version updated to v${NEW_VERSION}"

# Deploy the updated file
echo ""
echo "Deploying debug alerts HTML to device..."
echo "========================================="

# Push the debug alerts HTML to /tmp on the device
echo "Pushing debug_alerts.html to /tmp on device..."
$ADB_PATH push debug_alerts.html /tmp/debug_alerts.html

if [ $? -ne 0 ]; then
    echo "Error: Failed to push debug_alerts.html to device"
    exit 1
fi

# Copy from /tmp to /data/rayhunter/web using rootshell
echo "Copying from /tmp to /data/rayhunter/web..."
$ADB_PATH shell rootshell -c "'cp /tmp/debug_alerts.html /data/rayhunter/web/debug_alerts.html'"

if [ $? -ne 0 ]; then
    echo "Error: Failed to copy debug_alerts.html to /data/rayhunter/web/"
    exit 1
fi

echo "Setting permissions..."
$ADB_PATH shell rootshell -c "'chmod 644 /data/rayhunter/web/debug_alerts.html'"

echo ""
echo "Deployment complete!"
echo "New version v${NEW_VERSION} deployed successfully!"
echo "You can now access the updated debug page at http://localhost:8080/fs/debug_alerts.html"
echo "========================================="
