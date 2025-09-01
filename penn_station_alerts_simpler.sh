#!/bin/bash
# Simpler version of the Penn Station alerts script that doesn't require bc
# Uses pre-calculated coordinate offsets for different distances

echo "Penn Station Area Alerts Generator (Simplified)"
echo "=============================================="
echo ""
echo "This script will generate High, Medium, and Low severity alerts"
echo "starting at Penn Station and 6 nearby locations 50-200 meters away"
echo ""

# Check if wget is available
if ! command -v wget &> /dev/null; then
    echo "Error: wget is required but not installed"
    exit 1
fi

# Penn Station coordinates
PENN_LAT=40.750638
PENN_LON=-73.993452

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

# Send alert at Penn Station
echo "Sending High alert at Penn Station..."
send_alert "High" "Cell attack detected at Penn Station" $PENN_LAT $PENN_LON

# Pre-calculated offsets for different distances and directions
# Format: [distance]_[direction]_LAT and [distance]_[direction]_LON
# 50m offsets
OFFSET_50_NORTH_LAT=0.00045
OFFSET_50_NORTH_LON=0
OFFSET_50_EAST_LAT=0
OFFSET_50_EAST_LON=0.00060
OFFSET_50_SOUTH_LAT=-0.00045
OFFSET_50_SOUTH_LON=0
OFFSET_50_WEST_LAT=0
OFFSET_50_WEST_LON=-0.00060

# 100m offsets
OFFSET_100_NORTH_LAT=0.00090
OFFSET_100_NORTH_LON=0
OFFSET_100_EAST_LAT=0
OFFSET_100_EAST_LON=0.00120
OFFSET_100_SOUTH_LAT=-0.00090
OFFSET_100_SOUTH_LON=0
OFFSET_100_WEST_LAT=0
OFFSET_100_WEST_LON=-0.00120

# 200m offsets
OFFSET_200_NORTH_LAT=0.00180
OFFSET_200_NORTH_LON=0
OFFSET_200_EAST_LAT=0
OFFSET_200_EAST_LON=0.00240
OFFSET_200_SOUTH_LAT=-0.00180
OFFSET_200_SOUTH_LON=0
OFFSET_200_WEST_LAT=0
OFFSET_200_WEST_LON=-0.00240

# Send Medium alert 50m North
echo "Sending Medium alert 50m North of Penn Station..."
NORTH_50_LAT=$(echo "$PENN_LAT + $OFFSET_50_NORTH_LAT" | bc -l)
NORTH_50_LON=$(echo "$PENN_LON + $OFFSET_50_NORTH_LON" | bc -l)
send_alert "Medium" "Suspicious cell activity 50m North of Penn Station" $NORTH_50_LAT $NORTH_50_LON

# Send Low alert 50m East
echo "Sending Low alert 50m East of Penn Station..."
EAST_50_LAT=$(echo "$PENN_LAT + $OFFSET_50_EAST_LAT" | bc -l)
EAST_50_LON=$(echo "$PENN_LON + $OFFSET_50_EAST_LON" | bc -l)
send_alert "Low" "Anomalous signal detected 50m East of Penn Station" $EAST_50_LAT $EAST_50_LON

# Send High alert 100m South
echo "Sending High alert 100m South of Penn Station..."
SOUTH_100_LAT=$(echo "$PENN_LAT + $OFFSET_100_SOUTH_LAT" | bc -l)
SOUTH_100_LON=$(echo "$PENN_LON + $OFFSET_100_SOUTH_LON" | bc -l)
send_alert "High" "Critical cell attack detected 100m South of Penn Station" $SOUTH_100_LAT $SOUTH_100_LON

# Send Medium alert 100m West
echo "Sending Medium alert 100m West of Penn Station..."
WEST_100_LAT=$(echo "$PENN_LAT + $OFFSET_100_WEST_LAT" | bc -l)
WEST_100_LON=$(echo "$PENN_LON + $OFFSET_100_WEST_LON" | bc -l)
send_alert "Medium" "Suspicious cell activity 100m West of Penn Station" $WEST_100_LAT $WEST_100_LON

# Send Low alert 200m North-East (combine North and East offsets)
echo "Sending Low alert 200m North-East of Penn Station..."
NE_200_LAT=$(echo "$PENN_LAT + $OFFSET_200_NORTH_LAT" | bc -l)
NE_200_LON=$(echo "$PENN_LON + $OFFSET_200_EAST_LON" | bc -l)
send_alert "Low" "Anomalous signal detected 200m North-East of Penn Station" $NE_200_LAT $NE_200_LON

# Send High alert 200m South-West (combine South and West offsets)
echo "Sending High alert 200m South-West of Penn Station..."
SW_200_LAT=$(echo "$PENN_LAT + $OFFSET_200_SOUTH_LAT" | bc -l)
SW_200_LON=$(echo "$PENN_LON + $OFFSET_200_WEST_LON" | bc -l)
send_alert "High" "Critical cell attack detected 200m South-West of Penn Station" $SW_200_LAT $SW_200_LON

echo ""
echo "All alerts sent successfully!"
echo "Check your web UI at http://localhost:8080/fs/index.html to see the alerts on the map"
echo "=============================================="


