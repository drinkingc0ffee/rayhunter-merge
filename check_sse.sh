#!/bin/bash

echo "Checking SSE endpoint connectivity..."

# Use wget to connect to the SSE endpoint
wget -O - http://localhost:8080/api/attack-alerts
