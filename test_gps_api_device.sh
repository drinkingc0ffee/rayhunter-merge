#!/bin/sh
# Test script for GPS v2 API directly on the device

# Set JWT secret
export RAYHUNTER_JWT_SECRET=test_secret

# Create a simple JWT token (hardcoded for testing)
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJsYXQiOjM3Ljc3NDksImxvbiI6LTEyMi40MTk0LCJleHAiOjE3NTYxNDc5NzksImlhdCI6MTc1NjE0Nzk0OSwianRpIjoiYTVhZjg3ZjctOTBmNS00MDY4LTk0ZDEtMzU3OWVlMWU0MDUyIn0.d-Jh0hnlbp1cUW_ExmyhEsFOOCZOrE12SyEn2qmnkLc"

# Create a temporary file for the request
cat > /tmp/request.txt << EOF
POST /api/v2/gps HTTP/1.1
Host: localhost:8080
Authorization: Bearer $TOKEN
Content-Length: 0
Connection: close

EOF

# Send the request using netcat
echo "Sending request to localhost:8080..."
cat /tmp/request.txt | busybox nc localhost 8080

# Clean up
rm /tmp/request.txt
