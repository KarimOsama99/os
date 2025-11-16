#!/usr/bin/env bash
#============================================================#
#              WOLF OS Wallpapers Installation               #
#============================================================#

RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
RESET="\033[0m"

info()    { echo -e "${BLUE}[INFO]${RESET} $1"; }
success() { echo -e "${GREEN}[OK]${RESET} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET} $1"; }
error()   { echo -e "${RED}[ERROR]${RESET} $1"; }

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
WALLPAPERS_SOURCE="$PROJECT_ROOT/wolf-backgrounds"

# Check if wallpapers folder exists
if [ ! -d "$WALLPAPERS_SOURCE" ]; then
    error "Wallpapers folder not found at: $WALLPAPERS_SOURCE"
    exit 1
fi

info "Installing WOLF OS wallpapers..."

# Create system wallpapers directory
SYSTEM_WALLPAPERS="/usr/share/backgrounds/wolf-os"
sudo mkdir -p "$SYSTEM_WALLPAPERS"

# Copy all wallpapers
info "Copying wallpapers to $SYSTEM_WALLPAPERS..."
sudo cp -r "$WALLPAPERS_SOURCE"/* "$SYSTEM_WALLPAPERS/"
sudo chmod 644 "$SYSTEM_WALLPAPERS"/*
success "Wallpapers copied!"

# Set desktop wallpaper (GNOME)
if command -v gsettings &> /dev/null; then
    info "Setting desktop wallpaper for GNOME..."
    DESKTOP_WALLPAPER="$SYSTEM_WALLPAPERS/wolf-desktop.jpg"
    if [ -f "$DESKTOP_WALLPAPER" ]; then
        gsettings set org.gnome.desktop.background picture-uri "file://$DESKTOP_WALLPAPER"
        gsettings set org.gnome.desktop.background picture-uri-dark "file://$DESKTOP_WALLPAPER"
        success "GNOME desktop wallpaper set!"
    fi
fi

# Set desktop wallpaper (XFCE)
if command -v xfconf-query &> /dev/null; then
    info "Setting desktop wallpaper for XFCE..."
    DESKTOP_WALLPAPER="$SYSTEM_WALLPAPERS/wolf-desktop.jpg"
    if [ -f "$DESKTOP_WALLPAPER" ]; then
        xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -s "$DESKTOP_WALLPAPER"
        success "XFCE desktop wallpaper set!"
    fi
fi

# Set desktop wallpaper (KDE)
if command -v kwriteconfig5 &> /dev/null; then
    info "Setting desktop wallpaper for KDE Plasma..."
    DESKTOP_WALLPAPER="$SYSTEM_WALLPAPERS/wolf-desktop.jpg"
    if [ -f "$DESKTOP_WALLPAPER" ]; then
        kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 1 --group Wallpaper --group org.kde.image --group General --key Image "file://$DESKTOP_WALLPAPER"
        success "KDE desktop wallpaper set!"
    fi
fi

success "✅ WOLF OS wallpapers installed!"
echo
info "Wallpapers location: $SYSTEM_WALLPAPERS"
info "Desktop wallpaper: wolf-desktop.jpg"
info "Greeter wallpaper: wolf-greeter.jpg (will be set by Plymouth/GRUB scripts)"