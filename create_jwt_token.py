#!/usr/bin/env python3
import jwt
import time
import uuid
import sys
import argparse

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

def main():
    parser = argparse.ArgumentParser(description="Create JWT token for GPS v2 API")
    parser.add_argument("--secret", default="test_secret", help="JWT secret key")
    parser.add_argument("--lat", type=float, default=37.7749, help="Latitude")
    parser.add_argument("--lon", type=float, default=-122.4194, help="Longitude")
    parser.add_argument("--accuracy", type=float, help="Accuracy in meters")
    parser.add_argument("--altitude", type=float, help="Altitude in meters")
    parser.add_argument("--speed", type=float, help="Speed in m/s")
    parser.add_argument("--heading", type=float, help="Heading in degrees")
    
    args = parser.parse_args()
    
    token = create_jwt_token(
        args.secret, 
        args.lat, 
        args.lon, 
        args.accuracy, 
        args.altitude, 
        args.speed, 
        args.heading
    )
    
    print(f"JWT Token: {token}")
    print(f"\nCURL command:")
    print(f"curl -X POST -H 'Authorization: Bearer {token}' http://127.0.0.1:8080/api/v2/gps")

if __name__ == "__main__":
    main()
