#!/bin/bash
# Script to send a single alert with a specific severity

if [ $# -ne 1 ]; then
  echo "Usage: $0 <high|medium|low>"
  exit 1
fi

SEVERITY=$(echo "$1" | tr '[:lower:]' '[:upper:]')

if [[ "$SEVERITY" != "HIGH" && "$SEVERITY" != "MEDIUM" && "$SEVERITY" != "LOW" ]]; then
  echo "Error: Severity must be high, medium, or low"
  exit 1
fi

echo "Testing Single $SEVERITY Alert"
echo "=========================="
echo ""

# Penn Station coordinates
LAT=40.7506
LON=-73.9935

# Send the alert
echo "Sending $SEVERITY severity alert..."
wget --quiet --output-document=- --header="Content-Type: application/json" \
  --post-data="{\"WarningDetected\":{\"event_type\":\"$SEVERITY\",\"location\":[${LAT}, ${LON}],\"message\":\"Debug $SEVERITY Alert\"}}" \
  http://localhost:8080/api/debug/display-state \
  && echo -e "$SEVERITY alert sent successfully"

echo ""
echo "Alert sent. Check your web UI"
echo "=========================="
