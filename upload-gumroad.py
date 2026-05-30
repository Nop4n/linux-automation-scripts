#!/usr/bin/env python3
"""Gumroad uploader using only stdlib (urllib + json)"""
import urllib.request
import urllib.parse
import json
import os

TOKEN = "lUnn..."
API = "https://api.gumroad.com/v2"

def api_post(endpoint, fields=None, files=None):
    """POST to Gumroad API using multipart form data"""
    url = f"{API}/{endpoint}"
    
    if files:
        boundary = "----PythonBoundary"
        body = b""
        
        if fields:
            for k, v in fields.items():
                body += f"--{boundary}\r\n".encode()
                body += f'Content-Disposition: form-data; name="{k}"\r\n\r\n'.encode()
                body += f"{v}\r\n".encode()
        
        for fname, fdata in files.items():
            body += f"--{boundary}\r\n".encode()
            body += f'Content-Disposition: form-data; name="file"; filename="{fname}"\r\n'.encode()
            body += b"Content-Type: application/zip\r\n\r\n"
            body += fdata
            body += b"\r\n"
        
        body += f"--{boundary}--\r\n".encode()
        
        req = urllib.request.Request(url, data=body)
        req.add_header("Content-Type", f"multipart/form-data; boundary={boundary}")
    else:
        data = urllib.parse.urlencode(fields).encode()
        req = urllib.request.Request(url, data=data)
    
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            return json.loads(resp.read())
    except Exception as e:
        return {"success": False, "error": str(e)}

def upload_file(filepath):
    filename = os.path.basename(filepath)
    filesize = os.path.getsize(filepath)
    
    # Step 1: Presign
    print(f"    Presigning {filename}...")
    presign = api_post("files/presign", {
        "access_token": TOKEN,
        "name": filename,
        "content_type": "application/zip",
        "size": str(filesize)
    })
    
    if not presign.get("success"):
        print(f"    FAIL presign: {presign}")
        return None
    
    upload_url = presign["upload_url"]
    upload_fields = presign["upload_fields"]
    key = presign["key"]
    
    # Step 2: Upload to S3
    print(f"    Uploading to S3...")
    boundary = "----UploadBoundary"
    body = b""
    
    for k, v in upload_fields.items():
        body += f"--{boundary}\r\n".encode()
        body += f'Content-Disposition: form-data; name="{k}"\r\n\r\n'.encode()
        body += f"{v}\r\n".encode()
    
    body += f"--{boundary}\r\n".encode()
    body += f'Content-Disposition: form-data; name="file"; filename="{filename}"\r\n'.encode()
    body += b"Content-Type: application/zip\r\n\r\n"
    with open(filepath, "rb") as f:
        body += f.read()
    body += b"\r\n"
    body += f"--{boundary}--\r\n".encode()
    
    req = urllib.request.Request(upload_url, data=body)
    req.add_header("Content-Type", f"multipart/form-data; boundary={boundary}")
    
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            pass
    except Exception as e:
        print(f"    FAIL upload: {e}")
        return None
    
    # Step 3: Complete
    print(f"    Completing upload...")
    complete = api_post("files/complete", {
        "access_token": TOKEN,
        "key": key
    })
    
    if complete.get("success"):
        return complete["url"]
    
    print(f"    FAIL complete: {complete}")
    return None

def create_product(name, slug, price, desc, tags, file_url):
    result = api_post("products", {
        "access_token": TOKEN,
        "name": name,
        "price": str(price),
        "description": desc,
        "url_slug": slug,
        "tags": tags,
        "files[][url]": file_url,
        "files[][name]": f"{slug}.zip"
    })
    return result

products = [
    ("Linux System Optimizer v1.0", "linux-optimizer", 500,
     "Boost performance on low-spec Linux machines with one click. Features: ZRAM, swappiness tuning, service control, preload, journal optimization, compositor disable, DNS optimization, cache cleanup.",
     "linux,optimization,performance,ubuntu,debian,bash",
     "/home/hp/products/linux-optimizer-v1.0.zip"),
    
    ("Linux Backup Script v1.0", "linux-backup", 500,
     "Professional automated backup solution for Linux. Features: Full/incremental/differential backups, local/remote (SSH/rsync) targets, gzip/zstd compression, cron scheduling, restore functionality, email notifications, logging.",
     "linux,backup,rsync,automation,ubuntu,debian",
     "/home/hp/products/linux-backup-v1.0.zip"),
    
    ("Linux Security Hardener v1.0", "linux-security", 500,
     "Professional Linux security hardening script. Features: SSH hardening, UFW/iptables firewall, Fail2Ban, automatic updates, file permission hardening, kernel sysctl hardening, audit logging, security report.",
     "linux,security,hardening,firewall,ubuntu,debian",
     "/home/hp/products/linux-security-v1.0.zip"),
    
    ("Docker Setup Script v1.0", "docker-setup", 500,
     "Complete Docker installation and configuration script. Features: Docker CE install, Docker Compose, daemon config, Portainer/Nginx Proxy Manager/Watchtower, network management, volume management, container backup, security best practices.",
     "docker,container,devops,ubuntu,debian,linux",
     "/home/hp/products/docker-setup-v1.0.zip"),
    
    ("Web Server Setup v1.0", "webserver-setup", 500,
     "Nginx + SSL web server setup script. Features: Nginx optimization, Let's Encrypt SSL, virtual host management, PHP-FPM, MySQL/MariaDB, WordPress auto-install, reverse proxy, security headers, performance tuning.",
     "nginx,ssl,wordpress,webserver,php,mysql,linux",
     "/home/hp/products/webserver-setup-v1.0.zip"),
    
    ("System Monitor Dashboard v1.0", "sysmonitor", 500,
     "Real-time system monitoring dashboard. Features: CPU/RAM/Disk monitoring, process management, network stats, service checker, log viewer, alert thresholds, HTML report export, continuous monitor mode.",
     "monitoring,system,linux,dashboard,ubuntu,debian",
     "/home/hp/products/sysmonitor-v1.0.zip"),
]

print("=" * 50)
print("Gumroad Product Uploader")
print("=" * 50)
print()

for i, (name, slug, price, desc, tags, filepath) in enumerate(products, 1):
    print(f"[{i}/6] {name}")
    
    file_url = upload_file(filepath)
    if not file_url:
        print(f"  SKIP\n")
        continue
    
    print(f"  URL: {file_url}")
    print(f"  Creating product...")
    
    result = create_product(name, slug, price, desc, tags, file_url)
    
    if result.get("success"):
        pid = result["product"]["id"]
        print(f"  ✓ SUCCESS! ID: {pid}")
        print(f"  Link: https://novantovenge.gumroad.com/l/{slug}")
    else:
        print(f"  ✗ FAIL: {result.get('message', result)}")
    print()

print("=" * 50)
print("Done!")
