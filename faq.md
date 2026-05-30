# Frequently Asked Questions (FAQ)

**Everything you need to know about our Linux automation scripts.**

---

## 📦 General Questions

### What are these scripts?

We offer a collection of production-ready bash scripts that automate common Linux system administration tasks — optimization, security hardening, backups, Docker setup, web server configuration, and system monitoring. Instead of spending hours configuring things manually, you run one script and get professional-grade results in minutes.

### What scripts are available?

We currently offer six scripts:

1. **Linux System Optimizer** — Free up RAM & CPU, optimize swap, disable bloat services
2. **Linux Backup Pro** — Automated incremental backups with encryption and scheduling
3. **Linux Security Hardener** — Firewall, SSH hardening, fail2ban, kernel hardening, audit logging
4. **Docker Setup Pro** — One-command Docker + Compose installation with security best practices
5. **Web Server Setup** — Nginx + Let's Encrypt SSL + PHP-FPM + WordPress in one click
6. **System Monitor Dashboard** — Real-time terminal monitoring with alerts and HTML reports

### What's the difference between the free and premium versions?

The free versions on GitHub include core functionality. The premium versions (available on Gumroad) include:

- Undo/rollback scripts for every change
- Advanced configuration options
- Priority email support
- Lifetime updates
- PDF guides and documentation

---

## 💻 Technical Questions

### Which Linux distributions are supported?

Our scripts support the most popular distros:

- ✅ Ubuntu 18.04, 20.04, 22.04, 24.04
- ✅ Debian 9, 10, 11, 12
- ✅ Linux Mint
- ✅ Xubuntu / Lubuntu
- ✅ CentOS 7, 8
- ✅ RHEL 7, 8, 9
- ✅ Fedora 30+
- ✅ Amazon Linux 2
- ✅ Arch Linux (partial support)

Not every script supports every distro — check each script's README for specific compatibility. The Security Hardener has the broadest support, while Web Server Setup and Docker Setup focus on Ubuntu/Debian.

### Do I need root access?

Yes, most scripts require `sudo` access because they modify system-level configurations like kernel parameters, firewall rules, service management, and package installation. The System Monitor can run with limited permissions but needs root for full access.

### Will these scripts delete my data?

No. Our scripts modify system configurations, caches, and service settings — they do **not** delete personal files, documents, or user data. The Optimizer clears package caches and old logs, but never touches your home directory contents.

### Can I undo the changes?

Yes. The premium versions include undo/rollback scripts that reverse every change made. The free versions modify system configs that can be manually reverted, and we create backups of modified files (e.g., `/etc/resolv.conf.backup`). The Security Hardener backs up all modified files to `/var/backups/security-hardening/`.

### Do I need to restart my server after running the scripts?

For most changes, a restart is recommended but not always required. The System Optimizer's ZRAM and kernel parameter changes take effect after a reboot. The Security Hardener's SSH changes require you to reconnect. The scripts will tell you when a restart is needed.

### Are these scripts safe to run on a production server?

The scripts follow industry best practices and have been tested on 50+ servers. However, we strongly recommend:

1. **Test in a staging environment first** before applying to production
2. **Ensure you have console/out-of-band access** before running SSH hardening
3. **Take a snapshot or backup** of your server beforehand
4. **Review what each option does** before selecting it from the menu

### Can I customize the scripts?

Absolutely. Every script is a well-commented bash file you can edit. You can adjust values like swappiness levels, ZRAM percentage, services to disable, alert thresholds, backup destinations, and more. The premium versions include a configuration file (`~/.linuxbackup/config` for backups) that makes customization even easier.

### Will the scripts work on a VPS?

Yes. They work on any Linux server including VPS instances from DigitalOcean, Linode, Vultr, AWS EC2, Hetzner, and others. Just make sure you have root access and a supported distro.

### How much disk space do I need?

- **System Optimizer**: 100MB free space
- **Backup Pro**: Depends on your data size (the script itself is tiny)
- **Security Hardener**: ~50MB for packages like fail2ban and auditd
- **Docker Setup**: Minimum 5GB free space
- **Web Server Setup**: ~500MB for Nginx, PHP, and dependencies
- **System Monitor**: ~10MB

---

## 💰 Purchase & Pricing Questions

### How much do the scripts cost?

