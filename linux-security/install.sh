#!/usr/bin/env bash
# =============================================================================
# Linux Security Hardening Script
# Version: 1.0.0
# Author: SecureLinux Team
# License: MIT
# Description: Comprehensive Linux server hardening tool with interactive menu
# Supported: Ubuntu 18.04+, Debian 9+, CentOS 7+, RHEL 7+, Fedora 30+
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

# =============================================================================
# CONFIGURATION & CONSTANTS
# =============================================================================
readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_NAME="Linux Security Hardening Script"
readonly LOG_DIR="/var/log/security-hardening"
readonly BACKUP_DIR="/var/backups/security-hardening"
readonly REPORT_FILE="${LOG_DIR}/security-report-$(date +%Y%m%d-%H%M%S).txt"
readonly SCRIPT_START_TIME=$(date +%s)

# Colors (disabled if not a terminal)
if [[ -t 1 ]]; then
    readonly RED='\033[0;31m'
    readonly GREEN='\033[0;32m'
    readonly YELLOW='\033[1;33m'
    readonly BLUE='\033[0;34m'
    readonly MAGENTA='\033[0;35m'
    readonly CYAN='\033[0;36m'
    readonly WHITE='\033[1;37m'
    readonly BOLD='\033[1m'
    readonly NC='\033[0m'
else
    readonly RED='' GREEN='' YELLOW='' BLUE='' MAGENTA='' CYAN='' WHITE='' BOLD='' NC=''
fi

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Print colored message
print_msg() {
    local color="$1"
    local msg="$2"
    echo -e "${color}${msg}${NC}"
}

# Print success message
print_success() { print_msg "${GREEN}" "  [✓] $1"; }

# Print error message
print_error() { print_msg "${RED}" "  [✗] $1"; }

# Print warning message
print_warning() { print_msg "${YELLOW}" "  [!] $1"; }

# Print info message
print_info() { print_msg "${CYAN}" "  [i] $1"; }

# Print header
print_header() {
    echo ""
    print_msg "${BOLD}${CYAN}" "═══════════════════════════════════════════════════════════════"
    print_msg "${BOLD}${WHITE}" "  $1"
    print_msg "${BOLD}${CYAN}" "═══════════════════════════════════════════════════════════════"
    echo ""
}

# Print banner
print_banner() {
    echo -e "${BOLD}${CYAN}"
    cat << 'BANNER'
    ╔══════════════════════════════════════════════════════════════╗
    ║                                                              ║
    ║          🔒  Linux Security Hardening Script  🔒             ║
    ║                                                              ║
    ║          Professional Server Security Automation             ║
    ║          Version 1.0.0                                       ║
    ║                                                              ║
    ╚══════════════════════════════════════════════════════════════╝
BANNER
    echo -e "${NC}"
}

# Log function
log() {
    local level="$1"
    local msg="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [${level}] ${msg}" >> "${LOG_DIR}/hardening.log" 2>/dev/null || true
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root!"
        print_info "Run with: sudo bash $0"
        exit 1
    fi
}

# Detect OS
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS_ID="${ID}"
        OS_VERSION="${VERSION_ID}"
        OS_CODENAME="${VERSION_CODENAME:-}"
    elif [[ -f /etc/redhat-release ]]; then
        OS_ID="rhel"
        OS_VERSION=$(grep -oP '\d+\.\d+' /etc/redhat-release | head -1)
    else
        print_error "Unable to detect operating system!"
        exit 1
    fi
    print_info "Detected OS: ${OS_ID} ${OS_VERSION}"
    log "INFO" "OS Detected: ${OS_ID} ${OS_VERSION}"
}

# Check available package manager
detect_package_manager() {
    if command -v apt-get &>/dev/null; then
        PKG_MANAGER="apt"
        PKG_UPDATE="apt-get update -qq"
        PKG_INSTALL="apt-get install -y -qq"
    elif command -v yum &>/dev/null; then
        PKG_MANAGER="yum"
        PKG_UPDATE="yum makecache -q"
        PKG_INSTALL="yum install -y -q"
    elif command -v dnf &>/dev/null; then
        PKG_MANAGER="dnf"
        PKG_UPDATE="dnf makecache -q"
        PKG_INSTALL="dnf install -y -q"
    else
        print_error "No supported package manager found!"
        exit 1
    fi
    print_info "Package manager: ${PKG_MANAGER}"
    log "INFO" "Package manager: ${PKG_MANAGER}"
}

# Install package with error handling
install_package() {
    local pkg="$1"
    if $PKG_INSTALL "$pkg" >> "${LOG_DIR}/package-install.log" 2>&1; then
        print_success "Installed: ${pkg}"
        return 0
    else
        print_warning "Failed to install: ${pkg}"
        return 1
    fi
}

# Backup file before modification
backup_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        local backup="${BACKUP_DIR}/$(basename "$file").$(date +%Y%m%d-%H%M%S).bak"
        cp "$file" "$backup"
        log "INFO" "Backed up: ${file} -> ${backup}"
        return 0
    fi
    return 1
}

# Initialize directories
init_dirs() {
    mkdir -p "${LOG_DIR}" "${BACKUP_DIR}"
    chmod 700 "${LOG_DIR}" "${BACKUP_DIR}"
}

# Pause for user input
pause_screen() {
    echo ""
    read -rp "  Press Enter to continue..." _
}

# Get user confirmation
confirm() {
    local prompt="$1"
    local default="${2:-y}"
    local response

    if [[ "$default" == "y" ]]; then
        read -rp "  ${prompt} [Y/n]: " response
        response="${response:-y}"
    else
        read -rp "  ${prompt} [y/N]: " response
        response="${response:-n}"
    fi

    [[ "$response" =~ ^[Yy]$ ]]
}

# Add to security report
report() {
    echo "$1" >> "${REPORT_FILE}" 2>/dev/null || true
}

# =============================================================================
# MODULE 1: SSH HARDENING
# =============================================================================

