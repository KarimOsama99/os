#!/usr/bin/env bash
#============================================================#
#              Additional Applications Installer             #
#============================================================#

set -e

RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
RESET="\033[0m"

info()    { echo -e "${BLUE}[INFO]${RESET} $1"; }
success() { echo -e "${GREEN}[OK]${RESET} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET} $1"; }
error()   { echo -e "${RED}[ERROR]${RESET} $1"; }

#==================#
#   Require Root   #
#==================#
if [ "$EUID" -ne 0 ]; then
    warn "This script requires root privileges."
    read -p "Press Enter to continue... " _
    sudo -k
    exec sudo bash "$0" "$@"
fi

# Get real user info
REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(eval echo ~$REAL_USER)

echo "======================================"
echo "      📦 Installing Applications"
echo "======================================"
echo

#==================#
# Update System
#==================#
info "Updating package lists..."
apt update
success "Package lists updated"

#==================#
# Brave Browser
#==================#
info "Installing Brave Browser..."
if command -v brave-browser &> /dev/null; then
    warn "Brave already installed, skipping..."
else
    curl -fsS https://dl.brave.com/install.sh | sh
    success "Brave Browser installed"
fi

#==================#
# VS Code
#==================#
info "Installing Visual Studio Code..."
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
# Ruby (for lolcat)
#==================#
info "Installing Ruby..."
apt install -y ruby-full ruby-dev build-essential
success "Ruby installed"

RUBY_VERSION=$(ruby --version)
info "Installed: $RUBY_VERSION"

#==================#
# Node.js via nvm
#==================#
info "Installing Node.js via nvm..."
if [ -d "$USER_HOME/.nvm" ]; then
    warn "nvm already installed, skipping..."
else
    info "Installing nvm for user $REAL_USER..."
    
    # Download and install nvm as the real user
    sudo -u $REAL_USER bash <<'EOF'
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
EOF
    
    success "nvm installed"
    
    info "Installing Node.js 24..."
    # Load nvm and install Node.js as the real user
    sudo -u $REAL_USER bash <<'EOF'
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install 24
nvm alias default 24
nvm use 24
EOF
    
    success "Node.js 24 installed and set as default"
    
    # Configure nvm in shell profiles with auto-use
    for rc_file in "$USER_HOME/.bashrc" "$USER_HOME/.zshrc"; do
        if [ -f "$rc_file" ] && ! grep -q "NVM_DIR" "$rc_file"; then
            cat >> "$rc_file" <<'NVMEOF'

# nvm configuration
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Auto-use default Node.js version
nvm use default &>/dev/null
NVMEOF
        fi
    done
    
    success "nvm configured to auto-use Node.js 24 on shell startup"
fi

#==================#
# LibreOffice
#==================#
info "Installing LibreOffice..."
apt install -y libreoffice libreoffice-gtk3 libreoffice-l10n-ar
success "LibreOffice installed (with Arabic support)"

#==================#
# Spotify
#==================#
info "Installing Spotify..."
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
info "Installing AnyDesk..."
if command -v anydesk &> /dev/null; then
    warn "AnyDesk already installed, skipping..."
else
    # Add AnyDesk repository
    wget -qO - https://keys.anydesk.com/repos/DEB-GPG-KEY | apt-key add -
    echo "deb http://deb.anydesk.com/ all main" > /etc/apt/sources.list.d/anydesk-stable.list
    apt update
    apt install -y anydesk
    success "AnyDesk installed"
fi

#==================#
# Discord
#==================#
info "Installing Discord..."
if command -v discord &> /dev/null; then
    warn "Discord already installed, skipping..."
else
    DISCORD_URL="https://discord.com/api/download?platform=linux&format=deb"
    wget -O /tmp/discord.deb "$DISCORD_URL"
    apt install -y /tmp/discord.deb
    rm -f /tmp/discord.deb
    success "Discord installed"
fi

#==================#
# GParted
#==================#
info "Installing GParted..."
apt install -y gparted
success "GParted installed"

