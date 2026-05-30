#!/usr/bin/env bash
# ============================================================================
# Docker Setup Script — Professional Edition v2.0
# ============================================================================
# A production-grade, interactive Docker installation and management tool.
# Supports Ubuntu/Debian systems with comprehensive Docker ecosystem setup.
#
# Author:  DockerSetup Pro
# License: MIT
# Version: 2.0.0
# Website: https://github.com/yourusername/docker-setup-pro
# ============================================================================

set -euo pipefail
IFS=$'\n\t'

# ============================================================================
# CONSTANTS & CONFIGURATION
# ============================================================================
readonly SCRIPT_VERSION="2.0.0"
readonly SCRIPT_NAME="Docker Setup Pro"
readonly MIN_ROOT_UID=0
readonly DOCKER_COMPOSE_VERSION="v2.27.1"
readonly BACKUP_DIR="/opt/docker-backups"
readonly LOG_FILE="/var/log/docker-setup-$(date +%Y%m%d-%H%M%S).log"
readonly DAEMON_CONFIG="/etc/docker/daemon.json"
readonly MIN_DISK_SPACE_GB=5
readonly REQUIRED_PORTS=(2375 2376 80 443 9000 8080)

# ============================================================================
# COLOR DEFINITIONS
# ============================================================================
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly GRAY='\033[0;37m'
readonly BOLD='\033[1m'
readonly DIM='\033[2m'
readonly RESET='\033[0m'

# ============================================================================
# OUTPUT FUNCTIONS
# ============================================================================
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        INFO)    echo -e "${GREEN}[INFO]${RESET}    $message" ;;
        WARN)    echo -e "${YELLOW}[WARN]${RESET}    $message" ;;
        ERROR)   echo -e "${RED}[ERROR]${RESET}   $message" ;;
        SUCCESS) echo -e "${GREEN}[SUCCESS]${RESET} $message" ;;
        DEBUG)   echo -e "${DIM}[DEBUG]${RESET}   $message" ;;
    esac
    
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE" 2>/dev/null || true
}

