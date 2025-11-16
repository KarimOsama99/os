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
GRUB_THEME_SOURCE="$PROJECT_ROOT/themes/CyberEXS"
WALLPAPERS_DIR="/usr/share/backgrounds/wolf-os"

echo "=================================="
echo "  GRUB Theme Installation"
echo "=================================="
echo

info "Project root: $PROJECT_ROOT"
info "GRUB theme source: $GRUB_THEME_SOURCE"

# Check if GRUB theme exists
if [ ! -d "$GRUB_THEME_SOURCE" ]; then
    error "GRUB theme 'CyberEXS' not found at: $GRUB_THEME_SOURCE"
    error "Please ensure the theme folder exists in themes/CyberEXS"
    exit 1
fi

info "Found GRUB theme: CyberEXS"

GRUB_THEMES_DIR="/boot/grub/themes"
THEME_NAME="CyberEXS"
THEME_DEST="$GRUB_THEMES_DIR/$THEME_NAME"

# Create themes directory
mkdir -p "$GRUB_THEMES_DIR"

# Remove old installation if exists
if [ -d "$THEME_DEST" ]; then
    info "Removing old GRUB theme installation..."
    rm -rf "$THEME_DEST"
fi

# Copy theme
info "Copying GRUB theme to $THEME_DEST..."
cp -r "$GRUB_THEME_SOURCE" "$THEME_DEST"

# Find theme.txt
THEME_FILE="$THEME_DEST/theme.txt"

if [ ! -f "$THEME_FILE" ]; then
    error "theme.txt not found in GRUB theme directory!"
    error "Contents of $THEME_DEST:"
    ls -la "$THEME_DEST"
    exit 1
fi

info "Found theme file: $THEME_FILE"

# Use wolf-greeter.jpg if it exists and theme has background
if [ -f "$WALLPAPERS_DIR/wolf-greeter.jpg" ]; then
    info "Checking for background image in theme..."
    
    # Find any background images
    BACKGROUND_FILES=$(find "$THEME_DEST" -type f \( -name "background.*" -o -name "bg.*" \) 2>/dev/null)
    
    if [ -n "$BACKGROUND_FILES" ]; then
        info "Found background images, backing up and replacing with wolf-greeter.jpg..."
        for bg in $BACKGROUND_FILES; do
            mv "$bg" "${bg}.backup"
            cp "$WALLPAPERS_DIR/wolf-greeter.jpg" "$bg"
            info "Replaced: $(basename $bg)"
        done
    else
        info "No background image found in theme, adding wolf-greeter.jpg..."
        cp "$WALLPAPERS_DIR/wolf-greeter.jpg" "$THEME_DEST/background.jpg"
    fi
fi

# Update GRUB config
GRUB_CONFIG="/etc/default/grub"

info "Backing up GRUB configuration..."
cp "$GRUB_CONFIG" "${GRUB_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"

# Remove old GRUB_THEME line if exists
info "Updating GRUB configuration..."
sed -i '/^GRUB_THEME=/d' "$GRUB_CONFIG"
sed -i '/^#GRUB_THEME=/d' "$GRUB_CONFIG"

# Add new GRUB_THEME line
echo "GRUB_THEME=\"$THEME_FILE\"" >> "$GRUB_CONFIG"

# Ensure GRUB_GFXMODE is set for better graphics
if ! grep -q "^GRUB_GFXMODE=" "$GRUB_CONFIG"; then
    echo "GRUB_GFXMODE=1920x1080" >> "$GRUB_CONFIG"
fi

# Verify the configuration
echo
info "Verifying GRUB configuration..."
grep "GRUB_THEME\|GRUB_GFXMODE" "$GRUB_CONFIG"

# Update GRUB
info "Updating GRUB configuration (this may take a moment)..."
update-grub

success "✅ GRUB theme installed successfully!"
echo
info "GRUB theme will be visible on next boot"
info "Theme location: $THEME_DEST"
info "Config backup: ${GRUB_CONFIG}.backup.*"