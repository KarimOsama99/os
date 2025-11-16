# 🐺 WOLF OS - The Ultimate Linux Experience

<div align="center">

![WOLF OS Banner](wolf-backgrounds/wolf-desktop.jpg)

**Transform your Debian/Ubuntu into a powerful, beautiful, and customized system**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Debian](https://img.shields.io/badge/Debian-13-red.svg)](https://www.debian.org/)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04+-orange.svg)](https://ubuntu.com/)

Made with ❤️ by **k4rim0sama**

</div>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [What Gets Installed](#-what-gets-installed)
- [Prerequisites](#-prerequisites)
- [Installation](#-installation)
- [Project Structure](#-project-structure)
- [Customization](#-customization)
- [Screenshots](#-screenshots)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🌟 Overview

**WOLF OS** is an automated setup script that transforms a fresh Debian or Ubuntu installation into a fully customized, themed, and feature-rich Linux system. It works with any existing desktop environment and adds beautiful themes, essential applications, security tools, and custom wallpapers.

### Key Highlights

- 🎨 **Beautiful Themes**: Catppuccin GTK/Qt themes with Bibata cursors
- 🖼️ **Custom Wallpapers**: WOLF-branded wallpapers for desktop, GRUB, and Plymouth
- 🔧 **Essential Tools**: Browsers, IDEs, media players, and productivity apps
- 🛡️ **Security Suite**: Optional penetration testing and security tools
- 🌐 **Multi-Language**: Full Arabic and English font support
- ⚡ **Fast Setup**: Automated installation with minimal user interaction

---

## ✨ Features

### 🎨 Theming & Customization
- **Catppuccin Theme**: Modern, soothing pastel theme for GTK and Qt applications
- **Bibata Cursors**: Smooth, modern cursor theme with multiple styles
- **Custom GRUB Theme**: Branded bootloader with WOLF wallpaper
- **Plymouth Boot Screen**: Beautiful boot animation with custom graphics
- **WOLF Wallpapers**: Collection of high-quality wallpapers

### 📦 Applications
- **Browsers**: Firefox (official repo), Brave, Chromium
- **Development**: VS Code, Node.js (via nvm), Python3, Golang, Git tools
- **Media**: VLC, Spotify, Audacious, MPV
- **Office**: LibreOffice with Arabic support
- **Communication**: Discord, AnyDesk
- **System Tools**: GParted, Btop, Wireshark, Timeshift

### 🛡️ Security Tools (Optional)
- **Network Scanning**: Nmap, Netcat, Subfinder, Httpx
- **Web Testing**: SQLMap, WPScan, Nikto, Ffuf, Gobuster, Nuclei
- **Wireless**: Aircrack-ng, Bully, Reaver, Airgeddon
- **Password Cracking**: Hydra, John the Ripper, CrackMapExec
- **Exploitation**: Metasploit, ExploitDB, Social Engineer Toolkit
- **Post-Exploitation**: Empire, Starkiller
- **Privilege Escalation**: PEASS-ng (LinPEAS/WinPEAS)
- **And much more...** (30+ security tools)

### 🔤 Fonts & Languages
- **Noto Fonts**: Arabic and English support
- **JetBrainsMono Nerd Font**: Programming font with icons
- **Font Awesome**: Icon font for system integration

### 🎯 Shell Enhancements
- **Oh My Zsh**: Powerful shell framework with plugins
- **Starship Prompt**: Fast, customizable shell prompt
- **FZF**: Fuzzy finder for command history
- **Eza**: Modern replacement for ls with colors and icons
- **Custom Banner**: "WOLF OS" ASCII art on terminal startup

---

## 📦 What Gets Installed

<details>
<summary><b>Click to expand full installation list</b></summary>

### System & Base
- System updates and essential tools
- Development libraries and dependencies
- Compression tools (zip, unzip, 7zip, rar)

### Desktop Themes
- Catppuccin GTK theme (all flavors)
- Catppuccin Qt/Kvantum theme
- Bibata cursor theme (Modern & Original)
- Papirus icon theme
- Custom WOLF wallpapers

### Browsers & Internet
- Firefox (official Mozilla repository)
- Brave Browser
- Tor Browser (manual installation guide)

### Development Tools
- Visual Studio Code
- Node.js 24 (via nvm with auto-load)
- Python 3 + pip + pipx + venv
- Golang (latest version)
- Ruby (for gems)
- Git + Git tools

### Media & Entertainment
- VLC Media Player
- Spotify
- Audacious
- MPV
- Imv (image viewer)
- FFmpeg

### Productivity
- LibreOffice (with Arabic language pack)
- Thunar file manager
- Mousepad/Leafpad text editor
- Document viewers (Evince, Atril)

### System Utilities
- GParted (partition manager)
- Btop (system monitor)
- Wireshark (network analyzer)
- OpenVPN
- Proxychains-ng
- Macchanger

### Communication
- Discord
- AnyDesk

### Security Tools (Optional)
See [Security Tools](#️-security-tools-optional) section above

</details>

---

## 🔧 Prerequisites

### System Requirements

- **OS**: Debian 12+ or Ubuntu 22.04+ (with existing Desktop Environment)
- **RAM**: 4GB minimum (8GB recommended)
- **Storage**: 20GB free space minimum
- **Internet**: Active internet connection
- **User**: sudo/root privileges

### Supported Desktop Environments

- ✅ GNOME
- ✅ KDE Plasma
- ✅ XFCE
- ✅ MATE
- ✅ Cinnamon
- ✅ Any other DE (basic support)

---

## 🚀 Installation

### Quick Start
```bash
# 1. Clone the repository
git clone https://github.com/k4rim0sama/wolf-os.git
cd wolf-os

# 2. Make scripts executable
chmod +x run.sh
chmod +x scripts/*.sh

# 3. Run the installer
./run.sh
```

### Installation Modes

#### 🖱️ Manual Mode (Default)
Asks for confirmation before running each script:
```bash
./run.sh
# or
./run.sh --manual
```

#### 🤖 Auto Mode
Automatically installs everything with default settings:
```bash
./run.sh --auto
# or
./run.sh --yes
```

#### ⚙️ Custom Installation
Skip specific components:
```bash
# Skip security tools
./run.sh --skip installSecurityTools.sh

# Skip multiple components
./run.sh --auto --skip installSecurityTools.sh --skip installApps.sh
```

#### ❓ Help
```bash
./run.sh --help
```

---

## 📁 Project Structure
```
wolf-os/
├── run.sh                          # Main installation script
├── scripts/                        # Individual installation scripts
│   ├── systemUpdate.sh            # System update & base tools
│   ├── installWallpapers.sh       # WOLF wallpaper installation
│   ├── installFirefox.sh          # Firefox from official repo
│   ├── installApps.sh             # All applications
│   ├── installSecurityTools.sh    # Security & pentesting tools
│   ├── installFonts.sh            # Arabic + English fonts
│   ├── installPlymouth.sh         # Plymouth boot theme
│   ├── installGrubTheme.sh        # GRUB bootloader theme
│   ├── catppuccinGTK.sh          # Catppuccin GTK theme
│   ├── catppuccinQT.sh           # Catppuccin Qt theme
│   ├── bibataCursor.sh           # Bibata cursor theme
│   ├── bashrc.sh                 # Shell configuration
│   └── finalSetup.sh             # Final cleanup & configuration
├── themes/                         # Theme files
│   ├── grub-theme/               # GRUB theme (add yours here)
│   └── plymouth-theme/           # Plymouth theme (optional)
├── wolf-backgrounds/              # Wallpaper collection
│   ├── wolf-desktop.jpg          # Desktop wallpaper
│   ├── wolf-greeter.jpg          # Login/GRUB/Plymouth wallpaper
│   └── [other wallpapers...]
├── logs/                          # Installation logs
└── README.md                      # This file
```

---

## 🎨 Customization

### Adding Your Own GRUB Theme

1. Place your GRUB theme folder in `themes/grub-theme/`
2. Ensure it contains a `theme.txt` file
3. The installer will automatically use `wolf-greeter.jpg` as background
```bash
themes/grub-theme/
├── theme.txt          # Required
├── icons/            # Optional
└── fonts/            # Optional
```

### Adding Your Own Plymouth Theme

1. Place your Plymouth theme in `themes/plymouth-theme/`
2. Include the `.plymouth` file
3. The installer will set it up automatically

### Adding More Wallpapers

Simply add more images to `wolf-backgrounds/` folder:
```bash
wolf-backgrounds/
├── wolf-desktop.jpg    # Used for desktop (required)
├── wolf-greeter.jpg    # Used for login/GRUB/Plymouth (required)
├── wallpaper1.jpg
├── wallpaper2.png
└── ...
```

All wallpapers will be installed to `/usr/share/backgrounds/wolf-os/`

### Customizing Installation

Edit `run.sh` to change which scripts run by default:
```bash
SCRIPTS=(
    "systemUpdate.sh|Update system and install base tools|Y"  # Y = Yes by default
    "installApps.sh|Install applications|N"                    # N = No by default
    # Add your own scripts here!
)
```

---

## 📸 Screenshots

<details>
<summary><b>Click to view screenshots</b></summary>

### Installation Process
![Installation](screenshots/installation.png)

### Desktop with WOLF Theme
![Desktop](screenshots/desktop.png)

### GRUB Bootloader
![GRUB](screenshots/grub.png)

### Plymouth Boot Screen
![Plymouth](screenshots/plymouth.png)

### Terminal with Custom Prompt
![Terminal](screenshots/terminal.png)

</details>

---

## 🔍 Troubleshooting

### Common Issues

<details>
<summary><b>Installation fails on a specific script</b></summary>

Check the log file:
```bash
cat logs/installation_*.log | grep ERROR
```

Run the failed script manually:
```bash
bash scripts/[script-name].sh
```
</details>

<details>
<summary><b>Plymouth theme doesn't show on boot</b></summary>
```bash
# Check Plymouth status
sudo plymouth-set-default-theme --list

# Test Plymouth
sudo plymouthd
sudo plymouth --show-splash
sleep 5
sudo plymouth quit

# Rebuild initramfs
sudo update-initramfs -u -k all
sudo reboot
```
</details>

<details>
<summary><b>GRUB theme doesn't appear</b></summary>
```bash
# Check GRUB configuration
cat /etc/default/grub | grep GRUB_THEME

# Update GRUB manually
sudo update-grub
sudo reboot
```
</details>

<details>
<summary><b>Wallpaper didn't change</b></summary>

**GNOME:**
```bash
gsettings set org.gnome.desktop.background picture-uri "file:///usr/share/backgrounds/wolf-os/wolf-desktop.jpg"
```

**XFCE:**
```bash
xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -s "/usr/share/backgrounds/wolf-os/wolf-desktop.jpg"
```

**KDE:**
```bash
kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 1 --group Wallpaper --group org.kde.image --group General --key Image "file:///usr/share/backgrounds/wolf-os/wolf-desktop.jpg"
```
</details>

<details>
<summary><b>Node.js not found after installation</b></summary>
```bash
# Reload shell configuration
source ~/.bashrc

# Or manually load nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Check Node version
node --version
```
</details>

<details>
<summary><b>Lolcat command not found</b></summary>
```bash
# Install lolcat
sudo gem install lolcat

# Add to PATH
export PATH="$PATH:/var/lib/gems/*/bin"
echo 'export PATH="$PATH:/var/lib/gems/*/bin"' >> ~/.bashrc
```
</details>

---

## 📊 Logs

All installation logs are saved in the `logs/` directory:
```bash
# View latest log
tail -f logs/installation_*.log

# Search for errors
grep -i "error\|failed" logs/installation_*.log

# View specific script output
grep "installApps.sh" logs/installation_*.log
```

---

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

### Reporting Issues

1. Check existing issues first
2. Provide detailed information:
   - OS version (Debian/Ubuntu)
   - Desktop Environment
   - Error messages from logs
   - Steps to reproduce

### Adding Features

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Add your script to `scripts/` folder
4. Update `run.sh` to include your script
5. Test thoroughly
6. Submit a Pull Request

### Adding Themes

1. Add your theme to `themes/` folder
2. Update documentation
3. Submit a Pull Request

---

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **Catppuccin** - For the beautiful pastel theme
- **Bibata** - For the modern cursor theme
- **Nerd Fonts** - For the amazing programming fonts
- **Oh My Zsh** - For the powerful shell framework
- All the open-source projects and tools included

---

## 📞 Contact & Support

- **Author**: k4rim0sama
- **GitHub**: [github.com/k4rim0sama](https://github.com/k4rim0sama)
- **Issues**: [Report a bug](https://github.com/k4rim0sama/wolf-os/issues)

---

## 🗺️ Roadmap

- [ ] Add more desktop environment support
- [ ] Create custom icon theme
- [ ] Add system backup/restore functionality
- [ ] Create GUI installer
- [ ] Add update mechanism
- [ ] Support for Fedora/Arch
- [ ] Custom package repository

---

## ⭐ Star History

If you find this project useful, please consider giving it a star! ⭐

---

<div align="center">

### 🐺 Transform your Linux. Unleash the Wolf. 🐺

**Made with ❤️ by k4rim0sama**

[⬆ Back to Top](#-wolf-os---the-ultimate-linux-experience)

</div>