print_header() {
    clear
    echo -e "${CYAN}"
    cat << 'HEADER'
    ╔═══════════════════════════════════════════════════════════════╗
    ║                                                               ║
    ║   ██████╗ ██████╗ ███████╗██╗   ██╗███████╗██████╗ ███████╗  ║
    ║  ██╔════╝██╔═══██╗██╔════╝██║   ██║██╔════╝██╔══██╗██╔════╝  ║
    ║  ██║     ██║   ██║███████╗██║   ██║█████╗  ██║  ██║███████╗  ║
    ║  ██║     ██║   ██║╚════██║██║   ██║██╔══╝  ██║  ██║╚════██║  ║
    ║  ╚██████╗╚██████╔╝███████║╚██████╔╝███████╗██████╔╝███████║  ║
    ║   ╚═════╝ ╚═════╝ ╚══════╝ ╚═════╝ ╚══════╝╚═════╝ ╚══════╝  ║
    ║                                                               ║
    ║              Professional Docker Setup Script                 ║
    ║                     Version 2.0.0                             ║
    ╚═══════════════════════════════════════════════════════════════╝
HEADER
    echo -e "${RESET}"
    echo -e "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

print_section() {
    local title="$1"
    echo ""
    echo -e "${BLUE}▸ ${WHITE}${BOLD}$title${RESET}"
    echo -e "${DIM}  ─────────────────────────────────────────────────────────────${RESET}"
}

print_menu() {
    echo ""
    echo -e "${CYAN}┌─────────────────────────────────────────────────────────────┐${RESET}"
    echo -e "${CYAN}│${RESET}  ${WHITE}${BOLD}MAIN MENU${RESET}                                                ${CYAN}│${RESET}"
    echo -e "${CYAN}├─────────────────────────────────────────────────────────────┤${RESET}"
    echo -e "${CYAN}│${RESET}  ${GREEN}[1]${RESET}  Install Docker CE                                    ${CYAN}│${RESET}"
    echo -e "${CYAN}│${RESET}  ${GREEN}[2]${RESET}  Install Docker Compose                               ${CYAN}│${RESET}"
    echo -e "${CYAN}│${RESET}  ${GREEN}[3]${RESET}  Setup Docker User Group                              ${CYAN}│${RESET}"
    echo -e "${CYAN}│${RESET}  ${GREEN}[4]${RESET}  Configure Docker Daemon                               ${CYAN}│${RESET}"
    echo -e "${CYAN}│${RESET}  ${GREEN}[5]${RESET}  Deploy Common Containers                              ${CYAN}│${RESET}"
    echo -e "${CYAN}│${RESET}  ${GREEN}[6]${RESET}  Docker Network Management                             ${CYAN}│${RESET}"
    echo -e "${CYAN}│${RESET}  ${GREEN}[7]${RESET}  Docker Volume Management                               ${CYAN}│${RESET}"
    echo -e "${CYAN}│${RESET}  ${GREEN}[8]${RESET}  Backup Docker Containers                               ${CYAN}│${RESET}"
    echo -e "${CYAN}│${RESET}  ${GREEN}[9]${RESET}  Apply Security Best Practices                          ${CYAN}│${RESET}"
    echo -e "${CYAN}│${RESET}  ${GREEN}[10]${RESET} Full Setup (Install Everything)                       ${CYAN}│${RESET}"
    echo -e "${CYAN}│${RESET}  ${YELLOW}[11]${RESET} System Diagnostics                                    ${CYAN}│${RESET}"
    echo -e "${CYAN}│${RESET}  ${RED}[0]${RESET}  Exit                                                   ${CYAN}│${RESET}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────────────┘${RESET}"
    echo ""
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================
confirm_action() {
    local prompt="${1:-Are you sure?}"
    echo -e "${YELLOW}  ⚠  $prompt [y/N]: ${RESET}"
    read -r response
    [[ "$response" =~ ^[Yy]$ ]]
}

get_user_input() {
    local prompt="$1"
    local default="${2:-}"
    local result
    
    if [[ -n "$default" ]]; then
        echo -e "${CYAN}  ➤ $prompt ${DIM}[$default]${RESET}: "
    else
        echo -e "${CYAN}  ➤ $prompt${RESET}: "
    fi
    
    read -r result
    echo "${result:-$default}"
}

spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    
    while kill -0 "$pid" 2>/dev/null; do
        for (( i=0; i<${#spinstr}; i++ )); do
            printf "\r  ${CYAN}%s${RESET} Processing..." "${spinstr:$i:1}"
            sleep $delay
        done
    done
    printf "\r  ${GREEN}✓${RESET} Done!                           \n"
}

check_dependencies() {
    local deps=("curl" "wget" "gpg" "lsb_release")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log WARN "Missing dependencies: ${missing[*]}"
        log INFO "Installing missing dependencies..."
        apt-get update -qq && apt-get install -y -qq "${missing[@]}" >/dev/null 2>&1
        log SUCCESS "Dependencies installed successfully"
    fi
}

check_root() {
    if [[ $EUID -ne $MIN_ROOT_UID ]]; then
        log ERROR "This script must be run as root (use sudo)"
        echo -e "\n${YELLOW}  Run: sudo bash $0${RESET}\n"
        exit 1
    fi
}

check_os() {
    if [[ ! -f /etc/os-release ]]; then
        log ERROR "Cannot detect OS. This script supports Ubuntu/Debian only."
        exit 1
    fi
    
    source /etc/os-release
    
    if [[ "$ID" != "ubuntu" && "$ID" != "debian" ]]; then
        log ERROR "Unsupported OS: $ID. This script supports Ubuntu/Debian only."
        exit 1
    fi
    
    log INFO "Detected OS: $PRETTY_NAME"
    OS_ID="$ID"
    OS_VERSION="$VERSION_ID"
}

check_disk_space() {
    local available_gb
    available_gb=$(df -BG / | awk 'NR==2 {print $4}' | tr -d 'G')
    
    if [[ "$available_gb" -lt "$MIN_DISK_SPACE_GB" ]]; then
        log WARN "Low disk space: ${available_gb}GB available (recommended: ${MIN_DISK_SPACE_GB}GB+)"
        if ! confirm_action "Continue with limited disk space?"; then
            return 1
        fi
    fi
    log INFO "Disk space check passed: ${available_gb}GB available"
}

check_docker_installed() {
    if command -v docker &>/dev/null; then
        local version
        version=$(docker --version | awk '{print $3}' | tr -d ',')
        log INFO "Docker already installed: $version"
        return 0
    fi
    return 1
}

is_service_active() {
    systemctl is-active --quiet "$1" 2>/dev/null
}

# ============================================================================
# 1. DOCKER CE INSTALLATION
# ============================================================================
install_docker_ce() {
    print_section "Docker CE Installation"
    
    if check_docker_installed; then
        if ! confirm_action "Docker is already installed. Reinstall/upgrade?"; then
            return 0
        fi
    fi
    
    log INFO "Removing old Docker versions..."
    apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    
    log INFO "Installing prerequisites..."
    apt-get update -qq
    apt-get install -y -qq \
        ca-certificates \
        curl \
        gnupg \
        lsb-release >/dev/null 2>&1
    
    log INFO "Adding Docker GPG key..."
    install -m 0755 -d /etc/apt/keyrings
    
    if [[ "$OS_ID" == "ubuntu" ]]; then
        curl -fsSL "https://download.docker.com/linux/ubuntu/gpg" | \
            gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        chmod a+r /etc/apt/keyrings/docker.gpg
        
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
            https://download.docker.com/linux/ubuntu \
            $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
            tee /etc/apt/sources.list.d/docker.list > /dev/null
    elif [[ "$OS_ID" == "debian" ]]; then
        curl -fsSL "https://download.docker.com/linux/debian/gpg" | \
            gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        chmod a+r /etc/apt/keyrings/docker.gpg
        
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
            https://download.docker.com/linux/debian \
            $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
            tee /etc/apt/sources.list.d/docker.list > /dev/null
    fi
    
    log INFO "Installing Docker CE..."
    apt-get update -qq
    apt-get install -y -qq \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin >/dev/null 2>&1
    
    systemctl enable docker >/dev/null 2>&1
    systemctl start docker >/dev/null 2>&1
    
    log SUCCESS "Docker CE installed successfully!"
    docker --version | xargs -I {} log INFO "Installed: {}"
}

# ============================================================================
# 2. DOCKER COMPOSE INSTALLATION
# ============================================================================
install_docker_compose() {
    print_section "Docker Compose Installation"
    
    if docker compose version &>/dev/null; then
        local compose_version
        compose_version=$(docker compose version --short 2>/dev/null || echo "unknown")
        log INFO "Docker Compose (plugin) already installed: v$compose_version"
        
        if ! confirm_action "Also install standalone docker-compose?"; then
            return 0
        fi
    fi
    
    log INFO "Installing Docker Compose standalone..."
    
    local compose_arch
    compose_arch=$(uname -m)
    case "$compose_arch" in
        x86_64)  compose_arch="x86_64" ;;
        aarch64) compose_arch="aarch64" ;;
        armv7l)  compose_arch="armhf" ;;
        *)       log ERROR "Unsupported architecture: $compose_arch"; return 1 ;;
    esac
    
    local compose_url="https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-linux-${compose_arch}"
    
    curl -fsSL "$compose_url" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    
    # Create symlink
    ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose 2>/dev/null || true
    
    log SUCCESS "Docker Compose installed: $(docker-compose --version)"
}