harden_ssh() {
    print_header "SSH HARDENING"
    log "INFO" "Starting SSH hardening"

    local ssh_config="/etc/ssh/sshd_config"
    local sshd_drop="/etc/ssh/sshd_config.d/99-hardened.conf"

    # Create backup
    backup_file "$ssh_config"

    # Detect SSH config directory
    if [[ -d /etc/ssh/sshd_config.d ]]; then
        ssh_config_target="$sshd_drop"
        print_info "Using drop-in config: ${sshd_drop}"
    else
        ssh_config_target="$ssh_config"
        print_info "Modifying main config: ${ssh_config}"
    fi

    # ---- Disable Root Login ----
    print_info "Disabling root SSH login..."
    if confirm "Disable direct root login via SSH?" "y"; then
        if [[ "$ssh_config_target" == "$sshd_drop" ]]; then
            echo "PermitRootLogin no" >> "$ssh_config_target"
        else
            if grep -q "^PermitRootLogin" "$ssh_config"; then
                sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' "$ssh_config"
            elif grep -q "#PermitRootLogin" "$ssh_config"; then
                sed -i 's/#PermitRootLogin.*/PermitRootLogin no/' "$ssh_config"
            else
                echo "PermitRootLogin no" >> "$ssh_config"
            fi
        fi
        print_success "Root login disabled"
        report "[SSH] Root login: DISABLED"
    fi

    # ---- Change SSH Port ----
    print_info "Current SSH port: $(grep -E '^#?Port ' "$ssh_config" | awk '{print $2}' | head -1)"
    if confirm "Change SSH port from 22 to a custom port?" "y"; then
        local new_port
        while true; do
            read -rp "  Enter new SSH port (1024-65535): " new_port
            if [[ "$new_port" =~ ^[0-9]+$ ]] && (( new_port >= 1024 && new_port <= 65535 )); then
                break
            fi
            print_error "Invalid port number. Please enter 1024-65535."
        done

        if [[ "$ssh_config_target" == "$sshd_drop" ]]; then
            echo "Port ${new_port}" >> "$ssh_config_target"
        else
            if grep -q "^Port " "$ssh_config"; then
                sed -i "s/^Port .*/Port ${new_port}/" "$ssh_config"
            else
                echo "Port ${new_port}" >> "$ssh_config"
            fi
        fi
        print_success "SSH port changed to ${new_port}"
        report "[SSH] Port changed to: ${new_port}"
    fi

    # ---- Key-Only Authentication ----
    if confirm "Enable key-based authentication only (disable password)?" "n"; then
        # First, check if SSH keys exist
        local root_keys="${HOME}/.ssh/authorized_keys"
        if [[ ! -f "$root_keys" ]] || [[ ! -s "$root_keys" ]]; then
            print_warning "No SSH keys found for root!"
            print_info "To set up key-based auth:"
            print_info "  1. Generate key on your client: ssh-keygen -t ed25519"
            print_info "  2. Copy to server: ssh-copy-id root@server"
            if ! confirm "Continue anyway? (You may lock yourself out!)" "n"; then
                print_warning "Skipping key-only authentication"
                return 0
            fi
        fi

        if [[ "$ssh_config_target" == "$sshd_drop" ]]; then
            cat >> "$ssh_config_target" << 'SSHAUTH'
PasswordAuthentication no
ChallengeResponseAuthentication no
UsePAM no
SSHAUTH
        else
            sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' "$ssh_config"
            sed -i 's/^#*ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' "$ssh_config"
        fi
        print_success "Key-only authentication enabled"
        report "[SSH] Authentication: KEY-ONLY (passwords disabled)"
    fi

    # ---- Additional SSH Hardening ----
    print_info "Applying additional SSH hardening..."

    local ssh_hardening=(
        "X11Forwarding no"
        "AllowAgentForwarding no"
        "MaxAuthTries 3"
        "ClientAliveInterval 300"
        "ClientAliveCountMax 2"
        "LoginGraceTime 30"
        "Protocol 2"
        "MaxSessions 3"
        "Banner /etc/issue.net"
        "AllowTcpForwarding no"
    )

    for setting in "${ssh_hardening[@]}"; do
        local key="${setting%% *}"
        if [[ "$ssh_config_target" == "$sshd_drop" ]]; then
            echo "$setting" >> "$ssh_config_target"
        else
            if grep -q "^${key}" "$ssh_config"; then
                sed -i "s|^${key}.*|${setting}|" "$ssh_config"
            else
                echo "$setting" >> "$ssh_config"
            fi
        fi
    done

    print_success "Additional SSH hardening applied"
    report "[SSH] Additional hardening: MaxAuthTries, timeouts, X11, etc."

    # ---- Generate Warning Banner ----
    cat > /etc/issue.net << 'BANNER'
*******************************************************************
*  AUTHORIZED ACCESS ONLY                                          *
*  All connections are monitored and recorded.                     *
*  Disconnect IMMEDIATELY if you are not an authorized user!       *
*******************************************************************
BANNER
    print_success "Warning banner configured"

    # Validate config before restarting
    print_info "Validating SSH configuration..."
    if sshd -t 2>/dev/null; then
        print_success "SSH configuration is valid"
        if systemctl is-active sshd &>/dev/null; then
            systemctl restart sshd
            print_success "SSH service restarted"
        elif systemctl is-active ssh &>/dev/null; then
            systemctl restart ssh
            print_success "SSH service restarted"
        fi
        report "[SSH] Service restarted successfully"
    else
        print_error "SSH configuration has errors! Check ${ssh_config_target}"
        print_warning "Rolling back changes..."
        cp "${BACKUP_DIR}/sshd_config."*.bak "$(head -1 <<< "$(ls -t ${BACKUP_DIR}/sshd_config.*.bak 2>/dev/null)")" "$ssh_config" 2>/dev/null || true
    fi

    log "INFO" "SSH hardening completed"
    pause_screen
}

# =============================================================================
# MODULE 2: FIREWALL SETUP
# =============================================================================

setup_firewall() {
    print_header "FIREWALL SETUP"
    log "INFO" "Starting firewall setup"

    local firewall_choice
    echo "  Select firewall type:"
    echo "    1) UFW (Uncomplicated Firewall) - Recommended for Ubuntu/Debian"
    echo "    2) firewalld - Recommended for CentOS/RHEL/Fedora"
    echo "    3) iptables (manual rules)"
    echo "    4) Skip firewall setup"
    echo ""
    read -rp "  Enter choice [1-4]: " firewall_choice

    case "$firewall_choice" in
        1) setup_ufw ;;
        2) setup_firewalld ;;
        3) setup_iptables ;;
        4) print_info "Skipping firewall setup"; return 0 ;;
        *) print_error "Invalid choice"; return 1 ;;
    esac
}