#==================#
# Btop
#==================#
info "Installing Btop..."
apt install -y btop
success "Btop installed"

#==================#
# VLC Media Player
#==================#
info "Installing VLC Media Player..."
apt install -y vlc
success "VLC installed"

#==================#
# Wireshark
#==================#
info "Installing Wireshark..."
# Preconfigure wireshark to allow non-root users
echo "wireshark-common wireshark-common/install-setuid boolean true" | debconf-set-selections
apt install -y wireshark
# Add user to wireshark group
usermod -aG wireshark $REAL_USER
success "Wireshark installed (user $REAL_USER added to wireshark group)"

#==================#
# Text Editor
#==================#
info "Checking for text editors..."
EDITOR_INSTALLED=false

# Check for common text editors
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
    info "Text editor already available, skipping installation"
fi

#==================#
# Proxychains-ng
#==================#
info "Installing Proxychains-ng..."
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
info "Installing Tor service..."
apt install -y tor
success "Tor service installed"

info "Starting and enabling Tor service..."
systemctl enable tor
systemctl start tor
success "Tor service is running"

#==================#
# Tor Browser
#==================#
info "Installing Tor Browser..."
if [ -d "/opt/tor-browser" ]; then
    warn "Tor Browser already installed at /opt/tor-browser"
else
    apt install -y libdbus-glib-1-2 libgtk-3-0
    
    TOR_VERSION="15.0.1"
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
info "Installing OpenVPN..."
apt install -y openvpn network-manager-openvpn network-manager-openvpn-gnome
success "OpenVPN installed"

#==================#
# Apache2
#==================#
info "Installing Apache2 web server..."
apt install -y apache2
success "Apache2 installed"

info "Starting and enabling Apache2..."
systemctl enable apache2
systemctl start apache2
success "Apache2 is running (http://localhost)"

#==================#
# Python3 & pipx
#==================#
info "Installing Python3 and essential tools..."
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
# Figlet & Lolcat
#==================#
info "Installing figlet and lolcat..."
apt install -y figlet
success "Figlet installed"

info "Installing lolcat via gem..."
gem install lolcat
success "Lolcat installed"

# Ensure lolcat is in PATH
LOLCAT_PATH=$(gem environment | grep "EXECUTABLE DIRECTORY" | cut -d: -f2 | xargs)
if [ -n "$LOLCAT_PATH" ]; then
    for rc_file in "$USER_HOME/.bashrc" "$USER_HOME/.zshrc"; do
        if [ -f "$rc_file" ] && ! grep -q "$LOLCAT_PATH" "$rc_file"; then
            echo "export PATH=\"\$PATH:$LOLCAT_PATH\"" >> "$rc_file"
        fi
    done
    success "Lolcat added to PATH"
fi

#==================#
# Oh My Zsh
#==================#
info "Installing Zsh..."
apt install -y zsh
success "Zsh installed"

if [ ! -d "$USER_HOME/.oh-my-zsh" ]; then
    info "Installing Oh My Zsh for user $REAL_USER..."
    
    # Install Oh My Zsh as the real user
    sudo -u $REAL_USER bash <<'EOF'
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
EOF
    
    success "Oh My Zsh installed"
    
    # Install plugins
    info "Installing zsh-autosuggestions..."
    sudo -u $REAL_USER git clone https://github.com/zsh-users/zsh-autosuggestions \
        "$USER_HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
    
    info "Installing zsh-syntax-highlighting..."
    sudo -u $REAL_USER git clone https://github.com/zsh-users/zsh-syntax-highlighting \
        "$USER_HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
    
    success "Zsh plugins installed"
    
    # Configure .zshrc
    ZSHRC="$USER_HOME/.zshrc"
    if [ -f "$ZSHRC" ]; then
        info "Configuring .zshrc..."
        
        # Enable plugins
        sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' "$ZSHRC"
        
        # Add banner at the end
        cat >> "$ZSHRC" <<'BANNEREOF'

