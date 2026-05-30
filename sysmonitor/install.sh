#!/bin/bash
#============================================================
# System Monitor Dashboard v1.0
# Real-time system monitoring with alerts & HTML reports
# Compatible with Ubuntu/Debian/Mint/Xubuntu/Lubuntu
#============================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'
BOLD='\033[1m'

# Icons
CHECK="${GREEN}✓${NC}"
CROSS="${RED}✗${NC}"
WARN="${YELLOW}⚠${NC}"
INFO="${CYAN}ℹ${NC}"

# Config
LOG_DIR="/var/log/sysmonitor"
DATA_DIR="/var/lib/sysmonitor"
ALERT_LOG="$LOG_DIR/alerts.log"
HISTORY_FILE="$DATA_DIR/history.csv"

#============================================================
# Helper Functions
#============================================================
print_header() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║              System Monitor Dashboard v1.0                 ║"
    echo "║              Real-time Monitoring & Alerts                 ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_section() {
    echo -e "\n${BLUE}[$1]${NC} ${WHITE}$2${NC}"
    echo "────────────────────────────────────────────────────────────────"
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}Please run as root: sudo bash $0${NC}"
        exit 1
    fi
}

setup_dirs() {
    mkdir -p "$LOG_DIR" "$DATA_DIR"
    chmod 755 "$LOG_DIR" "$DATA_DIR"
}

timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

#============================================================
# Monitoring Functions
#============================================================

cpu_monitor() {
    print_section "1" "CPU Monitor"
    
    local cores=$(nproc)
    local usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'.' -f1)
    local load=$(cat /proc/loadavg | awk '{print $1, $2, $3}')
    local temp=""
    
    if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
        temp=$(cat /sys/class/thermal/thermal_zone0/temp)
        temp=$(echo "scale=1; $temp/1000" | bc)
    fi
    
    echo -e "${INFO} Cores: ${GREEN}$cores${NC}"
    echo -e "${INFO} Usage: ${GREEN}${usage}%${NC}"
    echo -e "${INFO} Load: ${GREEN}$load${NC}"
    [ -n "$temp" ] && echo -e "${INFO} Temp: ${GREEN}${temp}°C${NC}"
    
    # Color code usage
    if [ "$usage" -gt 80 ]; then
        echo -e "${WARN} ${RED}CPU usage is HIGH!${NC}"
    elif [ "$usage" -gt 60 ]; then
        echo -e "${WARN} ${YELLOW}CPU usage is moderate${NC}"
    else
        echo -e "${CHECK} ${GREEN}CPU usage is normal${NC}"
    fi
}

ram_monitor() {
    print_section "2" "Memory Monitor"
    
    local total=$(free -m | awk '/^Mem:/{print $2}')
    local used=$(free -m | awk '/^Mem:/{print $3}')
    local free=$(free -m | awk '/^Mem:/{print $4}')
    local available=$(free -m | awk '/^Mem:/{print $7}')
    local swap_total=$(free -m | awk '/^Swap:/{print $2}')
    local swap_used=$(free -m | awk '/^Swap:/{print $3}')
    
    local usage_pct=$((used * 100 / total))
    
    echo -e "${INFO} Total: ${GREEN}${total}MB${NC}"
    echo -e "${INFO} Used: ${GREEN}${used}MB${NC}"
    echo -e "${INFO} Free: ${GREEN}${free}MB${NC}"
    echo -e "${INFO} Available: ${GREEN}${available}MB${NC}"
    echo -e "${INFO} Swap: ${GREEN}${swap_used}MB / ${swap_total}MB${NC}"
    
    # Visual bar
    local bar=""
    local filled=$((usage_pct / 5))
    for ((i=0; i<20; i++)); do
        if [ $i -lt $filled ]; then
            bar="${bar}█"
        else
            bar="${bar}░"
        fi
    done
    
    if [ "$usage_pct" -gt 80 ]; then
        echo -e "${WARN} Usage: [${RED}${bar}${NC}] ${RED}${usage_pct}%${NC}"
    elif [ "$usage_pct" -gt 60 ]; then
        echo -e "${INFO} Usage: [${YELLOW}${bar}${NC}] ${YELLOW}${usage_pct}%${NC}"
    else
        echo -e "${CHECK} Usage: [${GREEN}${bar}${NC}] ${GREEN}${usage_pct}%${NC}"
    fi
}

disk_monitor() {
    print_section "3" "Disk Monitor"
    
    echo -e "${BOLD}Filesystem      Size  Used  Avail  Use%  Mount${NC}"
    df -h / | tail -1 | awk '{
        printf "%-15s %-5s %-5s %-5s %-5s %s\n", $1, $2, $3, $4, $5, $6
    }'
    echo ""
    
    # Disk I/O
    if command -v iostat &> /dev/null; then
        echo -e "${BOLD}Disk I/O:${NC}"
        iostat -d 1 1 | tail -n +4 | head -5
    fi
    
    # Inode usage
    local inode_usage=$(df -i / | tail -1 | awk '{print $5}' | cut -d'%' -f1)
    echo -e "${INFO} Inode usage: ${GREEN}${inode_usage}%${NC}"
}

