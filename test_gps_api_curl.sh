#!/bin/sh
# Test script for GPS v2 API using curl

# Set JWT secret
export RAYHUNTER_JWT_SECRET=test_secret

# JWT token (replace with your generated token)
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJsYXQiOjM3Ljc3NDksImxvbiI6LTEyMi40MTk0LCJleHAiOjE3NTYxNDc5NzksImlhdCI6MTc1NjE0Nzk0OSwianRpIjoiYTVhZjg3ZjctOTBmNS00MDY4LTk0ZDEtMzU3OWVlMWU0MDUyIn0.d-Jh0hnlbp1cUW_ExmyhEsFOOCZOrE12SyEn2qmnkLc"

# Run curl with verbose output to see all headers
echo "Testing with curl..."
curl -v -X POST -H "Authorization: Bearer $TOKEN" http://localhost:8080/api/v2/gps
