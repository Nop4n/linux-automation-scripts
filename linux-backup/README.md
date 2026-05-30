# 🐧 LinuxBackup Pro

**Professional Linux Backup Solution v2.0.0**

A production-quality, menu-driven backup script for Linux systems with support for full, incremental, and differential backups, remote destinations, compression, scheduling, email notifications, and more.

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 🔄 **Backup Types** | Full, incremental, and differential backups |
| 📁 **Destinations** | Local disk, external drive, remote (SSH/rsync) |
| 🗜️ **Compression** | gzip, zstd, or no compression |
| ⏰ **Scheduling** | Cron-based scheduling with presets |
| 🔧 **Restore** | One-click restore from any backup |
| 📧 **Notifications** | Email alerts on success/failure |
| 📊 **Logging** | Detailed logs with automatic rotation |
| 🚫 **Excludes** | Configurable exclude patterns |
| 🖥️ **Interactive** | Beautiful colored menu interface |
| 🖧 **CLI** | Full command-line interface for automation |
| 🔒 **Safety** | Lock files, error handling, verification |
| 🧹 **Cleanup** | Automatic old backup/log management |

---

## 🚀 Quick Start

### Installation

```bash
# Clone or download the script
git clone https://github.com/yourusername/linuxbackup-pro.git
cd linuxbackup-pro

# Make it executable
chmod +x install.sh

# Launch the interactive menu
./install.sh

# Or run as root for system-wide backups
sudo ./install.sh
```

### First-Time Setup

```bash
# Launch the installer
./install.sh

# 1. Select "Configure Settings" from the menu
# 2. Set your backup destination and source directories
# 3. Configure email notifications (optional)
# 4. Edit exclude patterns if needed
# 5. Set up a backup schedule
# 6. Run your first backup!
```

---

## 📋 Command-Line Usage

LinuxBackup Pro supports both interactive and command-line modes:

```bash
# Interactive menu (default)
./install.sh

# Full backup
./install.sh --full

# Incremental backup
./install.sh --incremental

# Differential backup
./install.sh --differential

# Restore from backup
./install.sh --restore

# List all backups
./install.sh --list

# Verify backup integrity
./install.sh --verify

# View backup history
./install.sh --history

# Configure settings
./install.sh --config

# Set up scheduling
./install.sh --schedule

# Dry run (preview what would be backed up)
./install.sh --dry-run

# Clean old logs and backups
./install.sh --cleanup

# Check system dependencies
./install.sh --check

# Show version
./install.sh --version

# Show help
./install.sh --help
```

---

## 🔧 Configuration

The configuration file is located at `~/.linuxbackup/config`:

```bash
# Backup destination type: local, external, remote
DEST_TYPE="local"

# Local/External backup directory
BACKUP_DIR="/backup"

# Remote SSH settings
REMOTE_HOST="backup-server.example.com"
REMOTE_USER="backupuser"
REMOTE_PATH="/backups"
REMOTE_SSH_KEY="/home/user/.ssh/id_rsa"
REMOTE_SSH_PORT=22

# Compression: none, gzip, zstd
COMPRESSION="zstd"

# Source directories to back up (space-separated)
SOURCE_DIRS="/home /etc /var/log"

# Exclude patterns file
EXCLUDE_FILE="~/.linuxbackup/excludes.txt"

# Email notifications
EMAIL_ENABLED="false"
EMAIL_TO="admin@example.com"

# Log retention (days)
LOG_RETENTION_DAYS=30
```

### Exclude Patterns

Edit `~/.linuxbackup/excludes.txt` to customize exclusions:

```
# System directories
/proc
/sys
/dev
/run
/tmp

# Cache directories
*/.cache
*/node_modules
*/__pycache__

# Temporary files
*.swp
*.swo
*~
```

---

## 🖥️ Remote Backup Setup

### SSH Configuration

