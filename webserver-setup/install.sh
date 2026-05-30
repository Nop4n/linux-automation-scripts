#!/bin/bash
#==============================================================================
# WebServer Setup Pro - Nginx + SSL Server Configuration Tool
# Version: 2.0.0
# License: MIT
# 
# Professional web server setup script with interactive menu
# Supports: Ubuntu 20.04+ / Debian 11+
#==============================================================================

set -euo pipefail

# Color definitions
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly GRAY='\033[0;37m'
readonly NC='\033[0m' # No Color
readonly BOLD='\033[1m'
readonly DIM='\033[2m'

# Script metadata
readonly SCRIPT_NAME="WebServer Setup Pro"
readonly VERSION="2.0.0"
readonly AUTHOR="WebServer Setup Pro"
readonly LOG_DIR="/var/log/webserver-setup"
readonly BACKUP_DIR="/var/backups/webserver-setup"

# Create log directory
mkdir -p "$LOG_DIR" 2>/dev/null || true

#==============================================================================
# UTILITY FUNCTIONS
#==============================================================================

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        INFO)    echo -e "${GREEN}[✓]${NC} $message" ;;
        WARN)    echo -e "${YELLOW}[⚠]${NC} $message" ;;
        ERROR)   echo -e "${RED}[✗]${NC} $message" ;;
        DEBUG)   echo -e "${CYAN}[●]${NC} $message" ;;
        SUCCESS) echo -e "${GREEN}[✓]${NC} ${BOLD}$message${NC}" ;;
    esac
    
    echo "[$timestamp] [$level] $message" >> "$LOG_DIR/install.log" 2>/dev/null || true
}

print_header() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║                    ${WHITE}$SCRIPT_NAME${CYAN}                    ║"
    echo "║                        Version $VERSION                           ║"
    echo "╠══════════════════════════════════════════════════════════════════╣"
    echo "║              Professional Nginx + SSL Setup                    ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_section() {
    local title="$1"
    echo -e "\n${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}${BOLD}  $title${NC}"
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

print_menu() {
    local title="$1"
    shift
    local -a items=("$@")
    
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${WHITE}${BOLD}                    $title                                   ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════╣${NC}"
    
    local i=1
    for item in "${items[@]}"; do
        if [[ "$item" == "0. Exit" ]]; then
            echo -e "${CYAN}║${NC}                                                                    ${CYAN}║${NC}"
        fi
        echo -e "${CYAN}║${NC}  ${GREEN}$i${NC}. $item"
        ((i++))
    done
    
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log ERROR "This script must be run as root (use sudo)"
        echo -e "${RED}Please run: sudo $0${NC}"
        exit 1
    fi
}

check_os() {
    if [[ ! -f /etc/os-release ]]; then
        log ERROR "Unsupported operating system"
        exit 1
    fi
    
    . /etc/os-release
    
    if [[ "$ID" != "ubuntu" && "$ID" != "debian" ]]; then
        log ERROR "This script only supports Ubuntu/Debian"
        log INFO "Detected: $PRETTY_NAME"
        exit 1
    fi
    
    log INFO "Detected OS: $PRETTY_NAME"
}

install_dependencies() {
    log INFO "Installing dependencies..."
    apt-get update -qq
    apt-get install -y -qq curl wget software-properties-common apt-transport-https ca-certificates gnupg lsb-release 2>/dev/null
    log SUCCESS "Dependencies installed"
}

confirm_action() {
    local message="$1"
    echo -en "${YELLOW}$message [Y/n]: ${NC}"
    read -r response
    [[ "$response" =~ ^[Yy]*$ || -z "$response" ]]
}

backup_config() {
    local config_path="$1"
    if [[ -f "$config_path" ]]; then
        local backup_name="$BACKUP_DIR/$(basename "$config_path").$(date +%Y%m%d_%H%M%S).bak"
        mkdir -p "$BACKUP_DIR"
        cp "$config_path" "$backup_name"
        log INFO "Backed up: $config_path -> $backup_name"
    fi
}

generate_random_password() {
    openssl rand -base64 32 | tr -d '=/+' | head -c 20
}

#==============================================================================
# 1. NGINX INSTALLATION & OPTIMIZATION
#==============================================================================

install_nginx() {
    print_section "Installing Nginx"
    
    if command -v nginx &>/dev/null; then
        log WARN "Nginx is already installed"
        nginx -v 2>&1 | while read -r line; do
            log INFO "$line"
        done
        if ! confirm_action "Do you want to reinstall/upgrade?"; then
            return 0
        fi
    fi
    
    log INFO "Adding Nginx repository..."
    apt-get install -y -qq nginx
    
    if [[ $? -eq 0 ]]; then
        systemctl enable nginx
        systemctl start nginx
        
        # Get Nginx version
        NGINX_VERSION=$(nginx -v 2>&1 | cut -d'/' -f2)
        log SUCCESS "Nginx $NGINX_VERSION installed successfully"
        
        # Basic optimization
        optimize_nginx_basic
    else
        log ERROR "Failed to install Nginx"
        return 1
    fi
}

optimize_nginx_basic() {
    print_section "Basic Nginx Optimization"
    
    local nginx_conf="/etc/nginx/nginx.conf"
    backup_config "$nginx_conf"
    
    # Get CPU cores for worker_processes
    local cpu_cores
    cpu_cores=$(nproc)
    
    cat > "$nginx_conf" << 'NGINX_CONF'
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
    worker_connections 2048;
    multi_accept on;
    use epoll;
}