# Custom Banner
if command -v figlet &> /dev/null && command -v lolcat &> /dev/null; then
    figlet -c "W O L F - O S" | lolcat
fi
BANNEREOF
        
        success ".zshrc configured with plugins and banner"
    fi
else
    warn "Oh My Zsh already installed, skipping..."
fi

# Configure .bashrc with banner if it exists
if [ -f "$BASHRC" ] && ! grep -q "W O L F - O S" "$BASHRC"; then
    info "Adding banner to .bashrc..."
    cat >> "$BASHRC" <<'BANNEREOF'

# Custom Banner
if command -v figlet &> /dev/null && command -v lolcat &> /dev/null; then
    figlet -c "W O L F - O S" | lolcat
fi
BANNEREOF
    success "Banner added to .bashrc"
fi

#==================#
# Change Default Shell to Zsh (Optional)
#==================#
echo
read -rp "Do you want to set Zsh as the default shell for $REAL_USER? (y/n): " answer
if [[ $answer == [Yy]* ]]; then
    info "Setting Zsh as default shell for $REAL_USER..."
    chsh -s $(which zsh) $REAL_USER
    success "Default shell changed to Zsh"
    warn "⚠️  Please log out and log back in for the shell change to take effect"
else
    info "Keeping current shell"
fi

#==================#
# Golang
#==================#
info "Installing Golang..."

if command -v go &> /dev/null; then
    warn "Golang already installed: $(go version)"
else
    GO_VERSION=$(curl -s https://go.dev/VERSION?m=text | head -1)
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
echo
echo "======================================"
success "✅ All applications installed!"
echo "======================================"
echo
info "📋 Installed applications:"
echo "  ✓ Brave Browser"
echo "  ✓ VS Code"
echo "  ✓ Node.js 24 (via nvm - auto-loads on shell start)"
echo "  ✓ Ruby (for lolcat)"
echo "  ✓ LibreOffice (with Arabic support)"
echo "  ✓ Spotify"
echo "  ✓ AnyDesk"
echo "  ✓ Discord"
echo "  ✓ GParted"
echo "  ✓ Btop"
echo "  ✓ VLC Media Player"
echo "  ✓ Wireshark"
echo "  ✓ Text Editor (mousepad or existing)"
echo "  ✓ Proxychains-ng (dynamic_chain)"
echo "  ✓ Tor Service (running)"
echo "  ✓ Tor Browser 15.0.1"
echo "  ✓ OpenVPN"
echo "  ✓ Apache2 (http://localhost)"
echo "  ✓ Python3 + pip + pipx"
echo "  ✓ Figlet + Lolcat"
echo "  ✓ Oh My Zsh (with autosuggestions + syntax-highlighting)"
echo "  ✓ Golang"
echo
info "🎨 Shell Customization:"
echo "  • Custom banner: W O L F - O S (figlet + lolcat)"
echo "  • Zsh plugins: autosuggestions + syntax-highlighting"
echo "  • nvm auto-loads Node.js 24 on every shell start"
echo "  • lolcat added to PATH automatically"
echo
info "🔧 Services status:"
echo "  • Tor: $(systemctl is-active tor)"
echo "  • Apache2: $(systemctl is-active apache2)"
echo
warn "⚠️  Important Notes:"
echo "  1. Restart your terminal to see all changes"
echo "  2. Node.js 24 will be automatically activated in new shells"
echo "  3. User '$REAL_USER' added to wireshark group (requires logout)"
if [[ $answer == [Yy]* ]]; then
    echo "  4. Zsh is now default shell (logout required)"
fi
echo
info "📝 Quick commands:"
echo "  • Node.js: node --version (auto-loaded via nvm)"
echo "  • Ruby: ruby --version"
echo "  • Spotify: spotify"
echo "  • Tor Browser: /opt/tor-browser/Browser/start-tor-browser"
echo "  • Proxychains: proxychains4 <command>"
echo "  • OpenVPN: openvpn --config <file.ovpn>"
echo "  • Wireshark: wireshark"
echo