```bash
# 1. Generate SSH key (if needed)
ssh-keygen -t ed25519 -f ~/.ssh/backup_key

# 2. Copy key to remote server
ssh-copy-id -i ~/.ssh/backup_key user@backup-server

# 3. Test SSH connection
ssh -i ~/.ssh/backup_key user@backup-server

# 4. Configure in LinuxBackup Pro
# Set DEST_TYPE="remote" and configure SSH settings
```

### rsync over SSH

LinuxBackup Pro uses rsync under the hood for efficient transfers:
- Only changed files are transferred (delta sync)
- Supports resume of interrupted transfers
- Preserves permissions and timestamps

---

## ⏰ Scheduling

Set up automated backups via the menu or crontab:

```bash
# Example crontab entries (managed by LinuxBackup Pro):

# Daily full backup at 2:00 AM
0 2 * * * /path/to/install.sh --auto-full

# Weekly backup on Sundays at 3:00 AM
0 3 * * 0 /path/to/install.sh --auto-full

# Custom: Every 6 hours
0 */6 * * * /path/to/install.sh --auto-full
```

---

## 📧 Email Notifications

Enable email notifications for backup alerts:

```bash
# Install mail utility (Debian/Ubuntu)
sudo apt install mailutils

# Install mail utility (CentOS/RHEL)
sudo yum install mailx

# Configure in LinuxBackup Pro settings
EMAIL_ENABLED="true"
EMAIL_TO="admin@example.com"
```

You'll receive emails for:
- ✅ Successful backups
- ❌ Failed backups
- ⚠️ Warnings
- ✅ Successful restores

---

## 🛡️ Safety Features

- **Lock files**: Prevents concurrent backup operations
- **Error handling**: Graceful error recovery throughout
- **Verification**: Built-in backup integrity checking
- **Logging**: All operations are logged for auditing
- **Root detection**: Warns when root access is needed

---

## 📁 Directory Structure

```
~/.linuxbackup/
├── config                  # Main configuration file
├── excludes.txt           # Exclude patterns
├── data/
│   └── backup_history.log # Backup history
├── logs/
│   └── backup_*.log       # Daily log files
└── locks/
    └── backup.lock        # Process lock file
```

---

## 🔄 Backup Types Explained

### Full Backup
- **What**: Complete copy of all source directories
- **Pros**: Fast restore, self-contained
- **Cons**: Takes more space and time
- **Use**: Base backup, periodic full backups

### Incremental Backup
- **What**: Only files changed since the last backup
- **Pros**: Fast, space-efficient
- **Cons**: Restore requires full + all incrementals
- **Use**: Daily backups

### Differential Backup
- **What**: Files changed since the last full backup
- **Pros**: Faster restore than incremental
- **Cons**: Larger than incremental, smaller than full
- **Use**: Weekly backups between full backups

---

## 📦 Requirements

### Required
- Bash 4.0+
- rsync
- tar
- find
- date

### Optional
- zstd (for zstd compression)
- gzip (for gzip compression)
- mail/mailx (for email notifications)
- ssh (for remote backups)
- bc (for size calculations)

---

## 🐛 Troubleshooting

### "Permission denied" error
```bash
# Run with sudo for system directories
sudo ./install.sh
```

### "No space left on device"
```bash
# Clean old backups
./install.sh --cleanup

# Check available space
df -h /backup
```

### Remote backup fails
```bash
# Test SSH connection
ssh -p 22 user@host

# Test rsync
rsync -avz /testdir user@host:/testdest/
```

### Email not sending
```bash
# Install mail utility
sudo apt install mailutils

# Test email
echo "Test" | mail -s "Test" user@example.com
```

---

## 📄 License

MIT License - See [LICENSE](LICENSE) for details.

---

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

---

## 📞 Support

- **Issues**: GitHub Issues
- **Email**: support@example.com

---

## 🙏 Credits

Built with ❤️ for the Linux community.

```bash
# Remember: The best backup is the one you actually make! 🐧
```
