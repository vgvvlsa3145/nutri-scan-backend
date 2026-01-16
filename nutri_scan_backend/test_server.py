import requests
import time

print("Attempting to connect to the server...")
url = "http://127.0.0.1:5000/api/health"

try:
    response = requests.get(url)
    print(f"Status Code: {response.status_code}")
    print(f"Response: {response.json()}")
    
    if response.status_code == 200:
        print("\n\u2705 SUCCESS: Backend is running and reachable!")
    else:
        print("\n\u274c FAIL: Backend returned error.")
        
except Exception as e:
    print(f"\n\u274c ERROR: Could not connect to server. {e}")
