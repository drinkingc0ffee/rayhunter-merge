#!/usr/bin/env python3

import math
import requests
import time
import json

print("Line of Alerts Test")
print("==================")
print("")
print("This script will send 6 alerts forming a straight line, 50 meters apart")
print("Starting from NYC coordinates (40.7506° N, 73.9935° W)")
print("")

# Base coordinates (New York City)
BASE_LAT = 40.7506
BASE_LON = -73.9935

# Calculate offsets (50 meters in degrees)
# 1 degree of latitude is approximately 111.32 km
# 1 degree of longitude is approximately 111.32 * cos(latitude) km
METERS_PER_DEGREE_LAT = 111320
METERS_PER_DEGREE_LON = 111320 * math.cos(math.radians(BASE_LAT))

# 50 meters in degrees
LAT_OFFSET = 50 / METERS_PER_DEGREE_LAT
LON_OFFSET = 50 / METERS_PER_DEGREE_LON

# Severities for the alerts
SEVERITIES = ["High", "Medium", "Low", "Medium", "High", "Low"]

# Function to send alert with location
def send_alert(severity, lat, lon):
    print(f"Sending {severity} alert at coordinates ({lat:.6f}, {lon:.6f})...")
    
    # Prepare data
    data = {
        "WarningDetected": {
            "event_type": severity,
            "location": [lat, lon]
        }
    }
    
    # Send request
    response = requests.post(
        "http://localhost:8080/api/debug/display-state",
        headers={"Content-Type": "application/json"},
        data=json.dumps(data)
    )
    
    if response.status_code == 200:
        print(f"{severity} alert sent successfully at ({lat:.6f}, {lon:.6f})")
    else:
        print(f"Error sending alert: {response.status_code} - {response.text}")
    
    time.sleep(1)

# Send alerts in a line (eastward direction)
for i in range(6):
    # Calculate coordinates
    lat = BASE_LAT
    lon = BASE_LON + (i * LON_OFFSET)
    
    # Send alert
    send_alert(SEVERITIES[i], lat, lon)

print("")
print("All alerts sent. Check the map at:")
print("http://localhost:8080/fs/debug_sse_minimal_with_map_fixed2.html")
print("==================")


