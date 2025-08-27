#!/bin/sh
# Test script for GPS v2 API

# Set JWT secret
export RAYHUNTER_JWT_SECRET=test_secret

# JWT token (replace with your generated token)
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJsYXQiOjM3Ljc3NDksImxvbiI6LTEyMi40MTk0LCJleHAiOjE3NTYxNDY5NzksImlhdCI6MTc1NjE0Njk0OSwianRpIjoiYTVhZjg3ZjctOTBmNS00MDY4LTk0ZDEtMzU3OWVlMWU0MDUyIn0.d-Jh0hnlbp1cUW_ExmyhEsFOOCZOrE12SyEn2qmnkLc"

# Create a temporary file for the request
cat > /tmp/request.txt << EOF
POST /api/v2/gps HTTP/1.1
Host: 127.0.0.1:8080
Authorization: Bearer $TOKEN
Content-Length: 0

EOF

# Send the request using netcat
cat /tmp/request.txt | nc 127.0.0.1 8080

# Clean up
rm /tmp/request.txt
