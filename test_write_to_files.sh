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

# Calculate offsets for different locations (50-100m apart)
# 1 degree of latitude is approximately 111.32 km
# 1 degree of longitude is approximately 111.32 * cos(latitude) km
# 75 meters is approximately 0.000675 degrees of latitude
LAT_OFFSET=0.000675
# cos(40.7506) ≈ 0.7587
LON_OFFSET=$(echo "scale=8; $LAT_OFFSET / 0.7587" | bc)

echo "Calculated coordinates:"
echo "  Base location: $BASE_LAT, $BASE_LON"
echo "  Medium alert: 75m northeast"
echo "  Low alert: 150m northeast from base"
echo ""

# Send test HIGH severity alert at base location
echo "Sending HIGH alert at base coordinates ($BASE_LAT, $BASE_LON)..."
send_alert "High" "Test High severity alert with file writing" $BASE_LAT $BASE_LON

# Send test MEDIUM severity alert 75m northeast
MEDIUM_LAT=$(echo "scale=8; $BASE_LAT + $LAT_OFFSET" | bc)
MEDIUM_LON=$(echo "scale=8; $BASE_LON + $LON_OFFSET" | bc)
echo "Sending MEDIUM alert at coordinates ($MEDIUM_LAT, $MEDIUM_LON)..."
send_alert "Medium" "Test Medium severity alert with file writing" $MEDIUM_LAT $MEDIUM_LON

# Send test LOW severity alert 150m northeast from base
LOW_LAT=$(echo "scale=8; $BASE_LAT + (2 * $LAT_OFFSET)" | bc)
LOW_LON=$(echo "scale=8; $BASE_LON + (2 * $LON_OFFSET)" | bc)
echo "Sending LOW alert at coordinates ($LOW_LAT, $LOW_LON)..."
send_alert "Low" "Test Low severity alert with file writing" $LOW_LAT $LOW_LON

echo ""
echo "Check your web UI for alerts and browser notifications"
echo "To verify file writing, check the NDJSON and GPS files in /data/rayhunter/qmdl/"
echo "You can use these commands:"
echo "  adb shell rootshell -c 'ls -la /data/rayhunter/qmdl/*.ndjson | tail -5'"
echo "  adb shell rootshell -c 'cat /data/rayhunter/qmdl/[filename].ndjson | tail -5'"
echo "  adb shell rootshell -c 'ls -la /data/rayhunter/qmdl/*.gps | tail -5'"
echo "  adb shell rootshell -c 'cat /data/rayhunter/qmdl/[filename].gps | tail -5'"
echo "======================"


