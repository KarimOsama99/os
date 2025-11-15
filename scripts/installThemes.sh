#!/usr/bin/env bash
#============================================================#
#            GRUB & Plymouth Theme Installer                #
#============================================================#

set -e

#==================#
#   Colors Setup   #
#==================#
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
    echo
    read -p "Press Enter to continue and enter your sudo password... " _
    sudo -k
    exec sudo bash "$0" "$@"
fi

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEMES_DIR="$SCRIPT_DIR/../themes"  # مجلد themes بجانب مجلد scripts

#==================#
# Install GRUB Theme
#==================#
info "Installing GRUB theme..."

GRUB_THEME_SRC="$THEMES_DIR/CyberEXS"  # غير الاسم حسب مجلدك
GRUB_THEMES_DIR="/boot/grub/themes"

if [ ! -d "$GRUB_THEME_SRC" ]; then
    error "GRUB theme folder not found at: $GRUB_THEME_SRC"
    exit 1
fi

# Create themes directory if it doesn't exist
mkdir -p "$GRUB_THEMES_DIR"

# Get theme folder name
THEME_NAME=$(basename "$GRUB_THEME_SRC")

# Copy theme
info "Copying GRUB theme to $GRUB_THEMES_DIR/$THEME_NAME"
cp -r "$GRUB_THEME_SRC" "$GRUB_THEMES_DIR/"

# Backup GRUB config
GRUB_CONFIG="/etc/default/grub"
cp "$GRUB_CONFIG" "${GRUB_CONFIG}.backup"
info "Backup created: ${GRUB_CONFIG}.backup"

# Update GRUB config
THEME_PATH="$GRUB_THEMES_DIR/$THEME_NAME/theme.txt"

if [ -f "$THEME_PATH" ]; then
    # Remove old GRUB_THEME line if exists
    sed -i '/^GRUB_THEME=/d' "$GRUB_CONFIG"
    
    # Add new GRUB_THEME line
    echo "GRUB_THEME=\"$THEME_PATH\"" >> "$GRUB_CONFIG"
    
    # Update GRUB
    info "Updating GRUB configuration..."
    update-grub
    
    success "GRUB theme installed successfully!"
else
    error "theme.txt not found in $GRUB_THEME_SRC"
    error "Make sure your GRUB theme has a theme.txt file"
    exit 1
fi

#==================#
# Install Plymouth Theme
#==================#
info "Installing Plymouth theme..."

PLYMOUTH_THEME_SRC="$THEMES_DIR/logo-mac-style"  # غير الاسم حسب مجلدك
PLYMOUTH_THEMES_DIR="/usr/share/plymouth/themes"

if [ ! -d "$PLYMOUTH_THEME_SRC" ]; then
    error "Plymouth theme folder not found at: $PLYMOUTH_THEME_SRC"
    exit 1
fi

# Get theme folder name
PLYMOUTH_THEME_NAME=$(basename "$PLYMOUTH_THEME_SRC")

# Copy theme
info "Copying Plymouth theme to $PLYMOUTH_THEMES_DIR/$PLYMOUTH_THEME_NAME"
cp -r "$PLYMOUTH_THEME_SRC" "$PLYMOUTH_THEMES_DIR/"

# Set as default theme
info "Setting Plymouth theme as default..."
plymouth-set-default-theme -R "$PLYMOUTH_THEME_NAME"

success "Plymouth theme installed successfully!"

#==================#
# Done
#==================#
echo
success "✅ All themes installed!"
warn "🔄 Changes will take effect after reboot"
echo
info "📋 Summary:"
echo "  GRUB Theme: $THEME_NAME"
echo "  Plymouth Theme: $PLYMOUTH_THEME_NAME"