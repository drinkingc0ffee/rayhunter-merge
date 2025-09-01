#!/bin/bash
# Script to deploy server-side changes to handle location data in alerts

echo "Deploying server-side changes for location data in alerts..."

# Check device connection
ADB_PATH="/Users/beisenmann/Library/Android/sdk/platform-tools/adb"

# Check if device is connected
if ! $ADB_PATH devices | grep -q "device$"; then
    echo "No device connected. Please connect your device and try again."
    exit 1
fi

# Create daemon/src directory if it doesn't exist
$ADB_PATH shell rootshell -c "'mkdir -p /data/rayhunter/daemon/src'"

# Push the modified files to the device
echo "Pushing modified files to device..."
$ADB_PATH push debug_display_state_with_location.rs /tmp/debug_display_state_with_location.rs
$ADB_PATH push debug_set_display_state_with_location.rs /tmp/debug_set_display_state_with_location.rs

$ADB_PATH shell rootshell -c "'cp /tmp/debug_display_state_with_location.rs /data/rayhunter/daemon/src/debug_display_state_with_location.rs'"
$ADB_PATH shell rootshell -c "'cp /tmp/debug_set_display_state_with_location.rs /data/rayhunter/daemon/src/debug_set_display_state_with_location.rs'"

echo "Files deployed to /data/rayhunter/daemon/src/"
echo ""
echo "IMPORTANT: To implement these changes, you'll need to:"
echo "1. Modify daemon/src/main.rs to import and use the new modules"
echo "2. Update the route in main.rs to use debug_set_display_state_with_location"
echo "3. Rebuild and redeploy the daemon"
echo "4. Reboot the device"
echo ""
echo "Since these changes require rebuilding the daemon, they cannot be"
echo "deployed directly to the running system."
echo ""
echo "Alternative approach:"
echo "Instead of modifying the server, we can update the test scripts to send"
echo "location data directly to the SSE endpoint for testing purposes."
echo ""
echo "Would you like to create a test script that directly sends alerts with"
echo "location data to the SSE endpoint? (y/n)"
read -p "> " response

if [[ "$response" =~ ^[Yy]$ ]]; then
    echo "Creating direct SSE test script..."
    cat > direct_sse_test.sh << 'EOF'
#!/bin/bash

# Test script to send alerts directly to the SSE endpoint
# This bypasses the DisplayState API and sends alerts with location data directly

echo "Direct SSE Alert Test"
echo "===================="
echo ""
echo "This script will send test alerts directly to the SSE endpoint"
echo ""

# NYC coordinates (40.7506° N, 73.9935° W)
LAT=40.7506
LON=-73.9935

# Function to send a direct alert
send_direct_alert() {
    local severity=$1
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%NZ")
    
    echo "Sending direct $severity alert with coordinates ($LAT, $LON)..."
    
    # Create alert JSON
    local alert_json=$(cat << EOF
{
  "timestamp": "$timestamp",
  "event_type": "$severity",
  "message": "Rayhunter has detected a $severity severity event",
  "location": [$LAT, $LON]
}
EOF
)
    
    # Send to a temporary endpoint that will broadcast to SSE clients
    # Note: This endpoint would need to be implemented in the daemon
    wget --quiet --output-document=- --header="Content-Type: application/json" \
      --post-data="$alert_json" \
      http://localhost:8080/api/debug/direct-alert \
      && echo -e "\n$severity alert sent successfully"
}

# Send test alerts
send_direct_alert "High"
sleep 2
send_direct_alert "Medium"
sleep 2
send_direct_alert "Low"

echo ""
echo "Check your web UI for alerts"
echo "===================="
EOF
    
    chmod +x direct_sse_test.sh
    echo "Created direct_sse_test.sh"
    echo ""
    echo "Note: This script requires a new endpoint (/api/debug/direct-alert)"
    echo "to be implemented in the daemon."
fi

echo ""
echo "Deployment complete."


