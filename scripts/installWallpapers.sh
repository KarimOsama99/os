#!/usr/bin/env bash
#============================================================#
#              WOLF OS Wallpapers Installation               #
#       Make wolf-os the default wallpapers collection      #
#============================================================#

set -euo pipefail

RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
CYAN="\033[1;36m"
MAGENTA="\033[1;35m"
RESET="\033[0m"

info()    { echo -e "${BLUE}[INFO]${RESET} $1"; }
success() { echo -e "${GREEN}[OK]${RESET} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET} $1"; }
error()   { echo -e "${RED}[ERROR]${RESET} $1"; }
section() { echo -e "${CYAN}${BOLD}┌── $1 ──┐${RESET}"; }

#==================#
#   Check Root     #
#==================#
if [ "$EUID" -ne 0 ]; then
    warn "This script requires root privileges."
    read -p "Press Enter to continue... " _
    exec sudo bash "$0" "$@"
fi

#==================#
#   Get Directories #
#==================#
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
WALLPAPERS_SOURCE="$PROJECT_ROOT/wolf-backgrounds"

echo "======================================"
echo "  WOLF OS Wallpapers Installation"
echo "======================================"
echo

info "Project root: $PROJECT_ROOT"
info "Wallpapers source: $WALLPAPERS_SOURCE"

#==================#
#   Validate Setup #
#==================#
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

success "Found required wallpapers!"

#===========================================#
#   Copy Wallpapers to System Directory    #
#===========================================#
SYSTEM_WALLPAPERS="/usr/share/backgrounds/wolf-os"

info "Creating system wallpapers directory..."
mkdir -p "$SYSTEM_WALLPAPERS"

