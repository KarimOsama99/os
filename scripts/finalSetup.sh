#!/usr/bin/env bash
#============================================================#
#              Final System Setup & Cleanup                  #
#============================================================#

RED="\033[1;31m"
GREEN="\033[1;32m"
BLUE="\033[1;34m"
YELLOW="\033[1;33m"
RESET="\033[0m"

info()    { echo -e "${BLUE}[INFO]${RESET} $1"; }
success() { echo -e "${GREEN}[OK]${RESET} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET} $1"; }

if [ "$EUID" -ne 0 ]; then
    exec sudo bash "$0" "$@"
fi

info "Running final system setup..."

# Update font cache
info "Updating font cache..."
fc-cache -fv
success "Font cache updated!"

# Update icon cache
if command -v gtk-update-icon-cache &> /dev/null; then
    info "Updating icon cache..."
    gtk-update-icon-cache -f /usr/share/icons/* 2>/dev/null || true
    success "Icon cache updated!"
fi

# Clean package cache
info "Cleaning package cache..."
apt autoremove -y
apt autoclean
success "System cleaned!"

echo
success "✅ Final setup complete!"
warn "🔄 Please reboot your system to apply all changes"
