#!/bin/bash

echo "Diagonal Alerts Test"
echo "==================="
echo ""
echo "This script will send 6 alerts forming a diagonal line, 50 meters apart"
echo "Starting from NYC coordinates (40.7506° N, 73.9935° W)"
echo "Moving northeast (increasing both latitude and longitude)"
echo ""

# Base coordinates (New York City)
BASE_LAT=40.7506
BASE_LON=-73.9935

# Calculate offsets (50 meters in degrees)
# 1 degree of latitude is approximately 111.32 km
# 1 degree of longitude is approximately 111.32 * cos(latitude) km
# 50 meters is approximately 0.00045 degrees of latitude
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
    
    # Use wget with proper JSON content type
    wget --quiet --output-document=- --header="Content-Type: application/json" \
      --post-data="{\"WarningDetected\":{\"event_type\":\"$severity\",\"location\":[$lat,$lon]}}" \
      http://localhost:8080/api/debug/display-state \
      && echo -e "\n$severity alert sent successfully at ($lat, $lon)"
      
    sleep 2
}

# Send alerts in a diagonal line (northeast direction)
for i in {0..5}; do
    # Calculate coordinates - move northeast (increasing both lat and lon)
    LAT=$(echo "scale=8; $BASE_LAT + ($i * $LAT_OFFSET)" | bc)
    LON=$(echo "scale=8; $BASE_LON + ($i * $LON_OFFSET)" | bc)
    
    echo "Alert $((i+1)): $LAT, $LON (offsets: lat +$i*$LAT_OFFSET, lon +$i*$LON_OFFSET)"
    
    # Send alert
    send_alert "${SEVERITIES[$i]}" $LAT $LON
done

echo ""
echo "All diagonal alerts sent. Check the map at:"
echo "http://localhost:8080/fs/debug_alerts.html"
echo "==================="
