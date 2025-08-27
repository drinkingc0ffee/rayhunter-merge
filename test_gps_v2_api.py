#!/usr/bin/env python3
import requests
import jwt
import time
import uuid

API_URL = "http://localhost:8080/api/v2/gps"  # Change port if needed
KEY_PATH = "/Users/beisenmann/rayhunter-merge/jwt-key.txt"

def get_secret():
    with open(KEY_PATH, "r") as f:
        return f.read().strip()

def test_request(token, payload_desc):
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    print("\n--- REQUEST ---")
    print(f"POST {API_URL}")
    print("Headers:", headers)
    print("JWT Payload:", payload_desc)
    response = requests.post(API_URL, headers=headers, json={})
    print("\n--- RESPONSE ---")
    print("Status:", response.status_code)
    print("Headers:", dict(response.headers))
    print("Body:", response.text)

def main():
    key = get_secret()
    now = int(time.time())

    print("Testing valid JWT...")
    valid_payload = {
        "sub": "testuser",
        "lat": 37.7749,
        "lon": -122.4194,
        "exp": now + 60,
        "iat": now,
        "jti": str(uuid.uuid4())
    }
    valid_token = jwt.encode(valid_payload, key, algorithm="HS256")
    test_request(valid_token, valid_payload)

    print("\nTesting expired JWT...")
    expired_payload = valid_payload.copy()
    expired_payload["exp"] = now - 60
    expired_token = jwt.encode(expired_payload, key, algorithm="HS256")
    test_request(expired_token, expired_payload)

    print("\nTesting with wrong key...")
    wrong_token = jwt.encode(valid_payload, "wrongkey", algorithm="HS256")
    test_request(wrong_token, valid_payload)

    print("\nTesting with missing fields...")
    incomplete_payload = {
        "sub": "testuser",
        "exp": now + 60,
        "iat": now,
        "jti": str(uuid.uuid4())
        # missing lat/lon
    }
    incomplete_token = jwt.encode(incomplete_payload, key, algorithm="HS256")
    test_request(incomplete_token, incomplete_payload)

if __name__ == "__main__":
    main()