setup_ufw() {
    print_info "Setting up UFW firewall..."

    install_package "ufw" || { print_error "Failed to install UFW"; return 1; }

    # Reset UFW to defaults
    print_info "Resetting UFW to defaults..."
    ufw --force reset >> "${LOG_DIR}/firewall.log" 2>&1

    # Set default policies
    ufw default deny incoming >> "${LOG_DIR}/firewall.log" 2>&1
    ufw default allow outgoing >> "${LOG_DIR}/firewall.log" 2>&1
    ufw default deny routed >> "${LOG_DIR}/firewall.log" 2>&1
    print_success "Default policies: deny incoming, allow outgoing, deny routed"

    # Get SSH port (check if we changed it)
    local ssh_port=22
    if [[ -f /etc/ssh/sshd_config ]]; then
        ssh_port=$(grep -E '^Port ' /etc/ssh/sshd_config | awk '{print $2}' | tail -1)
        ssh_port="${ssh_port:-22}"
    fi

    # Allow SSH
    ufw allow "$ssh_port/tcp" comment "SSH" >> "${LOG_DIR}/firewall.log" 2>&1
    print_success "Allowed SSH on port ${ssh_port}"

    # Allow HTTP/HTTPS if web server detected
    if systemctl is-active --quiet nginx apache2 httpd 2>/dev/null; then
        ufw allow 80/tcp comment "HTTP" >> "${LOG_DIR}/firewall.log" 2>&1
        ufw allow 443/tcp comment "HTTPS" >> "${LOG_DIR}/firewall.log" 2>&1
        print_success "Allowed HTTP (80) and HTTPS (443)"
    fi

    # Additional ports
    if confirm "Allow additional ports? (e.g., 8080, 3306)" "n"; then
        local ports
        read -rp "  Enter ports (space-separated, e.g., '8080/tcp 3306/tcp'): " ports
        for port in $ports; do
            ufw allow "$port" >> "${LOG_DIR}/firewall.log" 2>&1
            print_success "Allowed ${port}"
        done
    fi

    # Enable logging
    ufw logging on >> "${LOG_DIR}/firewall.log" 2>&1
    print_success "Firewall logging enabled"

    # Enable UFW
    ufw --force enable >> "${LOG_DIR}/firewall.log" 2>&1
    print_success "UFW firewall enabled"

    # Show status
    echo ""
    ufw status verbose
    report "[FIREWALL] UFW enabled with deny-incoming default policy"
    report "[FIREWALL] SSH allowed on port ${ssh_port}"
}

setup_firewalld() {
    print_info "Setting up firewalld..."

    install_package "firewalld" || { print_error "Failed to install firewalld"; return 1; }

    systemctl enable firewalld
    systemctl start firewalld

    # Set default zone to drop
    firewall-cmd --set-default-zone=drop >> "${LOG_DIR}/firewall.log" 2>&1
    firewall-cmd --permanent --set-default-zone=drop >> "${LOG_DIR}/firewall.log" 2>&1

    # Get SSH port
    local ssh_port=22
    if [[ -f /etc/ssh/sshd_config ]]; then
        ssh_port=$(grep -E '^Port ' /etc/ssh/sshd_config | awk '{print $2}' | tail -1)
        ssh_port="${ssh_port:-22}"
    fi

    # Allow SSH
    firewall-cmd --permanent --add-port="${ssh_port}/tcp" >> "${LOG_DIR}/firewall.log" 2>&1
    print_success "Allowed SSH on port ${ssh_port}"

    # Allow HTTP/HTTPS
    if systemctl is-active --quiet nginx httpd 2>/dev/null; then
        firewall-cmd --permanent --add-service=http >> "${LOG_DIR}/firewall.log" 2>&1
        firewall-cmd --permanent --add-service=https >> "${LOG_DIR}/firewall.log" 2>&1
        print_success "Allowed HTTP and HTTPS"
    fi

    # Enable logging
    firewall-cmd --set-log-denied=all >> "${LOG_DIR}/firewall.log" 2>&1

    firewall-cmd --reload >> "${LOG_DIR}/firewall.log" 2>&1
    print_success "firewalld configured and reloaded"
    firewall-cmd --list-all

    report "[FIREWALL] firewalld enabled with drop zone"
}

setup_iptables() {
    print_info "Setting up iptables rules..."

    # Flush existing rules
    iptables -F
    iptables -X
    iptables -t nat -F
    iptables -t nat -X

    # Default policies
    iptables -P INPUT DROP
    iptables -P FORWARD DROP
    iptables -P OUTPUT ACCEPT

    # Loopback
    iptables -A INPUT -i lo -j ACCEPT
    iptables -A OUTPUT -o lo -j ACCEPT

    # Established connections
    iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

    # Get SSH port
    local ssh_port=22
    if [[ -f /etc/ssh/sshd_config ]]; then
        ssh_port=$(grep -E '^Port ' /etc/ssh/sshd_config | awk '{print $2}' | tail -1)
        ssh_port="${ssh_port:-22}"
    fi

    # Allow SSH
    iptables -A INPUT -p tcp --dport "$ssh_port" -j ACCEPT

    # Allow ICMP (ping)
    iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT

    # Drop invalid packets
    iptables -A INPUT -m conntrack --ctstate INVALID -j DROP

    # Anti-SSH brute force (rate limiting)
    iptables -A INPUT -p tcp --dport "$ssh_port" -m conntrack --ctstate NEW -m recent --set
    iptables -A INPUT -p tcp --dport "$ssh_port" -m conntrack --ctstate NEW -m recent --update --seconds 60 --hitcount 6 -j DROP

    # Save rules
    if command -v netfilter-persistent &>/dev/null; then
        netfilter-persistent save
    elif command -v iptables-save &>/dev/null; then
        iptables-save > /etc/iptables/rules.v4 2>/dev/null || \
        iptables-save > /etc/sysconfig/iptables 2>/dev/null || \
        print_warning "Could not auto-save iptables rules"
    fi

    print_success "iptables rules applied"
    report "[FIREWALL] iptables configured with DROP default policy"
}

# =============================================================================
# MODULE 3: FAIL2BAN
# =============================================================================