Each premium script is available individually on our [Gumroad store](https://novantovenge.gumroad.com). Check the store for current pricing — we occasionally run bundle deals and promotions.

### What payment methods do you accept?

Gumroad handles all payments and supports credit cards, debit cards, PayPal, and Apple Pay.

### Do you offer refunds?

Yes. If a script doesn't work on your system and we can't resolve the issue, we'll give you a full refund. Contact us within 7 days of purchase with your error details and we'll make it right.

### Do I get free updates?

Yes. Premium purchases include lifetime updates. When we release a new version, you'll receive a download link via email at no extra cost.

### Can I use the scripts on multiple servers?

Yes. You can deploy the scripts on as many servers as you own or manage. There's no per-server licensing — buy once, use everywhere.

### Is there a bundle deal?

We occasionally offer bundle pricing for multiple scripts. Check our Gumroad store or follow us on Twitter for announcements.

---

## 🚀 Usage Questions

### How do I install and run a script?

It's the same for every script:

```bash
# 1. Download or clone the repository
git clone https://github.com/Nop4n/linux-automation-scripts.git
cd linux-automation-scripts/<script-name>

# 2. Make it executable
chmod +x install.sh

# 3. Run with root privileges
sudo ./install.sh
```

The script will present an interactive menu where you select what you want to do.

### I bought the premium version — how do I install it?

1. Download the `.zip` file from your Gumroad purchase email
2. Extract it: `unzip linux-optimizer-v1.0.zip`
3. Enter the directory: `cd linux-optimizer`
4. Make it executable: `chmod +x install.sh`
5. Run it: `sudo bash install.sh`

### How do I run the scripts non-interactively?

The Backup Pro script supports full CLI mode:

```bash
./install.sh --full              # Full backup
./install.sh --incremental       # Incremental backup
./install.sh --restore           # Restore from backup
./install.sh --list              # List all backups
./install.sh --schedule          # Set up cron scheduling
```

Other scripts are menu-driven. If you need headless/automated operation, check the script source — many options can be triggered via command-line flags.

### How do I set up automated backups?

Use the scheduling feature in Linux Backup Pro:

```bash
./install.sh --schedule
```

Or manually add a cron job:

```bash
# Daily full backup at 2:00 AM
0 2 * * * /path/to/install.sh --auto-full
```

The script supports local, external drive, and remote (SSH/rsync) backup destinations.

### Can I run the System Monitor in continuous mode?

Yes. Run the script and select **'C'** for continuous mode. It refreshes the dashboard in real-time with CPU, RAM, disk, and network stats. Press `Ctrl+C` to exit.

### How do I generate a security report?

Run the Security Hardener and select option **9** from the menu. It generates a comprehensive report covering SSH config, firewall rules, fail2ban status, kernel parameters, open ports, and recent failed logins.

---

## 🔧 Troubleshooting

### I get "Permission denied" when running the script

Run with `sudo`:

```bash
sudo ./install.sh
```

If you're already using sudo, make sure the script is executable:

```bash
chmod +x install.sh
```

### The script says "command not found"

Install the missing dependency. The scripts auto-install most things, but if something's missing:

```bash
# Debian/Ubuntu
sudo apt update && sudo apt install <package-name>

# CentOS/RHEL
sudo yum install <package-name>
```

### Docker commands don't work after installing

Log out and back in, or run:

```bash
newgrp docker
```

This applies the docker group membership without requiring a full logout.

### I locked myself out after SSH hardening

This is why we recommend having console access before running SSH hardening. If you're on a VPS, use your provider's web console (DigitalOcean Droplet Console, AWS EC2 Instance Connect, etc.) to access the server and revert the SSH changes.

Backup location: `/var/backups/security-hardening/`

### A port is already in use

Check what's using the port:

```bash
sudo ss -tlnp | grep :PORT_NUMBER
```

Stop the conflicting service:

```bash
sudo systemctl stop SERVICE_NAME
```

### Backup to remote server fails

Test your SSH connection first:

```bash
ssh -p 22 user@backup-server

# If that works, test rsync:
rsync -avz /testdir user@backup-server:/testdest/
```

Make sure your SSH key is set up and the remote directory exists.

### Email notifications aren't working

Install the mail utility:

```bash
# Debian/Ubuntu
sudo apt install mailutils

# CentOS/RHEL
sudo yum install mailx
```

Test it:

```bash
echo "Test" | mail -s "Test Email" your@email.com
```

### The script seems stuck or frozen

Some operations (like SSL certificate generation or package installation) take time. If it's been more than 5 minutes with no output, press `Ctrl+C` and check the logs:

- **Backup Pro**: `~/.linuxbackup/logs/`
- **Security Hardener**: `/var/log/security-hardening/`
- **Docker Setup**: `/var/log/docker-setup-*.log`

### I ran the Optimizer and my system feels slower

This is rare, but if it happens:

1. Reboot the system — some changes need a restart to take full effect
2. If still slow, use the undo script (premium) to revert changes
3. The ZRAM compression can temporarily increase CPU usage during heavy swap activity — this normalizes after a few minutes

### How do I check if the scripts actually worked?

- **Optimizer**: Run `free -h` to check RAM usage, `swapon --show` for ZRAM
- **Security**: Run `sudo ufw status` for firewall, `sudo fail2ban-client status` for fail2ban
- **Docker**: Run `docker info` and `docker ps` to verify installation
- **Web Server**: Visit your domain in a browser, check for the SSL padlock
- **Monitor**: Generate an HTML report from the menu

---

## 📞 Support

### How do I get help?

- **Free users**: Open an issue on GitHub
- **Premium users**: Email us directly — we respond within 24 hours
- **Everyone**: Check the README in each script's folder for detailed documentation

### I found a bug — what do I do?

Open a GitHub issue with:
1. Your distro and version (`lsb_release -a`)
2. The script name and version
3. The exact error message
4. Steps to reproduce

### Can I request a feature?

Yes! We love feature requests. Open a GitHub issue with the "enhancement" label and describe what you'd like. Premium users get priority on feature development.

### Do you offer custom scripting or consulting?

Yes. If you need a custom automation script, server setup, or security audit beyond what our standard scripts offer, reach out via email for a quote.

---

## 🔗 Quick Links

- **Gumroad Store**: [novantovenge.gumroad.com](https://novantovenge.gumroad.com)
- **Twitter**: [@Nopan____](https://twitter.com/Nopan____)
- **GitHub**: [Nop4n/linux-automation-scripts](https://github.com/Nop4n/linux-automation-scripts)

---

*Last updated: May 2026*
