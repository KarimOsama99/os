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

echo "=================================="
echo "  WOLF OS Wallpapers Installation"
echo "=================================="
echo

info "Project root: $PROJECT_ROOT"
info "Wallpapers source: $WALLPAPERS_SOURCE"

# Check if wallpapers folder exists
if [ ! -d "$WALLPAPERS_SOURCE" ]; then
    error "Wallpapers folder not found at: $WALLPAPERS_SOURCE"
    exit 1
fi

# Check for required wallpapers
if [ ! -f "$WALLPAPERS_SOURCE/wolf-desktop.jpg" ]; then
    error "wolf-desktop.jpg not found in $WALLPAPERS_SOURCE"
    exit 1
fi

if [ ! -f "$WALLPAPERS_SOURCE/wolf-greeter.jpg" ]; then
    error "wolf-greeter.jpg not found in $WALLPAPERS_SOURCE"
    exit 1
fi

info "Found required wallpapers!"

# Create system wallpapers directory
SYSTEM_WALLPAPERS="/usr/share/backgrounds/wolf-os"
sudo mkdir -p "$SYSTEM_WALLPAPERS"

# Copy all wallpapers
info "Copying wallpapers to $SYSTEM_WALLPAPERS..."
sudo cp -r "$WALLPAPERS_SOURCE"/* "$SYSTEM_WALLPAPERS/"
sudo chmod 644 "$SYSTEM_WALLPAPERS"/*
success "Wallpapers copied!"

# Get current user
CURRENT_USER=${SUDO_USER:-$USER}
CURRENT_USER_HOME=$(eval echo ~$CURRENT_USER)

echo
info "Setting up wallpapers for user: $CURRENT_USER"

# Desktop wallpaper paths
DESKTOP_WALLPAPER="$SYSTEM_WALLPAPERS/wolf-desktop.jpg"
GREETER_WALLPAPER="$SYSTEM_WALLPAPERS/wolf-greeter.jpg"

# Set desktop wallpaper (GNOME)
if command -v gsettings &> /dev/null; then
    info "Setting desktop wallpaper for GNOME..."
    
    # Run as the actual user
    sudo -u $CURRENT_USER DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u $CURRENT_USER)/bus \
        gsettings set org.gnome.desktop.background picture-uri "file://$DESKTOP_WALLPAPER" 2>/dev/null || \
        warn "Could not set GNOME wallpaper (user may need to be logged in)"
    
    sudo -u $CURRENT_USER DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u $CURRENT_USER)/bus \
        gsettings set org.gnome.desktop.background picture-uri-dark "file://$DESKTOP_WALLPAPER" 2>/dev/null
    
    success "GNOME desktop wallpaper configured!"
fi

# Set desktop wallpaper (XFCE)
if command -v xfconf-query &> /dev/null; then
    info "Setting desktop wallpaper for XFCE..."
    
    sudo -u $CURRENT_USER DISPLAY=:0 \
        xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image \
        -s "$DESKTOP_WALLPAPER" 2>/dev/null || \
        warn "Could not set XFCE wallpaper (user may need to be logged in)"
    
    success "XFCE desktop wallpaper configured!"
fi

# Set desktop wallpaper (KDE Plasma)
if command -v kwriteconfig5 &> /dev/null; then
    info "Setting desktop wallpaper for KDE Plasma..."
    
    sudo -u $CURRENT_USER \
        kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc \
        --group Containments --group 1 --group Wallpaper --group org.kde.image \
        --group General --key Image "file://$DESKTOP_WALLPAPER" 2>/dev/null || \
        warn "Could not set KDE wallpaper (user may need to be logged in)"
    
    success "KDE desktop wallpaper configured!"
fi

# Set desktop wallpaper (MATE)
if command -v gsettings &> /dev/null && [ -d "/usr/share/mate" ]; then
    info "Setting desktop wallpaper for MATE..."
    
    sudo -u $CURRENT_USER DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u $CURRENT_USER)/bus \
        gsettings set org.mate.background picture-filename "$DESKTOP_WALLPAPER" 2>/dev/null || \
        warn "Could not set MATE wallpaper"
    
    success "MATE desktop wallpaper configured!"
fi

# Set desktop wallpaper (Cinnamon)
if command -v gsettings &> /dev/null && [ -d "/usr/share/cinnamon" ]; then
    info "Setting desktop wallpaper for Cinnamon..."
    
    sudo -u $CURRENT_USER DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u $CURRENT_USER)/bus \
        gsettings set org.cinnamon.desktop.background picture-uri "file://$DESKTOP_WALLPAPER" 2>/dev/null || \
        warn "Could not set Cinnamon wallpaper"
    
    success "Cinnamon desktop wallpaper configured!"
fi

# Set LightDM greeter background
if [ -f "/etc/lightdm/lightdm-gtk-greeter.conf" ]; then
    info "Setting LightDM greeter background..."
    
    sudo sed -i "s|^background=.*|background=$GREETER_WALLPAPER|" /etc/lightdm/lightdm-gtk-greeter.conf
    
    # If line doesn't exist, add it
    if ! grep -q "^background=" /etc/lightdm/lightdm-gtk-greeter.conf; then
        echo "background=$GREETER_WALLPAPER" | sudo tee -a /etc/lightdm/lightdm-gtk-greeter.conf
    fi
    
    success "LightDM greeter background set!"
fi

# Set LightDM greeter background (alternative config)
if [ -f "/etc/lightdm/slick-greeter.conf" ]; then
    info "Setting LightDM Slick greeter background..."
    
    sudo sed -i "s|^background=.*|background=$GREETER_WALLPAPER|" /etc/lightdm/slick-greeter.conf
    
    if ! grep -q "^background=" /etc/lightdm/slick-greeter.conf; then
        echo "background=$GREETER_WALLPAPER" | sudo tee -a /etc/lightdm/slick-greeter.conf
    fi
    
    success "LightDM Slick greeter background set!"
fi

# Set GDM background (GNOME Display Manager)
if command -v gdm3 &> /dev/null || command -v gdm &> /dev/null; then
    info "Setting GDM greeter background..."
    
    GDM_CONF="/etc/gdm3/greeter.dconf-defaults"
    if [ ! -f "$GDM_CONF" ]; then
        GDM_CONF="/etc/gdm/greeter.dconf-defaults"
    fi
    
    if [ -f "$GDM_CONF" ]; then
        sudo sed -i "s|^picture-uri=.*|picture-uri='file://$GREETER_WALLPAPER'|" "$GDM_CONF"
        
        if ! grep -q "^picture-uri=" "$GDM_CONF"; then
            echo "[org/gnome/desktop/background]" | sudo tee -a "$GDM_CONF"
            echo "picture-uri='file://$GREETER_WALLPAPER'" | sudo tee -a "$GDM_CONF"
        fi
        
        success "GDM greeter background set!"
    fi
fi

echo
success "✅ WOLF OS wallpapers installed successfully!"
echo
info "📁 Wallpapers location: $SYSTEM_WALLPAPERS"
info "🖼️  Desktop wallpaper: wolf-desktop.jpg"
info "🔐 Greeter wallpaper: wolf-greeter.jpg"
echo
warn "⚠️  Note: Desktop wallpaper changes require user to be logged in"
warn "⚠️  If wallpaper didn't change, log out and log back in, or set manually"
echo
info "📝 Manual wallpaper change:"
echo "   Right-click desktop → Change Background → Browse to:"
echo "   $SYSTEM_WALLPAPERS"