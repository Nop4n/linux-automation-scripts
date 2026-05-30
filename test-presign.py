#!/usr/bin/env python3
import urllib.request
import urllib.parse
import json
import os
import sys

API = "https://api.gumroad.com/v2"
TOKEN = open("/home/hp/products/.gumroad_token").read().strip()

print(f"Token length: {len(TOKEN)}")

# Test 1: user (should work)
print("\n--- Test 1: user endpoint ---")
req = urllib.request.Request(f"{API}/user?access_token={TOKEN}")
try:
    with urllib.request.urlopen(req, timeout=30) as resp:
        print("OK:", json.loads(resp.read()).get("success"))
except Exception as e:
    print(f"FAIL: {e}")

# Test 2: products list
print("\n--- Test 2: products list ---")
data = urllib.parse.urlencode({"access_token": TOKEN}).encode()
req = urllib.request.Request(f"{API}/products", data=data)
try:
    with urllib.request.urlopen(req, timeout=30) as resp:
        r = json.loads(resp.read())
        print("OK:", r.get("success"), "Products:", len(r.get("products", [])))
except urllib.error.HTTPError as e:
    print(f"FAIL: HTTP {e.code} - {e.read().decode()[:200]}")

# Test 3: presign
print("\n--- Test 3: presign ---")
filesize = os.path.getsize("/home/hp/products/linux-optimizer-v1.0.zip")
data = urllib.parse.urlencode({
    "access_token": TOKEN,
    "name": "linux-optimizer-v1.0.zip",
    "content_type": "application/zip",
    "size": str(filesize)
}).encode()
req = urllib.request.Request(f"{API}/files/presign", data=data)
try:
    with urllib.request.urlopen(req, timeout=30) as resp:
        r = json.loads(resp.read())
        print("OK:", json.dumps(r, indent=2)[:500])
except urllib.error.HTTPError as e:
    print(f"FAIL: HTTP {e.code}")
    body = e.read().decode()
    print(f"Body: {body[:500]}")

# Test 4: create product without file
print("\n--- Test 4: create product (no file) ---")
data = urllib.parse.urlencode({
    "access_token": TOKEN,
    "name": "Test Product",
    "price": "500",
    "description": "Test",
    "url_slug": "test-delete-me"
}).encode()
req = urllib.request.Request(f"{API}/products", data=data)
try:
    with urllib.request.urlopen(req, timeout=30) as resp:
        r = json.loads(resp.read())
        print("OK:", json.dumps(r, indent=2)[:500])
        # Delete test product
        if r.get("success"):
            pid = r["product"]["id"]
            del_data = urllib.parse.urlencode({"access_token": TOKEN}).encode()
            del_req = urllib.request.Request(f"{API}/products/{pid}", data=del_data, method="DELETE")
            with urllib.request.urlopen(del_req, timeout=30) as dr:
                print("Deleted test product")
except urllib.error.HTTPError as e:
    print(f"FAIL: HTTP {e.code} - {e.read().decode()[:300]}")
