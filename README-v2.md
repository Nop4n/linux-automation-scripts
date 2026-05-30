<!-- Banner image placeholder -->
<p align="center">
  <img src="docs/banner.png" alt="Linux Automation Scripts" width="100%">
</p>

<h1 align="center">🐧 Linux Automation Scripts</h1>

<p align="center">
  <strong>Stop wasting hours on server setup. Automate it in seconds.</strong>
</p>

<p align="center">
  <a href="https://github.com/Nop4n/linux-automation-scripts/stargazers"><img src="https://img.shields.io/github/stars/Nop4n/linux-automation-scripts?style=flat-square&logo=github" alt="Stars"></a>
  <a href="https://github.com/Nop4n/linux-automation-scripts/network/members"><img src="https://img.shields.io/github/forks/Nop4n/linux-automation-scripts?style=flat-square&logo=github" alt="Forks"></a>
  <a href="https://github.com/Nop4n/linux-automation-scripts/issues"><img src="https://img.shields.io/github/issues/Nop4n/linux-automation-scripts?style=flat-square&logo=github" alt="Issues"></a>
  <a href="https://github.com/Nop4n/linux-automation-scripts/blob/main/LICENSE"><img src="https://img.shields.io/github/license/Nop4n/linux-automation-scripts?style=flat-square" alt="License"></a>
  <img src="https://img.shields.io/badge/platform-Linux-blueviolet?style=flat-square&logo=linux" alt="Linux">
</p>

---

## 🤔 Why This Exists

A few years ago, I was a sysadmin managing a handful of VPS instances. Every time I spun up a new server, I'd spend **2-3 hours** running the same commands: hardening SSH, configuring firewalls, setting up backups, tuning kernel parameters... Copy-pasting from my notes, Googling the same StackOverflow answers, forgetting one step and having to redo it.

One night at 2 AM, after a server got compromised because I forgot to disable password authentication on SSH, I snapped. I wrote a script to harden it. Then another to automate backups. Then one to optimize performance. Before I knew it, I had a toolkit that turned **hours of work into minutes**.

These scripts are the result of **3+ years of real-world production use** on 50+ servers. They're battle-tested, idempotent, and designed so you don't have to learn the hard way like I did.