setup_fail2ban() {
    print_header "FAIL2BAN INSTALLATION & CONFIGURATION"
    log "INFO" "Starting Fail2Ban setup"

    if ! confirm "Install and configure Fail2Ban?" "y"; then
        return 0
    fi

    # Install Fail2Ban
    install_package "fail2ban" || { print_error "Failed to install Fail2Ban"; return 1; }

    # Backup existing config
    backup_file "/etc/fail2ban/jail.local" 2>/dev/null || true

    # Create jail.local configuration
    cat > /etc/fail2ban/jail.local << 'F2B'
# =============================================================================
# Fail2Ban Configuration - Generated by Linux Security Hardening Script
# =============================================================================

[DEFAULT]
# Ban for 1 hour
bantime  = 3600
# Detection window of 10 minutes
findtime = 600
# Ban after 5 failed attempts
maxretry = 5
# Use systemd backend
backend  = systemd
# Ignore localhost
ignoreip = 127.0.0.1/8 ::1
# Email notifications (uncomment and configure)
# destemail = admin@example.com
# sender = fail2ban@example.com
# action = %(action_mwl)s
# Default action: ban + log
banaction = %(banaction_allports)s

# ---- SSH Protection ----
[sshd]
enabled  = true
port     = ssh
filter   = sshd
logpath  = /var/log/auth.log
maxretry = 3
bantime  = 7200
findtime = 600

[sshd-ddos]
enabled  = true
port     = ssh
filter   = sshd-ddos
logpath  = /var/log/auth.log
maxretry = 6
bantime  = 3600

# ---- Apache Protection ----
[apache-auth]
enabled  = false
port     = http,https
filter   = apache-auth
logpath  = /var/log/apache2/error.log
maxretry = 5

[apache-badbots]
enabled  = false
port     = http,https
filter   = apache-badbots
logpath  = /var/log/apache2/access.log
maxretry = 2

# ---- Nginx Protection ----
[nginx-http-auth]
enabled  = false
port     = http,https
filter   = nginx-http-auth
logpath  = /var/log/nginx/error.log
maxretry = 5

# ---- Recidive (repeat offenders) ----
[recidive]
enabled  = true
filter   = recidive
logpath  = /var/log/fail2ban.log
bantime  = 604800
findtime = 86400
maxretry = 3
F2B

    print_success "Fail2Ban configuration created"

    # Enable and start service
    systemctl enable fail2ban
    systemctl restart fail2ban

    if systemctl is-active --quiet fail2ban; then
        print_success "Fail2Ban is running"
        echo ""
        print_info "Fail2Ban status:"
        fail2ban-client status sshd 2>/dev/null || true
    else
        print_error "Fail2Ban failed to start. Check logs."
    fi

    report "[FAIL2BAN] Installed and configured"
    report "[FAIL2BAN] SSH protection: enabled (3 retries, 2h ban)"
    report "[FAIL2BAN] Recidive: enabled (repeat offender protection)"

    log "INFO" "Fail2Ban setup completed"
    pause_screen
}

# =============================================================================
# MODULE 4: AUTOMATIC SECURITY UPDATES
# =============================================================================

setup_auto_updates() {
    print_header "AUTOMATIC SECURITY UPDATES"
    log "INFO" "Setting up automatic security updates"

    if ! confirm "Configure automatic security updates?" "y"; then
        return 0
    fi

    case "$PKG_MANAGER" in
        apt)
            # Install unattended-upgrades
            install_package "unattended-upgrades"
            install_package "apt-listchanges" 2>/dev/null || true

            # Enable automatic updates
            cat > /etc/apt/apt.conf.d/20auto-upgrades << 'AUTOUP'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Download-Upgradeable-Packages "1";
AUTOUP

            # Configure unattended-upgrades
            cat > /etc/apt/apt.conf.d/50unattended-upgrades << 'UNATT'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
    "${distro_id}ESMApps:${distro_codename}-apps-security";
    "${distro_id}ESM:${distro_codename}-infra-security";
};
Unattended-Upgrade::Package-Blacklist {
};
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Mail "root";
Unattended-Upgrade::MailReport "on-change";
Unattended-Upgrade::SyslogEnable "true";
Unattended-Upgrade::SyslogFacility "daemon";
UNATT

            # Enable the service
            systemctl enable unattended-upgrades
            systemctl restart unattended-upgrades

            print_success "Unattended security upgrades configured"
            report "[UPDATES] Automatic security updates: ENABLED (unattended-upgrades)"
            ;;

        yum|dnf)
            # Install yum-cron or dnf-automatic
            local auto_pkg="dnf-automatic"
            [[ "$PKG_MANAGER" == "yum" ]] && auto_pkg="yum-cron"

            install_package "$auto_pkg" || { print_error "Failed to install auto-update package"; return 1; }

            if [[ "$PKG_MANAGER" == "dnf" ]]; then
                # Configure dnf-automatic
                sed -i 's/^apply_updates.*/apply_updates = yes/' /etc/dnf/automatic.conf 2>/dev/null
                sed -i 's/^upgrade_type.*/upgrade_type = security/' /etc/dnf/automatic.conf 2>/dev/null
                systemctl enable --now dnf-automatic.timer
            else
                # Configure yum-cron
                sed -i 's/^apply_updates.*/apply_updates = yes/' /etc/yum/yum-cron.conf 2>/dev/null
                sed -i 's/^update_cmd.*/update_cmd = security/' /etc/yum/yum-cron.conf 2>/dev/null
                systemctl enable --now yum-cron
            fi

            print_success "Automatic security updates configured"
            report "[UPDATES] Automatic security updates: ENABLED (${auto_pkg})"
            ;;
    esac

    # Configure AIDE (Advanced Intrusion Detection Environment)
    print_info "Setting up AIDE file integrity checking..."
    if install_package "aide" 2>/dev/null; then
        # Initialize AIDE database
        aideinit >> "${LOG_DIR}/aide-init.log" 2>&1 || aide --init >> "${LOG_DIR}/aide-init.log" 2>&1 || true
        cp /var/lib/aide/aide.db.new /var/lib/aide/aide.db 2>/dev/null || \
        cp /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz 2>/dev/null || true
        print_success "AIDE file integrity checking initialized"
        report "[AIDE] File integrity monitoring: ENABLED"
    else
        print_warning "AIDE not available on this system"
    fi

    log "INFO" "Auto-update setup completed"
    pause_screen
}

# =============================================================================
# MODULE 5: FILE PERMISSION HARDENING
# =============================================================================