http {
    # Basic settings
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    server_tokens off;
    client_max_body_size 64M;
    
    # MIME types
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    # Logging
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml
        application/xml+rss
        application/vnd.ms-fontobject
        font/opentype
        image/svg+xml;
    
    # Virtual Host Configs
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
NGINX_CONF
    
    # Update worker_processes
    sed -i "s/worker_processes auto;/worker_processes $cpu_cores;/" "$nginx_conf"
    
    # Remove default site
    rm -f /etc/nginx/sites-enabled/default
    
    # Test and reload
    if nginx -t 2>&1 | grep -q "successful"; then
        systemctl reload nginx
        log SUCCESS "Nginx optimized (workers: $cpu_cores)"
    else
        log ERROR "Nginx configuration test failed"
        return 1
    fi
}

#==============================================================================
# 2. LET'S ENCRYPT SSL AUTO-SETUP
#==============================================================================

setup_ssl() {
    print_section "Let's Encrypt SSL Setup"
    
    # Install certbot
    if ! command -v certbot &>/dev/null; then
        log INFO "Installing Certbot..."
        apt-get install -y -qq certbot python3-certbot-nginx
    fi
    
    echo -en "${CYAN}Enter your domain name: ${NC}"
    read -r domain
    
    if [[ -z "$domain" ]]; then
        log ERROR "Domain name cannot be empty"
        return 1
    fi
    
    echo -en "${CYAN}Enter your email address (for SSL notifications): ${NC}"
    read -r email
    
    if [[ -z "$email" ]]; then
        log ERROR "Email address cannot be empty"
        return 1
    fi
    
    log INFO "Setting up SSL for: $domain"
    
    # Get SSL certificate
    certbot --nginx \
        -d "$domain" \
        -d "www.$domain" \
        --non-interactive \
        --agree-tos \
        --email "$email" \
        --redirect \
        --hsts \
        --staple-ocsp \
        --register-unsafely-without-email 2>/dev/null
    
    if [[ $? -eq 0 ]]; then
        log SUCCESS "SSL certificate installed for $domain"
        
        # Setup auto-renewal
        setup_ssl_renewal
        
        # Optimize SSL configuration
        optimize_ssl
    else
        log ERROR "Failed to obtain SSL certificate"
        log INFO "Make sure your domain points to this server"
    fi
}

setup_ssl_renewal() {
    log INFO "Setting up SSL auto-renewal..."
    
    # Create renewal hook
    cat > /etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh << 'RENEWAL_HOOK'
#!/bin/bash
systemctl reload nginx
RENEWAL_HOOK
    chmod +x /etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh
    
    # Add cron job for renewal
    (crontab -l 2>/dev/null; echo "0 0,12 * * * certbot renew --quiet --deploy-hook 'systemctl reload nginx'") | crontab -
    
    log SUCCESS "SSL auto-renewal configured"
}

optimize_ssl() {
    log INFO "Optimizing SSL configuration..."
    
    cat > /etc/nginx/snippets/ssl-params.conf << 'SSL_PARAMS'
# SSL Optimization
ssl_protocols TLSv1.2 TLSv1.3;
ssl_prefer_server_ciphers off;
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;

# SSL Session
ssl_session_timeout 1d;
ssl_session_cache shared:SSL:10m;
ssl_session_tickets off;

# OCSP Stapling
ssl_stapling on;
ssl_stapling_verify on;

# Security Headers
add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
add_header X-Frame-Options DENY always;
add_header X-Content-Type-Options nosniff always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self';" always;
SSL_PARAMS
    
    log SUCCESS "SSL optimized with modern ciphers and security headers"
}

#==============================================================================
# 3. VIRTUAL HOST MANAGEMENT
#==============================================================================

manage_virtual_hosts() {
    while true; do
        clear
        print_header
        echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║${WHITE}${BOLD}                    Virtual Host Management                      ${CYAN}║${NC}"
        echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${CYAN}║${NC}  ${GREEN}1${NC}. Add Virtual Host"
        echo -e "${CYAN}║${NC}  ${GREEN}2${NC}. Remove Virtual Host"
        echo -e "${CYAN}║${NC}  ${GREEN}3${NC}. List Virtual Hosts"
        echo -e "${CYAN}║${NC}  ${GREEN}4${NC}. Enable Virtual Host"
        echo -e "${CYAN}║${NC}  ${GREEN}5${NC}. Disable Virtual Host"
        echo -e "${CYAN}║${NC}  ${GREEN}0${NC}. Back to Main Menu"
        echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
        
        echo -en "\n${YELLOW}Select an option: ${NC}"
        read -r choice
        
        case $choice in
            1) add_virtual_host ;;
            2) remove_virtual_host ;;
            3) list_virtual_hosts ;;
            4) enable_virtual_host ;;
            5) disable_virtual_host ;;
            0) return 0 ;;
            *) log ERROR "Invalid option" ;;
        esac
        
        echo -e "\n${DIM}Press Enter to continue...${NC}"
        read -r
    done
}

