#!/bin/bash

echo "Cell Attack Alert System Test"
echo "============================"
echo ""
echo "This script will send a test alert to the running Rayhunter daemon"
echo "Make sure the daemon is running before executing this script"
echo ""

# Base coordinates (New York City - 40.7506° N, 73.9935° W)
LAT=40.7506
LON=-73.9935

# Send test HIGH severity alert
echo "Sending test High severity alert with GPS coordinates..."
wget --quiet --output-document=- --header="Content-Type: application/json" \
  --post-data="{\"WarningDetected\":{\"event_type\":\"High\",\"location\":[$LAT,$LON]}}" \
  http://localhost:8080/api/debug/display-state \
  && echo -e "\nHigh severity alert sent successfully"

sleep 2

# Send test MEDIUM severity alert
echo "Sending test Medium severity alert with GPS coordinates..."
wget --quiet --output-document=- --header="Content-Type: application/json" \
  --post-data="{\"WarningDetected\":{\"event_type\":\"Medium\",\"location\":[$LAT,$LON]}}" \
  http://localhost:8080/api/debug/display-state \
  && echo -e "\nMedium severity alert sent successfully"

sleep 2

# Send test LOW severity alert
echo "Sending test Low severity alert with GPS coordinates..."
wget --quiet --output-document=- --header="Content-Type: application/json" \
  --post-data="{\"WarningDetected\":{\"event_type\":\"Low\",\"location\":[$LAT,$LON]}}" \
  http://localhost:8080/api/debug/display-state \
  && echo -e "\nLow severity alert sent successfully"

echo ""
echo "Check your web UI for alerts and browser notifications"
echo "============================"