harden_permissions() {
    print_header "FILE PERMISSION HARDENING"
    log "INFO" "Starting file permission hardening"

    if ! confirm "Harden file permissions?" "y"; then
        return 0
    fi

    # ---- Critical System Files ----
    print_info "Hardening critical system file permissions..."

    local -A critical_files=(
        ["/etc/passwd"]="644"
        ["/etc/shadow"]="600"
        ["/etc/group"]="644"
        ["/etc/gshadow"]="600"
        ["/etc/sudoers"]="440"
        ["/etc/ssh/sshd_config"]="600"
        ["/etc/crontab"]="600"
        ["/etc/hosts"]="644"
        ["/etc/hostname"]="644"
        ["/etc/resolv.conf"]="644"
        ["/etc/sysctl.conf"]="600"
    )

    local fixed=0
    for file in "${!critical_files[@]}"; do
        if [[ -f "$file" ]]; then
            chmod "${critical_files[$file]}" "$file"
            ((fixed++))
        fi
    done
    print_success "Hardened ${fixed} critical system files"
    report "[PERMS] Critical system files hardened: ${fixed} files"

    # ---- World-Writable Files ----
    print_info "Scanning for world-writable files..."
    local world_writable
    world_writable=$(find / -xdev -type f -perm -0002 2>/dev/null | head -50)

    if [[ -n "$world_writable" ]]; then
        local ww_count
        ww_count=$(echo "$world_writable" | wc -l)
        print_warning "Found ${ww_count} world-writable files"

        if confirm "Remove world-writable permissions from found files?" "y"; then
            while IFS= read -r file; do
                chmod o-w "$file" 2>/dev/null || true
            done <<< "$world_writable"
            print_success "World-writable permissions removed"
        fi
    else
        print_success "No world-writable files found"
    fi

    # ---- SUID/SGID Files ----
    print_info "Scanning for SUID/SGID files..."
    local suid_files
    suid_files=$(find / -xdev \( -perm -4000 -o -perm -2000 \) -type f 2>/dev/null)

    if [[ -n "$suid_files" ]]; then
        local suid_count
        suid_count=$(echo "$suid_files" | wc -l)
        print_info "Found ${suid_count} SUID/SGID files (showing non-essential):"

        # Common safe SUID binaries
        local safe_suids="/usr/bin/sudo|/usr/bin/passwd|/usr/bin/su|/usr/bin/chsh|/usr/bin/newgrp|/usr/bin/gpasswd|/usr/lib/openssh/ssh-keysign|/usr/bin/pkexec"

        while IFS= read -r file; do
            if ! echo "$file" | grep -qE "$safe_suids"; then
                print_warning "  ${file}"
            fi
        done <<< "$suid_files"

        if confirm "Remove SUID/SGID from non-essential binaries?" "n"; then
            local removed=0
            while IFS= read -r file; do
                if ! echo "$file" | grep -qE "$safe_suids"; then
                    chmod u-s "$file" 2>/dev/null || true
                    chmod g-s "$file" 2>/dev/null || true
                    ((removed++))
                fi
            done <<< "$suid_files"
            print_success "Removed SUID/SGID from ${removed} non-essential files"
            report "[PERMS] SUID/SGID removed from ${removed} non-essential binaries"
        fi
    fi

    # ---- Home Directory Permissions ----
    print_info "Hardening home directory permissions..."
    while IFS= read -r dir; do
        if [[ -d "$dir" ]]; then
            chmod 700 "$dir" 2>/dev/null || true
        fi
    done < <(find /home -maxdepth 1 -mindepth 1 -type d 2>/dev/null)
    print_success "Home directory permissions set to 700"
    report "[PERMS] Home directories: 700"

    # ---- Remove world-readable home contents ----
    print_info "Removing group/other read from home directories..."
    find /home -maxdepth 1 -mindepth 1 -type d -exec chmod g-rwx,o-rwx {} \; 2>/dev/null || true
    print_success "Home directories secured"

    # ---- Umask Configuration ----
    print_info "Configuring default umask..."
    if ! grep -q "umask 027" /etc/profile 2>/dev/null; then
        echo "umask 027" >> /etc/profile
    fi
    if ! grep -q "umask 027" /etc/bash.bashrc 2>/dev/null; then
        echo "umask 027" >> /etc/bash.bashrc 2>/dev/null || true
    fi
    print_success "Default umask set to 027"
    report "[PERMS] Default umask: 027"

    log "INFO" "File permission hardening completed"
    pause_screen
}

# =============================================================================
# MODULE 6: DISABLE UNUSED SERVICES
# =============================================================================

disable_services() {
    print_header "DISABLE UNUSED SERVICES"
    log "INFO" "Scanning for unused services"

    if ! confirm "Scan and disable unused services?" "y"; then
        return 0
    fi

    # Common unnecessary services
    local -a potentially_unnecessary=(
        "avahi-daemon"
        "cups"
        "rpcbind"
        "nfs-server"
        "vsftpd"
        "telnet.socket"
        "rsh.socket"
        "rlogin.socket"
        "tftp.socket"
        "xinetd"
        "bluetooth"
        "cups-browsed"
        "ModemManager"
        "wpa_supplicant"
    )

    local disabled_count=0

    echo "  Checking for potentially unnecessary services..."
    echo ""

    for service in "${potentially_unnecessary[@]}"; do
        if systemctl is-enabled --quiet "$service" 2>/dev/null; then
            print_warning "  Enabled: ${service}"

            # Check if it's actually in use (basic heuristic)
            local in_use=false
            case "$service" in
                cups)
                    # Check if any printer is configured
                    lpstat -p &>/dev/null && in_use=true ;;
                bluetooth)
                    # Check if bluetooth hardware exists
                    lsusb 2>/dev/null | grep -qi bluetooth && in_use=true ;;
                rpcbind|nfs-server)
                    # Check for NFS mounts
                    mount | grep -q nfs && in_use=true ;;
                wpa_supplicant)
                    # Check for wifi
                    iwconfig 2>/dev/null | grep -q "no wireless" && in_use=true || in_use=false ;;
            esac

            if $in_use; then
                print_info "    ${service} appears to be in use - skipping"
                continue
            fi

            if confirm "    Disable ${service}?" "y"; then
                systemctl stop "$service" 2>/dev/null || true
                systemctl disable "$service" 2>/dev/null || true
                systemctl mask "$service" 2>/dev/null || true
                print_success "    Disabled and masked: ${service}"
                ((disabled_count++))
            fi
        fi
    done

    # Disable core dumps
    print_info "Disabling core dumps..."
    cat > /etc/security/limits.d/99-nocoredump.conf << 'CORE'