info "Copying wallpapers to $SYSTEM_WALLPAPERS..."
cp -r "$WALLPAPERS_SOURCE"/* "$SYSTEM_WALLPAPERS/"
chmod 644 "$SYSTEM_WALLPAPERS"/*

success "Wallpapers copied to backgrounds!"

#===========================================#
#   Copy to /usr/share/images (Debian)     #
#===========================================#
section "Installing to /usr/share/images (Debian default)"

IMAGES_DIR="/usr/share/images"
mkdir -p "$IMAGES_DIR"

# Create symlink for easy access
if [ -L "$IMAGES_DIR/wolf-os" ]; then
    rm "$IMAGES_DIR/wolf-os"
fi
ln -sf "$SYSTEM_WALLPAPERS" "$IMAGES_DIR/wolf-os"
success "Symlink created: $IMAGES_DIR/wolf-os"

# Also copy directly for maximum compatibility
info "Copying wallpapers to $IMAGES_DIR/wolf-os-wallpapers..."
IMAGES_WALLPAPERS="$IMAGES_DIR/wolf-os-wallpapers"
mkdir -p "$IMAGES_WALLPAPERS"
cp -r "$SYSTEM_WALLPAPERS"/* "$IMAGES_WALLPAPERS/"
chmod 644 "$IMAGES_WALLPAPERS"/*
success "Wallpapers also available in $IMAGES_WALLPAPERS"

#===========================================#
#   Create GNOME XML Wallpaper Metadata    #
#===========================================#
section "Creating GNOME wallpaper metadata"

GNOME_PROPERTIES_DIR="/usr/share/gnome-background-properties"
mkdir -p "$GNOME_PROPERTIES_DIR"

WOLF_XML="$GNOME_PROPERTIES_DIR/wolf-os-wallpapers.xml"

info "Generating wallpaper metadata XML..."

cat > "$WOLF_XML" << 'XMLEOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE wallpapers SYSTEM "gnome-wp-list.dtd">
<wallpapers>
XMLEOF

# Find all image files and add them to XML
find "$SYSTEM_WALLPAPERS" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) | while read -r wallpaper; do
    filename=$(basename "$wallpaper")
    name="${filename%.*}"
    # Capitalize first letter and replace dashes/underscores with spaces
    pretty_name=$(echo "$name" | sed 's/[-_]/ /g' | sed 's/\b\(.\)/\u\1/g')
    
    cat >> "$WOLF_XML" << ITEMEOF
  <wallpaper deleted="false">
    <name>WOLF OS - $pretty_name</name>
    <filename>$wallpaper</filename>
    <options>zoom</options>
    <shade_type>solid</shade_type>
    <pcolor>#000000</pcolor>
    <scolor>#000000</scolor>
  </wallpaper>
ITEMEOF
done

cat >> "$WOLF_XML" << 'XMLEOF'
</wallpapers>
XMLEOF

chmod 644 "$WOLF_XML"
success "GNOME metadata created: $WOLF_XML"

#===========================================#
#   Create XFCE Wallpaper List             #
#===========================================#
section "Creating XFCE wallpaper metadata"

XFCE_BACKDROPS_DIR="/usr/share/xfce4/backdrops"
mkdir -p "$XFCE_BACKDROPS_DIR"

# Create symlink to make wallpapers appear in XFCE
if [ -L "$XFCE_BACKDROPS_DIR/wolf-os" ]; then
    rm "$XFCE_BACKDROPS_DIR/wolf-os"
fi

ln -sf "$SYSTEM_WALLPAPERS" "$XFCE_BACKDROPS_DIR/wolf-os"
success "XFCE wallpapers linked: $XFCE_BACKDROPS_DIR/wolf-os"

#===========================================#
#   Create KDE Wallpaper Metadata          #
#===========================================#
section "Creating KDE wallpaper metadata"

KDE_WALLPAPER_DIR="/usr/share/wallpapers/WOLF-OS"
mkdir -p "$KDE_WALLPAPER_DIR/contents/images"

# Copy wallpapers for KDE
cp "$SYSTEM_WALLPAPERS"/* "$KDE_WALLPAPER_DIR/contents/images/" 2>/dev/null || true

# Create metadata.desktop for KDE
cat > "$KDE_WALLPAPER_DIR/metadata.desktop" << 'KDEEOF'
[Desktop Entry]
Name=WOLF OS Wallpapers
X-KDE-PluginInfo-Name=WOLF-OS
X-KDE-PluginInfo-Author=WOLF OS Team
X-KDE-PluginInfo-License=CC-BY-SA-4.0
KDEEOF

chmod 644 "$KDE_WALLPAPER_DIR/metadata.desktop"
success "KDE wallpapers configured: $KDE_WALLPAPER_DIR"

#===========================================#
#   Make WOLF OS Default Wallpaper Set     #
#===========================================#
section "Configuring as default wallpaper collection"

# Create a marker file to indicate these are system wallpapers
cat > "$SYSTEM_WALLPAPERS/.wolf-os-wallpapers" << 'MARKEREOF'
WOLF OS Official Wallpapers
Installed by WOLF OS Setup Script
These wallpapers are now part of the system wallpaper collection
MARKEREOF

success "WOLF OS wallpapers registered as system collection!"

#==================#
#   Get User Info  #
#==================#
CURRENT_USER=${SUDO_USER:-$USER}
CURRENT_USER_HOME=$(eval echo ~$CURRENT_USER)
CURRENT_USER_UID=$(id -u $CURRENT_USER)

echo
info "Setting up wallpapers for user: $CURRENT_USER"

#===========================================#
#   Desktop Wallpaper Paths                #
#===========================================#
DESKTOP_WALLPAPER="$SYSTEM_WALLPAPERS/wolf-desktop.jpg"
GREETER_WALLPAPER="$SYSTEM_WALLPAPERS/wolf-greeter.jpg"

#===========================================#
#   Set Desktop Wallpapers (All DEs)       #
#===========================================#
set_wallpaper_success=false

# Helper function to run commands as user with proper D-Bus
run_as_user() {
    sudo -u $CURRENT_USER \
        DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${CURRENT_USER_UID}/bus \
        "$@" 2>/dev/null
}

echo
section "Configuring desktop wallpapers"
echo

# GNOME
if command -v gsettings &> /dev/null && [ -d "/usr/share/gnome" ]; then
    info "Detected: GNOME Desktop"
    
    if run_as_user gsettings set org.gnome.desktop.background picture-uri "file://$DESKTOP_WALLPAPER"; then
        run_as_user gsettings set org.gnome.desktop.background picture-uri-dark "file://$DESKTOP_WALLPAPER"
        success "  ✓ GNOME desktop wallpaper configured!"
        set_wallpaper_success=true
    else
        warn "  ⚠  Could not set GNOME wallpaper (user may need to be logged in)"
    fi
    echo
fi

# XFCE
if command -v xfconf-query &> /dev/null && [ -d "/usr/share/xfce4" ]; then
    info "Detected: XFCE Desktop"
    
    # Find all monitors and workspaces
    if run_as_user DISPLAY=:0 xfconf-query -c xfce4-desktop -l | grep -q "last-image"; then
        for property in $(run_as_user DISPLAY=:0 xfconf-query -c xfce4-desktop -l | grep "last-image"); do
            if run_as_user DISPLAY=:0 xfconf-query -c xfce4-desktop -p "$property" -s "$DESKTOP_WALLPAPER"; then
                success "  ✓ Set wallpaper for: $property"
                set_wallpaper_success=true
            fi
        done
    else
        warn "  ⚠  Could not detect XFCE monitors (user may need to be logged in)"
    fi
    echo
fi

# KDE Plasma
if command -v kwriteconfig5 &> /dev/null && [ -d "/usr/share/plasma" ]; then
    info "Detected: KDE Plasma Desktop"
    
    if run_as_user kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc \
        --group Containments --group 1 --group Wallpaper --group org.kde.image \
        --group General --key Image "file://$DESKTOP_WALLPAPER"; then
        success "  ✓ KDE desktop wallpaper configured!"
        set_wallpaper_success=true
    else
        warn "  ⚠  Could not set KDE wallpaper (user may need to be logged in)"
    fi
    echo
fi

# MATE
if command -v gsettings &> /dev/null && [ -d "/usr/share/mate" ]; then
    info "Detected: MATE Desktop"
    
    if run_as_user gsettings set org.mate.background picture-filename "$DESKTOP_WALLPAPER"; then
        success "  ✓ MATE desktop wallpaper configured!"
        set_wallpaper_success=true
    else
        warn "  ⚠  Could not set MATE wallpaper"
    fi
    echo
fi

# Cinnamon
if command -v gsettings &> /dev/null && [ -d "/usr/share/cinnamon" ]; then
    info "Detected: Cinnamon Desktop"
    
    if run_as_user gsettings set org.cinnamon.desktop.background picture-uri "file://$DESKTOP_WALLPAPER"; then
        success "  ✓ Cinnamon desktop wallpaper configured!"
        set_wallpaper_success=true
    else
        warn "  ⚠  Could not set Cinnamon wallpaper"
    fi
    echo
fi

# LXQt / LXDE
if [ -d "/usr/share/lxqt" ] || [ -d "/usr/share/lxde" ]; then
    info "Detected: LXQt/LXDE Desktop"
    
    pcmanfm_config="$CURRENT_USER_HOME/.config/pcmanfm/LXDE/desktop-items-0.conf"
    if [ -f "$pcmanfm_config" ]; then
        sed -i "s|^wallpaper=.*|wallpaper=$DESKTOP_WALLPAPER|" "$pcmanfm_config"
        success "  ✓ LXQt/LXDE wallpaper configured!"
        set_wallpaper_success=true
    else
        warn "  ⚠  Could not find PCManFM config"
    fi
    echo
fi

if [ "$set_wallpaper_success" = false ]; then
    warn "Could not auto-configure desktop wallpaper"
    info "Desktop environment may not be detected or user needs to be logged in"
fi

#===========================================#
#   Set Login/Greeter Wallpapers           #
#   (wolf-greeter.jpg ONLY for LightDM)    #
#===========================================#
echo
section "Configuring login screen wallpapers"
echo

greeter_configured=false

# LightDM - GTK Greeter
if [ -f "/etc/lightdm/lightdm-gtk-greeter.conf" ]; then
    info "Detected: LightDM GTK Greeter"
    
    # Backup config
    cp /etc/lightdm/lightdm-gtk-greeter.conf \
       /etc/lightdm/lightdm-gtk-greeter.conf.backup.$(date +%Y%m%d_%H%M%S)
    
    # Update or add background line
    if grep -q "^background=" /etc/lightdm/lightdm-gtk-greeter.conf; then
        sed -i "s|^background=.*|background=$GREETER_WALLPAPER|" /etc/lightdm/lightdm-gtk-greeter.conf
    else
        echo "background=$GREETER_WALLPAPER" >> /etc/lightdm/lightdm-gtk-greeter.conf
    fi
    
    success "  ✓ LightDM GTK greeter background set!"
    greeter_configured=true
    echo
fi

# LightDM - Slick Greeter
if [ -f "/etc/lightdm/slick-greeter.conf" ]; then
    info "Detected: LightDM Slick Greeter"
    
    # Backup config
    cp /etc/lightdm/slick-greeter.conf \
       /etc/lightdm/slick-greeter.conf.backup.$(date +%Y%m%d_%H%M%S)
    
    # Update or add background line
    if grep -q "^background=" /etc/lightdm/slick-greeter.conf; then
        sed -i "s|^background=.*|background=$GREETER_WALLPAPER|" /etc/lightdm/slick-greeter.conf
    else
        echo "background=$GREETER_WALLPAPER" >> /etc/lightdm/slick-greeter.conf
    fi
    
    success "  ✓ LightDM Slick greeter background set!"
    greeter_configured=true
    echo
fi

# GDM (GNOME Display Manager) - INFO ONLY, NOT SETTING
if command -v gdm3 &> /dev/null || command -v gdm &> /dev/null; then
    info "Detected: GDM (GNOME Display Manager)"
    warn "  ⚠  GDM configuration skipped (uses theme background, not wallpaper)"
    info "  ℹ️  To customize GDM, modify the GNOME Shell theme instead"
    echo
fi

# SDDM (KDE/Qt Display Manager) - INFO ONLY
if command -v sddm &> /dev/null; then
    info "Detected: SDDM (Simple Desktop Display Manager)"
    warn "  ⚠  SDDM configuration skipped (uses theme background)"
    info "  ℹ️  To customize SDDM, edit /etc/sddm.conf or use System Settings"
    echo
fi

if [ "$greeter_configured" = false ]; then
    warn "No compatible login manager detected for greeter wallpaper"
    info "Detected login managers are using their theme backgrounds"
fi

#===========================================#
#   Summary                                #
#===========================================#
echo
echo "┌────────────────────────────────────────────────────────────┐"
success "✅ WOLF OS Wallpapers Configured as System Collection!"
echo "└────────────────────────────────────────────────────────────┘"
echo
info "📋 Installation Summary:"
echo
echo "  📁 System Locations:"
echo "     • $SYSTEM_WALLPAPERS"
echo "     • $IMAGES_WALLPAPERS"
echo "     • $IMAGES_DIR/wolf-os (symlink)"
echo
echo "  🎨 Desktop Environment Integration:"
if [ -f "$GNOME_PROPERTIES_DIR/wolf-os-wallpapers.xml" ]; then
    echo "     ✅ GNOME: Registered in wallpaper picker"
fi
if [ -L "$XFCE_BACKDROPS_DIR/wolf-os" ]; then
    echo "     ✅ XFCE: Available in settings"
fi
if [ -d "$KDE_WALLPAPER_DIR" ]; then
    echo "     ✅ KDE: Added to wallpaper collection"
fi
echo "     ✅ Debian: Available in /usr/share/images"
echo
echo "  🖼️  Desktop Wallpaper:"
echo "     $DESKTOP_WALLPAPER"
if [ "$set_wallpaper_success" = true ]; then
    echo "     Status: ✅ Currently active"
else
    echo "     Status: ⚠️  Manual setup required (user not logged in)"
fi
echo
echo "  🔐 Login Screen (LightDM only):"
echo "     $GREETER_WALLPAPER"
if [ "$greeter_configured" = true ]; then
    echo "     Status: ✅ Configured"
else
    echo "     Status: ℹ️  Not applicable (GDM/SDDM use themes)"
fi
echo
echo "┌────────────────────────────────────────────────────────────┐"
echo
info "🎨 How to Use WOLF OS Wallpapers:"
echo
echo "  ${CYAN}GNOME / Ubuntu:${RESET}"
echo "    Settings → Appearance → Background"
echo "    → You'll see 'WOLF OS - ...' wallpapers in the list!"
echo
echo "  ${CYAN}XFCE:${RESET}"
echo "    Desktop → Right-click → Desktop Settings"
echo "    → Folder: wolf-os (in the dropdown)"
echo
echo "  ${CYAN}KDE Plasma:${RESET}"
echo "    Desktop → Right-click → Configure Desktop and Wallpaper"
echo "    → Look for 'WOLF OS Wallpapers' in the list"
echo
echo "  ${CYAN}Other DEs:${RESET}"
echo "    Settings → Appearance → Browse to:"
echo "    $SYSTEM_WALLPAPERS"
echo "    Or: $IMAGES_WALLPAPERS"
echo
warn "⚠️  Important Notes:"
echo
echo "  • WOLF OS wallpapers are now part of system collection"
echo "  • Available in BOTH /usr/share/backgrounds AND /usr/share/images"
echo "  • They will appear in wallpaper pickers of all desktop environments"
echo "  • Desktop wallpaper changes require user to be logged in"
echo "  • LightDM greeter will show wolf-greeter.jpg on next login"
echo "  • To add more wallpapers, copy them to: $SYSTEM_WALLPAPERS"
echo "  • Then re-run this script to update metadata"
echo
info "🔄 Refresh Wallpaper List (if needed):"
echo
echo "  GNOME:   Log out and back in"
echo "  XFCE:    Restart xfdesktop: xfdesktop --reload"
echo "  KDE:     Run: kbuildsycoca5 --noincremental"
echo