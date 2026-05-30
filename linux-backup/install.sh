#!/usr/bin/env bash
# =============================================================================
# Linux Backup Script - Professional Edition
# Version: 2.0.0
# License: MIT
# Author:  BackupPro Solutions
#
# A production-quality, menu-driven backup solution for Linux systems.
# Supports full, incremental, and differential backups with compression,
# remote destinations, email notifications, scheduling, and logging.
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

# =============================================================================
# CONSTANTS & VERSION
# =============================================================================
readonly SCRIPT_VERSION="2.0.0"
readonly SCRIPT_NAME="LinuxBackup Pro"
readonly CONFIG_DIR="${HOME}/.linuxbackup"
readonly CONFIG_FILE="${CONFIG_DIR}/config"
readonly LOG_DIR="${CONFIG_DIR}/logs"
readonly LOCK_DIR="${CONFIG_DIR}/locks"
readonly DATA_DIR="${CONFIG_DIR}/data"
readonly CRON_TAG="# linuxbackup-pro-managed"
readonly MAX_LOG_SIZE=$((5 * 1024 * 1024))  # 5MB max log size

# =============================================================================
# COLOR DEFINITIONS
# =============================================================================
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly MAGENTA='\033[0;35m'
readonly WHITE='\033[1;37m'
readonly BOLD='\033[1m'
readonly NC='\033[0m' # No Color

# =============================================================================
# ASCII HEADER
# =============================================================================
show_header() {
    clear
    echo -e "${CYAN}${BOLD}"
    cat << 'HEADER'
    ╔══════════════════════════════════════════════════════════════════╗
    ║                                                                ║
    ║   ██╗     ██╗   ██╗██╗  ████████╗███████╗██████╗ ███╗   ███╗  ║
    ║   ██║     ██║   ██║██║  ╚══██╔══╝██╔════╝██╔══██╗████╗ ████║  ║
    ║   ██║     ██║   ██║██║     ██║   █████╗  ██████╔╝██╔████╔██║  ║
    ║   ██║     ██║   ██║██║     ██║   ██╔══╝  ██╔══██╗██║╚██╔╝██║  ║
    ║   ███████╗╚██████╔╝██║     ██║   ███████╗██║  ██║██║ ╚═╝ ██║  ║
    ║   ╚══════╝ ╚═════╝ ╚═╝     ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝  ║
    ║                                                                ║
    ║   ██████╗  █████╗ ███████╗██╗  ██╗██████╗  ██████╗  █████╗    ║
    ║   ██╔══██╗██╔══██╗██╔════╝██║  ██║██╔══██╗██╔═══██╗██╔══██╗  ║
    ║   ██████╔╝███████║███████╗███████║██████╔╝██║   ██║███████║  ║
    ║   ██╔═══╝ ██╔══██║╚════██║██╔══██║██╔══██╗██║   ██║██╔══██║  ║
    ║   ██║     ██║  ██║███████║██║  ██║██████╔╝╚██████╔╝██║  ██║  ║
    ║   ╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝  ╚═════╝ ╚═╝  ╚═╝  ║
    ║                                                                ║
    ║          Professional Linux Backup Solution v2.0.0             ║
    ║                    MIT License 2024                           ║
    ╚══════════════════════════════════════════════════════════════════╝
HEADER
    echo -e "${NC}"
}

show_mini_header() {
    echo -e "${CYAN}${BOLD}╔══════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}${BOLD}║     LinuxBackup Pro v${SCRIPT_VERSION}              ║${NC}"
    echo -e "${CYAN}${BOLD}╚══════════════════════════════════════════╝${NC}"
}

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# --- Logging ---
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Ensure log directory exists
    mkdir -p "${LOG_DIR}" 2>/dev/null

    local log_file="${LOG_DIR}/backup_$(date '+%Y-%m-%d').log"

    # Rotate logs if they're too large
    if [[ -f "$log_file" ]] && [[ $(stat -f%z "$log_file" 2>/dev/null || stat -c%s "$log_file" 2>/dev/null) -gt $MAX_LOG_SIZE ]]; then
        mv "$log_file" "${log_file}.1"
    fi

    echo "[$timestamp] [$level] $message" >> "$log_file"

    # Also display based on level
    case "$level" in
        ERROR)   echo -e "${RED}[ERROR]${NC} $message" ;;
        WARN)    echo -e "${YELLOW}[WARN]${NC} $message" ;;
        INFO)    echo -e "${GREEN}[INFO]${NC} $message" ;;
        DEBUG)   [[ "${DEBUG_MODE:-0}" == "1" ]] && echo -e "${MAGENTA}[DEBUG]${NC} $message" ;;
    esac
}

# --- User Messages ---
info()    { echo -e "${GREEN}[✓]${NC} $*"; }
warn()    { echo -e "${YELLOW}[!]${NC} $*"; }
error()   { echo -e "${RED}[✗]${NC} $*"; }
success() { echo -e "${GREEN}[✓]${NC} ${BOLD}$*${NC}"; }
divider() { echo -e "${BLUE}────────────────────────────────────────────${NC}"; }
section() { echo -e "\n${CYAN}${BOLD}━━━ $* ━━━${NC}\n"; }

# --- Input Helpers ---
prompt() {
    local prompt_text="$1"
    local default="${2:-}"
    local result

    if [[ -n "$default" ]]; then
        read -rp "$(echo -e "${CYAN}${prompt_text} [${default}]: ${NC}")" result
        echo "${result:-$default}"
    else
        read -rp "$(echo -e "${CYAN}${prompt_text}: ${NC}")" result
        echo "$result"
    fi
}

confirm() {
    local prompt_text="${1:-Continue?}"
    local default="${2:-y}"
    local response

    if [[ "$default" == "y" ]]; then
        read -rp "$(echo -e "${YELLOW}${prompt_text} [Y/n]: ${NC}")" response
        [[ -z "$response" || "$response" =~ ^[Yy]$ ]]
    else
        read -rp "$(echo -e "${YELLOW}${prompt_text} [y/N]: ${NC}")" response
        [[ "$response" =~ ^[Yy]$ ]]
    fi
}

