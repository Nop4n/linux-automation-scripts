# 🔒 Linux Security Hardening Script

**Professional-grade server hardening in minutes, not hours.**

![Version](https://img.shields.io/badge/version-1.0.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Platform](https://img.shields.io/badge/platform-Ubuntu%20|%20Debian%20|%20CentOS%20|%20RHEL%20|%20Fedora-orange)

---

## 📋 What's Included

A comprehensive, production-ready bash script that automates Linux server security hardening with an interactive menu system.

### Features

| Module | Description |
|--------|-------------|
| 🔐 **SSH Hardening** | Disable root login, change port, key-only auth, X11 forwarding, connection limits |
| 🔥 **Firewall Setup** | UFW, firewalld, or iptables with smart defaults |
| 🚫 **Fail2Ban** | Auto-install & configure with SSH protection and recidive jail |
| 🔄 **Auto Updates** | Automatic security patches (unattended-upgrades / dnf-automatic) |
| 📁 **File Permissions** | Harden system files, remove SUID/SGID, fix world-writable |
| ⚙️ **Service Control** | Detect & disable unnecessary services with smart heuristics |
| 🧠 **Kernel Hardening** | 40+ sysctl parameters for network, memory, and filesystem security |
| 📊 **Audit Logging** | Full auditd setup with rules for auth, sudo, SSH, cron changes |
| 📈 **Security Report** | Comprehensive system security assessment report |
| 🤖 **Full Automation** | One-click hardening of all modules |

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/linux-security.git
cd linux-security

# Make executable
chmod +x install.sh

# Run (requires root)
sudo ./install.sh
```

## 📖 Interactive Menu

```
╔══════════════════════════════════════════════════╗
║           MAIN MENU                             ║
╠══════════════════════════════════════════════════╣
║   1)  SSH Hardening                              ║
║   2)  Firewall Setup                             ║
║   3)  Fail2Ban Installation & Config             ║
║   4)  Automatic Security Updates                 ║
║   5)  File Permission Hardening                  ║
║   6)  Disable Unused Services                    ║
║   7)  Kernel Parameter Hardening (sysctl)        ║
║   8)  Audit Logging                              ║
║   9)  Generate Security Report                   ║
║   A)  Full Automated Hardening (ALL)             ║
║   R)  View Last Security Report                  ║
║   Q)  Quit                                      ║
╚══════════════════════════════════════════════════╝
```

## 🔧 Detailed Features

### SSH Hardening
- Disable direct root login
- Change SSH port (configurable)
- Enable key-only authentication
- Disable X11 forwarding
- Set connection timeouts and limits
- Generate login warning banner

### Firewall Setup
- **UFW**: Full configuration with deny-by-default
- **firewalld**: For RHEL/CentOS systems
- **iptables**: Manual rule creation with anti-brute force
- Auto-detect web server and allow HTTP/HTTPS
- Rate limiting for SSH connections

### Fail2Ban
- SSH brute force protection (3 retries, 2-hour ban)
- DDoS protection filter
- Recidive jail for repeat offenders
- Configurable ban times and thresholds

### File Permission Hardening
- Critical system files (passwd, shadow, sudoers, etc.)
- Remove world-writable permissions
- SUID/SGID binary audit
- Home directory lockdown
- Default umask configuration

### Kernel Hardening (40+ Parameters)
- Network security (ICMP redirects, source routing, SYN cookies)
- Memory protection (ASLR, dmesg restrictions, core dumps)
- TCP hardening (timestamps, keepalive, connection tracking)
- IPv6 security hardening

### Audit Logging
- Monitor authentication events
- Track user/group modifications
- Log sudo and SSH configuration changes
- Monitor cron job modifications
- Kernel module loading tracking

## 📊 Security Report Example

The script generates a comprehensive security report including:

- System information (hostname, OS, kernel, uptime)
- SSH configuration status
- Firewall rules and status
- Fail2Ban statistics (banned IPs, active jails)
- Kernel parameter values
- Audit rule count and status
- Open ports and active connections
- Recent failed login attempts

## 🛡️ Supported Platforms

| OS | Version | Status |
|----|---------|--------|
| Ubuntu | 18.04, 20.04, 22.04, 24.04 | ✅ Fully Supported |
| Debian | 9, 10, 11, 12 | ✅ Fully Supported |
| CentOS | 7, 8 | ✅ Fully Supported |
| RHEL | 7, 8, 9 | ✅ Fully Supported |
| Fedora | 30+ | ✅ Fully Supported |
| Amazon Linux | 2 | ✅ Fully Supported |

## ⚠️ Important Notes

1. **Always test in a staging environment first** before applying to production
2. **Ensure console/out-of-band access** before SSH hardening
3. **Backups are automatic** - all modified files are backed up to `/var/backups/security-hardening/`
4. **Logs are saved** to `/var/log/security-hardening/`
5. **Review the security report** after hardening

## 🔒 Security Considerations

This script follows industry best practices:

- **CIS Benchmarks** alignment
- **NIST SP 800-123** guidelines
- **STIG** (Security Technical Implementation Guide) recommendations
- **Defense in depth** approach
- **Principle of least privilege** applied

## 📝 License

MIT License - see [LICENSE](LICENSE) file.

## 🤝 Contributing

Contributions are welcome! Please read our contributing guidelines before submitting PRs.

## 📞 Support

- 🐛 Report bugs via GitHub Issues
- 📧 Email: support@example.com
- 📖 Documentation: See this README

## ⭐ Star Us

If this script helped secure your server, please give us a star on GitHub!

---

**Made with ❤️ for the Linux community**
