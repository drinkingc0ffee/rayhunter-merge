#!/bin/bash
# Test script for the cell attack alert system

echo "Cell Attack Alert System Test"
echo "============================"
echo ""
echo "This script will send a test alert to the running Rayhunter daemon"
echo "Make sure the daemon is running before executing this script"
echo ""

# Check if wget is available
if ! command -v wget &> /dev/null; then
    echo "Error: wget is required but not installed"
    exit 1
fi

# Send test HIGH severity alert
echo "Sending test High severity alert..."
wget --quiet --output-document=- --header="Content-Type: application/json" \
  --post-data='{"WarningDetected":{"event_type":"High"}}' \
  http://localhost:8080/api/debug/display-state \
  && echo -e "\nHigh severity alert sent successfully"

sleep 2

# Send test MEDIUM severity alert
echo "Sending test Medium severity alert..."
wget --quiet --output-document=- --header="Content-Type: application/json" \
  --post-data='{"WarningDetected":{"event_type":"Medium"}}' \
  http://localhost:8080/api/debug/display-state \
  && echo -e "\nMedium severity alert sent successfully"

sleep 2

# Send test LOW severity alert
echo "Sending test Low severity alert..."
wget --quiet --output-document=- --header="Content-Type: application/json" \
  --post-data='{"WarningDetected":{"event_type":"Low"}}' \
  http://localhost:8080/api/debug/display-state \
  && echo -e "\nLow severity alert sent successfully"

echo ""
echo "Check your web UI for alerts and browser notifications"
echo "============================"
