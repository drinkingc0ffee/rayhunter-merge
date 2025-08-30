#!/bin/bash

# Test script for the cell attack alert system with GPS coordinates
# GPS coordinates are centered on New York City (40.7506° N, 73.9935° W)

echo "Cell Attack Alert System GPS Test"
echo "================================="
echo ""
echo "This script will send test alerts with GPS coordinates to the Rayhunter daemon"
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

# Function to generate slightly randomized coordinates
generate_coords() {
    # Add small random offset (-0.01 to 0.01 degrees, approximately 1km)
    LAT_OFFSET=$(awk -v seed=$RANDOM 'BEGIN { srand(seed); print rand()*0.02-0.01 }')
    LON_OFFSET=$(awk -v seed=$RANDOM 'BEGIN { srand(seed); print rand()*0.02-0.01 }')
    
    LAT=$(awk "BEGIN { printf \"%.6f\", $BASE_LAT + $LAT_OFFSET }")
    LON=$(awk "BEGIN { printf \"%.6f\", $BASE_LON + $LON_OFFSET }")
    
    echo "$LAT,$LON"
}

# Create GPS data file in the current recording directory
create_gps_data() {
    # Get the current recording directory
    QMDL_DIR=$(adb shell rootshell -c "'ls -1t /data/rayhunter/qmdl/*.qmdl 2>/dev/null | head -1'" | sed 's/\.qmdl$//')
    
    if [ -z "$QMDL_DIR" ]; then
        echo "No active recording found. Cannot create GPS data."
        return 1
    fi
    
    # Get coordinates
    COORDS=$(generate_coords)
    LAT=$(echo $COORDS | cut -d',' -f1)
    LON=$(echo $COORDS | cut -d',' -f2)
    
    # Create GPS data entry
    TIMESTAMP=$(date +%s)
    GPS_ENTRY="$TIMESTAMP,$LAT,$LON"
    
    # Write to GPS file
    GPS_FILE="${QMDL_DIR}.gps"
    adb shell rootshell -c "'echo \"$GPS_ENTRY\" >> $GPS_FILE'"
    
    echo "Added GPS coordinates ($LAT, $LON) to $GPS_FILE"
    return 0
}

# Send test HIGH severity alert
echo "Sending test High severity alert with GPS coordinates..."
create_gps_data
wget --quiet --output-document=- --header="Content-Type: application/json" \
  --post-data='{"WarningDetected":{"event_type":"High"}}' \
  http://localhost:8080/api/debug/display-state \
  && echo -e "\nHigh severity alert sent successfully"

sleep 2

# Send test MEDIUM severity alert
echo "Sending test Medium severity alert with GPS coordinates..."
create_gps_data
wget --quiet --output-document=- --header="Content-Type: application/json" \
  --post-data='{"WarningDetected":{"event_type":"Medium"}}' \
  http://localhost:8080/api/debug/display-state \
  && echo -e "\nMedium severity alert sent successfully"

sleep 2

# Send test LOW severity alert
echo "Sending test Low severity alert with GPS coordinates..."
create_gps_data
wget --quiet --output-document=- --header="Content-Type: application/json" \
  --post-data='{"WarningDetected":{"event_type":"Low"}}' \
  http://localhost:8080/api/debug/display-state \
  && echo -e "\nLow severity alert sent successfully"

echo ""
echo "Check your web UI for alerts and browser notifications"
echo "Navigate to: http://localhost:8080/fs/debug_sse_minimal.html"
echo "================================="
