#!/bin/sh
# Test script for GPS v2 API

# Set JWT secret
export RAYHUNTER_JWT_SECRET=test_secret

# JWT token (replace with your generated token)
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJsYXQiOjM3Ljc3NDksImxvbiI6LTEyMi40MTk0LCJleHAiOjE3NTYxNDY5NzksImlhdCI6MTc1NjE0Njk0OSwianRpIjoiYTVhZjg3ZjctOTBmNS00MDY4LTk0ZDEtMzU3OWVlMWU0MDUyIn0.d-Jh0hnlbp1cUW_ExmyhEsFOOCZOrE12SyEn2qmnkLc"

# Test with busybox wget
echo "Testing with busybox wget..."
busybox wget -qO- --method=POST --header="Authorization: Bearer $TOKEN" http://127.0.0.1:8080/api/v2/gps

# Create a temporary file for the request
echo "Testing with netcat..."
cat > /tmp/request.txt << EOF
POST /api/v2/gps HTTP/1.1
Host: 127.0.0.1:8080
Authorization: Bearer $TOKEN
Content-Length: 0
Connection: close

EOF

# Send the request using netcat
cat /tmp/request.txt | busybox nc 127.0.0.1 8080

# Clean up
rm /tmp/request.txt
