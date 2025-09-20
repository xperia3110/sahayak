#!/usr/bin/env python3
"""
Simple test script to verify the API endpoints are working
"""
import requests
import json

BASE_URL = "http://127.0.0.1:8000/api"

def test_register():
    """Test user registration"""
    print("Testing user registration...")
    data = {
        "username": "testuser",
        "email": "test@example.com",
        "password": "testpass123"
    }
    
    try:
        response = requests.post(f"{BASE_URL}/auth/register/", json=data)
        print(f"Status Code: {response.status_code}")
        print(f"Response: {response.json()}")
        return response.json().get('token')
    except Exception as e:
        print(f"Error: {e}")
        return None

def test_login():
    """Test user login"""
    print("\nTesting user login...")
    data = {
        "username": "testuser",
        "password": "testpass123"
    }
    
    try:
        response = requests.post(f"{BASE_URL}/auth/login/", json=data)
        print(f"Status Code: {response.status_code}")
        print(f"Response: {response.json()}")
        return response.json().get('token')
    except Exception as e:
        print(f"Error: {e}")
        return None

def test_authenticated_endpoint(token):
    """Test an authenticated endpoint"""
    print(f"\nTesting authenticated endpoint with token: {token[:10]}...")
    headers = {
        "Authorization": f"Token {token}",
        "Content-Type": "application/json"
    }
    
    try:
        response = requests.get(f"{BASE_URL}/children/", headers=headers)
        print(f"Status Code: {response.status_code}")
        print(f"Response: {response.json()}")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    print("Testing SAHAYAK API Endpoints")
    print("=" * 40)
    
    # Test registration
    token = test_register()
    
    if token:
        # Test login
        token = test_login()
        
        if token:
            # Test authenticated endpoint
            test_authenticated_endpoint(token)
    
    print("\nTest completed!")
