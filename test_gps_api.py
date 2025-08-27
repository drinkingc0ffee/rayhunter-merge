#!/usr/bin/env python3
"""
Test script for GPS v2 API with JWT authentication
"""

import jwt
import requests
import time
import json

# Configuration
JWT_SECRET = "caa3549fdf95d608e28c08f6c4b57b2d4995638584e98cf679cd27378630b46e"
API_BASE_URL = "http://localhost:8080"
GPS_ENDPOINT = f"{API_BASE_URL}/api/v2/gps"

def generate_jwt_token(lat, lon, accuracy=None, altitude=None, speed=None, heading=None):
    """Generate a JWT token with GPS coordinates"""
    now = int(time.time())
    
    payload = {
        "lat": lat,
        "lon": lon,
        "exp": now + 30,  # Expires in 30 seconds
        "iat": now,
        "jti": f"test_{now}_{lat}_{lon}",  # Unique JWT ID
    }
    
    if accuracy is not None:
        payload["accuracy"] = accuracy
    if altitude is not None:
        payload["altitude"] = altitude
    if speed is not None:
        payload["speed"] = speed
    if heading is not None:
        payload["heading"] = heading
    
    # Create JWT token
    token = jwt.encode(payload, JWT_SECRET, algorithm="HS256")
    return token

def test_gps_api(lat, lon, accuracy=None, altitude=None, speed=None, heading=None):
    """Test the GPS API endpoint"""
    try:
        # Generate JWT token
        token = generate_jwt_token(lat, lon, accuracy, altitude, speed, heading)
        print(f"Generated JWT token: {token[:50]}...")
        
        # Prepare headers
        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        }
        
        # Make POST request (no body needed, all data is in JWT)
        response = requests.post(GPS_ENDPOINT, headers=headers, timeout=10)
        
        print(f"Response Status: {response.status_code}")
        print(f"Response Headers: {dict(response.headers)}")
        
        if response.status_code == 200:
            try:
                data = response.json()
                print(f"Response Data: {json.dumps(data, indent=2)}")
                return True
            except json.JSONDecodeError:
                print(f"Response Text: {response.text}")
        else:
            print(f"Error Response: {response.text}")
            
    except requests.exceptions.RequestException as e:
        print(f"Request failed: {e}")
    except Exception as e:
        print(f"Error: {e}")
    
    return False

def main():
    """Main test function"""
    print("Testing GPS v2 API with JWT authentication")
    print("=" * 50)
    
    # Test coordinates (San Francisco)
    test_coordinates = [
        (37.7749, -122.4194, 5.0, 100.0, 25.0, 180.0),  # Full data
        (40.7128, -74.0060, 10.0, None, None, None),     # Partial data
        (51.5074, -0.1278, None, None, None, None),       # Basic coordinates
    ]
    
    for i, (lat, lon, accuracy, altitude, speed, heading) in enumerate(test_coordinates, 1):
        print(f"\nTest {i}: Coordinates ({lat}, {lon})")
        print("-" * 30)
        
        success = test_gps_api(lat, lon, accuracy, altitude, speed, heading)
        
        if success:
            print(f"✅ Test {i} PASSED")
        else:
            print(f"❌ Test {i} FAILED")
        
        # Wait between tests
        time.sleep(1)
    
    print("\n" + "=" * 50)
    print("GPS API testing complete!")

if __name__ == "__main__":
    main()
