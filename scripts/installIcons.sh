#!/usr/bin/env bash
set -euo pipefail

# Check dependencies
for cmd in curl tar git; do
  if ! command -v "$cmd" &> /dev/null; then
    echo "❌ Missing dependency: $cmd"
    echo "Install with: sudo apt install curl tar git"
    exit 1
  fi
done

ICONS_DIR="$HOME/.local/share/icons"
mkdir -p "$ICONS_DIR"

echo "🎨 Icon Theme Installer"
echo "======================"
echo

# Available icon themes
echo "Choose an icon theme:"
echo " 1) Papirus (modern, colorful)"
echo " 2) Flat Remix (flat, vibrant)"
echo " 3) Both (install all)"
echo

read -rp "Theme number: " choice

install_papirus() {
    echo "📥 Installing Papirus Icons..."
    
    # Check if already installed
    if [ -d "$ICONS_DIR/Papirus" ] || [ -d "$ICONS_DIR/Papirus-Dark" ]; then
        echo "⚠️  Papirus already exists, removing old version..."
        rm -rf "$ICONS_DIR"/Papirus*
    fi
    
    # Install via system package manager (best method)
    if command -v apt &> /dev/null; then
        echo "📦 Installing from repository..."
        sudo apt update -qq
        sudo apt install -y papirus-icon-theme
        echo "✅ Papirus installed from repository!"
    else
        # Fallback: manual install
        echo "📦 Installing manually..."
        TEMP_DIR="/tmp/papirus-$$"
        mkdir -p "$TEMP_DIR"
        cd "$TEMP_DIR"
        
        wget -qO- https://git.io/papirus-icon-theme-install | sh
        
        cd - > /dev/null
        rm -rf "$TEMP_DIR"
        echo "✅ Papirus installed manually!"
    fi
    
    echo "   📂 Available variants:"
    echo "      • Papirus (colorful)"
    echo "      • Papirus-Dark (dark theme)"
    echo "      • Papirus-Light (light theme)"
}

install_flat_remix() {
    echo "📥 Installing Flat Remix Icons..."
    
    # Check if already installed
    if [ -d "$ICONS_DIR/Flat-Remix-Blue-Dark" ]; then
        echo "⚠️  Flat Remix already exists, updating..."
        rm -rf "$ICONS_DIR"/Flat-Remix*
    fi
    
    TEMP_DIR="/tmp/flat-remix-$$"
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR"
    
    echo "🔍 Fetching latest release..."
    LATEST_URL=$(curl -s https://api.github.com/repos/daniruiz/flat-remix/releases/latest | grep "tarball_url" | cut -d '"' -f 4)
    
    if [ -z "$LATEST_URL" ]; then
        echo "❌ Failed to fetch latest release, using git clone..."
        git clone --depth 1 https://github.com/daniruiz/flat-remix.git
        cd flat-remix
    else
        echo "📦 Downloading from: $LATEST_URL"
        curl -L -o flat-remix.tar.gz "$LATEST_URL"
        tar -xzf flat-remix.tar.gz
        cd daniruiz-flat-remix-*
    fi
    
    echo "📂 Installing icon themes..."
    mkdir -p "$ICONS_DIR"
    cp -r Flat-Remix* "$ICONS_DIR/"
    
    cd - > /dev/null
    rm -rf "$TEMP_DIR"
    
    echo "✅ Flat Remix installed!"
    echo "   📂 Available variants:"
    echo "      • Flat-Remix-Blue-Dark"
    echo "      • Flat-Remix-Blue-Light"
    echo "      • Flat-Remix-Green-Dark"
    echo "      • Flat-Remix-Red-Dark"
    echo "      • ... and more!"
}

case "$choice" in
    1)
        install_papirus
        ;;
    2)
        install_flat_remix
        ;;
    3)
        install_papirus
        echo
        install_flat_remix
        ;;
    *)
        echo "❌ Invalid choice"
        exit 1
        ;;
esac

echo
echo "✅ Icon installation complete!"
echo
echo "📝 Next steps:"
echo "1. Open your system settings"
echo "2. Go to Appearance → Icons"
echo "3. Select your new icon theme"
echo "4. Log out and back in if icons don't change immediately"
echo
echo "🎨 Installed icons are in:"
echo "   $ICONS_DIR"
echo "   /usr/share/icons (system-wide for Papirus)"