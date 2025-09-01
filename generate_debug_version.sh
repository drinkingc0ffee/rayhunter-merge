#!/bin/bash
# Script to generate a new version of debug_alerts.html with incremented version number

# Version file to track the current version
VERSION_FILE="debug_version.txt"

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

echo "New version: $NEW_VERSION"

# Update version file
echo "$NEW_VERSION" > "$VERSION_FILE"

# Create new debug file with updated version
NEW_FILE="debug_alerts_v${NEW_VERSION}.html"

# Copy the template and update version
cp debug_alerts.html "$NEW_FILE"

# Update version number in the new file
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s/Debug Alerts v[0-9]\+\.[0-9]\+/Debug Alerts v${NEW_VERSION}/g" "$NEW_FILE"
else
    # Linux
    sed -i "s/Debug Alerts v[0-9]\+\.[0-9]\+/Debug Alerts v${NEW_VERSION}/g" "$NEW_FILE"
fi

echo "Generated new debug file: $NEW_FILE with version v${NEW_VERSION}"

# Optionally deploy the new version
read -p "Deploy this new version to device? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Deploying $NEW_FILE to device..."
    
    # Set the full path to adb
    ADB_PATH="/Users/beisenmann/Library/Android/sdk/platform-tools/adb"
    
    # Push to device
    $ADB_PATH push "$NEW_FILE" /tmp/debug_alerts.html
    
    if [ $? -eq 0 ]; then
        # Copy to web directory
        $ADB_PATH shell rootshell -c "'cp /tmp/debug_alerts.html /data/rayhunter/web/debug_alerts.html'"
        
        if [ $? -eq 0 ]; then
            echo "Setting permissions..."
            $ADB_PATH shell rootshell -c "'chmod 644 /data/rayhunter/web/debug_alerts.html'"
            echo "Deployment complete!"
            echo "New version v${NEW_VERSION} available at: http://localhost:8080/fs/debug_alerts.html"
        else
            echo "Error: Failed to copy file to device"
        fi
    else
        echo "Error: Failed to push file to device"
    fi
else
    echo "New file $NEW_FILE created but not deployed."
    echo "You can deploy it manually later."
fi

echo "Version tracking updated in $VERSION_FILE"