network_monitor() {
    print_section "4" "Network Monitor"
    
    # Interfaces
    echo -e "${BOLD}Active Interfaces:${NC}"
    ip -br addr show | grep -v "lo" | while read line; do
        echo -e "  ${GREEN}$line${NC}"
    done
    echo ""
    
    # Bandwidth
    echo -e "${BOLD}Bandwidth (1s sample):${NC}"
    if command -v ifstat &> /dev/null; then
        ifstat -i eth0 1 1 2>/dev/null || echo "  No traffic detected"
    else
        # Fallback: use /proc/net/dev
        local rx1=$(cat /proc/net/dev | grep -E "eth0|wlan0" | awk '{print $2}' | head -1)
        local tx1=$(cat /proc/net/dev | grep -E "eth0|wlan0" | awk '{print $10}' | head -1)
        sleep 1
        local rx2=$(cat /proc/net/dev | grep -E "eth0|wlan0" | awk '{print $2}' | head -1)
        local tx2=$(cat /proc/net/dev | grep -E "eth0|wlan0" | awk '{print $10}' | head -1)
        
        if [ -n "$rx1" ] && [ -n "$rx2" ]; then
            local rx_diff=$(( (rx2 - rx1) / 1024 ))
            local tx_diff=$(( (tx2 - tx1) / 1024 ))
            echo -e "  RX: ${GREEN}${rx_diff} KB/s${NC}  TX: ${GREEN}${tx_diff} KB/s${NC}"
        fi
    fi
    echo ""
    
    # Connections
    echo -e "${BOLD}Active Connections:${NC}"
    ss -tunap | head -10
}

process_monitor() {
    print_section "5" "Process Monitor"
    
    echo -e "${BOLD}Top 10 CPU Consumers:${NC}"
    ps aux --sort=-%cpu | head -11 | tail -10 | awk '{printf "%-8s %-6s %-6s %s\n", $1, $3, $4, $11}'
    echo ""
    
    echo -e "${BOLD}Top 10 RAM Consumers:${NC}"
    ps aux --sort=-%mem | head -11 | tail -10 | awk '{printf "%-8s %-6s %-6s %s\n", $1, $4, $3, $11}'
    echo ""
    
    # Process count
    local total=$(ps aux | wc -l)
    local running=$(ps aux | grep -c "[R]")
    echo -e "${INFO} Total: ${GREEN}$total${NC}  Running: ${GREEN}$running${NC}"
}

service_monitor() {
    print_section "6" "Service Status"
    
    local services=(
        "nginx"
        "apache2"
        "mysql"
        "mariadb"
        "postgresql"
        "docker"
        "ssh"
        "NetworkManager"
        "bluetooth"
        "tailscaled"
        "hermes-agent"
    )
    
    for service in "${services[@]}"; do
        local status=$(systemctl is-active "$service" 2>/dev/null || echo "inactive")
        if [ "$status" = "active" ]; then
            echo -e "  ${CHECK} ${GREEN}$service${NC} — active"
        elif [ "$status" = "inactive" ]; then
            echo -e "  ${INFO} ${YELLOW}$service${NC} — inactive"
        else
            echo -e "  ${CROSS} ${RED}$service${NC} — $status"
        fi
    done
}

log_viewer() {
    print_section "7" "Log Viewer"
    
    echo -e "${BOLD}Recent System Logs:${NC}"
    journalctl --no-pager -n 15 --priority=warning 2>/dev/null || echo "  No warning logs"
    echo ""
    
    echo -e "${BOLD}Recent Auth Logs:${NC}"
    tail -5 /var/log/auth.log 2>/dev/null || echo "  No auth logs"
}

alert_check() {
    print_section "8" "Alert Check"
    
    local alerts=()
    
    # CPU alert
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'.' -f1)
    if [ "$cpu_usage" -gt 90 ]; then
        alerts+=("CRITICAL: CPU usage is ${cpu_usage}%")
    elif [ "$cpu_usage" -gt 80 ]; then
        alerts+=("WARNING: CPU usage is ${cpu_usage}%")
    fi
    
    # RAM alert
    local ram_usage=$(free | awk '/^Mem:/{printf "%.0f", $3/$2 * 100}')
    if [ "$ram_usage" -gt 90 ]; then
        alerts+=("CRITICAL: RAM usage is ${ram_usage}%")
    elif [ "$ram_usage" -gt 80 ]; then
        alerts+=("WARNING: RAM usage is ${ram_usage}%")
    fi
    
    # Disk alert
    local disk_usage=$(df / | tail -1 | awk '{print $5}' | cut -d'%' -f1)
    if [ "$disk_usage" -gt 90 ]; then
        alerts+=("CRITICAL: Disk usage is ${disk_usage}%")
    elif [ "$disk_usage" -gt 80 ]; then
        alerts+=("WARNING: Disk usage is ${disk_usage}%")
    fi
    
    # Display alerts
    if [ ${#alerts[@]} -eq 0 ]; then
        echo -e "${CHECK} ${GREEN}No alerts — system healthy${NC}"
    else
        for alert in "${alerts[@]}"; do
            if [[ $alert == *"CRITICAL"* ]]; then
                echo -e "${CROSS} ${RED}$alert${NC}"
            else
                echo -e "${WARN} ${YELLOW}$alert${NC}"
            fi
            echo "$(timestamp) $alert" >> "$ALERT_LOG"
        done
    fi
}

save_history() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local cpu=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'.' -f1)
    local ram=$(free | awk '/^Mem:/{printf "%.0f", $3/$2 * 100}')
    local disk=$(df / | tail -1 | awk '{print $5}' | cut -d'%' -f1)
    
    echo "$timestamp,$cpu,$ram,$disk" >> "$HISTORY_FILE"
}