**💰 Want the full premium versions with rollback support, advanced options, and priority support? [Get them on Gumroad →](https://novantovenge.gumroad.com)**

---

## 🎬 See It In Action

<!-- Replace these placeholders with actual screenshots/GIFs -->

<p align="center">
  <img src="docs/demo-optimizer.gif" alt="System Optimizer Demo" width="45%">
  &nbsp;&nbsp;
  <img src="docs/demo-monitor.gif" alt="System Monitor Dashboard" width="45%">
</p>

<p align="center">
  <em>Left: Linux Optimizer freeing up resources &nbsp;|&nbsp; Right: Real-time system monitoring dashboard</em>
</p>

<!-- Additional screenshot row -->
<!-- 
<p align="center">
  <img src="docs/demo-security.png" alt="Security Hardener" width="45%">
  &nbsp;&nbsp;
  <img src="docs/demo-backup.png" alt="Backup Script" width="45%">
</p>
-->

---

## ⚡ Quick Start (30 Seconds)

```bash
# 1. Clone the repo
git clone https://github.com/Nop4n/linux-automation-scripts.git && cd linux-automation-scripts

# 2. Pick a script and run it — that's it!
sudo ./linux-optimizer/install.sh     # Optimize system performance
sudo ./linux-security/install.sh      # Harden your server
sudo ./linux-backup/install.sh        # Set up automated backups
sudo ./docker-setup/install.sh        # Install Docker + Compose
sudo ./webserver-setup/install.sh     # Nginx/Apache with SSL
sudo ./sysmonitor/install.sh          # Terminal monitoring dashboard
```

> **That's it.** No config files to edit. No dependencies to install first. Just clone and run.

---

## 🚀 Scripts Included

| # | Script | What It Does | Get Started |
|---|--------|-------------|-------------|
| 1 | **[Linux Optimizer](./linux-optimizer/)** | Free RAM & CPU, disable bloat, tweak kernel params | `sudo ./linux-optimizer/install.sh` |
| 2 | **[Linux Backup](./linux-backup/)** | AES-256 encrypted incremental backups with cron | `sudo ./linux-backup/install.sh` |
| 3 | **[Security Hardener](./linux-security/)** | Firewall, SSH hardening, fail2ban, auto-updates | `sudo ./linux-security/install.sh` |
| 4 | **[Docker Setup](./docker-setup/)** | One-command Docker + Compose with production defaults | `sudo ./docker-setup/install.sh` |
| 5 | **[Web Server Setup](./webserver-setup/)** | Nginx/Apache + Let's Encrypt SSL + PHP-FPM | `sudo ./webserver-setup/install.sh` |
| 6 | **[System Monitor](./sysmonitor/)** | Beautiful terminal dashboard for real-time monitoring | `sudo ./sysmonitor/install.sh` |

---

## 📋 Free vs Premium

| Feature | Free (this repo) | [Premium (Gumroad)](https://novantovenge.gumroad.com) |
|---------|:----------------:|:-----------------------------------------------------:|
| Core functionality | ✅ | ✅ |
| Basic documentation | ✅ | ✅ |
| **Undo/rollback script** | ❌ | ✅ |
| **Advanced options** | ❌ | ✅ |
| **Priority email support** | ❌ | ✅ |
| **Lifetime updates** | ❌ | ✅ |
| **PDF setup guides** | ❌ | ✅ |

> 🔓 **Premium users** get the ability to **safely undo every change** — critical for production servers.

---

## 🛠️ Compatibility

<p align="center">
  <img src="https://img.shields.io/badge/Ubuntu-✅-brightgreen?style=flat-square&logo=ubuntu" alt="Ubuntu">
  <img src="https://img.shields.io/badge/Debian-✅-brightgreen?style=flat-square&logo=debian" alt="Debian">
  <img src="https://img.shields.io/badge/CentOS-✅-brightgreen?style=flat-square&logo=centos" alt="CentOS">
  <img src="https://img.shields.io/badge/RHEL-✅-brightgreen?style=flat-square&logo=redhat" alt="RHEL">
  <img src="https://img.shields.io/badge/Fedora-✅-brightgreen?style=flat-square&logo=fedora" alt="Fedora">
  <img src="https://img.shields.io/badge/Arch-✅-brightgreen?style=flat-square&logo=archlinux" alt="Arch">
</p>

**Tested on:** DigitalOcean · Linode · Vultr · AWS EC2 · Bare Metal · Raspberry Pi

---

## 🤝 Contributing

Contributions are welcome! Whether it's a bug fix, new script, or improved documentation — every PR helps.

1. **Fork** this repo
2. **Create** a feature branch: `git checkout -b feature/your-feature`
3. **Commit** your changes: `git commit -m "Add your feature"`
4. **Push** to your branch: `git push origin feature/your-feature`
5. **Open** a Pull Request

### Guidelines
- Test your scripts on at least Ubuntu and one other distro
- Follow the existing script structure (install.sh entrypoint)
- Add a README.md for any new script
- Keep scripts idempotent (safe to run multiple times)

**Found a bug?** [Open an issue](https://github.com/Nop4n/linux-automation-scripts/issues/new) — I read every one.

---

## 💡 Why Trust These Scripts?

- ✅ **Battle-tested** — Used on 50+ production servers
- 🔒 **Safe** — Undo scripts included (premium), idempotent by design
- ⚡ **Fast** — Optimized for minimal downtime
- 📖 **Documented** — Clear README for every script
- 🆘 **Supported** — Priority email support for premium users
- 🔄 **Maintained** — Regular updates for new distro releases

---

## 🔗 Links

- 🛒 **[Get Premium Scripts on Gumroad →](https://novantovenge.gumroad.com)**
- 🐦 **[Follow me on Twitter @Nopan____](https://twitter.com/Nopan____)**

---

## 📄 License

MIT License — Free for personal and commercial use. See [LICENSE](./LICENSE).

---

<p align="center">
  <strong>⭐ If this saved you time, star the repo — it helps others find it!</strong>
</p>

<p align="center">
  <a href="https://github.com/Nop4n/linux-automation-scripts/stargazers">⭐ Star</a> ·
  <a href="https://github.com/Nop4n/linux-automation-scripts/fork">🍴 Fork</a> ·
  <a href="https://github.com/Nop4n/linux-automation-scripts/issues">🐛 Report Bug</a> ·
  <a href="https://novantovenge.gumroad.com">💰 Get Premium</a>
</p>
