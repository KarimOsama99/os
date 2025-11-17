#!/usr/bin/env bash
#============================================================#
#              WOLF OS Wallpapers Installation               #
#              (wolf-greeter.jpg only for LightDM)           #
#============================================================#

set -euo pipefail

RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
CYAN="\033[1;36m"
RESET="\033[0m"

info()    { echo -e "${BLUE}[INFO]${RESET} $1"; }
success() { echo -e "${GREEN}[OK]${RESET} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET} $1"; }
error()   { echo -e "${RED}[ERROR]${RESET} $1"; }

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

success "Wallpapers copied!"

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
info "🖼️  Configuring desktop wallpapers..."
echo

# GNOME
if command -v gsettings &> /dev/null && [ -d "/usr/share/gnome" ]; then
    info "Detected: GNOME Desktop"
    
    if run_as_user gsettings set org.gnome.desktop.background picture-uri "file://$DESKTOP_WALLPAPER"; then
        run_as_user gsettings set org.gnome.desktop.background picture-uri-dark "file://$DESKTOP_WALLPAPER"
        success "  ✓ GNOME desktop wallpaper configured!"
        set_wallpaper_success=true
    else
        warn "  ⚠ Could not set GNOME wallpaper (user may need to be logged in)"
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
        warn "  ⚠ Could not detect XFCE monitors (user may need to be logged in)"
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
        warn "  ⚠ Could not set KDE wallpaper (user may need to be logged in)"
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
        warn "  ⚠ Could not set MATE wallpaper"
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
        warn "  ⚠ Could not set Cinnamon wallpaper"
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
        warn "  ⚠ Could not find PCManFM config"
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
info "🔐 Configuring login screen wallpapers..."
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
    warn "  ⚠ GDM configuration skipped (uses theme background, not wallpaper)"
    info "  ℹ️  To customize GDM, modify the GNOME Shell theme instead"
    echo
fi

# SDDM (KDE/Qt Display Manager) - INFO ONLY
if command -v sddm &> /dev/null; then
    info "Detected: SDDM (Simple Desktop Display Manager)"
    warn "  ⚠ SDDM configuration skipped (uses theme background)"
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
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
success "✅ WOLF OS Wallpapers Configured!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
info "📋 Configuration Summary:"
echo
echo "  📁 System Location:"
echo "     $SYSTEM_WALLPAPERS"
echo
echo "  🖼️  Desktop Wallpaper:"
echo "     $DESKTOP_WALLPAPER"
if [ "$set_wallpaper_success" = true ]; then
    echo "     Status: ✅ Configured"
else
    echo "     Status: ⚠️  Manual setup required"
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
warn "⚠️  Important Notes:"
echo
echo "  • Desktop wallpaper changes require user to be logged in"
echo "  • If wallpaper didn't change automatically:"
echo "    Right-click desktop → Change Background → Browse to:"
echo "    $SYSTEM_WALLPAPERS"
echo
echo "  • LightDM greeter will show wolf-greeter.jpg on next login"
echo "  • GDM/SDDM use their own theme backgrounds (not affected)"
echo "  • GRUB and Plymouth use their own theme backgrounds"
echo
info "🔧 Manual Configuration:"
echo
echo "  Desktop (any DE):"
echo "    Settings → Appearance → Background → Browse"
echo
echo "  LightDM GTK:"
echo "    Edit: /etc/lightdm/lightdm-gtk-greeter.conf"
echo "    Set: background=$GREETER_WALLPAPER"
echo
echo "  LightDM Slick:"
echo "    Edit: /etc/lightdm/slick-greeter.conf"
echo "    Set: background=$GREETER_WALLPAPER"
echo