export_html() {
    print_section "9" "Export HTML Report"
    
    local report="$LOG_DIR/report-$(date +%Y%m%d-%H%M%S).html"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local hostname=$(hostname)
    local uptime=$(uptime -p)
    local cpu=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}')
    local ram_total=$(free -h | awk '/^Mem:/{print $2}')
    local ram_used=$(free -h | awk '/^Mem:/{print $3}')
    local disk_used=$(df -h / | tail -1 | awk '{print $3}')
    local disk_total=$(df -h / | tail -1 | awk '{print $2}')
    
    cat > "$report" << HTMLEOF
<!DOCTYPE html>
<html>
<head>
    <title>System Report - $hostname</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #333; border-bottom: 2px solid #007bff; padding-bottom: 10px; }
        h2 { color: #555; margin-top: 20px; }
        .stat { display: flex; justify-content: space-between; padding: 10px; border-bottom: 1px solid #eee; }
        .stat-label { color: #666; }
        .stat-value { font-weight: bold; color: #333; }
        .good { color: #28a745; }
        .warning { color: #ffc107; }
        .danger { color: #dc3545; }
        .footer { margin-top: 30px; text-align: center; color: #999; font-size: 12px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🖥️ System Report</h1>
        <p><strong>Hostname:</strong> $hostname</p>
        <p><strong>Generated:</strong> $timestamp</p>
        <p><strong>Uptime:</strong> $uptime</p>
        
        <h2>📊 Resource Usage</h2>
        <div class="stat">
            <span class="stat-label">CPU Usage</span>
            <span class="stat-value">${cpu}%</span>
        </div>
        <div class="stat">
            <span class="stat-label">RAM Usage</span>
            <span class="stat-value">$ram_used / $ram_total</span>
        </div>
        <div class="stat">
            <span class="stat-label">Disk Usage</span>
            <span class="stat-value">$disk_used / $disk_total</span>
        </div>
        
        <h2>🔧 System Info</h2>
        <div class="stat">
            <span class="stat-label">Kernel</span>
            <span class="stat-value">$(uname -r)</span>
        </div>
        <div class="stat">
            <span class="stat-label">OS</span>
            <span class="stat-value">$(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)</span>
        </div>
        
        <div class="footer">
            <p>Generated by System Monitor Dashboard v1.0</p>
        </div>
    </div>
</body>
</html>
HTMLEOF
    
    echo -e "${CHECK} Report saved: ${GREEN}$report${NC}"
}

#============================================================
# Continuous Monitor
#============================================================
continuous_monitor() {
    print_section "C" "Continuous Monitor (Press Ctrl+C to stop)"
    
    while true; do
        clear
        echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║              System Monitor — $(date '+%Y-%m-%d %H:%M:%S')              ║${NC}"
        echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
        
        cpu_monitor
        echo ""
        ram_monitor
        echo ""
        disk_monitor
        echo ""
        
        save_history
        sleep 3
    done
}

#============================================================
# Main Menu
#============================================================
main() {
    print_header
    check_root
    setup_dirs
    
    while true; do
        echo ""
        echo -e "${BOLD}Main Menu:${NC}"
        echo "────────────────────────────────────────────────────────────────"
        echo -e "  ${CYAN}1${NC}) CPU Monitor"
        echo -e "  ${CYAN}2${NC}) Memory Monitor"
        echo -e "  ${CYAN}3${NC}) Disk Monitor"
        echo -e "  ${CYAN}4${NC}) Network Monitor"
        echo -e "  ${CYAN}5${NC}) Process Monitor"
        echo -e "  ${CYAN}6${NC}) Service Status"
        echo -e "  ${CYAN}7${NC}) Log Viewer"
        echo -e "  ${CYAN}8${NC}) Alert Check"
        echo -e "  ${CYAN}9${NC}) Export HTML Report"
        echo -e "  ${CYAN}C${NC}) Continuous Monitor"
        echo -e "  ${CYAN}0${NC}) Exit"
        echo ""
        
        read -p "Select option: " choice
        
        case $choice in
            1) cpu_monitor ;;
            2) ram_monitor ;;
            3) disk_monitor ;;
            4) network_monitor ;;
            5) process_monitor ;;
            6) service_monitor ;;
            7) log_viewer ;;
            8) alert_check ;;
            9) export_html ;;
            c|C) continuous_monitor ;;
            0) 
                echo -e "${GREEN}Goodbye!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option${NC}"
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}

# Run main function
main
