#!/bin/sh
# Test script for POST endpoints

# Test endpoint (change this to test different endpoints)
ENDPOINT="/api/start-recording"

# Create a temporary file for the request
cat > /tmp/request.txt << EOF
POST $ENDPOINT HTTP/1.1
Host: localhost:8080
Content-Length: 0
Connection: close

EOF

# Send the request using netcat
echo "Sending POST request to localhost:8080$ENDPOINT..."
cat /tmp/request.txt | busybox nc localhost 8080

# Clean up
rm /tmp/request.txt