* hard core 0
* soft core 0
CORE
    cat > /etc/sysctl.d/99-nocore.conf << 'SYSCTL'
fs.suid_dumpable = 0
kernel.core_pattern = |/bin/false
SYSCTL
    sysctl -p /etc/sysctl.d/99-nocore.conf >> "${LOG_DIR}/sysctl.log" 2>&1
    print_success "Core dumps disabled"

    # Disable USB storage (optional)
    if confirm "Disable USB storage devices?" "n"; then
        echo "blacklist usb-storage" > /etc/modprobe.d/blacklist-usb-storage.conf
        print_success "USB storage disabled"
        report "[SERVICES] USB storage: DISABLED"
    fi

    print_success "Disabled ${disabled_count} unnecessary services"
    report "[SERVICES] ${disabled_count} unnecessary services disabled"
    report "[SERVICES] Core dumps: DISABLED"

    log "INFO" "Service hardening completed: ${disabled_count} services disabled"
    pause_screen
}

# =============================================================================
# MODULE 7: KERNEL PARAMETER HARDENING (SYSCTL)
# =============================================================================

harden_kernel() {
    print_header "KERNEL PARAMETER HARDENING (SYSCTL)"
    log "INFO" "Starting kernel parameter hardening"

    if ! confirm "Apply kernel security parameters?" "y"; then
        return 0
    fi

    # Backup existing sysctl config
    backup_file "/etc/sysctl.conf"
    backup_file "/etc/sysctl.d/99-security.conf" 2>/dev/null || true

    # Create hardened sysctl configuration
    cat > /etc/sysctl.d/99-security.conf << 'SYSCTL'
# =============================================================================
# Kernel Security Parameters - Generated by Linux Security Hardening Script
# =============================================================================

# ---- Network Security ----
# Disable IP forwarding (enable only if running a router/container host)
# net.ipv4.ip_forward = 0
# net.ipv6.conf.all.forwarding = 0

# Disable source routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0

# Disable ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# Disable secure ICMP redirects
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0

# Log suspicious packets
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1

# Ignore ICMP broadcast requests (Smurf attack prevention)
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Ignore bogus ICMP error responses
net.ipv4.icmp_ignore_bogus_error_responses = 1

# SYN flood protection
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 2

# Reverse path filtering
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# RFC 1337 - TIME-WAIT assassination prevention
net.ipv4.tcp_rfc1337 = 1

# ---- IPv6 Security ----
net.ipv6.conf.all.accept_ra = 0
net.ipv6.conf.default.accept_ra = 0

# ---- Memory Protection ----
# Restrict dmesg access
kernel.dmesg_restrict = 1

# Restrict kernel pointer exposure
kernel.kptr_restrict = 2

# Disable SysRq key (emergency keyboard shortcuts)
kernel.sysrq = 0

# Restrict user namespace (may break Docker)
# kernel.unprivileged_userns_clone = 0

# Restrict perf_event access
kernel.perf_event_paranoid = 3

# Restrict BPF
kernel.unprivileged_bpf_disabled = 1

# ---- File System Protection ----
# Restrict /proc access
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
fs.suid_dumpable = 0

# ---- Kernel ASLR ----
kernel.randomize_va_space = 2

# ---- Network Buffers ----
# Increase connection tracking (if using iptables/nftables)
# net.netfilter.nf_conntrack_max = 262144

# Increase local port range
net.ipv4.ip_local_port_range = 1024 65535

# ---- TCP Hardening ----
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_max_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_intvl = 10
net.ipv4.tcp_keepalive_probes = 5
SYSCTL

    # Apply sysctl settings
    print_info "Applying kernel parameters..."
    if sysctl -p /etc/sysctl.d/99-security.conf >> "${LOG_DIR}/sysctl.log" 2>&1; then
        print_success "Kernel parameters applied successfully"
    else
        print_error "Some kernel parameters failed to apply"
        print_warning "Check ${LOG_DIR}/sysctl.log for details"
    fi

    # Ensure sysctl loads at boot
    if [[ ! -f /etc/sysctl.d/99-security.conf ]] || \
       ! grep -q "99-security.conf" /etc/rc.local 2>/dev/null; then
        print_success "Kernel parameters will persist across reboots"
    fi

    report "[KERNEL] Sysctl hardening applied"
    report "[KERNEL] ASLR: enabled (randomize_va_space=2)"
    report "[KERNEL] SYN cookies: enabled"
    report "[KERNEL] ICMP redirects: disabled"
    report "[KERNEL] Source routing: disabled"

    log "INFO" "Kernel hardening completed"
    pause_screen
}

# =============================================================================
# MODULE 8: AUDIT LOGGING
# =============================================================================

