#!/bin/bash
# Gumroad product uploader using curl
TOKEN="lUnn...
nAPI="https://api.gumroad.com/v2"

upload_product() {
    local name="$1"
    local slug="$2"
    local price="$3"
    local desc="$4"
    local tags="$5"
    local file="$6"
    local filesize=$(stat -c%s "$file")
    local filename=$(basename "$file")
    
    echo "  [1/3] Presigning file..."
    local presign=$(curl -s "$API/files/presign" \
        -F "access_token=$TOKEN" \
        -F "name=$filename" \
        -F "content_type=application/zip" \
        -F "size=$filesize")
    
    local upload_url=$(echo "$presign" | python3 -c "import sys,json; print(json.load(sys.stdin).get('upload_url',''))")
    local key=$(echo "$presign" | python3 -c "import sys,json; print(json.load(sys.stdin).get('key',''))")
    local upload_fields=$(echo "$presign" | python3 -c "import sys,json; d=json.load(sys.stdin).get('upload_fields',{}); print(' '.join(f'-F {k}={v}' for k,v in d.items()))")
    
    if [ -z "$upload_url" ]; then
        echo "  FAIL: Presign failed"
        return 1
    fi
    
    echo "  [2/3] Uploading to S3..."
    # Build form fields
    local form_args=""
    while IFS='=' read -r k v; do
        form_args="$form_args -F $k=$v"
    done < <(echo "$presign" | python3 -c "import sys,json; [print(f'{k}={v}') for k,v in json.load(sys.stdin).get('upload_fields',{}).items()]")
    
    curl -s "$upload_url" $form_args -F "file=@$file" > /dev/null
    
    echo "  [3/3] Completing upload..."
    local complete=$(curl -s "$API/files/complete" \
        -F "access_token=$TOKEN" \
        -F "key=$key")
    
    local file_url=$(echo "$complete" | python3 -c "import sys,json; print(json.load(sys.stdin).get('url',''))")
    
    if [ -z "$file_url" ]; then
        echo "  FAIL: Complete failed"
        return 1
    fi
    
    echo "  File URL: $file_url"
    
    echo "  Creating product..."
    local result=$(curl -s "$API/products" \
        -F "access_token=$TOKEN" \
        -F "name=$name" \
        -F "price=$price" \
        -F "description=$desc" \
        -F "url_slug=$slug" \
        -F "tags=$tags" \
        -F "files[][url]=$file_url" \
        -F "files[][name]=$slug.zip")
    
    local success=$(echo "$result" | python3 -c "import sys,json; print(json.load(sys.stdin).get('success',''))")
    local pid=$(echo "$result" | python3 -c "import sys,json; print(json.load(sys.stdin).get('product',{}).get('id',''))")
    
    if [ "$success" = "True" ]; then
        echo "  ✓ SUCCESS! Product ID: $pid"
        echo "  URL: https://novantovenge.gumroad.com/l/$slug"
    else
        echo "  ✗ FAIL: $result"
    fi
}

echo "=== Gumroad Product Uploader ==="
echo ""

echo "[1/6] Linux System Optimizer v1.0"
upload_product "Linux System Optimizer v1.0" "linux-optimizer" 500 \
    "Boost performance on low-spec Linux machines with one click. Features: ZRAM, swappiness tuning, service control, preload, journal optimization, compositor disable, DNS optimization, cache cleanup." \
    "linux,optimization,performance,ubuntu,debian,bash" \
    "/home/hp/products/linux-optimizer-v1.0.zip"
echo ""

echo "[2/6] Linux Backup Script v1.0"
upload_product "Linux Backup Script v1.0" "linux-backup" 500 \
    "Professional automated backup solution for Linux. Features: Full/incremental/differential backups, local/remote (SSH/rsync) targets, gzip/zstd compression, cron scheduling, restore functionality, email notifications, logging." \
    "linux,backup,rsync,automation,ubuntu,debian" \
    "/home/hp/products/linux-backup-v1.0.zip"
echo ""

echo "[3/6] Linux Security Hardener v1.0"
upload_product "Linux Security Hardener v1.0" "linux-security" 500 \
    "Professional Linux security hardening script. Features: SSH hardening, UFW/iptables firewall, Fail2Ban, automatic updates, file permission hardening, kernel sysctl hardening, audit logging, security report." \
    "linux,security,hardening,firewall,ubuntu,debian" \
    "/home/hp/products/linux-security-v1.0.zip"
echo ""

echo "[4/6] Docker Setup Script v1.0"
upload_product "Docker Setup Script v1.0" "docker-setup" 500 \
    "Complete Docker installation and configuration script. Features: Docker CE install, Docker Compose, daemon config, Portainer/Nginx Proxy Manager/Watchtower, network management, volume management, container backup, security best practices." \
    "docker,container,devops,ubuntu,debian,linux" \
    "/home/hp/products/docker-setup-v1.0.zip"
echo ""

echo "[5/6] Web Server Setup v1.0"
upload_product "Web Server Setup v1.0" "webserver-setup" 500 \
    "Nginx + SSL web server setup script. Features: Nginx optimization, Let's Encrypt SSL, virtual host management, PHP-FPM, MySQL/MariaDB, WordPress auto-install, reverse proxy, security headers, performance tuning." \
    "nginx,ssl,wordpress,webserver,php,mysql,linux" \
    "/home/hp/products/webserver-setup-v1.0.zip"
echo ""

echo "[6/6] System Monitor Dashboard v1.0"
upload_product "System Monitor Dashboard v1.0" "sysmonitor" 500 \
    "Real-time system monitoring dashboard. Features: CPU/RAM/Disk monitoring, process management, network stats, service checker, log viewer, alert thresholds, HTML report export, continuous monitor mode." \
    "monitoring,system,linux,dashboard,ubuntu,debian" \
    "/home/hp/products/sysmonitor-v1.0.zip"
echo ""

echo "=== Done! ==="