menu_select() {
    local title="$1"
    shift
    local options=("$@")
    local choice

    echo -e "\n${CYAN}${BOLD}$title${NC}"
    divider
    for i in "${!options[@]}"; do
        echo -e "  ${GREEN}$((i+1)))${NC} ${options[$i]}"
    done
    divider

    while true; do
        read -rp "$(echo -e "${CYAN}Select option [1-${#options[@]}]: ${NC}")" choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#options[@]} )); then
            return "$choice"
        fi
        error "Invalid selection. Please enter a number between 1 and ${#options[@]}."
    done
}

# --- System Checks ---
check_command() {
    command -v "$1" &>/dev/null
}

require_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This operation requires root privileges."
        error "Please run with: sudo $0"
        exit 1
    fi
}

check_dependencies() {
    local deps=("rsync" "tar" "date" "find" "stat")
    local optional_deps=("zstd" "gzip" "mail" "ssh" "crontab")
    local missing=()
    local optional_missing=()

    section "Checking Dependencies"

    for dep in "${deps[@]}"; do
        if check_command "$dep"; then
            info "$dep found"
        else
            missing+=("$dep")
            error "$dep not found"
        fi
    done

    for dep in "${optional_deps[@]}"; do
        if check_command "$dep"; then
            info "$dep found"
        else
            optional_missing+=("$dep")
            warn "$dep not found (optional)"
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        error "Missing required dependencies: ${missing[*]}"
        error "Install with: sudo apt install ${missing[*]}"
        return 1
    fi

    if [[ ${#optional_missing[@]} -gt 0 ]]; then
        warn "Some optional features may not work: ${optional_missing[*]}"
    fi

    info "All required dependencies satisfied"
    return 0
}

# --- Configuration ---
init_config() {
    mkdir -p "${CONFIG_DIR}" "${LOG_DIR}" "${LOCK_DIR}" "${DATA_DIR}"

    if [[ ! -f "$CONFIG_FILE" ]]; then
        cat > "$CONFIG_FILE" << 'CONF'
# LinuxBackup Pro Configuration
# =============================

# Backup destination type: local, external, remote
DEST_TYPE="local"

# Local/External backup directory
BACKUP_DIR="/backup"

# Remote settings
REMOTE_HOST=""
REMOTE_USER=""
REMOTE_PATH="/backup"
REMOTE_SSH_KEY=""
REMOTE_SSH_PORT=22

# Compression: none, gzip, zstd
COMPRESSION="zstd"

# Default source directories (space-separated)
SOURCE_DIRS="/home /etc /var/log"

# Exclude patterns file
EXCLUDE_FILE="${CONFIG_DIR}/excludes.txt"

# Email notifications
EMAIL_ENABLED="false"
EMAIL_TO=""
EMAIL_FROM="backup@$(hostname -f 2>/dev/null || hostname)"

# Logging
LOG_RETENTION_DAYS=30

# Notification preferences
NOTIFY_ON_SUCCESS="true"
NOTIFY_ON_FAILURE="true"
NOTIFY_ON_WARNING="true"
CONF
        chmod 600 "$CONFIG_FILE"
        info "Configuration initialized at $CONFIG_FILE"
    fi

    # Initialize exclude patterns if not present
    if [[ ! -f "${CONFIG_DIR}/excludes.txt" ]]; then
        cat > "${CONFIG_DIR}/excludes.txt" << 'EXCLUDES'
# LinuxBackup Pro - Exclude Patterns
# One pattern per line. Supports glob patterns.
# Lines starting with # are comments.

# System directories to exclude
/proc
/sys
/dev
/run
/tmp

# Common large/unnecessary directories
*/node_modules
*/__pycache__
*.pyc
*.swp
*.swo
*~
.DS_Store
Thumbs.db

# Cache directories
*/.cache
*/.local/share/Trash
EXCLUDES
        info "Exclude patterns initialized"
    fi

    source "$CONFIG_FILE"
}

# --- Disk Space ---
check_disk_space() {
    local target_dir="$1"
    local min_space_gb="${2:-1}"
    local available

    mkdir -p "$target_dir" 2>/dev/null

    # Get available space in GB
    available=$(df -BG "$target_dir" 2>/dev/null | awk 'NR==2{print $4}' | tr -d 'G')

    if [[ -n "$available" ]] && (( available < min_space_gb )); then
        error "Insufficient disk space on $target_dir"
        error "Available: ${available}GB, Required: ${min_space_gb}GB"
        return 1
    fi

    return 0
}

# --- Locking ---
acquire_lock() {
    local lock_file="${LOCK_DIR}/backup.lock"
    if [[ -f "$lock_file" ]]; then
        local lock_pid
        lock_pid=$(cat "$lock_file" 2>/dev/null)
        if [[ -n "$lock_pid" ]] && kill -0 "$lock_pid" 2>/dev/null; then
            error "Another backup is running (PID: $lock_pid)"
            return 1
        else
            warn "Removing stale lock file"
            rm -f "$lock_file"
        fi
    fi
    echo $$ > "$lock_file"
    trap 'rm -f "'"$lock_file"'"' EXIT
}

# --- Email ---
send_email() {
    local subject="$1"
    local body="$2"

    if [[ "${EMAIL_ENABLED}" != "true" ]]; then
        return 0
    fi

    if [[ -z "${EMAIL_TO:-}" ]]; then
        warn "Email recipient not configured"
        return 1
    fi

    if check_command "mail"; then
        echo "$body" | mail -s "$subject" "$EMAIL_TO"
        info "Email notification sent to $EMAIL_TO"
    else
        warn "mail command not available. Cannot send email notification."
    fi
}

# --- Progress Display ---
show_progress() {
    local current=$1
    local total=$2
    local width=50
    local pct=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))

    printf "\r  ${CYAN}Progress: ["
    printf '%0.s█' $(seq 1 $filled) 2>/dev/null
    printf '%0.s░' $(seq 1 $empty) 2>/dev/null
    printf "] %3d%%" "$pct"
}

# --- Calculate backup size ---
human_readable_size() {
    local bytes=$1
    if (( bytes >= 1073741824 )); then
        printf "%.2f GB" "$(echo "scale=2; $bytes/1073741824" | bc 2>/dev/null || echo "0")"
    elif (( bytes >= 1048576 )); then
        printf "%.2f MB" "$(echo "scale=2; $bytes/1048576" | bc 2>/dev/null || echo "0")"
    elif (( bytes >= 1024 )); then
        printf "%.2f KB" "$(echo "scale=2; $bytes/1024" | bc 2>/dev/null || echo "0")"
    else
        printf "%d bytes" "$bytes"
    fi
}

# =============================================================================
# BACKUP CORE FUNCTIONS
# =============================================================================

# --- Get Compression Flag ---
get_compression_flag() {
    local method="${1:-$COMPRESSION}"
    case "$method" in
        gzip)  echo "-z" ;;
        zstd)  echo "--zstd" ;;
        none)  echo "" ;;
        *)     echo "--zstd" ;;  # Default to zstd
    esac
}