add_virtual_host() {
    print_section "Add Virtual Host"
    
    echo -en "${CYAN}Enter domain name: ${NC}"
    read -r domain
    
    if [[ -z "$domain" ]]; then
        log ERROR "Domain name cannot be empty"
        return 1
    fi
    
    local web_root="/var/www/$domain"
    mkdir -p "$web_root"
    
    # Create virtual host configuration
    cat > "/etc/nginx/sites-available/$domain" << VHOST
server {
    listen 80;
    listen [::]:80;
    server_name $domain www.$domain;
    
    root $web_root;
    index index.php index.html index.htm;
    
    # Logging
    access_log /var/log/nginx/$domain.access.log;
    error_log /var/log/nginx/$domain.error.log;
    
    # Security
    location ~ /\.ht {
        deny all;
    }
    
    # PHP handling
    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }
    
    # Static files caching
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|pdf|svg|woff|woff2|ttf|eot)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
    
    # Main location
    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }
}
VHOST
    
    # Create default index
    cat > "$web_root/index.html" << INDEX
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Welcome to $domain</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; 
               display: flex; justify-content: center; align-items: center; min-height: 100vh;
               background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
               margin: 0; color: white; }
        .container { text-align: center; padding: 3rem; background: rgba(255,255,255,0.1);
                     border-radius: 20px; backdrop-filter: blur(10px); }
        h1 { font-size: 2.5rem; margin-bottom: 1rem; }
        p { font-size: 1.2rem; opacity: 0.9; }
        .status { margin-top: 2rem; padding: 1rem; background: rgba(0,255,0,0.2);
                  border-radius: 10px; display: inline-block; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Server Ready!</h1>
        <p>Your website is now live at</p>
        <p><strong>$domain</strong></p>
        <div class="status">✅ Nginx Configured</div>
    </div>
</body>
</html>
INDEX
    
    chown -R www-data:www-data "$web_root"
    
    # Enable site
    ln -sf "/etc/nginx/sites-available/$domain" "/etc/nginx/sites-enabled/"
    
    # Test and reload
    if nginx -t 2>&1 | grep -q "successful"; then
        systemctl reload nginx
        log SUCCESS "Virtual host created for $domain"
        log INFO "Web root: $web_root"
    else
        log ERROR "Nginx configuration test failed"
        rm -f "/etc/nginx/sites-available/$domain" "/etc/nginx/sites-enabled/$domain"
        return 1
    fi
}

remove_virtual_host() {
    print_section "Remove Virtual Host"
    
    echo -e "${YELLOW}Available virtual hosts:${NC}"
    ls -1 /etc/nginx/sites-available/ 2>/dev/null || echo "None found"
    
    echo -en "\n${CYAN}Enter domain to remove: ${NC}"
    read -r domain
    
    if [[ ! -f "/etc/nginx/sites-available/$domain" ]]; then
        log ERROR "Virtual host '$domain' not found"
        return 1
    fi
    
    if confirm_action "Remove virtual host '$domain' and its files?"; then
        rm -f "/etc/nginx/sites-available/$domain" "/etc/nginx/sites-enabled/$domain"
        
        if [[ -d "/var/www/$domain" ]]; then
            rm -rf "/var/www/$domain"
        fi
        
        systemctl reload nginx
        log SUCCESS "Virtual host '$domain' removed"
    fi
}

