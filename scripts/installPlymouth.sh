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
PLYMOUTH_THEME_SOURCE="$PROJECT_ROOT/themes/plymouth-theme"
WALLPAPERS_DIR="/usr/share/backgrounds/wolf-os"

info "Installing Plymouth and dependencies..."

# Install Plymouth and tools
apt update
apt install -y plymouth plymouth-themes plymouth-label

success "Plymouth installed!"

# Check if custom theme exists
if [ ! -d "$PLYMOUTH_THEME_SOURCE" ]; then
    warn "Custom Plymouth theme not found at: $PLYMOUTH_THEME_SOURCE"
    warn "Using default Plymouth theme with WOLF wallpaper..."
    
    # Use a default theme and customize it
    PLYMOUTH_THEMES_DIR="/usr/share/plymouth/themes"
    
    # Check if wolf-greeter.jpg exists
    if [ -f "$WALLPAPERS_DIR/wolf-greeter.jpg" ]; then
        info "Setting wolf-greeter.jpg as Plymouth background..."
        
        # Use spinner theme as base
        if [ -d "$PLYMOUTH_THEMES_DIR/spinner" ]; then
            cp -r "$PLYMOUTH_THEMES_DIR/spinner" "$PLYMOUTH_THEMES_DIR/wolf-spinner"
            cp "$WALLPAPERS_DIR/wolf-greeter.jpg" "$PLYMOUTH_THEMES_DIR/wolf-spinner/background.jpg"
            
            # Update theme file
            sed -i 's/ImageDir=.*/ImageDir=\/usr\/share\/plymouth\/themes\/wolf-spinner/' "$PLYMOUTH_THEMES_DIR/wolf-spinner/spinner.plymouth"
            
            # Set as default
            update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth "$PLYMOUTH_THEMES_DIR/wolf-spinner/spinner.plymouth" 100
            update-alternatives --set default.plymouth "$PLYMOUTH_THEMES_DIR/wolf-spinner/spinner.plymouth"
            
            success "Wolf Plymouth theme created and set as default!"
        fi
    fi
else
    info "Installing custom Plymouth theme..."
    
    PLYMOUTH_THEMES_DIR="/usr/share/plymouth/themes"
    THEME_NAME=$(basename "$PLYMOUTH_THEME_SOURCE")
    THEME_DEST="$PLYMOUTH_THEMES_DIR/$THEME_NAME"
    
    # Copy theme
    cp -r "$PLYMOUTH_THEME_SOURCE" "$THEME_DEST"
    
    # Find .plymouth file
    PLYMOUTH_FILE=$(find "$THEME_DEST" -name "*.plymouth" | head -1)
    
    if [ -n "$PLYMOUTH_FILE" ]; then
        # Set as default
        update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth "$PLYMOUTH_FILE" 100
        update-alternatives --set default.plymouth "$PLYMOUTH_FILE"
        
        success "Custom Plymouth theme installed!"
    else
        error "No .plymouth file found in theme directory!"
        exit 1
    fi
fi

# Update initramfs
info "Updating initramfs..."
update-initramfs -u

success "✅ Plymouth installation complete!"
echo
info "Plymouth theme will be visible on next boot"
warn "To test: sudo plymouthd; sudo plymouth --show-splash; sleep 5; sudo plymouth quit"