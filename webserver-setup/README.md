# 🚀 WebServer Setup Pro

**Professional Nginx + SSL Server Setup Script**

A production-ready, one-command web server setup for Ubuntu/Debian. Install Nginx, PHP-FPM, MySQL/MariaDB, Let's Encrypt SSL, and WordPress — all with a beautiful interactive menu.

---

## ⚡ Features

| Feature | Description |
|---------|-------------|
| 🖥️ **Interactive Menu** | Colored, user-friendly CLI interface |
| 🔧 **Nginx Setup** | Full installation & performance optimization |
| 🔒 **SSL Certificates** | Auto-setup with Let's Encrypt (certbot) |
| 🌐 **Virtual Hosts** | Add, remove, and list virtual hosts |
| 🐘 **PHP-FPM** | PHP 8.x with-FPM configuration |
| 🗄️ **MySQL/MariaDB** | Database server installation |
| 📝 **WordPress** | One-click WordPress installation |
| 🔄 **Reverse Proxy** | Configure Nginx as reverse proxy |
| 🛡️ **Security Headers** | Production-grade security configuration |
| ⚡ **Performance** | Caching, Gzip, Brotli compression |

## 📋 Requirements

- **OS**: Ubuntu 20.04+ / Debian 11+
- **Privileges**: Root access (sudo)
- **Dependencies**: curl, wget (installed automatically)

## 🛠️ Installation

```bash
# Download or clone the repository
git clone https://github.com/yourusername/webserver-setup.git
cd webserver-setup

# Make executable
chmod +x install.sh

# Run as root
sudo ./install.sh
```

## 📖 Usage

After running the script, you'll see a menu:

```
╔═══════════════════════════════════════════════════════════════╗
║            WebServer Setup Pro - Main Menu                   ║
╠═══════════════════════════════════════════════════════════════╣
║  1. Install Nginx                                           ║
║  2. Install PHP-FPM                                        ║
║  3. Install MySQL/MariaDB                                  ║
║  4. Setup Let's Encrypt SSL                                ║
║  5. Manage Virtual Hosts                                   ║
║  6. Install WordPress                                      ║
║  7. Configure Reverse Proxy                                ║
║  8. Apply Security Headers                                 ║
║  9. Optimize Performance                                   ║
║  0. Exit                                                   ║
╚═══════════════════════════════════════════════════════════════╝
```

## 🔐 Security Features

- **Security Headers**: X-Frame-Options, X-Content-Type-Options, CSP, HSTS
- **Rate Limiting**: Protect against brute-force attacks
- **SSL Hardening**: TLS 1.2/1.3 only, strong ciphers
- **Firewall**: UFW configuration with recommended rules

## ⚡ Performance Optimizations

- **Gzip/Brotli Compression**: Reduce bandwidth by 60-80%
- **Browser Caching**: Optimize static asset delivery
- **FastCGI Cache**: Server-side page caching
- **Connection Tuning**: Optimized worker processes and connections

## 📁 Project Structure

```
webserver-setup/
├── install.sh          # Main installation script
├── README.md           # Documentation
├── LICENSE             # MIT License
└── configs/            # Generated during installation
    ├── nginx/          # Nginx configurations
    ├── php/            # PHP-FPM configs
    └── ssl/            # SSL certificates
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 💬 Support

- 📧 Email: support@example.com
- 🐛 Issues: [GitHub Issues](https://github.com/yourusername/webserver-setup/issues)

---

**Made with ❤️ by WebServer Setup Pro**
