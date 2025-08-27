#!/opt/local/bin/python3
import requests
import jwt
import time
import uuid

API_URL = "http://localhost:8080/api/v2/gps"  # Change port if needed
KEY_PATH = "/Users/beisenmann/rayhunter-merge/jwt-key.txt"

def get_secret():
    with open(KEY_PATH, "r") as f:
        return f.read().strip()

def make_jwt(sub, lat, lon, exp_offset=60, valid=True, key=None):
    now = int(time.time())
    payload = {
        "sub": sub,
        "lat": lat,
        "lon": lon,
        "exp": now + exp_offset if valid else now - 60,  # expired if not valid
        "iat": now,
        "jti": str(uuid.uuid4())
    }
    token = jwt.encode(payload, key, algorithm="HS256")
    return token

def test_request(token):
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    response = requests.post(API_URL, headers=headers, json={})
    print(f"Status: {response.status_code}")
    print(f"Response: {response.text}")

def main():
    key = get_secret()
    print("Testing valid JWT...")
    valid_token = make_jwt("testuser", 37.7749, -122.4194, valid=True, key=key)
    test_request(valid_token)

    print("\nTesting expired JWT...")
    expired_token = make_jwt("testuser", 37.7749, -122.4194, valid=False, key=key)
    test_request(expired_token)

    print("\nTesting with wrong key...")
    wrong_token = make_jwt("testuser", 37.7749, -122.4194, valid=True, key="wrongkey")
    test_request(wrong_token)

    print("\nTesting with missing fields...")
    now = int(time.time())
    incomplete_payload = {
        "sub": "testuser",
        "exp": now + 60,
        "iat": now,
        "jti": str(uuid.uuid4())
        # missing lat/lon
    }
    incomplete_token = jwt.encode(incomplete_payload, key, algorithm="HS256")
    test_request(incomplete_token)

if __name__ == "__main__":
    main()
