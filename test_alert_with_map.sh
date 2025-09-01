#!/bin/bash
# Test script for the /api/debug/test-alert endpoint that writes to NDJSON and GPS files
# and shows the location on the map

echo "Test Alert with Map Integration"
echo "=============================="
echo ""
echo "This script will send a test alert that writes to NDJSON and GPS files"
echo "and displays the location on the map in the web UI"
echo ""

# Check if wget is available
if ! command -v wget &> /dev/null; then
    echo "Error: wget is required but not installed"
    exit 1
fi

# NYC coordinates
LAT=40.7506
LON=-73.9935

# Send test HIGH severity alert with location
echo "Sending HIGH severity alert with NYC coordinates ($LAT, $LON)..."
wget --quiet --output-document=- --header="Content-Type: application/json" \
  --post-data="{\"severity\":\"High\",\"message\":\"Cell attack detected in New York City\",\"location\":[$LAT,$LON]}" \
  http://localhost:8080/api/debug/test-alert \
  && echo -e "\nHIGH alert sent successfully"

echo ""
echo "Check your web UI at http://localhost:8080/fs/index.html"
echo "You should see:"
echo "1. A toast notification for the alert"
echo "2. The alert in the Cell Attack Alerts section at the top"
echo "3. A map showing the location of the attack"
echo ""
echo "This alert has been written to:"
echo "- The NDJSON file for the current recording"
echo "- The GPS file for the current recording"
echo "=============================="