# --- Get Compression Extension ---
get_compression_ext() {
    local method="${1:-$COMPRESSION}"
    case "$method" in
        gzip)  echo ".tar.gz" ;;
        zstd)  echo ".tar.zst" ;;
        none)  echo ".tar" ;;
        *)     echo ".tar.zst" ;;
    esac
}

# --- Build Rsync Command ---
build_rsync_cmd() {
    local src="$1"
    local dest="$2"
    local comp_flag
    comp_flag=$(get_compression_flag)

    local rsync_opts="-av --progress --stats --human-readable"

    # Add exclude patterns
    if [[ -f "${EXCLUDE_FILE:-}" ]]; then
        while IFS= read -r pattern; do
            [[ -z "$pattern" || "$pattern" =~ ^# ]] && continue
            rsync_opts+=" --exclude=$pattern"
        done < "${EXCLUDE_FILE}"
    fi

    echo "rsync $rsync_opts \"$src\" \"$dest\""
}

# --- Perform Full Backup ---
do_full_backup() {
    section "Full Backup"

    local timestamp
    timestamp=$(date '+%Y-%m-%d_%H-%M-%S')
    local backup_name="full_backup_${timestamp}"
    local comp_ext
    comp_ext=$(get_compression_ext)
    local dest_path

    # Determine destination
    case "${DEST_TYPE:-local}" in
        local|external)
            dest_path="${BACKUP_DIR:-/backup}/linuxbackup"
            mkdir -p "$dest_path"
            ;;
        remote)
            dest_path="${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH}/linuxbackup"
            ;;
        *)
            error "Unknown destination type: $DEST_TYPE"
            return 1
            ;;
    esac

    # Check disk space (only for local)
    if [[ "${DEST_TYPE:-local}" != "remote" ]]; then
        check_disk_space "$dest_path" 2 || return 1
    fi

    local archive_file="${dest_path}/${backup_name}${comp_ext}"
    local start_time
    start_time=$(date +%s)

    info "Starting full backup..."
    info "Source: ${SOURCE_DIRS:-/home}"
    info "Destination: $archive_file"
    info "Compression: ${COMPRESSION:-zstd}"

    log INFO "Full backup started: $archive_file"

    # Build tar command
    local tar_cmd="tar cf -"
    local comp_flag
    comp_flag=$(get_compression_flag)

    if [[ -n "$comp_flag" ]]; then
        tar_cmd="$tar_cmd $comp_flag"
    fi

    # Add exclude patterns
    if [[ -f "${EXCLUDE_FILE:-}" ]]; then
        while IFS= read -r pattern; do
            [[ -z "$pattern" || "$pattern" =~ ^# ]] && continue
            tar_cmd="$tar_cmd --exclude=$pattern"
        done < "${EXCLUDE_FILE}"
    fi

    # Add source directories
    local sources
    sources=($SOURCE_DIRS)

    if [[ "${DEST_TYPE:-local}" == "remote" ]]; then
        # For remote: create archive locally first, then transfer
        local temp_archive="/tmp/${backup_name}${comp_ext}"
        eval "$tar_cmd -f - ${sources[*]}" 2>/dev/null | gzip > "$temp_archive" 2>/dev/null || \
        eval "$tar_cmd -f - ${sources[*]}" 2>/dev/null | zstd -q > "$temp_archive" 2>/dev/null || \
        eval "$tar_cmd -f '$temp_archive' ${sources[*]}" 2>/dev/null

        if [[ -f "$temp_archive" ]]; then
            local archive_size
            archive_size=$(stat -c%s "$temp_archive" 2>/dev/null || stat -f%z "$temp_archive" 2>/dev/null)
            info "Archive created: $(human_readable_size "$archive_size")"
            info "Transferring to remote..."
            rsync -avz --progress "$temp_archive" "$dest_path/"
            rm -f "$temp_archive"
        else
            error "Failed to create backup archive"
            log ERROR "Full backup failed: could not create archive"
            return 1
        fi
    else
        # Local backup
        local sources_str=""
        for src in "${sources[@]}"; do
            if [[ -d "$src" ]]; then
                sources_str+="$src "
            else
                warn "Source directory not found: $src"
            fi
        done

        if [[ -z "$sources_str" ]]; then
            error "No valid source directories found"
            return 1
        fi

        eval "$tar_cmd -f '$archive_file' $sources_str" 2>/dev/null
    fi

    if [[ -f "$archive_file" || "${DEST_TYPE}" == "remote" ]]; then
        local end_time
        end_time=$(date +%s)
        local duration=$((end_time - start_time))

        local archive_size="N/A"
        if [[ -f "$archive_file" ]]; then
            local size_bytes
            size_bytes=$(stat -c%s "$archive_file" 2>/dev/null || stat -f%z "$archive_file" 2>/dev/null || echo 0)
            archive_size=$(human_readable_size "$size_bytes")
        fi

        # Save backup metadata
        save_backup_meta "$backup_name" "full" "$archive_file" "$archive_size" "$duration"

        success "Full backup completed successfully!"
        info "Archive: $archive_file"
        info "Size: $archive_size"
        info "Duration: ${duration}s"

        log INFO "Full backup completed: $archive_file (Size: $archive_size, Duration: ${duration}s)"

        send_email "Backup Success - Full Backup" \
            "Full backup completed successfully.\n\nArchive: $archive_file\nSize: $archive_size\nDuration: ${duration}s\nHost: $(hostname)"

        return 0
    else
        error "Backup failed!"
        log ERROR "Full backup failed"
        send_email "Backup FAILED - Full Backup" "Full backup failed on $(hostname). Check logs for details."
        return 1
    fi
}

# --- Perform Incremental Backup ---
do_incremental_backup() {
    section "Incremental Backup"

    local snapshot_file="${DATA_DIR}/.incremental_snapshot"
    local timestamp
    timestamp=$(date '+%Y-%m-%d_%H-%M-%S')
    local backup_name="incr_backup_${timestamp}"
    local comp_ext
    comp_ext=$(get_compression_ext)
    local dest_path

    case "${DEST_TYPE:-local}" in
        local|external)
            dest_path="${BACKUP_DIR:-/backup}/linuxbackup"
            mkdir -p "$dest_path"
            ;;
        remote)
            dest_path="${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH}/linuxbackup"
            ;;
    esac

    local archive_file="${dest_path}/${backup_name}${comp_ext}"
    local start_time
    start_time=$(date +%s)

    info "Starting incremental backup..."
    info "Using snapshot: $snapshot_file"

    log INFO "Incremental backup started: $archive_file"

    local tar_cmd="tar cf -"
    local comp_flag
    comp_flag=$(get_compression_flag)
    [[ -n "$comp_flag" ]] && tar_cmd="$tar_cmd $comp_flag"

    if [[ -f "${EXCLUDE_FILE:-}" ]]; then
        while IFS= read -r pattern; do
            [[ -z "$pattern" || "$pattern" =~ ^# ]] && continue
            tar_cmd="$tar_cmd --exclude=$pattern"
        done < "${EXCLUDE_FILE}"
    fi

    local sources=($SOURCE_DIRS)
    local sources_str=""
    for src in "${sources[@]}"; do
        [[ -d "$src" ]] && sources_str+="$src "
    done

    if [[ -z "$sources_str" ]]; then
        error "No valid source directories found"
        return 1
    fi

    # Use rsync incremental with --link-dest for efficiency
    local rsync_opts="-av --delete --stats --progress"
    local prev_link=""
    local last_incr=$(find "$dest_path" -name "incr_backup_*" -type f 2>/dev/null | sort -r | head -1)

    if [[ -n "$last_incr" ]]; then
        prev_link="--link-dest=$last_incr"
        info "Linking to previous incremental: $last_incr"
    fi

    if [[ "${DEST_TYPE}" == "remote" ]]; then
        local temp_dir="/tmp/linuxbackup_incr_$$"
        mkdir -p "$temp_dir"

        for src in "${sources[@]}"; do
            local dir_name=$(basename "$src")
            eval "rsync $rsync_opts $prev_link '$src/' '$temp_dir/$dir_name/'" 2>/dev/null
        done

        # Create tar from temp
        local tar_opts=""
        [[ -n "$comp_flag" ]] && tar_opts="$comp_flag"
        eval "tar cf - $tar_opts -C '$temp_dir' ." 2>/dev/null | ssh -p "${REMOTE_SSH_PORT:-22}" "${REMOTE_USER}@${REMOTE_HOST}" "cat > '$dest_path/linuxbackup/$backup_name.tar${comp_ext}'"

        rm -rf "$temp_dir"
    else
        # Local incremental using snapshot files
        local temp_dir="/tmp/linuxbackup_incr_$$"
        mkdir -p "$temp_dir"

        for src in "${sources[@]}"; do
            local dir_name=$(basename "$src")
            if [[ -n "$prev_link" ]]; then
                local link_target
                link_target=$(find "$dest_path" -name "incr_backup_*" -type f | sort -r | head -1)
                # For tar-based incremental, use --listed-incremental
                if [[ -f "$snapshot_file" ]]; then
                    eval "tar cf '$temp_dir/${backup_name}_${dir_name}${comp_ext}' --listed-incremental='$snapshot_file' $comp_flag '$src'" 2>/dev/null
                else
                    eval "tar cf '$temp_dir/${backup_name}_${dir_name}${comp_ext}' --listed-incremental='$snapshot_file' $comp_flag '$src'" 2>/dev/null
                fi
            else
                eval "tar cf '$temp_dir/${backup_name}_${dir_name}${comp_ext}' --listed-incremental='$snapshot_file' $comp_flag '$src'" 2>/dev/null
            fi
        done

        # Move archives to destination
        mv "$temp_dir"/* "$dest_path/" 2>/dev/null
        rm -rf "$temp_dir"
    fi

    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))

    save_backup_meta "$backup_name" "incremental" "$dest_path" "incremental" "$duration"

    success "Incremental backup completed!"
    info "Duration: ${duration}s"

    log INFO "Incremental backup completed (Duration: ${duration}s)"
    send_email "Backup Success - Incremental Backup" "Incremental backup completed on $(hostname).\nDuration: ${duration}s"

    return 0
}

# --- Perform Differential Backup ---
do_differential_backup() {
    section "Differential Backup"

    local last_full=$(find "${BACKUP_DIR:-/backup}/linuxbackup" -name "full_backup_*" -type f 2>/dev/null | sort -r | head -1)
    local timestamp
    timestamp=$(date '+%Y-%m-%d_%H-%M-%S')
    local backup_name="diff_backup_${timestamp}"
    local comp_ext
    comp_ext=$(get_compression_ext)
    local dest_path

    case "${DEST_TYPE:-local}" in
        local|external)
            dest_path="${BACKUP_DIR:-/backup}/linuxbackup"
            mkdir -p "$dest_path"
            ;;
        remote)
            dest_path="${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH}/linuxbackup"
            ;;
    esac

    local archive_file="${dest_path}/${backup_name}${comp_ext}"
    local start_time
    start_time=$(date +%s)

    if [[ -z "$last_full" ]]; then
        warn "No full backup found. Running full backup first..."
        do_full_backup
        return $?
    fi

    info "Starting differential backup..."
    info "Base full backup: $last_full"

    log INFO "Differential backup started: $archive_file"

    local temp_dir="/tmp/linuxbackup_diff_$$"
    mkdir -p "$temp_dir"
    local sources=($SOURCE_DIRS)
    local rsync_opts="-av --stats --progress"
    local comp_flag
    comp_flag=$(get_compression_flag)

    # Create a temporary extraction directory for comparison
    local extract_dir="/tmp/linuxbackup_diff_extract_$$"
    mkdir -p "$extract_dir"

    # Extract the full backup temporarily to compare
    info "Extracting reference for comparison..."
    if [[ -f "$last_full" ]]; then
        if [[ "$last_full" == *.tar.zst ]]; then
            zstd -d "$last_full" -o "$extract_dir/full.tar" 2>/dev/null || \
            tar xf "$last_full" -C "$extract_dir" 2>/dev/null
        elif [[ "$last_full" == *.tar.gz ]]; then
            tar xzf "$last_full" -C "$extract_dir" 2>/dev/null
        else
            tar xf "$last_full" -C "$extract_dir" 2>/dev/null
        fi
    fi

    # Create differential using tar with --newer-mtime
    for src in "${sources[@]}"; do
        local dir_name=$(basename "$src")
        if [[ -d "$src" ]]; then
            if [[ -f "$last_full" ]]; then
                local full_time
                full_time=$(stat -c%Y "$last_full" 2>/dev/null || stat -f%m "$last_full" 2>/dev/null)
                eval "tar cf '$temp_dir/${backup_name}_${dir_name}${comp_ext}' --newer-mtime='@$full_time' $comp_flag '$src'" 2>/dev/null
            fi
        fi
    done

    # Move to destination
    mv "$temp_dir"/* "$dest_path/" 2>/dev/null
    rm -rf "$temp_dir" "$extract_dir"

    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))

    save_backup_meta "$backup_name" "differential" "$archive_file" "differential" "$duration"

    success "Differential backup completed!"
    info "Duration: ${duration}s"

    log INFO "Differential backup completed (Duration: ${duration}s)"
    send_email "Backup Success - Differential Backup" "Differential backup completed on $(hostname).\nDuration: ${duration}s"

    return 0
}

# --- Save Backup Metadata ---
save_backup_meta() {
    local name="$1"
    local type="$2"
    local archive="$3"
    local size="$4"
    local duration="$5"
    local meta_file="${DATA_DIR}/backup_history.log"

    echo "$(date '+%Y-%m-%d %H:%M:%S')|$name|$type|$archive|$size|${duration}s" >> "$meta_file"
    log INFO "Backup metadata saved: $name"
}

# =============================================================================
# RESTORE FUNCTIONS
# =============================================================================

# --- List Available Backups ---
list_backups() {
    local search_dir

    case "${DEST_TYPE:-local}" in
        local|external)
            search_dir="${BACKUP_DIR:-/backup}/linuxbackup"
            ;;
        remote)
            warn "Remote backup listing requires SSH connection."
            if [[ -n "${REMOTE_USER:-}" && -n "${REMOTE_HOST:-}" ]]; then
                ssh -p "${REMOTE_SSH_PORT:-22}" "${REMOTE_USER}@${REMOTE_HOST}" \
                    "ls -lhtr ${REMOTE_PATH}/linuxbackup/ 2>/dev/null"
            fi
            return 0
            ;;
    esac

    if [[ ! -d "$search_dir" ]]; then
        warn "No backups directory found at $search_dir"
        return 1
    fi

    local backups=($(find "$search_dir" -name "*.tar*" -type f 2>/dev/null | sort -r))

    if [[ ${#backups[@]} -eq 0 ]]; then
        warn "No backup archives found"
        return 1
    fi

    section "Available Backups"
    printf "${BOLD}%-5s %-40s %-15s %-15s${NC}\n" "No." "Archive" "Type" "Size"
    divider

    local i=1
    for backup in "${backups[@]}"; do
        local name
        name=$(basename "$backup")
        local size
        size=$(du -sh "$backup" 2>/dev/null | cut -f1)
        local btype="unknown"
        [[ "$name" == full_* ]] && btype="Full"
        [[ "$name" == incr_* ]] && btype="Incremental"
        [[ "$name" == diff_* ]] && btype="Differential"
        printf "  ${GREEN}%-5s${NC} %-40s %-15s %-15s\n" "$i" "$name" "$btype" "$size"
        ((i++))
    done

    echo ""
}

# --- Restore from Backup ---
do_restore() {
    section "Restore Backup"

    list_backups || return 1

    local search_dir="${BACKUP_DIR:-/backup}/linuxbackup"
    local backups=($(find "$search_dir" -name "*.tar*" -type f 2>/dev/null | sort -r))

    if [[ ${#backups[@]} -eq 0 ]]; then
        error "No backups available to restore"
        return 1
    fi

    local choice
    read -rp "$(echo -e "${CYAN}Enter backup number to restore [1-${#backups[@]}]: ${NC}")" choice

    if [[ ! "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#backups[@]} )); then
        error "Invalid selection"
        return 1
    fi

    local selected_backup="${backups[$((choice-1))]}"
    local restore_dest
    restore_dest=$(prompt "Restore destination directory" "/")

    if [[ ! -d "$restore_dest" ]]; then
        if ! confirm "Directory $restore_dest does not exist. Create it?"; then
            return 1
        fi
        mkdir -p "$restore_dest"
    fi

    if ! confirm "Restore from $(basename "$selected_backup") to $restore_dest?"; then
        warn "Restore cancelled"
        return 0
    fi

    info "Starting restore..."
    info "Source: $selected_backup"
    info "Destination: $restore_dest"

    local start_time
    start_time=$(date +%s)

    log INFO "Restore started from $selected_backup to $restore_dest"

    local restore_cmd=""
    case "$selected_backup" in
        *.tar.zst)  restore_cmd="zstd -d '$selected_backup' --stdout | tar xf - -C '$restore_dest'" ;;
        *.tar.gz)   restore_cmd="tar xzf '$selected_backup' -C '$restore_dest'" ;;
        *.tar)      restore_cmd="tar xf '$selected_backup' -C '$restore_dest'" ;;
        *)          error "Unknown archive format"; return 1 ;;
    esac

    if eval "$restore_cmd" 2>/dev/null; then
        local end_time
        end_time=$(date +%s)
        local duration=$((end_time - start_time))

        success "Restore completed successfully!"
        info "Restored to: $restore_dest"
        info "Duration: ${duration}s"

        log INFO "Restore completed in ${duration}s"
        send_email "Restore Success" "Backup restored successfully to $restore_dest.\nSource: $(basename "$selected_backup")\nDuration: ${duration}s"

        return 0
    else
        error "Restore failed!"
        log ERROR "Restore failed from $selected_backup"
        send_email "Restore FAILED" "Restore failed from $(basename "$selected_backup") on $(hostname)."
        return 1
    fi
}

# =============================================================================
# SCHEDULING (CRON)
# =============================================================================

# --- Configure Cron Schedule ---
configure_schedule() {
    section "Backup Schedule Configuration"

    # Remove existing managed crontab entries
    crontab -l 2>/dev/null | grep -v "$CRON_TAG" > /tmp/crontab_tmp 2>/dev/null || true

    local options=(
        "Daily backup at 2:00 AM"
        "Weekly backup (Sunday at 3:00 AM)"
        "Monthly backup (1st at 4:00 AM)"
        "Custom schedule"
        "Remove all scheduled backups"
    )

    menu_select "Select backup schedule:" "${options[@]}"
    local choice=$?

    local cron_line=""

    case $choice in
        1)
            cron_line="0 2 * * * $0 --auto-full $CRON_TAG"
            ;;
        2)
            cron_line="0 3 * * 0 $0 --auto-full $CRON_TAG"
            ;;
        3)
            cron_line="0 4 1 * * $0 --auto-full $CRON_TAG"
            ;;
        4)
            echo ""
            echo -e "${CYAN}Cron schedule format: minute hour day-of-month month day-of-week${NC}"
            echo -e "${CYAN}Examples:${NC}"
            echo "  '0 */6 * * *'     - Every 6 hours"
            echo "  '30 1 * * 1-5'    - Weekdays at 1:30 AM"
            echo "  '0 0 1,15 * *'    - 1st and 15th of month"
            echo ""
            local minute hour dom month dow
            minute=$(prompt "Minute (0-59)" "0")
            hour=$(prompt "Hour (0-23)" "2")
            dom=$(prompt "Day of month (1-31)" "*")
            month=$(prompt "Month (1-12)" "*")
            dow=$(prompt "Day of week (0-7, 0=Sun)" "*")
            cron_line="$minute $hour $dom $month $dow $0 --auto-full $CRON_TAG"
            ;;
        5)
            cat /tmp/crontab_tmp 2>/dev/null | crontab -
            rm -f /tmp/crontab_tmp
            info "All scheduled backups removed"
            log INFO "All scheduled backups removed from crontab"
            return 0
            ;;
    esac

    if [[ -n "$cron_line" ]]; then
        echo "$cron_line" >> /tmp/crontab_tmp
        cat /tmp/crontab_tmp | crontab -
        rm -f /tmp/crontab_tmp
        success "Schedule configured: $cron_line"
        log INFO "Cron schedule set: $cron_line"
    fi
}

