#!/usr/bin/env python3
"""Test Gumroad API"""
import urllib.request
import urllib.parse
import json
import os

API = "https://api.gumroad.com/v2"

# Read token from file
with open("/home/hp/products/.gumroad_token") as f:
    TOKEN = f.read().strip()

def api_call(endpoint, method="POST", fields=None):
    url = f"{API}/{endpoint}"
    data = urllib.parse.urlencode(fields).encode() if fields else None
    req = urllib.request.Request(url, data=data, method=method)
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            return json.loads(resp.read())
    except urllib.error.HTTPError as e:
        body = e.read().decode()
        return {"success": False, "error": f"HTTP {e.code}: {body[:200]}"}
    except Exception as e:
        return {"success": False, "error": str(e)}

# Test
print("Testing API...")
result = api_call("user", "GET", {"access_token": TOKEN})
print(json.dumps(result, indent=2))

# Test presign
print("\nTesting presign...")
filesize = os.path.getsize("/home/hp/products/linux-optimizer-v1.0.zip")
result = api_call("files/presign", "POST", {
    "access_token": TOKEN,
    "name": "linux-optimizer-v1.0.zip",
    "content_type": "application/zip",
    "size": str(filesize)
})
print(json.dumps(result, indent=2)[:1000])