setup_audit() {
    print_header "AUDIT LOGGING"
    log "INFO" "Setting up audit logging"

    if ! confirm "Configure audit logging (auditd)?" "y"; then
        return 0
    fi

    # Install auditd
    install_package "auditd" || { print_error "Failed to install auditd"; return 1; }

    # Backup existing config
    backup_file "/etc/audit/auditd.conf" 2>/dev/null || true

    # Configure auditd
    cat > /etc/audit/auditd.conf << 'AUDITCONF'
#
# auditd configuration - Generated by Linux Security Hardening Script
#
log_file = /var/log/audit/audit.log
log_format = ENRICHED
log_group = adm
write_logs = yes
priority_boost = 4
flush = INCREMENTAL_ASYNC
freq = 50
num_logs = 10
disp_qos = lossy
dispatcher = /sbin/audispd
name_format = HOSTNAME
max_log_file = 50
max_log_file_action = ROTATE
space_left = 150
space_left_action = SYSLOG
admin_space_left = 50
admin_space_left_action = SUSPEND
disk_full_action = SUSPEND
disk_error_action = SUSPEND
tcp_listen_queue = 5
tcp_max_per_addr = 1
tcp_client_max_idle = 0
distribute_network = no
AUDITCONF

    # Configure audit rules
    cat > /etc/audit/rules.d/hardening.rules << 'AUDITRULES'
# =============================================================================
# Audit Rules - Linux Security Hardening Script
# =============================================================================

# Delete all existing rules
-D
# Buffer size
-b 8192
# Failure mode (1=printk, 2=panic)
-f 1

# ---- Authentication Events ----
-w /var/log/auth.log -p wa -k auth_log
-w /var/log/secure -p wa -k auth_log
-w /var/run/utmp -p wa -k session
-w /var/log/wtmp -p wa -k session
-w /var/log/btmp -p wa -k session

# ---- User & Group Changes ----
-w /etc/passwd -p wa -k user_modification
-w /etc/shadow -p wa -k user_modification
-w /etc/group -p wa -k user_modification
-w /etc/gshadow -p wa -k user_modification
-w /etc/security/opasswd -p wa -k user_modification

# ---- Sudo Configuration ----
-w /etc/sudoers -p wa -k sudo_changes
-w /etc/sudoers.d/ -p wa -k sudo_changes

# ---- SSH Configuration ----
-w /etc/ssh/sshd_config -p wa -k ssh_config
-w /etc/ssh/sshd_config.d/ -p wa -k ssh_config

# ---- Cron Changes ----
-w /etc/crontab -p wa -k cron_modification
-w /etc/cron.d/ -p wa -k cron_modification
-w /etc/cron.daily/ -p wa -k cron_modification
-w /etc/cron.hourly/ -p wa -k cron_modification
-w /etc/cron.monthly/ -p wa -k cron_modification
-w /etc/cron.weekly/ -p wa -k cron_modification
-w /var/spool/cron/ -p wa -k cron_modification

# ---- Kernel Module Loading ----
-w /sbin/insmod -p x -k kernel_modules
-w /sbin/rmmod -p x -k kernel_modules
-w /sbin/modprobe -p x -k kernel_modules

# ---- System Startup Scripts ----
-w /etc/init.d/ -p wa -k init_scripts
-w /etc/systemd/ -p wa -k systemd_changes

# ---- Network Configuration ----
-w /etc/hosts -p wa -k network_config
-w /etc/sysconfig/network -p wa -k network_config
-w /etc/resolv.conf -p wa -k network_config

# ---- File System Mounts ----
-w /etc/fstab -p wa -k mount_changes
-w /etc/mtab -p wa -k mount_changes

# ---- Time Changes ----
-w /etc/localtime -p wa -k time_change
-w /etc/timezone -p wa -k time_change

# ---- Login Defaults ----
-w /etc/login.defs -p wa -k login_defaults
-w /etc/pam.d/ -p wa -k pam_config

# ---- Firewall Changes ----
-w /etc/ufw/ -p wa -k firewall_changes
-w /etc/iptables/ -p wa -k firewall_changes

# ---- Package Manager Changes ----
-w /var/lib/dpkg/ -p wa -k package_manager
-w /var/lib/rpm/ -p wa -k package_manager

# ---- Make audit configuration immutable (must be last rule) ---
# -e 2
AUDITRULES

    # Enable and start auditd
    systemctl enable auditd
    systemctl restart auditd

    # Load audit rules
    if command -v augenrules &>/dev/null; then
        augenrules --load >> "${LOG_DIR}/audit.log" 2>&1 || \
        auditctl -R /etc/audit/rules.d/hardening.rules >> "${LOG_DIR}/audit.log" 2>&1 || true
    fi

    if systemctl is-active --quiet auditd; then
        print_success "Audit daemon is running"
        print_success "Audit rules loaded"
        report "[AUDIT] auditd: ENABLED and configured"
        report "[AUDIT] Rules: auth, user changes, sudo, SSH, cron, kernel modules"
    else
        print_error "Audit daemon failed to start"
    fi

    log "INFO" "Audit setup completed"
    pause_screen
}

# =============================================================================
# MODULE 9: SECURITY REPORT GENERATION
# =============================================================================

generate_report() {
    print_header "GENERATING SECURITY REPORT"
    log "INFO" "Generating security report"

    local script_end_time
    script_end_time=$(date +%s)
    local elapsed=$(( script_end_time - SCRIPT_START_TIME ))

    # Clear old report and start fresh
    : > "${REPORT_FILE}"

    report "╔══════════════════════════════════════════════════════════════╗"
    report "║           LINUX SECURITY HARDENING REPORT                   ║"
    report "║           Generated: $(date '+%Y-%m-%d %H:%M:%S')                      ║"
    report "╚══════════════════════════════════════════════════════════════╝"
    report ""
    report "System Information:"
    report "  Hostname:     $(hostname)"
    report "  OS:           $(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d'"' -f2)"
    report "  Kernel:       $(uname -r)"
    report "  Uptime:       $(uptime -p 2>/dev/null || uptime)"
    report "  Script Time:  ${elapsed} seconds"
    report ""

    report "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    report "SSH Configuration:"
    report "  Root Login:    $(grep -E '^PermitRootLogin' /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}' | tail -1)"
    report "  SSH Port:      $(grep -E '^Port ' /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}' | tail -1)"
    report "  Password Auth: $(grep -E '^PasswordAuthentication' /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}' | tail -1)"
    report ""

    report "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    report "Firewall Status:"
    if command -v ufw &>/dev/null; then
        report "  Type: UFW"
        report "  Status: $(ufw status 2>/dev/null | head -1)"
    elif command -v firewall-cmd &>/dev/null; then
        report "  Type: firewalld"
        report "  Status: $(firewall-cmd --state 2>/dev/null)"
    elif command -v iptables &>/dev/null; then
        report "  Type: iptables"
        report "  Rules: $(iptables -L -n 2>/dev/null | grep -c "^[A-Z]") chains"
    fi
    report ""

    report "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    report "Fail2Ban Status:"
    if command -v fail2ban-client &>/dev/null; then
        report "  Status: $(systemctl is-active fail2ban 2>/dev/null)"
        report "  Jails: $(fail2ban-client status 2>/dev/null | grep "Jail list" | cut -d: -f2)"
        report "  Banned IPs (SSH): $(fail2ban-client status sshd 2>/dev/null | grep "Currently banned" | cut -d: -f2)"
    else
        report "  Status: NOT INSTALLED"
    fi
    report ""

    report "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    report "Kernel Parameters:"
    report "  ASLR:           $(sysctl -n kernel.randomize_va_space 2>/dev/null)"
    report "  SYN Cookies:    $(sysctl -n net.ipv4.tcp_syncookies 2>/dev/null)"
    report "  IP Forward:     $(sysctl -n net.ipv4.ip_forward 2>/dev/null)"
    report "  Dmesg Restrict: $(sysctl -n kernel.dmesg_restrict 2>/dev/null)"
    report "  Kptr Restrict:  $(sysctl -n kernel.kptr_restrict 2>/dev/null)"
    report ""

    report "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    report "Audit Status:"
    if command -v auditctl &>/dev/null; then
        report "  Status: $(systemctl is-active auditd 2>/dev/null)"
        report "  Rules: $(auditctl -l 2>/dev/null | grep -v "^No rules" | wc -l) loaded"
    else
        report "  Status: NOT INSTALLED"
    fi
    report ""

    report "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    report "Open Ports:"
    report "$(ss -tlnp 2>/dev/null || netstat -tlnp 2>/dev/null)"
    report ""

    report "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    report "Active Network Connections:"
    report "$(ss -tunp 2>/dev/null | head -20 || netstat -tunp 2>/dev/null | head -20)"
    report ""

    report "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    report "Last 10 Failed Login Attempts:"
    report "$(journalctl _SYSTEMD_UNIT=sshd.service --no-pager -n 50 2>/dev/null | grep -i "failed\|invalid" | tail -10 || lastb 2>/dev/null | head -10)"
    report ""

    report "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    report "Security Recommendations:"
    report "  [✓] Review the report above for any remaining issues"
    report "  [✓] Schedule regular security audits"
    report "  [✓] Keep system updated regularly"
    report "  [✓] Monitor /var/log/ for suspicious activity"
    report "  [✓] Consider setting up intrusion detection (AIDE/OSSEC)"
    report "  [✓] Implement principle of least privilege"
    report "  [✓] Regular backup verification"
    report ""
    report "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    report "Report saved to: ${REPORT_FILE}"
    report "Logs saved to: ${LOG_DIR}/"

    # Display report
    print_success "Security report generated: ${REPORT_FILE}"
    echo ""
    cat "${REPORT_FILE}"

    log "INFO" "Security report generated"
    pause_screen
}

