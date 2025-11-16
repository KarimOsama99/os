#!/usr/bin/env bash
#============================================================#
#              Plymouth Boot Theme Installation              #
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
PLYMOUTH_THEME_SOURCE="$PROJECT_ROOT/themes/logo-mac-style"
WALLPAPERS_DIR="/usr/share/backgrounds/wolf-os"

echo "=================================="
echo "  Plymouth Theme Installation"
echo "=================================="
echo

info "Project root: $PROJECT_ROOT"
info "Plymouth theme source: $PLYMOUTH_THEME_SOURCE"

# Install Plymouth and dependencies
info "Installing Plymouth and dependencies..."
apt update
apt install -y plymouth plymouth-themes plymouth-label plymouth-x11

success "Plymouth installed!"

# Check if custom theme exists
if [ ! -d "$PLYMOUTH_THEME_SOURCE" ]; then
    error "Plymouth theme 'logo-mac-style' not found at: $PLYMOUTH_THEME_SOURCE"
    error "Please ensure the theme folder exists in themes/logo-mac-style"
    exit 1
fi

info "Found Plymouth theme: logo-mac-style"

# Install the theme
PLYMOUTH_THEMES_DIR="/usr/share/plymouth/themes"
THEME_NAME="logo-mac-style"
THEME_DEST="$PLYMOUTH_THEMES_DIR/$THEME_NAME"

# Remove old installation if exists
if [ -d "$THEME_DEST" ]; then
    info "Removing old Plymouth theme installation..."
    rm -rf "$THEME_DEST"
fi

# Copy theme
info "Copying Plymouth theme to $THEME_DEST..."
cp -r "$PLYMOUTH_THEME_SOURCE" "$THEME_DEST"

# Find .plymouth file
PLYMOUTH_FILE=$(find "$THEME_DEST" -name "*.plymouth" -type f | head -1)

if [ -z "$PLYMOUTH_FILE" ]; then
    error "No .plymouth file found in theme directory!"
    error "Contents of $THEME_DEST:"
    ls -la "$THEME_DEST"
    exit 1
fi

info "Found Plymouth file: $PLYMOUTH_FILE"

# Set as default theme
PLYMOUTH_BASENAME=$(basename "$PLYMOUTH_FILE")
THEME_NAME_FROM_FILE="${PLYMOUTH_BASENAME%.plymouth}"

info "Setting Plymouth theme: $THEME_NAME_FROM_FILE"

# Remove old alternatives
update-alternatives --remove-all default.plymouth 2>/dev/null || true

# Install as alternative
update-alternatives --install \
    /usr/share/plymouth/themes/default.plymouth \
    default.plymouth \
    "$PLYMOUTH_FILE" \
    100

# Set as default
update-alternatives --set default.plymouth "$PLYMOUTH_FILE"

# Also use plymouth-set-default-theme
plymouth-set-default-theme -R "$THEME_NAME" 2>/dev/null || true

success "Plymouth theme set to: $THEME_NAME"

# Update initramfs
info "Updating initramfs (this may take a few minutes)..."
update-initramfs -u -k all

success "Initramfs updated!"

# Verify installation
echo
info "Verifying Plymouth installation..."
CURRENT_THEME=$(plymouth-set-default-theme)
info "Current Plymouth theme: $CURRENT_THEME"

if [ "$CURRENT_THEME" = "$THEME_NAME" ]; then
    success "✅ Plymouth theme installed successfully!"
else
    warn "Plymouth theme may not be set correctly"
    info "Trying alternative method..."
    plymouth-set-default-theme "$THEME_NAME"
    update-initramfs -u
fi

echo
success "✅ Plymouth installation complete!"
echo
info "Plymouth theme will be visible on next boot"
info "To test now (will briefly show boot screen):"
echo "  sudo plymouthd"
echo "  sudo plymouth --show-splash"
echo "  sleep 5"
echo "  sudo plymouth quit"