#!/bin/bash

echo "Line of Alerts Test"
echo "=================="
echo ""
echo "This script will send 6 alerts forming a straight line eastward, 50 meters apart"
echo "Starting from NYC coordinates (40.7506° N, 73.9935° W)"
echo "Note: Only longitude changes (moving east), latitude stays constant"
echo ""

# Base coordinates (New York City)
BASE_LAT=40.7506
BASE_LON=-73.9935

# Calculate offsets (50 meters in degrees)
# 1 degree of latitude is approximately 111.32 km
# 1 degree of longitude is approximately 111.32 * cos(latitude) km
# 50 meters is approximately 0.00045 degrees of latitude
# 50 meters in longitude depends on the latitude
LAT_OFFSET=0.00045
# cos(40.7506) ≈ 0.7587
LON_OFFSET=$(echo "scale=8; $LAT_OFFSET / 0.7587" | bc)

# Severities for the alerts
SEVERITIES=("High" "Medium" "Low" "Medium" "High" "Low")

# Function to send alert with location
send_alert() {
    local severity=$1
    local lat=$2
    local lon=$3
    
    echo "Sending $severity alert at coordinates ($lat, $lon)..."
    
    # Use fetch with proper JSON content type
    wget --quiet --output-document=- --header="Content-Type: application/json" \
      --post-data="{\"WarningDetected\":{\"event_type\":\"$severity\",\"location\":[$lat,$lon]}}" \
      http://localhost:8080/api/debug/display-state \
      && echo -e "\n$severity alert sent successfully at ($lat, $lon)"
      
    sleep 1
}

# Send alerts in a line (eastward direction)
for i in {0..5}; do
    # Calculate coordinates - move eastward (increasing longitude)
    LAT=$(echo "scale=8; $BASE_LAT" | bc)
    LON=$(echo "scale=8; $BASE_LON + ($i * $LON_OFFSET)" | bc)
    
    echo "Alert $((i+1)): $LAT, $LON (offset: $i * $LON_OFFSET = $(echo "scale=8; $i * $LON_OFFSET" | bc))"
    
    # Send alert
    send_alert "${SEVERITIES[$i]}" $LAT $LON
done

echo ""
echo "All alerts sent. Check the map at:"
echo "http://localhost:8080/fs/debug_sse_minimal_with_map_fixed2.html"
echo "=================="