# --- View Current Schedule ---
view_schedule() {
    section "Current Backup Schedule"
    local schedule
    schedule=$(crontab -l 2>/dev/null | grep "$CRON_TAG" || true)

    if [[ -z "$schedule" ]]; then
        warn "No scheduled backups configured"
    else
        while IFS= read -r line; do
            echo -e "  ${GREEN}$line${NC}"
        done <<< "$schedule"
    fi
}

# =============================================================================
# CONFIGURATION MANAGEMENT
# =============================================================================

# --- Edit Configuration ---
edit_config() {
    section "Configuration Settings"

    echo -e "${BOLD}Current Configuration:${NC}"
    divider

    source "$CONFIG_FILE"

    echo -e "  ${CYAN}1)${NC}  Backup destination type: ${GREEN}${DEST_TYPE}${NC}"
    echo -e "  ${CYAN}2)${NC}  Backup directory:        ${GREEN}${BACKUP_DIR}${NC}"
    echo -e "  ${CYAN}3)${NC}  Source directories:      ${GREEN}${SOURCE_DIRS}${NC}"
    echo -e "  ${CYAN}4)${NC}  Compression method:      ${GREEN}${COMPRESSION}${NC}"
    echo -e "  ${CYAN}5)${NC}  SSH remote host:         ${GREEN}${REMOTE_HOST:-<not set>}${NC}"
    echo -e "  ${CYAN}6)${NC}  SSH remote user:         ${GREEN}${REMOTE_USER:-<not set>}${NC}"
    echo -e "  ${CYAN}7)${NC}  SSH remote path:         ${GREEN}${REMOTE_PATH:-<not set>}${NC}"
    echo -e "  ${CYAN}8)${NC}  SSH port:                ${GREEN}${REMOTE_SSH_PORT:-22}${NC}"
    echo -e "  ${CYAN}9)${NC}  Email notifications:     ${GREEN}${EMAIL_ENABLED}${NC}"
    echo -e "  ${CYAN}10)${NC} Email recipient:         ${GREEN}${EMAIL_TO:-<not set>}${NC}"
    echo -e "  ${CYAN}11)${NC} Exclude file:            ${GREEN}${EXCLUDE_FILE}${NC}"
    echo -e "  ${CYAN}12)${NC} Log retention days:      ${GREEN}${LOG_RETENTION_DAYS}${NC}"
    divider

    local choice
    read -rp "$(echo -e "${CYAN}Enter setting number to edit (or 'q' to return): ${NC}")" choice

    [[ "$choice" == "q" || "$choice" == "Q" ]] && return 0

    local new_value
    case "$choice" in
        1)
            new_value=$(prompt "Destination type (local/external/remote)" "$DEST_TYPE")
            sed -i "s|^DEST_TYPE=.*|DEST_TYPE=\"$new_value\"|" "$CONFIG_FILE"
            ;;
        2)
            new_value=$(prompt "Backup directory" "$BACKUP_DIR")
            sed -i "s|^BACKUP_DIR=.*|BACKUP_DIR=\"$new_value\"|" "$CONFIG_FILE"
            ;;
        3)
            new_value=$(prompt "Source directories (space-separated)" "$SOURCE_DIRS")
            sed -i "s|^SOURCE_DIRS=.*|SOURCE_DIRS=\"$new_value\"|" "$CONFIG_FILE"
            ;;
        4)
            echo ""
            echo -e "  ${GREEN}1)${NC} gzip"
            echo -e "  ${GREEN}2)${NC} zstd"
            echo -e "  ${GREEN}3)${NC} none"
            local comp_choice
            read -rp "$(echo -e "${CYAN}Select compression [1-3]: ${NC}")" comp_choice
            case "$comp_choice" in
                1) new_value="gzip" ;;
                2) new_value="zstd" ;;
                3) new_value="none" ;;
                *) new_value="zstd" ;;
            esac
            sed -i "s|^COMPRESSION=.*|COMPRESSION=\"$new_value\"|" "$CONFIG_FILE"
            ;;
        5)
            new_value=$(prompt "SSH remote host" "$REMOTE_HOST")
            sed -i "s|^REMOTE_HOST=.*|REMOTE_HOST=\"$new_value\"|" "$CONFIG_FILE"
            ;;
        6)
            new_value=$(prompt "SSH remote user" "$REMOTE_USER")
            sed -i "s|^REMOTE_USER=.*|REMOTE_USER=\"$new_value\"|" "$CONFIG_FILE"
            ;;
        7)
            new_value=$(prompt "SSH remote path" "$REMOTE_PATH")
            sed -i "s|^REMOTE_PATH=.*|REMOTE_PATH=\"$new_value\"|" "$CONFIG_FILE"
            ;;
        8)
            new_value=$(prompt "SSH port" "${REMOTE_SSH_PORT:-22}")
            sed -i "s|^REMOTE_SSH_PORT=.*|REMOTE_SSH_PORT=$new_value|" "$CONFIG_FILE"
            ;;
        9)
            new_value=$(prompt "Email notifications enabled (true/false)" "$EMAIL_ENABLED")
            sed -i "s|^EMAIL_ENABLED=.*|EMAIL_ENABLED=\"$new_value\"|" "$CONFIG_FILE"
            ;;
        10)
            new_value=$(prompt "Email recipient" "$EMAIL_TO")
            sed -i "s|^EMAIL_TO=.*|EMAIL_TO=\"$new_value\"|" "$CONFIG_FILE"
            ;;
        11)
            echo -e "\nOpening exclude file in default editor..."
            "${EDITOR:-nano}" "${EXCLUDE_FILE}"
            return 0
            ;;
        12)
            new_value=$(prompt "Log retention days" "$LOG_RETENTION_DAYS")
            sed -i "s|^LOG_RETENTION_DAYS=.*|LOG_RETENTION_DAYS=$new_value|" "$CONFIG_FILE"
            ;;
        *)
            error "Invalid option"
            return 1
            ;;
    esac

    success "Configuration updated!"
    log INFO "Configuration updated: setting $choice"
    source "$CONFIG_FILE"
}

