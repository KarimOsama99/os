#!/usr/bin/env bash
#============================================================#
#              GRUB Theme Installation                       #
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

if [ "$EUID" -ne 0 ]; then
    echo "This script requires root privileges."
    read -p "Press Enter to continue... " _
    exec sudo bash "$0" "$@"
fi

# Get directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
GRUB_THEME_SOURCE="$PROJECT_ROOT/themes/grub-theme"
WALLPAPERS_DIR="/usr/share/backgrounds/wolf-os"

info "Installing GRUB theme..."

# Check if GRUB theme exists
if [ ! -d "$GRUB_THEME_SOURCE" ]; then
    error "GRUB theme not found at: $GRUB_THEME_SOURCE"
    warn "Please add your GRUB theme to themes/grub-theme/"
    exit 1
fi

GRUB_THEMES_DIR="/boot/grub/themes"
THEME_NAME=$(basename "$GRUB_THEME_SOURCE")
THEME_DEST="$GRUB_THEMES_DIR/$THEME_NAME"

# Create themes directory
mkdir -p "$GRUB_THEMES_DIR"

# Copy theme
info "Copying GRUB theme to $THEME_DEST..."
cp -r "$GRUB_THEME_SOURCE" "$THEME_DEST"

# Find theme.txt
THEME_FILE="$THEME_DEST/theme.txt"

if [ ! -f "$THEME_FILE" ]; then
    error "theme.txt not found in GRUB theme directory!"
    exit 1
fi

# Use wolf-greeter.jpg if it exists
if [ -f "$WALLPAPERS_DIR/wolf-greeter.jpg" ]; then
    info "Using wolf-greeter.jpg as GRUB background..."
    cp "$WALLPAPERS_DIR/wolf-greeter.jpg" "$THEME_DEST/background.jpg"
fi

# Update GRUB config
GRUB_CONFIG="/etc/default/grub"
cp "$GRUB_CONFIG" "${GRUB_CONFIG}.backup"

# Remove old GRUB_THEME line if exists
sed -i '/^GRUB_THEME=/d' "$GRUB_CONFIG"

# Add new GRUB_THEME line
echo "GRUB_THEME=\"$THEME_FILE\"" >> "$GRUB_CONFIG"

# Update GRUB
info "Updating GRUB configuration..."
update-grub

success "✅ GRUB theme installed!"
echo
info "GRUB theme will be visible on next boot"
info "Backup: ${GRUB_CONFIG}.backup"