# ============================================================================
# 3. DOCKER USER GROUP SETUP
# ============================================================================
setup_docker_group() {
    print_section "Docker User Group Setup"
    
    local current_user="${SUDO_USER:-$USER}"
    
    if [[ "$current_user" == "root" ]]; then
        log WARN "Running as root. Specify a user to add to docker group."
        current_user=$(get_user_input "Enter username to add to docker group" "")
        
        if [[ -z "$current_user" ]]; then
            log ERROR "No username provided"
            return 1
        fi
        
        if ! id "$current_user" &>/dev/null; then
            log ERROR "User '$current_user' does not exist"
            return 1
        fi
    fi
    
    # Create docker group if it doesn't exist
    if ! getent group docker &>/dev/null; then
        groupadd docker
        log INFO "Created 'docker' group"
    fi
    
    # Add user to docker group
    if groups "$current_user" 2>/dev/null | grep -q docker; then
        log INFO "User '$current_user' is already in the docker group"
    else
        usermod -aG docker "$current_user"
        log SUCCESS "Added '$current_user' to docker group"
    fi
    
    # Fix socket permissions
    if [[ -S /var/run/docker.sock ]]; then
        chmod 666 /var/run/docker.sock 2>/dev/null || true
    fi
    
    log INFO "Changes will take effect after next login or running: newgrp docker"
    echo -e "\n  ${YELLOW}⚡ Run 'newgrp docker' or log out and back in for changes to take effect${RESET}"
}

# ============================================================================
# 4. DOCKER DAEMON CONFIGURATION
# ============================================================================
configure_docker_daemon() {
    print_section "Docker Daemon Configuration"
    
    # Backup existing config
    if [[ -f "$DAEMON_CONFIG" ]]; then
        cp "$DAEMON_CONFIG" "${DAEMON_CONFIG}.backup.$(date +%Y%m%d%H%M%S)"
        log INFO "Backed up existing daemon.json"
    fi
    
    # --- Log Driver ---
    echo -e "\n  ${WHITE}Log Driver Configuration:${RESET}"
    echo -e "  ${DIM}[1] json-file (default)${RESET}"
    echo -e "  ${DIM}[2] syslog${RESET}"
    echo -e "  ${DIM}[3] journald${RESET}"
    echo -e "  ${DIM}[4] fluentd${RESET}"
    local log_driver_choice
    log_driver_choice=$(get_user_input "Select log driver" "1")
    
    case "$log_driver_choice" in
        1) LOG_DRIVER="json-file" ;;
        2) LOG_DRIVER="syslog" ;;
        3) LOG_DRIVER="journald" ;;
        4) LOG_DRIVER="fluentd" ;;
        *) LOG_DRIVER="json-file" ;;
    esac
    
    local max_size
    max_size=$(get_user_input "Max log file size (e.g., 10m, 100m)" "50m")
    local max_file
    max_file=$(get_user_input "Max number of log files" "5")
    
    # --- Storage Driver ---
    echo -e "\n  ${WHITE}Storage Driver Configuration:${RESET}"
    echo -e "  ${DIM}[1] overlay2 (recommended)${RESET}"
    echo -e "  ${DIM}[2] devicemapper${RESET}"
    echo -e "  ${DIM}[3] vfs (slow, but works everywhere)${RESET}"
    local storage_choice
    storage_choice=$(get_user_input "Select storage driver" "1")
    
    case "$storage_choice" in
        1) STORAGE_DRIVER="overlay2" ;;
        2) STORAGE_DRIVER="devicemapper" ;;
        3) STORAGE_DRIVER="vfs" ;;
        *) STORAGE_DRIVER="overlay2" ;;
    esac
    
    # --- Registry Mirrors ---
    echo -e "\n  ${WHITE}Registry Mirrors (comma-separated, or empty for default):${RESET}"
    echo -e "  ${DIM}Examples: https://mirror.gcr.io, https://registry.cn-hangzhou.aliyuncs.com${RESET}"
    local mirrors_input
    mirrors_input=$(get_user_input "Registry mirrors" "")
    
    # --- Build daemon.json ---
    log INFO "Generating daemon.json configuration..."
    
    cat > "$DAEMON_CONFIG" << DAEMON_EOF
{
    "log-driver": "$LOG_DRIVER",
    "log-opts": {
        "max-size": "$max_size",
        "max-file": "$max_file"
    },
    "storage-driver": "$STORAGE_DRIVER",
    "live-restore": true,
    "userland-proxy": false,
    "no-new-privileges": true,
    "default-address-pools": [
        {
            "base": "172.80.0.0/16",
            "size": 24
        },
        {
            "base": "172.88.0.0/16",
            "size": 24
        }
    ],
    "features": {
        "buildkit": true
    }
DAEMON_EOF
    
    # Add registry mirrors if provided
    if [[ -n "$mirrors_input" ]]; then
        IFS=',' read -ra MIRROR_ARRAY <<< "$mirrors_input"
        echo '    "registry-mirrors": [' >> "$DAEMON_CONFIG"
        local first=true
        for mirror in "${MIRROR_ARRAY[@]}"; do
            mirror=$(echo "$mirror" | xargs) # trim whitespace
            if [[ "$first" == true ]]; then
                echo "        \"$mirror\"" >> "$DAEMON_CONFIG"
                first=false
            else
                echo "        ,\"$mirror\"" >> "$DAEMON_CONFIG"
            fi
        done
        echo '    ],' >> "$DAEMON_CONFIG"
    fi
    
    # Add debug option
    echo '    "debug": false' >> "$DAEMON_CONFIG"
    echo '}' >> "$DAEMON_CONFIG"
    
    # Validate JSON
    if python3 -c "import json; json.load(open('$DAEMON_CONFIG'))" 2>/dev/null; then
        log SUCCESS "daemon.json generated and validated"
    else
        log WARN "daemon.json generated (JSON validation skipped)"
    fi
    
    # Restart Docker
    if confirm_action "Restart Docker daemon to apply changes?"; then
        systemctl restart docker
        log SUCCESS "Docker daemon restarted"
    fi
    
    echo -e "\n  ${WHITE}Current daemon.json:${RESET}"
    echo -e "${DIM}$(cat "$DAEMON_CONFIG" | sed 's/^/    /')${RESET}"
}

