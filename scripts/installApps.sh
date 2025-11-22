#!/usr/bin/env bash
#============================================================#
#              Additional Applications Installer             #
#============================================================#

set -e

RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
CYAN="\033[1;36m"
MAGENTA="\033[1;35m"
RESET="\033[0m"
BOLD="\033[1m"

info()    { echo -e "${BLUE}[INFO]${RESET} $1"; }
success() { echo -e "${GREEN}[OK]${RESET} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET} $1"; }
error()   { echo -e "${RED}[ERROR]${RESET} $1"; }
section() { echo -e "${CYAN}┌── $1 ──┐${RESET}"; }

# Ask user function
ask_user() {
    local prompt="$1"
    local default="${2:-n}"
    local response
    
    echo ""
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${YELLOW}${BOLD}❓ ${prompt}${RESET}"
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
    
    if [[ "$default" == "y" ]]; then
        read -rp "$(echo -e ${GREEN}👉 [Y/n]: ${RESET})" response
    else
        read -rp "$(echo -e ${YELLOW}👉 [y/N]: ${RESET})" response
    fi
    echo ""
    
    response=${response:-$default}
    echo "${response,,}"
}

#==================#
#   Require Root   #
#==================#
if [ "$EUID" -ne 0 ]; then
    warn "This script requires root privileges."
    read -p "Press Enter to continue... " _
    sudo -k
    exec sudo bash "$0" "$@"
fi

REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(eval echo ~$REAL_USER)

echo ""
echo -e "${CYAN}${BOLD}╔═══════════════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}${BOLD}║                                                       ║${RESET}"
echo -e "${CYAN}${BOLD}║          📦 Installing Applications 📦                ║${RESET}"
echo -e "${CYAN}${BOLD}║                                                       ║${RESET}"
echo -e "${CYAN}${BOLD}╚═══════════════════════════════════════════════════════╝${RESET}"
echo ""

#==================#
# Update System
#==================#
section "System Update"
info "Updating package lists..."
apt update
success "Package lists updated"

#==================#
# Brave Browser
#==================#
section "Installing Brave Browser"
if command -v brave-browser &> /dev/null; then
    warn "Brave already installed, skipping..."
else
    info "Installing Brave Browser..."
    curl -fsS https://dl.brave.com/install.sh | sh
    success "Brave Browser installed"
fi

#==================#
# VS Code
#==================#
section "Installing Visual Studio Code"
if command -v code &> /dev/null; then
    warn "VS Code already installed, skipping..."
else
    info "Adding VS Code repository..."
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /usr/share/keyrings/packages.microsoft.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
        | tee /etc/apt/sources.list.d/vscode.list
    apt update
    apt install -y code
    success "VS Code installed"
fi

#==================#
# Node.js via nvm
#==================#
section "Installing Node.js via NVM"
if [ -d "$USER_HOME/.nvm" ]; then
    warn "nvm already installed, skipping..."
else
    info "Fetching latest nvm version..."
    
    NVM_VERSION=$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")' 2>/dev/null || echo "")
    
    if [ -z "$NVM_VERSION" ]; then
        warn "Could not fetch latest version, using fallback v0.40.1"
        NVM_VERSION="v0.40.1"
    else
        success "Latest nvm version: $NVM_VERSION"
    fi
    
    info "Installing nvm $NVM_VERSION for user $REAL_USER..."
    
    sudo -u $REAL_USER bash <<NVMEOF
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh | bash
NVMEOF
    
    success "nvm installed"
    
    info "Installing Node.js 22..."
    sudo -u $REAL_USER bash <<'NODEEOF'
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install 22
nvm alias default 22
nvm use 22
NODEEOF
    
    success "Node.js 22 installed and set as default"
    
    for rc_file in "$USER_HOME/.bashrc" "$USER_HOME/.zshrc"; do
        if [ -f "$rc_file" ] && ! grep -q "NVM_DIR" "$rc_file"; then
            cat >> "$rc_file" <<'NVMRCEOF'

# nvm configuration
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
NVMRCEOF
        fi
    done
    
    success "nvm configured in shell profiles"
fi

#==================#
# LibreOffice
#==================#
section "LibreOffice Installation"
install_libreoffice=$(ask_user "Install LibreOffice with Arabic support?" "n")
if [[ $install_libreoffice == "y" ]]; then
    info "Installing LibreOffice..."
    apt install -y libreoffice libreoffice-gtk3 libreoffice-l10n-ar
    success "LibreOffice installed (with Arabic support)"
else
    info "Skipping LibreOffice installation"
fi

#==================#
# Spotify
#==================#
section "Installing Spotify"
if command -v spotify &> /dev/null; then
    warn "Spotify already installed, skipping..."