list_virtual_hosts() {
    print_section "Virtual Hosts"
    
    echo -e "${CYAN}Active Virtual Hosts:${NC}\n"
    
    local count=0
    for vhost in /etc/nginx/sites-available/*; do
        if [[ -f "$vhost" ]]; then
            local name
            name=$(basename "$vhost")
            local status="disabled"
            [[ -L "/etc/nginx/sites-enabled/$name" ]] && status="${GREEN}enabled${NC}"
            
            echo -e "  ${WHITE}•${NC} $name [$status]"
            ((count++))
        fi
    done
    
    if [[ $count -eq 0 ]]; then
        echo -e "  ${DIM}No virtual hosts configured${NC}"
    fi
}

enable_virtual_host() {
    echo -en "${CYAN}Enter domain to enable: ${NC}"
    read -r domain
    
    if [[ -f "/etc/nginx/sites-available/$domain" ]] && [[ ! -L "/etc/nginx/sites-enabled/$domain" ]]; then
        ln -sf "/etc/nginx/sites-available/$domain" "/etc/nginx/sites-enabled/"
        systemctl reload nginx
        log SUCCESS "Virtual host '$domain' enabled"
    else
        log ERROR "Virtual host not found or already enabled"
    fi
}

disable_virtual_host() {
    echo -en "${CYAN}Enter domain to disable: ${NC}"
    read -r domain
    
    if [[ -L "/etc/nginx/sites-enabled/$domain" ]]; then
        rm -f "/etc/nginx/sites-enabled/$domain"
        systemctl reload nginx
        log SUCCESS "Virtual host '$domain' disabled"
    else
        log ERROR "Virtual host not found or already disabled"
    fi
}

#==============================================================================
# 4. PHP-FPM SETUP
#==============================================================================

install_php_fpm() {
    print_section "PHP-FPM Installation"
    
    if command -v php &>/dev/null; then
        log WARN "PHP is already installed"
        php -v | head -n1
        if ! confirm_action "Install additional PHP version?"; then
            return 0
        fi
    fi
    
    echo -e "${CYAN}Available PHP versions:${NC}"
    echo -e "  ${GREEN}1${NC}. PHP 8.1"
    echo -e "  ${GREEN}2${NC}. PHP 8.2"
    echo -e "  ${GREEN}3${NC}. PHP 8.3"
    echo -e "  ${GREEN}4${NC}. PHP 8.4 (latest)"
    
    echo -en "\n${YELLOW}Select PHP version: ${NC}"
    read -r php_choice
    
    local php_version
    case $php_choice in
        1) php_version="8.1" ;;
        2) php_version="8.2" ;;
        3) php_version="8.3" ;;
        4) php_version="8.4" ;;
        *) 
            log WARN "Invalid selection, using PHP 8.3"
            php_version="8.3"
            ;;
    esac
    
    log INFO "Installing PHP $php_version with FPM..."
    
    # Add PHP repository
    add-apt-repository -y ppa:ondrej/php 2>/dev/null || true
    apt-get update -qq
    
    # Install PHP and common extensions
    apt-get install -y -qq \
        "php${php_version}-fpm" \
        "php${php_version}-mysql" \
        "php${php_version}-cli" \
        "php${php_version}-common" \
        "php${php_version}-curl" \
        "php${php_version}-mbstring" \
        "php${php_version}-xml" \
        "php${php_version}-zip" \
        "php${php_version}-bcmath" \
        "php${php_version}-gd" \
        "php${php_version}-imagick" \
        "php${php_version}-intl" \
        "php${php_version}-soap" \
        "php${php_version}-redis" \
        "php${php_version}-memcached"
    
    if [[ $? -eq 0 ]]; then
        # Optimize PHP-FPM
        optimize_php_fpm "$php_version"
        
        systemctl enable "php${php_version}-fpm"
        systemctl start "php${php_version}-fpm"
        
        log SUCCESS "PHP $php_version with FPM installed"
    else
        log ERROR "Failed to install PHP $php_version"
        return 1
    fi
}

optimize_php_fpm() {
    local php_version="$1"
    local pool_conf="/etc/php/${php_version}/fpm/pool.d/www.conf"
    
    backup_config "$pool_conf"
    
    # Get CPU cores
    local cpu_cores
    cpu_cores=$(nproc)
    local dynamic_workers=$((cpu_cores * 2))
    
    cat > "$pool_conf" << POOL_CONF
[www]
user = www-data
group = www-data

listen = /run/php/php${php_version}-fpm.sock
listen.owner = www-data
listen.group = www-data
listen.mode = 0660

; Process Manager
pm = dynamic
pm.max_children = $((cpu_cores * 4))
pm.start_servers = $((cpu_cores * 2))
pm.min_spare_servers = $cpu_cores
pm.max_spare_servers = $dynamic_workers
pm.max_requests = 500
pm.process_idle_timeout = 10s

; Status page
pm.status_path = /status
ping.path = /ping
ping.response = pong

; Logging
access.log = /var/log/php${php_version}-fpm-access.log
access.format = "%R - %u %t \"%m %r%Q%q\" %s %f %{mili}d %{kilo}M %C%%"

slowlog = /var/log/php${php_version}-fpm-slow.log
request_slowlog_timeout = 5s
request_terminate_timeout = 300s

; Security
security.limit_extensions = .php .php3 .php4 .php5 .php7 .php8

; Environment
env[HOSTNAME] = \$HOSTNAME
env[PATH] = /usr/local/bin:/usr/bin:/bin
env[TMP] = /tmp
env[TMPDIR] = /tmp
env[TEMP] = /tmp
POOL_CONF
    
    log SUCCESS "PHP-FPM optimized (workers: ${cpu_cores}x4=${dynamic_workers})"
}

#==============================================================================
# 5. MYSQL/MARIADB INSTALLATION
#==============================================================================

install_mysql() {
    print_section "MySQL/MariaDB Installation"
    
    if command -v mysql &>/dev/null; then
        log WARN "MySQL/MariaDB is already installed"
        if ! confirm_action "Reconfigure existing installation?"; then
            return 0
        fi
    fi
    
    echo -e "${CYAN}Choose database server:${NC}"
    echo -e "  ${GREEN}1${NC}. MySQL 8.0"
    echo -e "  ${GREEN}2${NC}. MariaDB 10.x"
    
    echo -en "\n${YELLOW}Select option: ${NC}"
    read -r db_choice
    
    case $db_choice in
        1)
            log INFO "Installing MySQL 8.0..."
            apt-get install -y -qq mysql-server
            ;;
        2)
            log INFO "Installing MariaDB..."
            apt-get install -y -qq mariadb-server mariadb-client
            ;;
        *)
            log WARN "Invalid selection, installing MySQL"
            apt-get install -y -qq mysql-server
            ;;
    esac
    
    if [[ $? -eq 0 ]]; then
        systemctl enable mysql 2>/dev/null || systemctl enable mariadb
        systemctl start mysql 2>/dev/null || systemctl start mariadb
        
        # Secure installation
        secure_mysql
        
        log SUCCESS "Database server installed and secured"
    else
        log ERROR "Failed to install database server"
        return 1
    fi
}

secure_mysql() {
    log INFO "Securing MySQL installation..."
    
    local root_password
    root_password=$(generate_random_password)
    
    # Secure installation using mysql_secure_installation equivalent
    mysql -e "DELETE FROM mysql.user WHERE User='';" 2>/dev/null
    mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');" 2>/dev/null
    mysql -e "DROP DATABASE IF EXISTS test;" 2>/dev/null
    mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';" 2>/dev/null
    mysql -e "FLUSH PRIVILEGES;" 2>/dev/null
    
    # Set root password
    mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$root_password';" 2>/dev/null
    
    # Save credentials
    mkdir -p /root/.my.cnf
    cat > /root/.my.cnf << EOF
[client]
user=root
password=$root_password
EOF
    chmod 600 /root/.my.cnf
    
    echo -e "\n${GREEN}MySQL secured successfully!${NC}"
    echo -e "${YELLOW}Root password saved to: /root/.my.cnf${NC}"
    echo -e "${YELLOW}Please save this password: $root_password${NC}"
}

#==============================================================================
# 6. WORDPRESS AUTO-INSTALL
#==============================================================================

install_wordpress() {
    print_section "WordPress Installation"
    
    echo -en "${CYAN}Enter domain for WordPress: ${NC}"
    read -r domain
    
    if [[ -z "$domain" ]]; then
        log ERROR "Domain name cannot be empty"
        return 1
    fi
    
    local wp_dir="/var/www/$domain"
    
    if [[ -d "$wp_dir/wp-admin" ]]; then
        log WARN "WordPress already installed at $wp_dir"
        if ! confirm_action "Overwrite existing installation?"; then
            return 0
        fi
    fi
    
    # Check if database is available
    if ! command -v mysql &>/dev/null; then
        log ERROR "MySQL/MariaDB not installed. Please install database first."
        return 1
    fi
    
    # Create database and user
    echo -en "${CYAN}Enter database name [wordpress]: ${NC}"
    read -r db_name
    db_name=${db_name:-wordpress}
    
    local db_user="wp_$(echo "$domain" | tr '.' '_' | tr -cd 'a-zA-Z0-9')"
    local db_password
    db_password=$(generate_random_password)
    
    log INFO "Creating WordPress database..."
    
    mysql -e "CREATE DATABASE IF NOT EXISTS \`$db_name\`;" 2>/dev/null
    mysql -e "CREATE USER IF NOT EXISTS '$db_user'@'localhost' IDENTIFIED BY '$db_password';" 2>/dev/null
    mysql -e "GRANT ALL PRIVILEGES ON \`$db_name\`.* TO '$db_user'@'localhost';" 2>/dev/null
    mysql -e "FLUSH PRIVILEGES;" 2>/dev/null
    
    # Download WordPress
    log INFO "Downloading WordPress..."
    cd /tmp
    wget -q https://wordpress.org/latest.tar.gz
    tar xzf latest.tar.gz
    
    # Setup WordPress
    mkdir -p "$wp_dir"
    cp -a wordpress/* "$wp_dir/"
    rm -rf /tmp/wordpress /tmp/latest.tar.gz
    
    # Create wp-config.php
    log INFO "Configuring WordPress..."
    
    # Generate security keys
    local salt
    salt=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/ 2>/dev/null || echo "")
    
    cat > "$wp_dir/wp-config.php" << WPCONFIG
<?php
define( 'DB_NAME', '$db_name' );
define( 'DB_USER', '$db_user' );
define( 'DB_PASSWORD', '$db_password' );
define( 'DB_HOST', 'localhost' );
define( 'DB_CHARSET', 'utf8mb4' );
define( 'DB_COLLATE', '' );

define( 'AUTH_KEY',         '$(echo "$salt" | grep "AUTH_KEY" | cut -d"'" -f4)' );
define( 'SECURE_AUTH_KEY',  '$(echo "$salt" | grep "SECURE_AUTH_KEY" | cut -d"'" -f4)' );
define( 'LOGGED_IN_KEY',    '$(echo "$salt" | grep "LOGGED_IN_KEY" | cut -d"'" -f4)' );
define( 'NONCE_KEY',        '$(echo "$salt" | grep "NONCE_KEY" | cut -d"'" -f4)' );
define( 'AUTH_SALT',        '$(echo "$salt" | grep "AUTH_SALT" | cut -d"'" -f4)' );
define( 'SECURE_AUTH_SALT', '$(echo "$salt" | grep "SECURE_AUTH_SALT" | cut -d"'" -f4)' );
define( 'LOGGED_IN_SALT',   '$(echo "$salt" | grep "LOGGED_IN_SALT" | cut -d"'" -f4)' );
define( 'NONCE_SALT',       '$(echo "$salt" | grep "NONCE_SALT" | cut -d"'" -f4)' );

\$table_prefix = 'wp_';

define( 'WP_DEBUG', false );
define( 'WP_MEMORY_LIMIT', '256M' );
define( 'WP_MAX_MEMORY_LIMIT', '512M' );
define( 'WP_POST_REVISIONS', 5 );
define( 'AUTOSAVE_INTERVAL', 300 );
define( 'EMPTY_TRASH_DAYS', 15 );
define( 'DISALLOW_FILE_EDIT', true );

if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', __DIR__ . '/' );
}

require_once ABSPATH . 'wp-settings.php';
WPCONFIG
    
    # Set permissions
    chown -R www-data:www-data "$wp_dir"
    find "$wp_dir" -type d -exec chmod 755 {} \;
    find "$wp_dir" -type f -exec chmod 644 {} \;
    chmod 600 "$wp_dir/wp-config.php"
    
    # Create Nginx config for WordPress
    create_wordpress_nginx_config "$domain" "$wp_dir"
    
    log SUCCESS "WordPress installed successfully!"
    echo -e "\n${GREEN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    WordPress Installation Complete!              ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo -e "\n${CYAN}Domain:${NC} $domain"
    echo -e "${CYAN}Database:${NC} $db_name"
    echo -e "${CYAN}Database User:${NC} $db_user"
    echo -e "${CYAN}Database Password:${NC} $db_password"
    echo -e "${CYAN}Web Root:${NC} $wp_dir"
    echo -e "\n${YELLOW}Complete WordPress setup at: http://$domain/wp-admin${NC}"
}

create_wordpress_nginx_config() {
    local domain="$1"
    local wp_dir="$2"
    
    cat > "/etc/nginx/sites-available/$domain" << NGINX_WP
# WordPress Configuration for $domain
server {
    listen 80;
    listen [::]:80;
    server_name $domain www.$domain;
    
    root $wp_dir;
    index index.php index.html;
    
    # Logging
    access_log /var/log/nginx/$domain.access.log;
    error_log /var/log/nginx/$domain.error.log;
    
    # Security
    location ~ /\.ht {
        deny all;
    }
    
    location ~* /(?:uploads|files|wp-content|wp-admin)/.*\.php$ {
        deny all;
    }
    
    # Cache static files
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|webp)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
        access_log off;
    }
    
    # Handle robots.txt
    location = /robots.txt {
        access_log off;
        log_not_found off;
    }
    
    # Handle favicon
    location = /favicon.ico {
        access_log off;
        log_not_found off;
    }
    
    # WordPress pretty permalinks
    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }
    
    # PHP handling
    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_read_timeout 300;
    }
    
    # Deny access to sensitive files
    location ~* \.(engine|inc|info|install|make|module|profile|po|sh|.*sql|theme|tpl|xtmpl)$ {
        deny all;
    }
    
    location ~* ^(?:wp-config\.php|readme\.html|license\.txt)$ {
        deny all;
    }
}
NGINX_WP
    
    systemctl reload nginx
    log SUCCESS "WordPress Nginx configuration created"
}

#==============================================================================
# 7. REVERSE PROXY CONFIGURATION
#==============================================================================

configure_reverse_proxy() {
    print_section "Reverse Proxy Configuration"
    
    echo -en "${CYAN}Enter domain name: ${NC}"
    read -r domain
    
    if [[ -z "$domain" ]]; then
        log ERROR "Domain name cannot be empty"
        return 1
    fi
    
    echo -en "${CYAN}Enter backend URL (e.g., http://127.0.0.1:3000): ${NC}"
    read -r backend_url
    
    if [[ -z "$backend_url" ]]; then
        log ERROR "Backend URL cannot be empty"
        return 1
    fi
    
    cat > "/etc/nginx/sites-available/$domain" << PROXY_CONF
# Reverse Proxy Configuration for $domain
# Backend: $backend_url

server {
    listen 80;
    listen [::]:80;
    server_name $domain www.$domain;
    
    # Logging
    access_log /var/log/nginx/$domain.access.log;
    error_log /var/log/nginx/$domain.error.log;
    
    # Proxy settings
    location / {
        proxy_pass $backend_url;
        proxy_http_version 1.1;
        
        # Headers
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-Port \$server_port;
        
        # Cache settings
        proxy_cache_bypass \$http_upgrade;
        proxy_no_cache \$http_upgrade;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # Buffering
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
    }
    
    # WebSocket support (if needed)
    location /ws {
        proxy_pass $backend_url;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host \$host;
        proxy_read_timeout 86400;
    }
    
    # Health check endpoint
    location /health {
        proxy_pass $backend_url;
        access_log off;
    }
    
    # Static files (optional - adjust as needed)
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|webp|woff|woff2)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
        proxy_pass $backend_url;
        access_log off;
    }
}
PROXY_CONF
    
    ln -sf "/etc/nginx/sites-available/$domain" "/etc/nginx/sites-enabled/"
    
    if nginx -t 2>&1 | grep -q "successful"; then
        systemctl reload nginx
        log SUCCESS "Reverse proxy configured for $domain -> $backend_url"
    else
        log ERROR "Nginx configuration test failed"
        rm -f "/etc/nginx/sites-available/$domain" "/etc/nginx/sites-enabled/$domain"
        return 1
    fi
}

#==============================================================================
# 8. SECURITY HEADERS
#==============================================================================

apply_security_headers() {
    print_section "Security Headers Configuration"
    
    # Create comprehensive security headers snippet
    cat > /etc/nginx/snippets/security-headers.conf << 'SECURITY_HEADERS'
# Security Headers Configuration
# Generated by WebServer Setup Pro

# Prevent clickjacking
add_header X-Frame-Options "SAMEORIGIN" always;

# Prevent MIME type sniffing
add_header X-Content-Type-Options "nosniff" always;

# XSS Protection
add_header X-XSS-Protection "1; mode=block" always;

# Referrer Policy
add_header Referrer-Policy "strict-origin-when-cross-origin" always;

# Content Security Policy (adjust based on your needs)
add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self'; connect-src 'self';" always;

# Permissions Policy
add_header Permissions-Policy "camera=(), microphone=(), geolocation=()" always;

# HSTS (only if using SSL)
# add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
SECURITY_HEADERS
    
    # Rate limiting configuration
    cat > /etc/nginx/snippets/rate-limit.conf << 'RATE_LIMIT'
# Rate Limiting Configuration
# Adjust limits based on your needs

# Define rate limiting zones
limit_req_zone $binary_remote_addr zone=general:10m rate=10r/s;
limit_req_zone $binary_remote_addr zone=login:10m rate=1r/s;
limit_req_zone $binary_remote_addr zone=api:10m rate=30r/s;

# Connection limiting
limit_conn_zone $binary_remote_addr zone=conn_limit:10m;

# Error handling for rate limited requests
limit_req_status 429;
limit_conn_status 429;

# Custom error page for rate limiting
error_page 429 /429.html;
RATE_LIMIT
    
    # 429 error page
    cat > /usr/share/nginx/html/429.html << 'ERROR_429'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>429 Too Many Requests</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
               display: flex; justify-content: center; align-items: center; min-height: 100vh;
               background: #1a1a2e; color: white; margin: 0; }
        .container { text-align: center; padding: 3rem; }
        h1 { font-size: 4rem; margin: 0; color: #e94560; }
        p { font-size: 1.2rem; color: #aaa; }
    </style>
</head>
<body>
    <div class="container">
        <h1>429</h1>
        <p>Too Many Requests</p>
        <p>Please slow down and try again later.</p>
    </div>
</body>
</html>
ERROR_429
    
    # Backup existing nginx.conf
    backup_config /etc/nginx/nginx.conf
    
    # Add security headers include to main nginx.conf
    if ! grep -q "include /etc/nginx/snippets/security-headers.conf;" /etc/nginx/nginx.conf; then
        sed -i '/http {/a \    # Include security headers\n    include /etc/nginx/snippets/security-headers.conf;' /etc/nginx/nginx.conf
    fi
    
    if ! grep -q "include /etc/nginx/snippets/rate-limit.conf;" /etc/nginx/nginx.conf; then
        sed -i '/http {/a \    # Include rate limiting\n    include /etc/nginx/snippets/rate-limit.conf;' /etc/nginx/nginx.conf
    fi
    
    if nginx -t 2>&1 | grep -q "successful"; then
        systemctl reload nginx
        log SUCCESS "Security headers and rate limiting configured"
        log INFO "Rate limits: 10r/s general, 1r/s login, 30r/s API"
    else
        log ERROR "Nginx configuration test failed"
    fi
}

#==============================================================================
# 9. PERFORMANCE TUNING
#==============================================================================

optimize_performance() {
    print_section "Performance Optimization"
    
    echo -e "${CYAN}Performance modules:${NC}"
    echo -e "  ${GREEN}1${NC}. Full Optimization (Recommended)"
    echo -e "  ${GREEN}2${NC}. Gzip Compression Only"
    echo -e "  ${GREEN}3${NC}. Browser Caching Only"
    echo -e "  ${GREEN}4${NC}. FastCGI Cache Only"
    echo -e "  ${GREEN}5${NC}. Brotli Compression"
    
    echo -en "\n${YELLOW}Select optimization: ${NC}"
    read -r opt_choice
    
    case $opt_choice in
        1) full_optimization ;;
        2) setup_gzip ;;
        3) setup_browser_caching ;;
        4) setup_fastcgi_cache ;;
        5) setup_brotli ;;
        *)
            log WARN "Invalid selection, applying full optimization"
            full_optimization
            ;;
    esac
}

full_optimization() {
    log INFO "Applying full performance optimization..."
    
    setup_gzip
    setup_browser_caching
    setup_fastcgi_cache
    
    # Additional optimizations
    setup_open_file_cache
    setup_buffer_optimization
    
    log SUCCESS "Full performance optimization applied"
}

setup_gzip() {
    log INFO "Configuring Gzip compression..."
    
    cat > /etc/nginx/snippets/gzip.conf << 'GZIP'
# Gzip Compression Configuration
gzip on;
gzip_vary on;
gzip_proxied any;
gzip_comp_level 6;
gzip_buffers 16 8k;
gzip_http_version 1.1;
gzip_min_length 256;
gzip_types
    application/atom+xml
    application/geo+json
    application/javascript
    application/x-javascript
    application/json
    application/ld+json
    application/manifest+json
    application/rdf+xml
    application/rss+xml
    application/vnd.ms-fontobject
    application/wasm
    application/x-web-app-manifest+json
    application/xhtml+xml
    application/xml
    font/eot
    font/otf
    font/ttf
    image/bmp
    image/svg+xml
    text/cache-manifest
    text/calendar
    text/css
    text/javascript
    text/markdown
    text/plain
    text/xml
    text/vcard
    text/vnd.rim.location.xloc
    text/vtt
    text/x-component
    text/x-cross-domain-policy
    text/yaml;
GZIP
    
    log SUCCESS "Gzip compression configured"
}

setup_browser_caching() {
    log INFO "Configuring browser caching..."
    
    cat > /etc/nginx/snippets/browser-cache.conf << 'CACHE'
# Browser Caching Configuration

# Cache everything for 1 month by default
location ~* \.(jpg|jpeg|png|gif|ico|svg|webp|avif)$ {
    expires 1M;
    add_header Cache-Control "public, immutable";
    access_log off;
}

location ~* \.(css|js)$ {
    expires 1M;
    add_header Cache-Control "public, immutable";
    access_log off;
}

location ~* \.(woff|woff2|ttf|eot|otf)$ {
    expires 1M;
    add_header Cache-Control "public";
    add_header Access-Control-Allow-Origin "*";
    access_log off;
}

location ~* \.(pdf|doc|docx|xls|xlsx|ppt|pptx|zip|gz|rar|7z)$ {
    expires 7d;
    add_header Cache-Control "public";
}

# HTML - no cache (always fresh)
location ~* \.html$ {
    expires -1;
    add_header Cache-Control "no-cache, no-store, must-revalidate";
    add_header Pragma "no-cache";
}

# API responses - no cache
location ~* /api/ {
    expires -1;
    add_header Cache-Control "no-cache, no-store, must-revalidate";
}
CACHE
    
    log SUCCESS "Browser caching configured"
}

setup_fastcgi_cache() {
    log INFO "Configuring FastCGI cache..."
    
    # Create cache directory
    mkdir -p /var/cache/nginx/fastcgi
    
    cat > /etc/nginx/snippets/fastcgi-cache.conf << 'FASTCGI'
# FastCGI Cache Configuration

# Cache zone definition (add to http block in nginx.conf)
# fastcgi_cache_path /var/cache/nginx/fastcgi 
#     levels=1:2 
#     keys_zone=WORDPRESS:100m 
#     inactive=60m 
#     max_size=1g;

# Cache settings for PHP
# location ~ \.php$ {
#     fastcgi_cache WORDPRESS;
#     fastcgi_cache_valid 200 60m;
#     fastcgi_cache_valid 404 10m;
#     fastcgi_cache_methods GET HEAD;
#     fastcgi_cache_key "$scheme$request_method$host$request_uri";
#     
#     # Skip cache for logged-in users
#     fastcgi_cache_bypass $skip_cache;
#     fastcgi_no_cache $skip_cache;
#     
#     add_header X-FastCGI-Cache $upstream_cache_status;
# }
FASTCGI
    
    # Add cache path to nginx.conf
    if ! grep -q "fastcgi_cache_path" /etc/nginx/nginx.conf; then
        sed -i '/http {/a \    # FastCGI cache\n    fastcgi_cache_path /var/cache/nginx/fastcgi levels=1:2 keys_zone=WORDPRESS:100m inactive=60m max_size=1g;' /etc/nginx/nginx.conf
    fi
    
    log SUCCESS "FastCGI cache configured"
    log INFO "Enable caching in your site configs by uncommenting the location block"
}

setup_brotli() {
    log INFO "Configuring Brotli compression..."
    
    # Check if brotli module is available
    if nginx -V 2>&1 | grep -q "brotli"; then
        cat > /etc/nginx/snippets/brotli.conf << 'BROTLI'
# Brotli Compression Configuration
brotli on;
brotli_comp_level 6;
brotli_static on;
brotli_types
    application/atom+xml
    application/javascript
    application/json
    application/ld+json
    application/manifest+json
    application/rdf+xml
    application/rss+xml
    application/vnd.ms-fontobject
    application/wasm
    application/x-javascript
    application/xhtml+xml
    application/xml
    font/eot
    font/otf
    font/ttf
    image/svg+xml
    text/css
    text/javascript
    text/plain
    text/xml;
BROTLI
        
        log SUCCESS "Brotli compression configured"
    else
        log WARN "Brotli module not available in Nginx"
        log INFO "Install nginx-extras or compile with brotli module"
    fi
}

setup_open_file_cache() {
    log INFO "Configuring open file cache..."
    
    cat > /etc/nginx/snippets/open-file-cache.conf << 'OPENFILE'
# Open File Cache Configuration
open_file_cache max=10000 inactive=20s;
open_file_cache_valid 30s;
open_file_cache_min_uses 2;
open_file_cache_errors on;
OPENFILE
    
    # Add to nginx.conf
    if ! grep -q "open_file_cache" /etc/nginx/nginx.conf; then
        sed -i '/http {/a \    # Open file cache\n    include /etc/nginx/snippets/open-file-cache.conf;' /etc/nginx/nginx.conf
    fi
    
    log SUCCESS "Open file cache configured"
}

setup_buffer_optimization() {
    log INFO "Configuring buffer optimization..."
    
    cat > /etc/nginx/snippets/buffers.conf << 'BUFFERS'
# Buffer Optimization

# Client body buffer
client_body_buffer_size 10K;
client_header_buffer_size 1k;
client_max_body_size 8m;
large_client_header_buffers 4 8k;

# Proxy buffers
proxy_buffer_size 128k;
proxy_buffers 4 256k;
proxy_busy_buffers_size 256k;

# FastCGI buffers
fastcgi_buffer_size 128k;
fastcgi_buffers 4 256k;
fastcgi_busy_buffers_size 256k;
BUFFERS
    
    log SUCCESS "Buffer optimization configured"
}

#==============================================================================
# MAIN MENU
#==============================================================================

main_menu() {
    while true; do
        clear
        print_header
        
        echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║${WHITE}${BOLD}                         Main Menu                                ${CYAN}║${NC}"
        echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${CYAN}║${NC}  ${GREEN}1${NC}.  Install Nginx                              ${DIM}[Web Server]${NC}"
        echo -e "${CYAN}║${NC}  ${GREEN}2${NC}.  Install PHP-FPM                            ${DIM}[PHP Runtime]${NC}"
        echo -e "${CYAN}║${NC}  ${GREEN}3${NC}.  Install MySQL/MariaDB                       ${DIM}[Database]${NC}"
        echo -e "${CYAN}║${NC}  ${GREEN}4${NC}.  Setup Let's Encrypt SSL                    ${DIM}[Security]${NC}"
        echo -e "${CYAN}║${NC}  ${GREEN}5${NC}.  Manage Virtual Hosts                       ${DIM}[Hosting]${NC}"
        echo -e "${CYAN}║${NC}  ${GREEN}6${NC}.  Install WordPress                          ${DIM}[CMS]${NC}"
        echo -e "${CYAN}║${NC}  ${GREEN}7${NC}.  Configure Reverse Proxy                    ${DIM}[Proxy]${NC}"
        echo -e "${CYAN}║${NC}  ${GREEN}8${NC}.  Apply Security Headers                     ${DIM}[Security]${NC}"
        echo -e "${CYAN}║${NC}  ${GREEN}9${NC}.  Optimize Performance                       ${DIM}[Speed]${NC}"
        echo -e "${CYAN}║${NC}                                                                    ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  ${GREEN}10${NC}. Quick Setup (Install Everything)           ${DIM}[Auto]${NC}"
        echo -e "${CYAN}║${NC}                                                                    ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  ${RED}0${NC}.  Exit"
        echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
        
        echo -en "\n${YELLOW}Select an option: ${NC}"
        read -r choice
        
        case $choice in
            1)  install_nginx ;;
            2)  install_php_fpm ;;
            3)  install_mysql ;;
            4)  setup_ssl ;;
            5)  manage_virtual_hosts ;;
            6)  install_wordpress ;;
            7)  configure_reverse_proxy ;;
            8)  apply_security_headers ;;
            9)  optimize_performance ;;
            10) quick_setup ;;
            0)  
                echo -e "\n${GREEN}Thank you for using $SCRIPT_NAME!${NC}\n"
                exit 0
                ;;
            *)
                log ERROR "Invalid option. Please try again."
                ;;
        esac
        
        echo -e "\n${DIM}Press Enter to continue...${NC}"
        read -r
    done
}

quick_setup() {
    print_section "Quick Setup - Install Everything"
    
    echo -e "${YELLOW}This will install and configure:${NC}"
    echo -e "  ${GREEN}•${NC} Nginx with optimization"
    echo -e "  ${GREEN}•${NC} PHP-FPM"
    echo -e "  ${GREEN}•${NC} MySQL/MariaDB"
    echo -e "  ${GREEN}•${NC} Security headers"
    echo -e "  ${GREEN}•${NC} Performance optimizations"
    
    if ! confirm_action "Proceed with quick setup?"; then
        return 0
    fi
    
    install_dependencies
    install_nginx
    install_php_fpm
    install_mysql
    apply_security_headers
    optimize_performance
    
    log SUCCESS "Quick setup completed!"
    echo -e "\n${GREEN}Your server is now ready!${NC}"
    echo -e "${CYAN}Next steps:${NC}"
    echo -e "  1. Add a virtual host (Option 5)"
    echo -e "  2. Setup SSL certificate (Option 4)"
    echo -e "  3. Install WordPress if needed (Option 6)"
}

#==============================================================================
# SCRIPT ENTRY POINT
#==============================================================================

main() {
    # Check if running as root
    check_root
    
    # Check OS
    check_os
    
    # Install dependencies
    install_dependencies
    
    # Show main menu
    main_menu
}

# Run the script
main "$@"