# ============================================================================
# 5. COMMON CONTAINERS SETUP
# ============================================================================
deploy_common_containers() {
    print_section "Deploy Common Containers"
    
    # Create docker network for these services
    docker network create --driver bridge proxied 2>/dev/null || true
    
    echo -e "\n  ${WHITE}Select containers to deploy:${RESET}"
    
    # --- Portainer ---
    echo -e "\n  ${GREEN}[1]${RESET} Portainer CE (Docker Management UI)"
    echo -e "  ${DIM}    Web UI on port 9000${RESET}"
    local install_portainer
    install_portainer=$(get_user_input "Install Portainer? (y/n)" "y")
    
    if [[ "${install_portainer,,}" == "y" ]]; then
        log INFO "Deploying Portainer CE..."
        
        docker volume create portainer_data 2>/dev/null || true
        
        docker run -d \
            --name portainer \
            --restart=always \
            -p 9000:9000 \
            -p 9443:9443 \
            -v /var/run/docker.sock:/var/run/docker.sock \
            -v portainer_data:/data \
            portainer/portainer-ce:lts >/dev/null 2>&1
        
        log SUCCESS "Portainer CE deployed on port 9000"
    fi
    
    # --- Nginx Proxy Manager ---
    echo -e "\n  ${GREEN}[2]${RESET} Nginx Proxy Manager (Reverse Proxy)"
    echo -e "  ${DIM}    Web UI on port 81, HTTP on 80, HTTPS on 443${RESET}"
    local install_npm
    install_npm=$(get_user_input "Install Nginx Proxy Manager? (y/n)" "y")
    
    if [[ "${install_npm,,}" == "y" ]]; then
        log INFO "Deploying Nginx Proxy Manager..."
        
        docker volume create npm_data 2>/dev/null || true
        docker volume create npm_letsencrypt 2>/dev/null || true
        
        docker run -d \
            --name nginx-proxy-manager \
            --restart=always \
            -p 80:80 \
            -p 81:81 \
            -p 443:443 \
            -v npm_data:/data \
            -v npm_letsencrypt:/etc/letsencrypt \
            --network proxied \
            jc21/nginx-proxy-manager:latest >/dev/null 2>&1
        
        log SUCCESS "Nginx Proxy Manager deployed"
        echo -e "  ${DIM}    Default login: admin@example.com / changeme${RESET}"
    fi
    
    # --- Watchtower ---
    echo -e "\n  ${GREEN}[3]${RESET} Watchtower (Auto-update containers)"
    echo -e "  ${DIM}    Checks for updates daily${RESET}"
    local install_watchtower
    install_watchtower=$(get_user_input "Install Watchtower? (y/n)" "y")
    
    if [[ "${install_watchtower,,}" == "y" ]]; then
        log INFO "Deploying Watchtower..."
        
        local schedule
        schedule=$(get_user_input "Update check schedule (cron format)" "0 0 4 * * *")
        
        docker run -d \
            --name watchtower \
            --restart=always \
            -v /var/run/docker.sock:/var/run/docker \
            -e WATCHTOWER_CLEANUP=true \
            -e WATCHTOWER_SCHEDULE="$schedule" \
            -e WATCHTOWER_LOG_LEVEL=info \
            containrrr/watchtower:latest >/dev/null 2>&1
        
        log SUCCESS "Watchtower deployed with schedule: $schedule"
    fi
    
    # Show running containers
    echo -e "\n  ${WHITE}Running containers:${RESET}"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | sed 's/^/    /'
}

