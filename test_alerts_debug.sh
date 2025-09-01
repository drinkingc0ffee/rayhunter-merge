#!/bin/bash
# Script to send multiple alerts with longer delays and debug information

echo "Testing Multiple Alerts with Debug"
echo "=================================="
echo ""

# Penn Station coordinates
LAT=40.7506
LON=-73.9935

# Send a High severity alert
echo "Sending High severity alert..."
wget --quiet --output-document=- --header="Content-Type: application/json" \
  --post-data="{\"WarningDetected\":{\"event_type\":\"High\",\"location\":[${LAT}, ${LON}],\"message\":\"Debug High Alert 1\"}}" \
  http://localhost:8080/api/debug/display-state \
  && echo -e "High alert sent successfully"

# Wait 10 seconds
echo "Waiting 10 seconds..."
sleep 10

# Send a Medium severity alert with slight offset
LAT=$(echo "$LAT + 0.001" | bc)
LON=$(echo "$LON + 0.001" | bc)
echo "Sending Medium severity alert..."
wget --quiet --output-document=- --header="Content-Type: application/json" \
  --post-data="{\"WarningDetected\":{\"event_type\":\"Medium\",\"location\":[${LAT}, ${LON}],\"message\":\"Debug Medium Alert 2\"}}" \
  http://localhost:8080/api/debug/display-state \
  && echo -e "Medium alert sent successfully"

# Wait 10 seconds
echo "Waiting 10 seconds..."
sleep 10

# Send a Low severity alert with slight offset
LAT=$(echo "$LAT + 0.001" | bc)
LON=$(echo "$LON + 0.001" | bc)
echo "Sending Low severity alert..."
wget --quiet --output-document=- --header="Content-Type: application/json" \
  --post-data="{\"WarningDetected\":{\"event_type\":\"Low\",\"location\":[${LAT}, ${LON}],\"message\":\"Debug Low Alert 3\"}}" \
  http://localhost:8080/api/debug/display-state \
  && echo -e "Low alert sent successfully"

echo ""
echo "All alerts sent. Check your web UI"
echo "=================================="
