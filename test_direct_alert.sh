#!/bin/bash
# Script to directly send an alert to the broadcast channel

echo "Direct Alert Test"
echo "================="
echo ""

# Send a direct alert using the debug display state endpoint
echo "Sending direct alert..."
wget --quiet --output-document=- --header="Content-Type: application/json" \
  --post-data='{"WarningDetected":{"event_type":"High"}}' \
  http://localhost:8080/api/debug/display-state \
  && echo -e "\nAlert sent successfully"

echo ""
echo "Check your web UI for alerts"
echo "=================="