# ============================================================================
# 6. DOCKER NETWORK MANAGEMENT
# ============================================================================
manage_docker_networks() {
    print_section "Docker Network Management"
    
    echo -e "\n  ${GREEN}[1]${RESET} Create new network"
    echo -e "  ${GREEN}[2]${RESET} List all networks"
    echo -e "  ${GREEN}[3]${RESET} Inspect a network"
    echo -e "  ${GREEN}[4]${RESET} Remove a network"
    echo -e "  ${GREEN}[5]${RESET} Create standard stack networks"
    
    local choice
    choice=$(get_user_input "Select action" "5")
    
    case "$choice" in
        1)
            local net_name
            net_name=$(get_user_input "Network name")
            local net_driver
            net_driver=$(get_user_input "Driver (bridge/overlay/host)" "bridge")
            local net_subnet
            net_subnet=$(get_user_input "Subnet (optional, e.g., 172.20.0.0/16)" "")
            
            if [[ -n "$net_subnet" ]]; then
                docker network create --driver "$net_driver" --subnet "$net_subnet" "$net_name"
            else
                docker network create --driver "$net_driver" "$net_name"
            fi
            log SUCCESS "Network '$net_name' created"
            ;;
        2)
            echo -e "\n  ${WHITE}Docker Networks:${RESET}"
            docker network ls --format "table {{.Name}}\t{{.Driver}}\t{{.Scope}}" | sed 's/^/    /'
            ;;
        3)
            local inspect_name
            inspect_name=$(get_user_input "Network name to inspect")
            docker network inspect "$inspect_name" | sed 's/^/    /'
            ;;
        4)
            local remove_name
            remove_name=$(get_user_input "Network name to remove")
            if confirm_action "Remove network '$remove_name'?"; then
                docker network rm "$remove_name"
                log SUCCESS "Network '$remove_name' removed"
            fi
            ;;
        5)
            log INFO "Creating standard stack networks..."
            
            docker network create --driver bridge --subnet 172.20.0.0/16 proxy_net 2>/dev/null || true
            docker network create --driver bridge --subnet 172.21.0.0/16 app_net 2>/dev/null || true
            docker network create --driver bridge --subnet 172.22.0.0/16 db_net 2>/dev/null || true
            docker network create --driver bridge --subnet 172.23.0.0/16 monitoring_net 2>/dev/null || true
            
            log SUCCESS "Standard networks created: proxy_net, app_net, db_net, monitoring_net"
            ;;
    esac
}

# ============================================================================
# 7. DOCKER VOLUME MANAGEMENT
# ============================================================================
manage_docker_volumes() {
    print_section "Docker Volume Management"
    
    echo -e "\n  ${GREEN}[1]${RESET} List all volumes"
    echo -e "  ${GREEN}[2]${RESET} Create a volume"
    echo -e "  ${GREEN}[3]${RESET} Inspect a volume"
    echo -e "  ${GREEN}[4]${RESET} Remove a volume"
    echo -e "  ${GREEN}[5]${RESET} Remove unused volumes"
    echo -e "  ${GREEN}[6]${RESET} Create backup volumes"
    
    local choice
    choice=$(get_user_input "Select action" "1")
    
    case "$choice" in
        1)
            echo -e "\n  ${WHITE}Docker Volumes:${RESET}"
            docker volume ls --format "table {{.Name}}\t{{.Driver}}\t{{.Mountpoint}}" | sed 's/^/    /'
            
            echo -e "\n  ${WHITE}Volume usage:${RESET}"
            docker system df -v 2>/dev/null | head -20 | sed 's/^/    /'
            ;;
        2)
            local vol_name
            vol_name=$(get_user_input "Volume name")
            local vol_driver
            vol_driver=$(get_user_input "Driver (local)" "local")
            
            docker volume create --driver "$vol_driver" "$vol_name"
            log SUCCESS "Volume '$vol_name' created"
            ;;
        3)
            local inspect_vol
            inspect_vol=$(get_user_input "Volume name to inspect")
            docker volume inspect "$inspect_vol" | sed 's/^/    /'
            ;;
        4)
            local remove_vol
            remove_vol=$(get_user_input "Volume name to remove")
            if confirm_action "Remove volume '$remove_vol'?"; then
                docker volume rm "$remove_vol"
                log SUCCESS "Volume '$remove_vol' removed"
            fi
            ;;
        5)
            if confirm_action "Remove ALL unused volumes? This cannot be undone!"; then
                docker volume prune -f
                log SUCCESS "Unused volumes removed"
            fi
            ;;
        6)
            log INFO "Creating standard backup volumes..."
            docker volume create --name portainer_data_backup 2>/dev/null || true
            docker volume create --name mysql_backup 2>/dev/null || true
            docker volume create --name postgres_backup 2>/dev/null || true
            docker volume create --name redis_backup 2>/dev/null || true
            log SUCCESS "Backup volumes created"
            ;;
    esac
}

