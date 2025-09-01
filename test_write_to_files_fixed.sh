#!/bin/bash
# Test script for the new test alert endpoint that writes to NDJSON and GPS files

echo "Test Alert File Writer"
echo "======================"
echo ""
echo "This script will send test alerts that write to NDJSON and GPS files"
echo "Make sure the daemon is running before executing this script"
echo ""

# Check if wget is available
if ! command -v wget &> /dev/null; then
    echo "Error: wget is required but not installed"
    exit 1
fi

# Base coordinates (New York City)
BASE_LAT=40.7506
BASE_LON=-73.9935

# Function to send alert with location
send_alert() {
    local severity=$1
    local message=$2
    local lat=$3
    local lon=$4
    
    echo "Sending $severity alert: \"$message\" at coordinates ($lat, $lon)..."
    
    wget --quiet --output-document=- --header="Content-Type: application/json" \
      --post-data="{\"severity\":\"$severity\",\"message\":\"$message\",\"location\":[$lat,$lon]}" \
      http://localhost:8080/api/debug/test-alert \
      && echo -e "\n$severity alert sent successfully"
      
    sleep 1
}

# Send test HIGH severity alert
send_alert "High" "Test High severity alert with file writing" $BASE_LAT $BASE_LON

# Send test MEDIUM severity alert
send_alert "Medium" "Test Medium severity alert with file writing" $BASE_LAT $BASE_LON

# Send test LOW severity alert
send_alert "Low" "Test Low severity alert with file writing" $BASE_LAT $BASE_LON

echo ""
echo "Check your web UI for alerts and browser notifications"
echo "To verify file writing, check the NDJSON and GPS files in /data/rayhunter/qmdl/"
echo "You can use these commands:"
echo "  adb shell rootshell -c 'ls -la /data/rayhunter/qmdl/*.ndjson | tail -5'"
echo "  adb shell rootshell -c 'cat /data/rayhunter/qmdl/[filename].ndjson | tail -5'"
echo "  adb shell rootshell -c 'ls -la /data/rayhunter/qmdl/*.gps | tail -5'"
echo "  adb shell rootshell -c 'cat /data/rayhunter/qmdl/[filename].gps | tail -5'"
echo "======================"