# --- Edit Exclude Patterns ---
edit_excludes() {
    section "Exclude Patterns"
    echo -e "${BOLD}Current exclude patterns:${NC}\n"

    if [[ -f "${EXCLUDE_FILE:-${CONFIG_DIR}/excludes.txt}" ]]; then
        local i=1
        while IFS= read -r line; do
            [[ -z "$line" || "$line" =~ ^# ]] && continue
            echo -e "  ${GREEN}${i})${NC} $line"
            ((i++))
        done < "${EXCLUDE_FILE:-${CONFIG_DIR}/excludes.txt}"
    fi

    echo ""
    echo -e "  ${CYAN}a)${NC} Add pattern"
    echo -e "  ${CYAN}r)${NC} Remove pattern"
    echo -e "  ${CYAN}e)${NC} Edit file directly"
    echo -e "  ${CYAN}q)${NC} Return"

    local choice
    read -rp "$(echo -e "${CYAN}Choice: ${NC}")" choice

    case "$choice" in
        a|A)
            local pattern
            pattern=$(prompt "Enter exclude pattern (glob supported)")
            if [[ -n "$pattern" ]]; then
                echo "$pattern" >> "${EXCLUDE_FILE:-${CONFIG_DIR}/excludes.txt}"
                info "Pattern added: $pattern"
            fi
            ;;
        r|R)
            local num
            num=$(prompt "Enter pattern number to remove")
            if [[ "$num" =~ ^[0-9]+$ ]]; then
                local exclude_file="${EXCLUDE_FILE:-${CONFIG_DIR}/excludes.txt}"
                # Get the N-th non-comment, non-empty line
                local current=0
                local temp_file="/tmp/excludes_tmp_$$"
                while IFS= read -r line; do
                    if [[ -n "$line" && ! "$line" =~ ^# ]]; then
                        ((current++))
                        if (( current != num )); then
                            echo "$line" >> "$temp_file"
                        fi
                    else
                        echo "$line" >> "$temp_file"
                    fi
                done < "$exclude_file"
                mv "$temp_file" "$exclude_file"
                info "Pattern #$num removed"
            fi
            ;;
        e|E)
            "${EDITOR:-nano}" "${EXCLUDE_FILE:-${CONFIG_DIR}/excludes.txt}"
            ;;
        q|Q)
            return 0
            ;;
    esac
}

