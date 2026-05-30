#!/usr/bin/env python3
"""Gumroad uploader v3 - correct presign flow"""
import urllib.request
import urllib.parse
import json
import os

API = "https://api.gumroad.com/v2"

def get_token():
    with open("/home/hp/products/.gumroad_token") as f:
        return f.read().strip()

def api_post(endpoint, fields=None):
    url = f"{API}/{endpoint}"
    data = urllib.parse.urlencode(fields).encode() if fields else None
    req = urllib.request.Request(url, data=data, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            return json.loads(resp.read())
    except urllib.error.HTTPError as e:
        body = e.read().decode()
        return {"success": False, "error": f"HTTP {e.code}", "body": body[:500]}
    except Exception as e:
        return {"success": False, "error": str(e)}

def upload_file(filepath, token):
    filename = os.path.basename(filepath)
    filesize = os.path.getsize(filepath)
    
    # Step 1: Presign
    r = api_post("files/presign", {
        "access_token": token,
        "filename": filename,
        "content_type": "application/zip",
        "file_size": str(filesize)
    })
    
    if not r.get("success"):
        return None, r
    
    upload_id = r["upload_id"]
    key = r["key"]
    file_url = r["file_url"]
    parts = r["parts"]
    
    # Step 2: Upload parts to S3
    with open(filepath, "rb") as f:
        file_data = f.read()
    
    for part in parts:
        presigned_url = part["presigned_url"]
        part_number = part["part_number"]
        
        req = urllib.request.Request(presigned_url, data=file_data, method="PUT")
        req.add_header("Content-Type", "application/zip")
        try:
            with urllib.request.urlopen(req, timeout=120) as resp:
                pass
        except Exception as e:
            return None, {"error": f"Part upload failed: {e}"}
    
    # Step 3: Complete
    r = api_post("files/complete", {
        "access_token": token,
        "upload_id": upload_id,
        "key": key
    })
    
    if r.get("success"):
        return file_url, None
    return None, r

def create_product(token, name, slug, price, desc, tags_list, file_url=None):
    fields = {
        "access_token": token,
        "name": name,
        "price": str(price),
        "description": desc,
        "url_slug": slug,
    }
    for i, tag in enumerate(tags_list):
        fields[f"tags[{i}]"] = tag
    if file_url:
        fields["files[][url]"] = file_url
        fields["files[][name]"] = f"{slug}.zip"
    return api_post("products", fields)

token = get_token()

products = [
    ("Linux System Optimizer v1.0", "linux-optimizer", 500,
     "Boost performance on low-spec Linux machines with one click. Features: ZRAM, swappiness tuning, service control, preload, journal optimization, compositor disable, DNS optimization, cache cleanup.",
     ["linux", "optimization", "performance", "ubuntu", "debian", "bash"],
     "/home/hp/products/linux-optimizer-v1.0.zip"),
    
    ("Linux Backup Script v1.0", "linux-backup", 500,
     "Professional automated backup solution for Linux. Features: Full/incremental/differential backups, local/remote (SSH/rsync) targets, gzip/zstd compression, cron scheduling, restore, email notifications, logging.",
     ["linux", "backup", "rsync", "automation", "ubuntu", "debian"],
     "/home/hp/products/linux-backup-v1.0.zip"),
    
    ("Linux Security Hardener v1.0", "linux-security", 500,
     "Professional Linux security hardening script. Features: SSH hardening, UFW/iptables firewall, Fail2Ban, automatic updates, file permission hardening, kernel sysctl hardening, audit logging, security report.",
     ["linux", "security", "hardening", "firewall", "ubuntu", "debian"],
     "/home/hp/products/linux-security-v1.0.zip"),
    
    ("Docker Setup Script v1.0", "docker-setup", 500,
     "Complete Docker installation and configuration. Features: Docker CE, Docker Compose, daemon config, Portainer/Nginx Proxy Manager/Watchtower, networks, volumes, backup, security.",
     ["docker", "container", "devops", "ubuntu", "debian", "linux"],
     "/home/hp/products/docker-setup-v1.0.zip"),
    
    ("Web Server Setup v1.0", "webserver-setup", 500,
     "Nginx + SSL web server setup. Features: Nginx optimization, Let's Encrypt SSL, virtual hosts, PHP-FPM, MySQL/MariaDB, WordPress auto-install, reverse proxy, security headers, performance tuning.",
     ["nginx", "ssl", "wordpress", "webserver", "php", "mysql", "linux"],
     "/home/hp/products/webserver-setup-v1.0.zip"),
    
    ("System Monitor Dashboard v1.0", "sysmonitor", 500,
     "Real-time system monitoring. Features: CPU/RAM/Disk monitoring, process management, network stats, service checker, log viewer, alert thresholds, HTML report export, continuous monitor.",
     ["monitoring", "system", "linux", "dashboard", "ubuntu", "debian"],
     "/home/hp/products/sysmonitor-v1.0.zip"),
]

print("=" * 50)
print("Gumroad Product Uploader v3")
print("=" * 50)
print()

success_count = 0
for i, (name, slug, price, desc, tags_list, filepath) in enumerate(products, 1):
    print(f"[{i}/6] {name}")
    
    # Upload file
    print(f"  Uploading file...")
    file_url, err = upload_file(filepath, token)
    
    if file_url:
        print(f"  File URL: {file_url[:80]}...")
    else:
        print(f"  File upload error: {err}")
        file_url = None
    
    # Create product
    print(f"  Creating product...")
    result = create_product(token, name, slug, price, desc, tags_list, file_url)
    
    if result.get("success"):
        pid = result["product"]["id"]
        short_url = result["product"].get("short_url", "")
        print(f"  SUCCESS! ID: {pid}")
        print(f"  URL: {short_url}")
        success_count += 1
    else:
        print(f"  FAIL: {result}")
    print()

print("=" * 50)
print(f"Done! {success_count}/6 products uploaded")
print("=" * 50)
