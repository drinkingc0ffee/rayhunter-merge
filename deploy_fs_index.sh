#!/bin/bash
# Script to deploy index.html to the device with automatic version incrementing

# Set the full path to adb
ADB_PATH="/Users/beisenmann/Library/Android/sdk/platform-tools/adb"

# Version file to track the current version
VERSION_FILE="index_version.txt"

echo "Index.html Deployment with Auto-Versioning"
echo "=========================================="

# Initialize version file if it doesn't exist
if [ ! -f "$VERSION_FILE" ]; then
    echo "0.6.2.0" > "$VERSION_FILE"
    echo "Initialized version file with v0.6.2.0"
fi

# Read current version and increment
CURRENT_VERSION=$(cat "$VERSION_FILE")
echo "Current version: $CURRENT_VERSION"

# Parse version components (0.6.2.X format)
MAJOR=$(echo "$CURRENT_VERSION" | cut -d. -f1)
MINOR=$(echo "$CURRENT_VERSION" | cut -d. -f2)
PATCH=$(echo "$CURRENT_VERSION" | cut -d. -f3)
BUILD=$(echo "$CURRENT_VERSION" | cut -d. -f4)

# Increment build number (X in 0.6.2.X)
NEW_BUILD=$((BUILD + 1))
NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}.${NEW_BUILD}"

echo "Incrementing to version: $NEW_VERSION"

# Update version file
echo "$NEW_VERSION" > "$VERSION_FILE"

# Get current deployment time
DEPLOYMENT_TIME=$(date '+%Y-%m-%d %H:%M:%S')

# Update version number and deployment time in index_fixed.html
echo "Updating version number and deployment time in index_fixed.html..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS (BSD) - update version and add deployment time
    sed -i '' "s/Rayhunter Version: [0-9]*\.[0-9]*\.[0-9]*\.[0-9]* GE.*/Rayhunter Version: ${NEW_VERSION} GE (Deployed: ${DEPLOYMENT_TIME})/g" index_fixed.html
else
    # Linux (GNU)
    sed -i "s/Rayhunter Version: [0-9]*\.[0-9]*\.[0-9]*\.[0-9]* GE.*/Rayhunter Version: ${NEW_VERSION} GE (Deployed: ${DEPLOYMENT_TIME})/g" index_fixed.html
fi

echo "Version updated to v${NEW_VERSION} with deployment time: ${DEPLOYMENT_TIME}"

# Deploy the updated file
echo ""
echo "Deploying index.html to device..."
echo "=================================="

# Push the updated index_fixed.html to /tmp on the device
echo "Pushing index_fixed.html to /tmp on device..."
$ADB_PATH push index_fixed.html /tmp/index.html

if [ $? -ne 0 ]; then
    echo "Error: Failed to push index_fixed.html to device"
    exit 1
fi

# Copy from /tmp to /data/rayhunter/web/index.html using rootshell
echo "Copying from /tmp to /data/rayhunter/web/index.html..."
$ADB_PATH shell rootshell -c "'cp /tmp/index.html /data/rayhunter/web/index.html'"

if [ $? -ne 0 ]; then
    echo "Error: Failed to copy index.html to /data/rayhunter/web/"
    exit 1
fi

echo "Setting permissions..."
$ADB_PATH shell rootshell -c "'chmod 644 /data/rayhunter/web/index.html'"

echo ""
echo "Deployment complete!"
echo "New version v${NEW_VERSION} deployed successfully!"
echo "Deployment time: ${DEPLOYMENT_TIME}"
echo "You can now access the updated page at http://localhost:8080/fs/index.html"
echo "=================================="