# =============================================================================
# MODULE 10: FULL AUTOMATED HARDENING
# =============================================================================

full_hardening() {
    print_header "FULL AUTOMATED HARDENING"
    log "INFO" "Starting full automated hardening"

    print_warning "This will apply ALL security hardening measures!"
    print_warning "Make sure you have console access in case SSH locks you out!"
    echo ""

    if ! confirm "Proceed with full hardening?" "n"; then
        return 0
    fi

    harden_ssh
    setup_firewall
    setup_fail2ban
    setup_auto_updates
    harden_permissions
    disable_services
    harden_kernel
    setup_audit
    generate_report

    print_header "HARDENING COMPLETE"
    print_success "All security measures have been applied!"
    print_info "Review the security report for details"
    print_info "Log files are in: ${LOG_DIR}/"
    print_warning "Important: Ensure you can still access your server!"

    log "INFO" "Full hardening completed"
}

# =============================================================================
# MAIN MENU
# =============================================================================

show_menu() {
    clear
    print_banner

    print_msg "${BOLD}${GREEN}" "  ╔══════════════════════════════════════════════════╗"
    print_msg "${BOLD}${GREEN}" "  ║           MAIN MENU                             ║"
    print_msg "${BOLD}${GREEN}" "  ╠══════════════════════════════════════════════════╣"
    print_msg "${BOLD}${GREEN}" "  ║                                                  ║"
    print_msg "${BOLD}${GREEN}" "  ║   1)  SSH Hardening                              ║"
    print_msg "${BOLD}${GREEN}" "  ║   2)  Firewall Setup                             ║"
    print_msg "${BOLD}${GREEN}" "  ║   3)  Fail2Ban Installation & Config             ║"
    print_msg "${BOLD}${GREEN}" "  ║   4)  Automatic Security Updates                 ║"
    print_msg "${BOLD}${GREEN}" "  ║   5)  File Permission Hardening                  ║"
    print_msg "${BOLD}${GREEN}" "  ║   6)  Disable Unused Services                    ║"
    print_msg "${BOLD}${GREEN}" "  ║   7)  Kernel Parameter Hardening (sysctl)        ║"
    print_msg "${BOLD}${GREEN}" "  ║   8)  Audit Logging                              ║"
    print_msg "${BOLD}${GREEN}" "  ║   9)  Generate Security Report                   ║"
    print_msg "${BOLD}${GREEN}" "  ║                                                  ║"
    print_msg "${BOLD}${YELLOW}" "  ║   A)  Full Automated Hardening (ALL)             ║"
    print_msg "${BOLD}${YELLOW}" "  ║   R)  View Last Security Report                  ║"
    print_msg "${BOLD}${RED}" "  ║   Q)  Quit                                      ║"
    print_msg "${BOLD}${GREEN}" "  ║                                                  ║"
    print_msg "${BOLD}${GREEN}" "  ╚══════════════════════════════════════════════════╝"
    echo ""
}

# =============================================================================
# ENTRY POINT
# =============================================================================

main() {
    # Check root privileges
    check_root

    # Initialize
    init_dirs
    detect_os
    detect_package_manager

    # Log start
    log "INFO" "========================================="
    log "INFO" "Security Hardening Script v${SCRIPT_VERSION} started"
    log "INFO" "========================================="

    # Main loop
    while true; do
        show_menu
        local choice
        read -rp "  Select option [1-9, A, R, Q]: " choice

        case "$choice" in
            1) harden_ssh ;;
            2) setup_firewall ;;
            3) setup_fail2ban ;;
            4) setup_auto_updates ;;
            5) harden_permissions ;;
            6) disable_services ;;
            7) harden_kernel ;;
            8) setup_audit ;;
            9) generate_report ;;
            [aA]) full_hardening ;;
            [rR])
                if [[ -f "${REPORT_FILE}" ]]; then
                    cat "${REPORT_FILE}"
                else
                    # Find most recent report
                    local latest_report
                    latest_report=$(ls -t "${LOG_DIR}"/security-report-*.txt 2>/dev/null | head -1)
                    if [[ -n "$latest_report" ]]; then
                        cat "$latest_report"
                    else
                        print_warning "No security reports found yet"
                    fi
                fi
                pause_screen
                ;;
            [qQ])
                print_msg "${GREEN}" ""
                print_msg "${GREEN}" "  Thank you for using Linux Security Hardening Script!"
                print_msg "${GREEN}" "  Report location: ${REPORT_FILE}"
                print_msg "${GREEN}" "  Logs location: ${LOG_DIR}/"
                print_msg "${GREEN}" ""
                log "INFO" "Script exited by user"
                exit 0
                ;;
            *)
                print_error "Invalid option. Please try again."
                sleep 1
                ;;
        esac
    done
}

# Run main function
main "$@"
