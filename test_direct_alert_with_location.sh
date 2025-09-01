#!/bin/bash
# Script to directly send an alert with location data to the broadcast channel

echo "Direct Alert Test with Location"
echo "=============================="
echo ""

# Send a direct alert using the debug display state endpoint
echo "Sending direct alert with NYC coordinates..."
wget --quiet --output-document=- --header="Content-Type: application/json" \
  --post-data='{"WarningDetected":{"event_type":"High","location":[40.7506, -73.9935]}}' \
  http://localhost:8080/api/debug/display-state \
  && echo -e "\nAlert with location sent successfully"

echo ""
echo "Check your web UI for alerts with map pins"
echo "=============================="


