#!/bin/bash
# Script to simulate an analyzer warning by modifying an NDJSON file

echo "Rayhunter Analyzer Warning Simulator"
echo "===================================="
echo ""

# Check if adb is available
if ! command -v /Users/beisenmann/Library/Android/sdk/platform-tools/adb &> /dev/null; then
    echo "Error: adb is required but not found at the specified path"
    exit 1
fi

# Get current QMDL files
echo "Checking current QMDL entries..."
ENTRIES=$(/Users/beisenmann/Library/Android/sdk/platform-tools/adb shell rootshell -c "'ls -1 /data/rayhunter/qmdl/*.ndjson'")

if [ -z "$ENTRIES" ]; then
    echo "No NDJSON files found. Make sure recording is active."
    exit 1
fi

# Get the most recent NDJSON file
LATEST_NDJSON=$(echo "$ENTRIES" | tail -n 1)
echo "Found latest NDJSON file: $LATEST_NDJSON"

# Create a temporary file with the modified NDJSON content
echo "Creating modified NDJSON content with a High severity warning..."
TMP_FILE="/tmp/modified_ndjson.json"

# First, get the current content
/Users/beisenmann/Library/Android/sdk/platform-tools/adb shell rootshell -c "'cat $LATEST_NDJSON'" > $TMP_FILE

# Add a warning entry to the file
cat > /tmp/warning_entry.json << EOL
{"timestamp":"$(date -u +"%Y-%m-%dT%H:%M:%SZ")","event_type":"High","message":"Null Cipher detected","analyzer":"Null Cipher","details":"Cell is using null encryption (EEA0)"}
EOL

# Push the warning entry to the device
/Users/beisenmann/Library/Android/sdk/platform-tools/adb push /tmp/warning_entry.json /tmp/

# Append the warning entry to the NDJSON file on the device
/Users/beisenmann/Library/Android/sdk/platform-tools/adb shell rootshell -c "'cat /tmp/warning_entry.json >> $LATEST_NDJSON'"

echo "Warning entry added to $LATEST_NDJSON"
echo "Check the web UI for alerts"
echo "===================================="