else
    info "Adding Spotify repository..."
    curl -sS https://download.spotify.com/debian/pubkey_C85668DF69375001.gpg | gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
    echo "deb https://repository.spotify.com stable non-free" | tee /etc/apt/sources.list.d/spotify.list
    apt update
    apt install -y spotify-client
    success "Spotify installed"
fi

#==================#
# AnyDesk
#==================#
section "AnyDesk Installation"
install_anydesk=$(ask_user "Install AnyDesk (remote desktop)?" "n")
if [[ $install_anydesk == "y" ]]; then
    if command -v anydesk &> /dev/null; then
        warn "AnyDesk already installed, skipping..."
    else
        info "Installing AnyDesk..."
        wget -qO - https://keys.anydesk.com/repos/DEB-GPG-KEY | apt-key add -
        echo "deb http://deb.anydesk.com/ all main" > /etc/apt/sources.list.d/anydesk-stable.list
        apt update
        apt install -y anydesk
        success "AnyDesk installed"
    fi
else
    info "Skipping AnyDesk installation"
fi

#==================#
# Discord
#==================#
section "Discord Installation"
install_discord=$(ask_user "Install Discord?" "n")
if [[ $install_discord == "y" ]]; then
    if command -v discord &> /dev/null; then
        warn "Discord already installed, skipping..."
    else
        info "Installing Discord..."
        DISCORD_URL="https://discord.com/api/download?platform=linux&format=deb"
        wget -O /tmp/discord.deb "$DISCORD_URL"
        apt install -y /tmp/discord.deb
        rm -f /tmp/discord.deb
        success "Discord installed"
    fi
else
    info "Skipping Discord installation"
fi

#==================#
# Essential Apps
#==================#
section "Installing Essential Applications"
apt install -y gparted btop vlc
success "GParted, Btop, and VLC installed"

#==================#
# Wireshark
#==================#
section "Installing Wireshark"
echo "wireshark-common wireshark-common/install-setuid boolean true" | debconf-set-selections
apt install -y wireshark
usermod -aG wireshark $REAL_USER
success "Wireshark installed (user $REAL_USER added to wireshark group)"

#==================#
# Text Editor
#==================#
section "Checking for Text Editors"
EDITOR_INSTALLED=false

for editor in gedit kate pluma mousepad leafpad geany; do
    if command -v $editor &> /dev/null; then
        EDITOR_INSTALLED=true
        info "Found text editor: $editor"
        break
    fi
done

if [ "$EDITOR_INSTALLED" = false ]; then
    info "No text editor found, installing mousepad..."
    apt install -y mousepad
    success "Mousepad installed"
else
    info "Text editor already available"
fi

#==================#
# Proxychains-ng
#==================#
section "Installing Proxychains-ng"
apt install -y proxychains4
success "Proxychains-ng installed"

info "Configuring proxychains..."
PROXYCHAINS_CONF="/etc/proxychains4.conf"
if [ -f "$PROXYCHAINS_CONF" ]; then
    cp "$PROXYCHAINS_CONF" "${PROXYCHAINS_CONF}.backup"
    sed -i 's/^strict_chain/#strict_chain/' "$PROXYCHAINS_CONF"
    sed -i 's/^#dynamic_chain/dynamic_chain/' "$PROXYCHAINS_CONF"
    success "Proxychains configured (dynamic_chain enabled)"
fi

#==================#
# Tor Service
#==================#
section "Installing Tor Service"
apt install -y tor
success "Tor service installed"

info "Starting and enabling Tor service..."
systemctl enable tor
systemctl start tor
success "Tor service is running"

#==================#
# Tor Browser
#==================#
section "Installing Tor Browser"
if [ -d "/opt/tor-browser" ]; then
    warn "Tor Browser already installed at /opt/tor-browser"
