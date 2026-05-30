# System Monitor Dashboard v1.0

**Real-time system monitoring with alerts and HTML reports.**

![Linux](https://img.shields.io/badge/Linux-000000?style=for-the-badge&logo=linux&logoColor=white)
![Bash](https://img.shields.io/badge/Bash-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)

## 🚀 What It Does

Comprehensive system monitoring with real-time data and alerts:

| Feature | Description |
|---------|-------------|
| **CPU Monitor** | Usage, temperature, load average |
| **Memory Monitor** | RAM & swap with visual bars |
| **Disk Monitor** | Space, inodes, I/O stats |
| **Network Monitor** | Interfaces, bandwidth, connections |
| **Process Monitor** | Top CPU/RAM consumers |
| **Service Status** | Check running services |
| **Log Viewer** | System & auth logs |
| **Alert Check** | Threshold-based alerts |
| **HTML Reports** | Export beautiful reports |
| **Continuous Mode** | Live updating dashboard |

## 📋 Requirements

- **OS:** Ubuntu, Debian, Linux Mint, Xubuntu (20.04+)
- **Root:** Requires sudo access
- **Optional:** `ifstat` for network bandwidth

## ⚡ Quick Start

```bash
# Download
git clone https://github.com/Nop4n/sysmonitor.git
cd sysmonitor

# Make executable
chmod +x install.sh

# Run with root
sudo bash install.sh
```

## 📊 Usage Examples

### Single Check
```bash
sudo bash install.sh
# Select option from menu
```

### Continuous Monitoring
```bash
sudo bash install.sh
# Select 'C' for continuous mode
```

### Generate Report
```bash
sudo bash install.sh
# Select '9' for HTML export
```

## 🎯 Alert Thresholds

| Metric | Warning | Critical |
|--------|---------|----------|
| CPU | >80% | >90% |
| RAM | >80% | >90% |
| Disk | >80% | >90% |

Alerts are logged to `/var/log/sysmonitor/alerts.log`

## 📈 HTML Reports

Reports include:
- System info (hostname, kernel, OS)
- Resource usage (CPU, RAM, Disk)
- Timestamp and uptime
- Beautiful responsive design

Saved to `/var/log/sysmonitor/report-*.html`

## 🔧 Customization

Edit `install.sh` to:
- Change alert thresholds
- Add/remove services to monitor
- Modify log retention
- Customize HTML report style

## 📁 File Locations

- **Logs:** `/var/log/sysmonitor/`
- **Data:** `/var/lib/sysmonitor/`
- **Alerts:** `/var/log/sysmonitor/alerts.log`
- **History:** `/var/lib/sysmonitor/history.csv`

## ⚠️ Important Notes

- **No data deleted** — Read-only monitoring
- **Root required** — For full system access
- **Low impact** — Minimal CPU/RAM usage
- **Safe to run** — Non-destructive operations

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Linux `/proc` filesystem for system data
- `systemctl` for service management
- Community for monitoring tips

## 📞 Support

- **Issues:** GitHub Issues
- **Email:** your.email@example.com

---

**Made with ❤️ for Linux system administrators**
