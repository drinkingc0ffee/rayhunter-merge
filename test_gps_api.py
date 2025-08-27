#!/usr/bin/env python3
import requests
import jwt
import time
import uuid
import sys
import os

def create_jwt_token(secret, lat, lon, accuracy=None, altitude=None, speed=None, heading=None):
    """Create a JWT token for GPS v2 API"""
    now = int(time.time())
    payload = {
        # GPS coordinates
        "lat": lat,
        "lon": lon,
        
        # Required JWT claims
        "exp": now + 30,  # 30 seconds expiration
        "iat": now,       # issued at
        "jti": str(uuid.uuid4()),  # unique ID to prevent replay attacks
    }
    
    # Add optional fields if provided
    if accuracy is not None:
        payload["accuracy"] = accuracy
    if altitude is not None:
        payload["altitude"] = altitude
    if speed is not None:
        payload["speed"] = speed
    if heading is not None:
        payload["heading"] = heading
    
    # Create token
    token = jwt.encode(payload, secret, algorithm="HS256")
    return token

def test_gps_api():
    # Create JWT token
    secret = "test_secret"
    token = create_jwt_token(secret, 37.7749, -122.4194, accuracy=10.0)
    
    # Set up ADB port forwarding
    os.system("adb forward tcp:8080 tcp:8080")
    
    # Set environment variable on device
    os.system("adb shell \"export RAYHUNTER_JWT_SECRET=test_secret\"")
    
    # Make request
    headers = {
        "Authorization": f"Bearer {token}"
    }
    
    print(f"Sending request with token: {token}")
    try:
        response = requests.post("http://localhost:8080/api/v2/gps", headers=headers)
        print(f"Status Code: {response.status_code}")
        print(f"Response: {response.text}")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    test_gps_api()