else
    apt install -y libdbus-glib-1-2 libgtk-3-0
    
    info "Fetching latest Tor Browser version..."
    TOR_VERSION=$(curl -s https://www.torproject.org/download/ | grep -oP 'torbrowser/\K[0-9.]+' | head -1 2>/dev/null || echo "")
    
    if [ -z "$TOR_VERSION" ]; then
        warn "Could not fetch latest version, using fallback 15.0.1"
        TOR_VERSION="15.0.1"
    else
        success "Latest Tor Browser version: $TOR_VERSION"
    fi
    
    TOR_ARCH="linux-x86_64"
    TOR_URL="https://www.torproject.org/dist/torbrowser/${TOR_VERSION}/tor-browser-${TOR_ARCH}-${TOR_VERSION}.tar.xz"
    
    info "Downloading Tor Browser ${TOR_VERSION}..."
    wget -O /tmp/tor-browser.tar.xz "$TOR_URL" --progress=bar:force
    
    info "Extracting Tor Browser..."
    tar -xf /tmp/tor-browser.tar.xz -C /opt/
    mv /opt/tor-browser* /opt/tor-browser
    
    cat > /usr/share/applications/tor-browser.desktop <<EOF
[Desktop Entry]
Name=Tor Browser
Comment=Anonymous web browser
Exec=/opt/tor-browser/Browser/start-tor-browser
Icon=/opt/tor-browser/Browser/browser/chrome/icons/default/default128.png
Type=Application
Categories=Network;WebBrowser;Security;
EOF
    
    chmod +x /usr/share/applications/tor-browser.desktop
    rm -f /tmp/tor-browser.tar.xz
    
    success "Tor Browser ${TOR_VERSION} installed"
fi

#==================#
# OpenVPN
#==================#
section "Installing OpenVPN"
apt install -y openvpn network-manager-openvpn network-manager-openvpn-gnome
success "OpenVPN installed"

#==================#
# Python3 & pipx
#==================#
section "Installing Python3 and Essential Tools"
apt install -y python3 python3-pip python3-venv python3-dev
success "Python3 installed"

PYTHON_VERSION=$(python3 --version)
info "Installed: $PYTHON_VERSION"

info "Installing pipx..."
apt install -y pipx
success "pipx installed"

info "Configuring pipx for user $REAL_USER..."
sudo -u $REAL_USER pipx ensurepath

BASHRC="$USER_HOME/.bashrc"
if [ -f "$BASHRC" ] && ! grep -q "pipx" "$BASHRC"; then
    echo '' >> "$BASHRC"
    echo '# pipx path' >> "$BASHRC"
    echo 'export PATH="$PATH:$HOME/.local/bin"' >> "$BASHRC"
fi

success "pipx configured"

#==================#
# Figlet
#==================#
section "Installing Figlet"
apt install -y figlet
success "Figlet installed"

#==================#
# Golang
#==================#
section "Installing Golang"

if command -v go &> /dev/null; then
    warn "Golang already installed: $(go version)"
else
    info "Fetching latest Golang version..."
    GO_VERSION=$(curl -s https://go.dev/VERSION?m=text | head -1 2>/dev/null || echo "")
    
    if [ -z "$GO_VERSION" ]; then
        warn "Could not fetch latest version, using fallback go1.23.4"
        GO_VERSION="go1.23.4"
    else
        success "Latest Golang version: $GO_VERSION"
    fi
    
    GO_TARBALL="${GO_VERSION}.linux-amd64.tar.gz"
    GO_URL="https://go.dev/dl/${GO_TARBALL}"
    
    info "Downloading Golang ${GO_VERSION}..."
    wget -O /tmp/go.tar.gz "$GO_URL" --progress=bar:force
    
    info "Installing Golang to /usr/local/go..."
    rm -rf /usr/local/go
    tar -C /usr/local -xzf /tmp/go.tar.gz
    
    if ! grep -q "/usr/local/go/bin" /etc/profile; then
        echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
    fi
    
    for rc_file in "$USER_HOME/.bashrc" "$USER_HOME/.zshrc"; do
        if [ -f "$rc_file" ] && ! grep -q "/usr/local/go/bin" "$rc_file"; then
            cat >> "$rc_file" <<'GOEOF'

# Go language paths
export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin
GOEOF
        fi
    done
    
    rm -f /tmp/go.tar.gz
    
    success "Golang installed"
    info "Go version: $(/usr/local/go/bin/go version)"
fi

#==================#
# Summary
#==================#
echo ""
echo -e "${CYAN}${BOLD}╔═══════════════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}${BOLD}║                                                       ║${RESET}"
echo -e "${CYAN}${BOLD}║         ✅ All Applications Installed! ✅             ║${RESET}"
echo -e "${CYAN}${BOLD}║                                                       ║${RESET}"
echo -e "${CYAN}${BOLD}╚═══════════════════════════════════════════════════════╝${RESET}"
echo ""
info "📋 Installed applications:"
echo "  ✓ Brave Browser"
echo "  ✓ VS Code"
echo "  ✓ Node.js 22 (via nvm)"
if [[ $install_libreoffice == "y" ]]; then
    echo "  ✓ LibreOffice (with Arabic)"
fi
echo "  ✓ Spotify"
if [[ $install_anydesk == "y" ]]; then
    echo "  ✓ AnyDesk"
fi
if [[ $install_discord == "y" ]]; then
    echo "  ✓ Discord"
fi
echo "  ✓ GParted, Btop, VLC"
echo "  ✓ Wireshark"
echo "  ✓ Proxychains-ng"
echo "  ✓ Tor Service + Browser"
echo "  ✓ OpenVPN"
echo "  ✓ Python3 + pipx"
echo "  ✓ Figlet"
echo "  ✓ Golang"
echo ""
warn "⚠️  Important:"
echo "  • Restart terminal for changes"
echo "  • User '$REAL_USER' needs logout for wireshark group"
echo ""