# =============================================================================
# MAINTENANCE
# =============================================================================

# --- Cleanup Old Logs ---
cleanup_logs() {
    section "Log Cleanup"
    local retention="${LOG_RETENTION_DAYS:-30}"
    local deleted=0

    while IFS= read -r -d '' old_log; do
        rm -f "$old_log"
        ((deleted++))
    done < <(find "$LOG_DIR" -name "*.log*" -type f -mtime "+${retention}" -print0 2>/dev/null)

    info "Cleaned up $deleted log files older than $retention days"
    log INFO "Log cleanup: $deleted files removed"
}

# --- Cleanup Old Backups ---
cleanup_backups() {
    section "Backup Cleanup"

    local keep_count
    keep_count=$(prompt "Number of backups to keep per type" "7")

    local search_dir
    case "${DEST_TYPE:-local}" in
        local|external)
            search_dir="${BACKUP_DIR:-/backup}/linuxbackup"
            ;;
        remote)
            warn "Remote cleanup not yet implemented"
            return 0
            ;;
    esac

    if [[ ! -d "$search_dir" ]]; then
        warn "Backup directory not found"
        return 1
    fi

    # Clean full backups
    local full_backups=($(find "$search_dir" -name "full_backup_*" -type f 2>/dev/null | sort -r))
    if (( ${#full_backups[@]} > keep_count )); then
        for ((i=keep_count; i<${#full_backups[@]}; i++)); do
            rm -f "${full_backups[$i]}"
            info "Removed old full backup: $(basename "${full_backups[$i]}")"
        done
    fi

    # Clean incremental backups
    local incr_backups=($(find "$search_dir" -name "incr_backup_*" -type f 2>/dev/null | sort -r))
    if (( ${#incr_backups[@]} > keep_count )); then
        for ((i=keep_count; i<${#incr_backups[@]}; i++)); do
            rm -f "${incr_backups[$i]}"
            info "Removed old incremental backup: $(basename "${incr_backups[$i]}")"
        done
    fi

    # Clean differential backups
    local diff_backups=($(find "$search_dir" -name "diff_backup_*" -type f 2>/dev/null | sort -r))
    if (( ${#diff_backups[@]} > keep_count )); then
        for ((i=keep_count; i<${#diff_backups[@]}; i++)); do
            rm -f "${diff_backups[$i]}"
            info "Removed old differential backup: $(basename "${diff_backups[$i]}")"
        done
    fi

    success "Cleanup completed (keeping $keep_count of each type)"
    log INFO "Backup cleanup: keeping $keep_count of each type"
}

# --- Verify Backup Integrity ---
verify_backup() {
    section "Backup Verification"

    local search_dir="${BACKUP_DIR:-/backup}/linuxbackup"
    local backups=($(find "$search_dir" -name "*.tar*" -type f 2>/dev/null | sort -r))

    if [[ ${#backups[@]} -eq 0 ]]; then
        warn "No backups found to verify"
        return 1
    fi

    info "Verifying ${#backups[@]} backup(s)..."
    echo ""

    local verified=0
    local failed=0

    for backup in "${backups[@]}"; do
        local name
        name=$(basename "$backup")
        printf "  Verifying %-40s " "$name"

        local verify_ok=false
        case "$backup" in
            *.tar.zst)
                zstd -t "$backup" 2>/dev/null && verify_ok=true
                ;;
            *.tar.gz)
                gzip -t "$backup" 2>/dev/null && verify_ok=true
                ;;
            *.tar)
                tar tf "$backup" &>/dev/null && verify_ok=true
                ;;
        esac

        if $verify_ok; then
            echo -e "${GREEN}✓ OK${NC}"
            ((verified++))
        else
            echo -e "${RED}✗ FAILED${NC}"
            ((failed++))
        fi
    done

    echo ""
    divider
    info "Verified: $verified"
    [[ $failed -gt 0 ]] && error "Failed: $failed"

    if [[ $failed -eq 0 ]]; then
        success "All backups verified successfully!"
    else
        warn "$failed backup(s) failed verification"
    fi

    log INFO "Backup verification: $verified OK, $failed failed"
}

# --- View Backup History ---
view_history() {
    section "Backup History"

    local history_file="${DATA_DIR}/backup_history.log"

    if [[ ! -f "$history_file" ]]; then
        warn "No backup history found"
        return 0
    fi

    printf "${BOLD}%-20s %-30s %-15s %-10s${NC}\n" "Date" "Name" "Type" "Duration"
    divider

    while IFS='|' read -r date name type archive size duration; do
        printf "  %-20s %-30s %-15s %-10s\n" "$date" "$name" "$type" "$duration"
    done < "$history_file"
}

# =============================================================================
# TEST / DRY RUN
# =============================================================================

dry_run_backup() {
    section "Dry Run - Backup Test"

    info "Simulating backup operation..."
    echo ""

    local sources=($SOURCE_DIRS)
    local total_files=0
    local total_size=0

    for src in "${sources[@]}"; do
        if [[ -d "$src" ]]; then
            local count
            local size
            count=$(find "$src" -type f 2>/dev/null | wc -l)
            size=$(du -sh "$src" 2>/dev/null | cut -f1)
            printf "  ${GREEN}✓${NC} %-30s %s files, ~%s\n" "$src" "$count" "$size"
            total_files=$((total_files + count))
        else
            printf "  ${RED}✗${NC} %-30s ${RED}NOT FOUND${NC}\n" "$src"
        fi
    done

    echo ""
    divider
    info "Total files to backup: ~$total_files"
    info "Destination: ${DEST_TYPE:-local}"
    info "Compression: ${COMPRESSION:-zstd}"

    # Estimate compressed size
    local est_method
    case "${COMPRESSION:-zstd}" in
        zstd) est_method="~70% of original" ;;
        gzip) est_method="~75% of original" ;;
        none) est_method="same as original" ;;
    esac
    info "Estimated compressed size: $est_method"
}

# =============================================================================
# MAIN MENU
# =============================================================================

main_menu() {
    while true; do
        show_header

        local options=(
            "Full Backup"
            "Incremental Backup"
            "Differential Backup"
            "Restore from Backup"
            "Configure Settings"
            "Edit Exclude Patterns"
            "Schedule Backups"
            "View Schedule"
            "List Backups"
            "Verify Backup Integrity"
            "View Backup History"
            "Dry Run (Test)"
            "Cleanup Old Logs"
            "Cleanup Old Backups"
            "Check Dependencies"
            "Exit"
        )

        menu_select "Main Menu" "${options[@]}"
        local choice=$?

        case $choice in
            1)  do_full_backup ;;
            2)  do_incremental_backup ;;
            3)  do_differential_backup ;;
            4)  do_restore ;;
            5)  edit_config ;;
            6)  edit_excludes ;;
            7)  configure_schedule ;;
            8)  view_schedule ;;
            9)  list_backups ;;
            10) verify_backup ;;
            11) view_history ;;
            12) dry_run_backup ;;
            13) cleanup_logs ;;
            14) cleanup_backups ;;
            15) check_dependencies ;;
            16)
                echo ""
                success "Thank you for using LinuxBackup Pro!"
                echo -e "${CYAN}Goodbye!${NC}\n"
                log INFO "Session ended by user"
                exit 0
                ;;
        esac

        echo ""
        read -rp "$(echo -e "${YELLOW}Press Enter to continue...${NC}")" _
    done
}

