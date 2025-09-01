#!/bin/bash
# Script to simulate a real analyzer warning by sending a display state update

echo "Rayhunter Real Analyzer Warning Simulator"
echo "========================================"
echo ""

# Check if the daemon is running
DAEMON_RUNNING=$(/Users/beisenmann/Library/Android/sdk/platform-tools/adb shell rootshell -c "'ps | grep rayhunter-daemon | grep -v grep'")
if [ -z "$DAEMON_RUNNING" ]; then
    echo "Error: Rayhunter daemon is not running"
    exit 1
fi

# Send a display state update with a High severity warning
echo "Sending High severity warning to the daemon..."
wget --quiet --output-document=- --header="Content-Type: application/json" \
  --post-data='{"WarningDetected":{"event_type":"High"}}' \
  http://localhost:8080/api/debug/display-state \
  && echo -e "\nHigh severity warning sent successfully"

echo ""
echo "Check the web UI for alerts at:"
echo "http://localhost:8080/index.html"
echo "http://localhost:8080/fs/debug_sse_test.html"
echo "========================================"


