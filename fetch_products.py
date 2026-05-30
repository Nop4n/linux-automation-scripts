#!/usr/bin/env python3
"""Fetch all Gumroad products and display current listings"""
import urllib.request
import urllib.parse
import json

with open("/home/hp/products/.gumroad_token") as f:
    TOKEN = f.read().strip()

API = "https://api.gumroad.com/v2"

def api_get(endpoint, params=None):
    url = f"{API}/{endpoint}"
    if params:
        url += "?" + urllib.parse.urlencode(params)
    req = urllib.request.Request(url, method="GET")
    req.add_header("Authorization", f"Bearer {TOKEN}")
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            return json.loads(resp.read())
    except urllib.error.HTTPError as e:
        body = e.read().decode()
        return {"success": False, "error": f"HTTP {e.code}: {body[:500]}"}
    except Exception as e:
        return {"success": False, "error": str(e)}

# Fetch all products
print("Fetching products...")
result = api_get("products", {"access_token": TOKEN})
if result.get("success"):
    products = result.get("products", [])
    print(f"\nFound {len(products)} products:\n")
    for p in products:
        print(f"ID: {p['id']}")
        print(f"Name: {p['name']}")
        print(f"Tags: {p.get('tags', 'none')}")
        print(f"URL: {p.get('short_url', 'n/a')}")
        print(f"Price: ${p.get('price', 0)/100:.2f}")
        print(f"Sales: {p.get('sales_count', 0)}")
        print()
else:
    print(f"Error: {result}")