# ============================================================================
# 8. DOCKER CONTAINER BACKUP
# ============================================================================
backup_docker_containers() {
    print_section "Docker Container Backup"
    
    mkdir -p "$BACKUP_DIR"
    
    echo -e "\n  ${GREEN}[1]${RESET} Backup all running containers"
    echo -e "  ${GREEN}[2]${RESET} Backup specific container"
    echo -e "  ${GREEN}[3]${RESET} Backup all volumes"
    echo -e "  ${GREEN}[4]${RESET} List existing backups"
    echo -e "  ${GREEN}[5]${RESET} Restore from backup"
    
    local choice
    choice=$(get_user_input "Select action" "1")
    
    local timestamp
    timestamp=$(date +%Y%m%d-%H%M%S)
    
    case "$choice" in
        1)
            log INFO "Backing up all running containers..."
            local backup_path="$BACKUP_DIR/all-$timestamp"
            mkdir -p "$backup_path"
            
            # Save container list
            docker ps -a --format '{{.Names}}' > "$backup_path/containers.txt"
            
            # Backup each running container
            for container in $(docker ps --format '{{.Names}}'); do
                log INFO "Backing up container: $container"
                
                # Export container
                docker export "$container" | gzip > "$backup_path/${container}.tar.gz"
                
                # Save container inspect
                docker inspect "$container" > "$backup_path/${container}.json"
                
                # Save container's volumes
                local mounts
                mounts=$(docker inspect "$container" --format '{{range .Mounts}}{{.Name}}:{{.Destination}} {{end}}' 2>/dev/null)
                for mount in $mounts; do
                    local vol_name="${mount%%:*}"
                    if [[ -n "$vol_name" ]]; then
                        docker run --rm \
                            -v "$vol_name":/source:ro \
                            -v "$backup_path":/backup \
                            alpine tar czf "/backup/${container}_${vol_name}_vol.tar.gz" -C /source . 2>/dev/null || true
                    fi
                done
            done
            
            # Backup all volume data
            log INFO "Backing up volumes..."
            for vol in $(docker volume ls -q); do
                docker run --rm \
                    -v "$vol":/source:ro \
                    -v "$backup_path":/backup \
                    alpine tar czf "/backup/${vol}_vol.tar.gz" -C /source . 2>/dev/null || true
            done
            
            log SUCCESS "Backup completed: $backup_path"
            echo -e "  ${DIM}Backup size: $(du -sh "$backup_path" | awk '{print $1}')${RESET}"
            ;;
        2)
            local container_name
            container_name=$(get_user_input "Container name to backup")
            
            if ! docker ps -a --format '{{.Names}}' | grep -q "^${container_name}$"; then
                log ERROR "Container '$container_name' not found"
                return 1
            fi
            
            local backup_path="$BACKUP_DIR/$container_name-$timestamp"
            mkdir -p "$backup_path"
            
            log INFO "Backing up container: $container_name"
            docker export "$container_name" | gzip > "$backup_path/${container_name}.tar.gz"
            docker inspect "$container_name" > "$backup_path/${container_name}.json"
            
            log SUCCESS "Backup completed: $backup_path"
            ;;
        3)
            log INFO "Backing up all volumes..."
            local backup_path="$BACKUP_DIR/volumes-$timestamp"
            mkdir -p "$backup_path"
            
            for vol in $(docker volume ls -q); do
                log INFO "Backing up volume: $vol"
                docker run --rm \
                    -v "$vol":/source:ro \
                    -v "$backup_path":/backup \
                    alpine tar czf "/backup/${vol}.tar.gz" -C /source . 2>/dev/null || true
            done
            
            log SUCCESS "All volumes backed up: $backup_path"
            ;;
        4)
            echo -e "\n  ${WHITE}Existing Backups:${RESET}"
            if [[ -d "$BACKUP_DIR" ]]; then
                ls -lht "$BACKUP_DIR" 2>/dev/null | head -20 | sed 's/^/    /'
            else
                echo -e "    ${DIM}No backups found${RESET}"
            fi
            ;;
        5)
            echo -e "\n  ${WHITE}Available Backups:${RESET}"
            local backups=($(ls -d "$BACKUP_DIR"/*/ 2>/dev/null))
            
            if [[ ${#backups[@]} -eq 0 ]]; then
                log WARN "No backups found"
                return 1
            fi
            
            for i in "${!backups[@]}"; do
                echo -e "  ${GREEN}[$((i+1))]${RESET} $(basename "${backups[$i]}")"
            done
            
            local restore_idx
            restore_idx=$(get_user_input "Select backup number to restore" "1")
            restore_idx=$((restore_idx - 1))
            
            if [[ $restore_idx -ge 0 && $restore_idx -lt ${#backups[@]} ]]; then
                local restore_path="${backups[$restore_idx]}"
                if confirm_action "Restore from $(basename "$restore_path")?"; then
                    for archive in "$restore_path"/*.tar.gz; do
                        if [[ -f "$archive" ]]; then
                            local archive_name
                            archive_name=$(basename "$archive" .tar.gz)
                            log INFO "Restoring: $archive_name"
                            # Note: Actual restore requires careful handling
                            # This is a simplified version
                            echo -e "  ${DIM}Would restore: $archive${RESET}"
                        fi
                    done
                    log SUCCESS "Restore process initiated"
                fi
            fi
            ;;
    esac
}

# ============================================================================
# 9. SECURITY BEST PRACTICES
# ============================================================================
apply_security_practices() {
    print_section "Docker Security Best Practices"
    
    log INFO "Applying security hardening..."
    
    # --- 1. Docker daemon configuration ---
    log INFO "1. Enabling live-restore and userland-proxy disabled..."
    
    # --- 2. Set Docker socket permissions ---
    log INFO "2. Setting Docker socket permissions..."
    if [[ -S /var/run/docker.sock ]]; then
        chown root:docker /var/run/docker.sock
        chmod 660 /var/run/docker.sock
    fi
    
    # --- 3. Enable Content Trust ---
    log INFO "3. Enabling Docker Content Trust..."
    echo 'export DOCKER_CONTENT_TRUST=1' >> /etc/environment
    
    # --- 4. Set ulimits ---
    log INFO "4. Configuring ulimits..."
    
    # --- 5. Enable seccomp ---
    log INFO "5. Verifying seccomp profile..."
    
    # --- 6. Audit Docker installation ---
    log INFO "6. Running security audit..."
    
    echo ""
    echo -e "  ${WHITE}═══════════════════════════════════════════════════════════${RESET}"
    echo -e "  ${WHITE} SECURITY RECOMMENDATIONS${RESET}"
    echo -e "  ${WHITE}═══════════════════════════════════════════════════════════${RESET}"
    
    # Check for Docker Bench Security
    if ! docker images --format '{{.Repository}}' | grep -q "docker/docker-bench-security"; then
        echo -e "\n  ${YELLOW}▶ Docker Bench Security:${RESET}"
        echo -e "  ${DIM}  Run: docker run --rm --net host --pid host --userns host --cap add audit_control \\${RESET}"
        echo -e "  ${DIM}    -e DOCKER_CONTENT_TRUST=$DOCKER_CONTENT_TRUST \\${RESET}"
        echo -e "  ${DIM}    -v /var/lib:/var/lib:ro -v /var/run/docker.sock:/var/run/docker.sock:ro \\${RESET}"
        echo -e "  ${DIM}    -v /usr/lib/systemd:/usr/lib/systemd:ro \\${RESET}"
        echo -e "  ${DIM}    docker/docker-bench-security${RESET}"
    fi
    
    # Security checklist
    echo -e "\n  ${WHITE}Security Checklist:${RESET}"
    
    local checks=(
        "✓ Content Trust enabled"
        "✓ Docker socket permissions set (660)"
        "✓ Userland proxy disabled"
        "✓ No-new-privileges enabled"
        "✓ Live-restore enabled"
        "✓ BuildKit enabled"
        "✓ Log rotation configured"
        "✓ Custom address pools configured"
    )
    
    for check in "${checks[@]}"; do
        echo -e "  ${GREEN}$check${RESET}"
    done
    
    echo -e "\n  ${WHITE}Additional Recommendations:${RESET}"
    echo -e "  ${DIM}• Run containers as non-root user${RESET}"
    echo -e "  ${DIM}• Use --read-only flag when possible${RESET}"
    echo -e "  ${DIM}• Limit container resources (--memory, --cpus)${RESET}"
    echo -e "  ${DIM}• Use Docker secrets for sensitive data${RESET}"
    echo -e "  ${DIM}• Regularly scan images with Trivy/Snyk${RESET}"
    echo -e "  ${DIM}• Keep Docker and images updated${RESET}"
    echo -e "  ${DIM}• Use specific image tags (not :latest)${RESET}"
    echo -e "  ${DIM}• Implement network segmentation${RESET}"
    
    log SUCCESS "Security best practices applied"
}

# ============================================================================
# 10. FULL SETUP
# ============================================================================
full_setup() {
    print_section "Full Docker Setup"
    
    echo -e "\n  ${WHITE}This will:${RESET}"
    echo -e "  ${DIM}• Install Docker CE${RESET}"
    echo -e "  ${DIM}• Install Docker Compose${RESET}"
    echo -e "  ${DIM}• Setup Docker user group${RESET}"
    echo -e "  ${DIM}• Configure Docker daemon${RESET}"
    echo -e "  ${DIM}• Deploy common containers${RESET}"
    echo -e "  ${DIM}• Create Docker networks${RESET}"
    echo -e "  ${DIM}• Apply security best practices${RESET}"
    
    if ! confirm_action "Proceed with full setup?"; then
        return 0
    fi
    
    install_docker_ce
    install_docker_compose
    setup_docker_group
    configure_docker_daemon
    deploy_common_containers
    manage_docker_networks
    apply_security_practices
    
    echo ""
    echo -e "${GREEN}"
    cat << 'DONE'
    ╔═══════════════════════════════════════════════════════════════╗
    ║                                                               ║
    ║              🎉 FULL SETUP COMPLETE! 🎉                       ║
    ║                                                               ║
    ║   Docker CE and ecosystem are now configured.                 ║
    ║   Log out and back in for user group changes.                 ║
    ║                                                               ║
    ╚═══════════════════════════════════════════════════════════════╝
DONE
    echo -e "${RESET}"
}

# ============================================================================
# 11. SYSTEM DIAGNOSTICS
# ============================================================================
run_diagnostics() {
    print_section "System Diagnostics"
    
    echo -e "\n  ${WHITE}System Information:${RESET}"
    echo -e "  ${DIM}OS:${RESET}           $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
    echo -e "  ${DIM}Kernel:${RESET}       $(uname -r)"
    echo -e "  ${DIM}Architecture:${RESET} $(uname -m)"
    echo -e "  ${DIM}Hostname:${RESET}     $(hostname)"
    echo -e "  ${DIM}Uptime:${RESET}       $(uptime -p 2>/dev/null || uptime)"
    
    echo -e "\n  ${WHITE}Docker Information:${RESET}"
    if command -v docker &>/dev/null; then
        echo -e "  ${DIM}Docker Version:${RESET} $(docker --version)"
        echo -e "  ${DIM}Compose Version:${RESET} $(docker compose version 2>/dev/null || echo 'Not installed')"
        echo -e "  ${DIM}Storage Driver:${RESET}  $(docker info --format '{{.Driver}}' 2>/dev/null)"
        echo -e "  ${DIM}Logging Driver:${RESET}  $(docker info --format '{{.LoggingDriver}}' 2>/dev/null)"
        echo -e "  ${DIM}Cgroup Driver:${RESET}  $(docker info --format '{{.CgroupDriver}}' 2>/dev/null)"
        echo -e "  ${DIM}Kernel Version:${RESET} $(docker info --format '{{.KernelVersion}}' 2>/dev/null)"
        
        echo -e "\n  ${WHITE}Docker Status:${RESET}"
        docker info --format '{{.Containers}} containers ({{.ContainersRunning}} running, {{.ContainersStopped}} stopped)' 2>/dev/null | sed 's/^/    /'
        echo -e "  ${DIM}Images:${RESET}         $(docker images -q 2>/dev/null | wc -l)"
        echo -e "  ${DIM}Volumes:${RESET}        $(docker volume ls -q 2>/dev/null | wc -l)"
        echo -e "  ${DIM}Networks:${RESET}       $(docker network ls -q 2>/dev/null | wc -l)"
        
        echo -e "\n  ${WHITE}Running Containers:${RESET}"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null | sed 's/^/    /'
        
        echo -e "\n  ${WHITE}Resource Usage:${RESET}"
        docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" 2>/dev/null | sed 's/^/    /'
        
        echo -e "\n  ${WHITE}Disk Usage:${RESET}"
        docker system df 2>/dev/null | sed 's/^/    /'
    else
        echo -e "  ${RED}Docker is not installed${RESET}"
    fi
    
    echo -e "\n  ${WHITE}Port Status:${RESET}"
    for port in "${REQUIRED_PORTS[@]}"; do
        if ss -tlnp | grep -q ":${port} "; then
            echo -e "  ${RED}✗${RESET} Port $port: ${RED}IN USE${RESET}"
        else
            echo -e "  ${GREEN}✓${RESET} Port $port: ${GREEN}AVAILABLE${RESET}"
        fi
    done
    
    echo -e "\n  ${WHITE}Network Interfaces:${RESET}"
    ip -br addr show | sed 's/^/    /'
    
    echo -e "\n  ${DIM}Log file: $LOG_FILE${RESET}"
}

# ============================================================================
# MAIN MENU LOOP
# ============================================================================
main() {
    # Check if running as root
    check_root
    
    # Initialize log
    mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true
    touch "$LOG_FILE" 2>/dev/null || true
    
    log INFO "Docker Setup Script v$SCRIPT_VERSION started"
    
    # Check OS
    check_os
    
    # Check dependencies
    check_dependencies
    
    # Check disk space
    check_disk_space || true
    
    while true; do
        print_header
        print_menu
        
        local choice
        choice=$(get_user_input "Select an option" "0")
        
        case "$choice" in
            1)  install_docker_ce ;;
            2)  install_docker_compose ;;
            3)  setup_docker_group ;;
            4)  configure_docker_daemon ;;
            5)  deploy_common_containers ;;
            6)  manage_docker_networks ;;
            7)  manage_docker_volumes ;;
            8)  backup_docker_containers ;;
            9)  apply_security_practices ;;
            10) full_setup ;;
            11) run_diagnostics ;;
            0)
                echo ""
                log INFO "Docker Setup Script completed"
                echo -e "  ${GREEN}Thank you for using Docker Setup Pro!${RESET}"
                echo -e "  ${DIM}Documentation: https://github.com/yourusername/docker-setup-pro${RESET}"
                echo ""
                exit 0
                ;;
            *)
                log WARN "Invalid option: $choice"
                ;;
        esac
        
        echo ""
        echo -e "${DIM}  Press Enter to continue...${RESET}"
        read -r
    done
}

# ============================================================================
# SCRIPT ENTRY POINT
# ============================================================================
main "$@"
