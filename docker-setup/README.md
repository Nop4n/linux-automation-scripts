# 🐳 Docker Setup Pro

**Professional Docker Installation & Management Script for Ubuntu/Debian**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)](https://github.com/yourusername/docker-setup-pro)

---

## 📋 Overview

Docker Setup Pro is a production-grade, interactive bash script that automates the complete Docker ecosystem setup on Ubuntu/Debian systems. Perfect for sysadmins, DevOps engineers, and developers who want a hassle-free Docker installation with security best practices built-in.

## 🎯 Features

| Feature | Description |
|---------|-------------|
| **Interactive Menu** | Beautiful colored terminal interface with easy navigation |
| **Docker CE Installation** | Full Docker Community Edition setup with official repos |
| **Docker Compose** | Both plugin and standalone installation |
| **User Group Setup** | Automatic docker group configuration |
| **Daemon Configuration** | Log drivers, storage drivers, registry mirrors |
| **Common Containers** | Portainer, Nginx Proxy Manager, Watchtower |
| **Network Management** | Create, list, inspect, and remove Docker networks |
| **Volume Management** | Full volume lifecycle management |
| **Container Backup** | Complete backup and restore functionality |
| **Security Hardening** | Industry best practices applied automatically |

## 🚀 Quick Start

### One-Line Install

```bash
curl -fsSL https://raw.githubusercontent.com/yourusername/docker-setup-pro/main/install.sh | sudo bash
```

### Manual Install

```bash
# Clone the repository
git clone https://github.com/yourusername/docker-setup-pro.git

# Navigate to directory
cd docker-setup-pro

# Make executable
chmod +x install.sh

# Run with root privileges
sudo ./install.sh
```

## 📖 Usage Guide

### Main Menu Options

| Option | Description |
|--------|-------------|
| `1` | Install Docker CE |
| `2` | Install Docker Compose |
| `3` | Setup Docker User Group |
| `4` | Configure Docker Daemon |
| `5` | Deploy Common Containers |
| `6` | Docker Network Management |
| `7` | Docker Volume Management |
| `8` | Backup Docker Containers |
| `9` | Apply Security Best Practices |
| `10` | Full Setup (Install Everything) |
| `11` | System Diagnostics |
| `0` | Exit |

### Example Workflows

#### Fresh Server Setup
```bash
# Run the script
sudo ./install.sh

# Select option 10 for full setup
# Follow the interactive prompts
# Log out and back in for user group changes
```

#### Just Install Docker
```bash
sudo ./install.sh
# Select option 1
```

#### Deploy Management Tools
```bash
sudo ./install.sh
# Select option 5
# Choose Portainer, Nginx Proxy Manager, Watchtower
```

#### Backup Containers
```bash
sudo ./install.sh
# Select option 8
# Choose backup type (all/specific/volumes)
```

## 🏗️ What Gets Installed

### Docker Components
- Docker CE (latest stable)
- Docker CLI
- Containerd
- Docker Buildx
- Docker Compose (plugin + standalone)

### Common Containers (Optional)
- **Portainer CE** - Web-based Docker management UI (port 9000)
- **Nginx Proxy Manager** - Reverse proxy with SSL (ports 80, 81, 443)
- **Watchtower** - Automatic container updates

### Pre-configured Networks
- `proxy_net` - For reverse proxies (172.20.0.0/16)
- `app_net` - For applications (172.21.0.0/16)
- `db_net` - For databases (172.22.0.0/16)
- `monitoring_net` - For monitoring tools (172.23.0.0/16)

## 🔒 Security Features

- ✅ Docker Content Trust enabled
- ✅ No-new-privileges flag
- ✅ Live-restore enabled
- ✅ Userland proxy disabled
- ✅ BuildKit enabled
- ✅ Log rotation configured
- ✅ Custom address pools
- ✅ Socket permissions hardened

## ⚙️ Daemon Configuration

The script configures `/etc/docker/daemon.json` with:

```json
{
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "50m",
        "max-file": "5"
    },
    "storage-driver": "overlay2",
    "live-restore": true,
    "userland-proxy": false,
    "no-new-privileges": true,
    "default-address-pools": [
        {"base": "172.80.0.0/16", "size": 24},
        {"base": "172.88.0.0/16", "size": 24}
    ],
    "features": {"buildkit": true},
    "debug": false
}
```

## 📦 Backup System

### Backup Locations
- Default: `/opt/docker-backups/`
- Format: `container-name-YYYYMMDD-HHMMSS/`

### Backup Contents
- Container export (`.tar.gz`)
- Container configuration (`.json`)
- Volume data (`.tar.gz`)

### Backup Commands
```bash
# Backup all running containers
sudo ./install.sh
# Select option 8 → 1

# Backup specific container
sudo ./install.sh
# Select option 8 → 2

# Backup all volumes
sudo ./install.sh
# Select option 8 → 3
```

## 🖥️ System Requirements

- **OS**: Ubuntu 18.04+ or Debian 10+
- **Disk**: Minimum 5GB free space
- **RAM**: 1GB minimum (2GB+ recommended)
- **Root**: Required (sudo access)
- **Network**: Internet connection for downloads

## 🐛 Troubleshooting

### Common Issues

**Permission denied**
```bash
# Make sure to run with sudo
sudo ./install.sh
```

**Docker command not found after install**
```bash
# Log out and back in, or run:
newgrp docker
```

**Port already in use**
```bash
# Check what's using the port
sudo ss -tlnp | grep :PORT

# Stop the conflicting service
sudo systemctl stop SERVICE_NAME
```

**Container won't start**
```bash
# Check container logs
docker logs CONTAINER_NAME

# Check container status
docker ps -a
```

## 📝 Logs

All operations are logged to:
```
/var/log/docker-setup-YYYYMMDD-HHMMSS.log
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Docker documentation for best practices
- Docker Bench Security for security recommendations
- The open-source community for inspiration

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/docker-setup-pro/issues)
- **Documentation**: [Wiki](https://github.com/yourusername/docker-setup-pro/wiki)
- **Email**: your.email@example.com

## ⭐ Star Us

If you find this tool useful, please give us a star on GitHub! It helps others discover the project.

---

**Made with ❤️ for the Docker community**
