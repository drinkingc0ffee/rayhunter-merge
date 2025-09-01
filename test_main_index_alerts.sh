#!/bin/bash

echo "Testing Main Index.html Alert System"
echo "===================================="
echo ""
echo "This script will test if the main index.html alert system is working"
echo "Make sure you have http://127.0.0.1:8080/fs/index.html open in your browser"
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
      --post-data="{\"WarningDetected\":{\"event_type\":\"$severity\",\"message\":\"$message\",\"location\":[$lat,$lon]}}" \
      http://localhost:8080/api/debug/display-state \
      && echo -e "\n$severity alert sent successfully"
      
    sleep 2
}

echo "Sending 3 test alerts to verify the main index.html alert system..."
echo ""

# Send test alerts with different locations
send_alert "High" "Test High severity alert for main index.html" $BASE_LAT $BASE_LON

# Send Medium alert 75m northeast
MEDIUM_LAT=$(echo "scale=8; $BASE_LAT + 0.000675" | bc)
MEDIUM_LON=$(echo "scale=8; $BASE_LON + 0.000889" | bc)
send_alert "Medium" "Test Medium severity alert for main index.html" $MEDIUM_LAT $MEDIUM_LON

# Send Low alert 150m northeast from base
LOW_LAT=$(echo "scale=8; $BASE_LAT + 0.00135" | bc)
LOW_LON=$(echo "scale=8; $BASE_LON + 0.001778" | bc)
send_alert "Low" "Test Low severity alert for main index.html" $LOW_LAT $LOW_LON

echo ""
echo "Test complete! Check your main index.html page at:"
echo "http://127.0.0.1:8080/fs/index.html"
echo ""
echo "You should see:"
echo "1. Three alerts displayed above the map"
echo "2. Three markers on the map at different locations"
echo "3. Toast notifications for each alert"
echo "4. Ability to click alerts and dismiss them"
echo "===================================="