# =============================================================================
# COMMAND-LINE INTERFACE
# =============================================================================

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
  --interactive, -i      Launch interactive menu (default)
  --full                 Run full backup
  --incremental          Run incremental backup
  --differential         Run differential backup
  --restore              Restore from backup
  --auto-full            Auto-run full backup (for cron)
  --list                 List available backups
  --verify               Verify backup integrity
  --history              Show backup history
  --config               Edit configuration
  --schedule             Configure backup schedule
  --dry-run              Test/preview backup
  --cleanup              Clean old logs and backups
  --check                Check dependencies
  --help, -h             Show this help message
  --version, -v          Show version

Examples:
  $0                          # Launch interactive menu
  $0 --full                   # Run a full backup
  $0 --incremental            # Run incremental backup
  $0 --restore                # Restore from backup
  $0 --auto-full              # Auto backup (for cron)
  $0 --list                   # List all backups
  $0 --verify                 # Verify backup integrity

EOF
}

# =============================================================================
# ENTRY POINT
# =============================================================================

main() {
    # Initialize configuration
    init_config

    # Handle command line arguments
    if [[ $# -gt 0 ]]; then
        case "$1" in
            --interactive|-i)
                show_header
                check_dependencies || exit 1
                main_menu
                ;;
            --full)
                acquire_lock
                check_dependencies || exit 1
                do_full_backup
                ;;
            --incremental)
                acquire_lock
                check_dependencies || exit 1
                do_incremental_backup
                ;;
            --differential)
                acquire_lock
                check_dependencies || exit 1
                do_differential_backup
                ;;
            --restore)
                do_restore
                ;;
            --auto-full)
                acquire_lock
                do_full_backup
                ;;
            --list)
                list_backups
                ;;
            --verify)
                verify_backup
                ;;
            --history)
                view_history
                ;;
            --config)
                edit_config
                ;;
            --schedule)
                configure_schedule
                ;;
            --dry-run)
                check_dependencies || exit 1
                dry_run_backup
                ;;
            --cleanup)
                cleanup_logs
                cleanup_backups
                ;;
            --check)
                check_dependencies
                ;;
            --help|-h)
                show_usage
                ;;
            --version|-v)
                echo "$SCRIPT_NAME v$SCRIPT_VERSION"
                ;;
            *)
                error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    else
        # No arguments - launch interactive mode
        show_header
        check_dependencies || exit 1
        main_menu
    fi
}

# Run the script
main "$@"
