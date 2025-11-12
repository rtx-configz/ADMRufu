<div align="center">

# 🚀 ADMRufu SCRIPT

### Advanced VPS Management Panel for Ubuntu/Debian
### English Version - Translated & Maintained by @rtx-configz

[![Ubuntu](https://img.shields.io/badge/Ubuntu-20.04%20to%2025.10-orange?style=for-the-badge&logo=ubuntu)]()

</div>

---

## 📋 About

**ADMRufu** is a comprehensive VPS management script for Ubuntu/Debian systems. This is an English translation of the original Spanish script, providing an easy-to-use interface for managing multiple protocols and services.

### ✨ Features

- 🔐 Multi-Protocol Support (SSH, Dropbear, OpenVPN, V2Ray, Python Socks, SSL)
- 🌐 Proxy Services (Squid, BadVPN-UDP, WebSocket, SlowDNS)
- 👥 User Account Management
- 📊 Real-time System Monitoring
- 🔧 System Optimization Tools (BBR/PLUS, RAM/Cache, SWAP)
- 🎨 Customizable SSH Banners
- 🔄 Auto-update System

---

## 🚀 Installation

### One-Line Installation

```bash
rm -rf install.sh && apt update && apt upgrade -y && \
wget https://raw.githubusercontent.com/wmm-x/ADMRufu/main/install/install.sh && \
chmod +x install.sh && ./install.sh
```

### Access Menu

After installation, use any of these commands:

```bash
menu
```
```bash
adm
```
```bash
ADMRufu
```

---

## 💻 System Requirements

### Supported Systems

| OS | Versions |
|---|---|
| **Ubuntu** | 20.04, 22.04, 24.04, 25.04, 25.10 |
| **Debian** | 8, 9, 10, 11 |

### Minimum Specs
- RAM: 512 MB (1 GB recommended)
- Storage: 2 GB free
- Root access required

---

## 📦 Included Services

### Connection Protocols

- **SSH** (Port 22)
- **Dropbear** (Port 444)
- **OpenVPN** (Configurable)
- **V2Ray** (Configurable)
- **SSL/TLS** (Port 443)
- **Squid Proxy** (3128, 8080)
- **BadVPN-UDP** (7300)
- **WebSocket** (Custom)
- **SlowDNS** (53, 5300)

### Python Socks Variants

- **PPub** - Simple Python Socks
- **PPriv** - Secure Python Socks
- **PDirect** - Direct Python Socks (with local port redirect)
- **POpen** - OpenVPN Python Socks
- **PGet** - Gettunel Python Socks

---

## 🎯 Main Features

### Account Management
- Create/Delete SSH/Dropbear users
- Manage V2Ray accounts
- Monitor online users
- Set expiration dates

### System Tools
- Cache/RAM optimization
- SWAP memory configuration
- TCP optimization (BBR/BBR PLUS)
- Custom SSH banners
- SSL certificate generation
- Port management


---

## 📜 Credits

- **Original Script**: @rudi9999
- **English Translation**: @rtx-configz (2025)


## 🔄 Recent Updates (R9)

- ✅ Translated to English
- ✅ Ubuntu 25.04 & 25.10 support
- ✅ Improved Python Socks management
- ✅ Fixed service status detection
- ✅ Enhanced IP detection
- ✅ Better menu navigation
- ✅ Bug fixes and optimizations

---

## 📝 License

MIT License - Free to use and modify

---

<div align="center">

### Made with ❤️ by @rtx-configz

**English Translation - 2025**

[![GitHub](https://img.shields.io/badge/GitHub-wmm--x-181717?style=flat&logo=github)](https://github.com/rtx-configz)

</div>

