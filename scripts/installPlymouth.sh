#!/usr/bin/env bash
#============================================================#
#        Plymouth Boot Theme Installation (Dynamic)         #
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
THEMES_DIR="$PROJECT_ROOT/themes"
PLYMOUTH_SYSTEM_DIR="/usr/share/plymouth/themes"

echo "======================================"
echo "  Plymouth Theme Installation"
echo "======================================"
echo

info "Project root: $PROJECT_ROOT"
info "Themes directory: $THEMES_DIR"

#==================#
#   Validate Setup #
#==================#
if [ ! -d "$THEMES_DIR" ]; then
    error "Themes directory not found: $THEMES_DIR"
    exit 1
fi

#===========================================#
#   Discover Plymouth Themes Dynamically   #
#===========================================#
info "Scanning for Plymouth themes..."
echo

declare -a PLYMOUTH_THEMES=()
declare -a PLYMOUTH_THEME_PATHS=()

# Search for .plymouth files in themes directory
while IFS= read -r -d '' plymouth_file; do
    theme_dir="$(dirname "$plymouth_file")"
    theme_name="$(basename "$theme_dir")"
    
    # Verify it's a valid Plymouth theme
    if [ -f "$plymouth_file" ]; then
        PLYMOUTH_THEMES+=("$theme_name")
        PLYMOUTH_THEME_PATHS+=("$theme_dir")
    fi
done < <(find "$THEMES_DIR" -name "*.plymouth" -type f -print0 2>/dev/null)

#==================#
#   Theme Selection #
#==================#
if [ ${#PLYMOUTH_THEMES[@]} -eq 0 ]; then
    error "No Plymouth themes found in $THEMES_DIR"
    echo
    info "Expected structure:"
    echo "  themes/"
    echo "  └── your-plymouth-theme/"
    echo "      ├── theme-name.plymouth"
    echo "      └── [theme files...]"
    exit 1
fi

echo -e "${CYAN}Found ${#PLYMOUTH_THEMES[@]} Plymouth theme(s):${RESET}"
echo

if [ ${#PLYMOUTH_THEMES[@]} -eq 1 ]; then
    # Only one theme found, use it automatically
    SELECTED_INDEX=0
    THEME_NAME="${PLYMOUTH_THEMES[0]}"
    THEME_PATH="${PLYMOUTH_THEME_PATHS[0]}"
    
    info "Auto-selecting: ${THEME_NAME}"
else
    # Multiple themes found, let user choose
    for i in "${!PLYMOUTH_THEMES[@]}"; do
        printf "%2d) %s\n" $((i+1)) "${PLYMOUTH_THEMES[$i]}"
    done
    
    echo
    read -rp "Select theme number [1-${#PLYMOUTH_THEMES[@]}]: " theme_choice
    
    # Validate input
    if ! [[ "$theme_choice" =~ ^[0-9]+$ ]] || \
       [ "$theme_choice" -lt 1 ] || \
       [ "$theme_choice" -gt ${#PLYMOUTH_THEMES[@]} ]; then
        error "Invalid selection"
        exit 1
    fi
    
    SELECTED_INDEX=$((theme_choice - 1))
    THEME_NAME="${PLYMOUTH_THEMES[$SELECTED_INDEX]}"
    THEME_PATH="${PLYMOUTH_THEME_PATHS[$SELECTED_INDEX]}"
fi

echo
info "Selected theme: ${THEME_NAME}"
info "Theme path: ${THEME_PATH}"

#==================#
#   Install Plymouth #
#==================#
info "Installing Plymouth and dependencies..."
if ! dpkg -l | grep -q plymouth; then
    apt update
    apt install -y plymouth plymouth-themes plymouth-label
    success "Plymouth installed!"
else
    info "Plymouth already installed"
fi

#===========================================#
#   Find .plymouth File in Selected Theme  #
#===========================================#
PLYMOUTH_FILE=$(find "$THEME_PATH" -maxdepth 1 -name "*.plymouth" -type f | head -1)

if [ -z "$PLYMOUTH_FILE" ]; then
    error "No .plymouth file found in theme directory!"
    error "Contents of $THEME_PATH:"
    ls -la "$THEME_PATH"
    exit 1
fi

info "Found Plymouth configuration: $(basename "$PLYMOUTH_FILE")"

#==================#
#   Install Theme  #
#==================#
THEME_DEST="$PLYMOUTH_SYSTEM_DIR/$THEME_NAME"

# Backup existing theme if present
if [ -d "$THEME_DEST" ]; then
    warn "Theme already exists, creating backup..."
    mv "$THEME_DEST" "${THEME_DEST}.backup.$(date +%Y%m%d_%H%M%S)"
fi

info "Copying theme to $THEME_DEST..."
cp -r "$THEME_PATH" "$THEME_DEST"

# Ensure proper permissions
chmod 755 "$THEME_DEST"
find "$THEME_DEST" -type f -exec chmod 644 {} \;

success "Theme copied successfully!"

#===========================================#
#   Configure Plymouth to Use Theme        #
#===========================================#
PLYMOUTH_FILE_NAME="$(basename "$PLYMOUTH_FILE")"
THEME_CONFIG_NAME="${PLYMOUTH_FILE_NAME%.plymouth}"

info "Setting Plymouth theme: $THEME_CONFIG_NAME"

# Remove old alternatives
update-alternatives --remove-all default.plymouth 2>/dev/null || true

# Install as alternative with high priority
update-alternatives --install \
    /usr/share/plymouth/themes/default.plymouth \
    default.plymouth \
    "$THEME_DEST/$PLYMOUTH_FILE_NAME" \
    100

# Set as default
update-alternatives --set default.plymouth "$THEME_DEST/$PLYMOUTH_FILE_NAME"

# Also use plymouth-set-default-theme
if command -v plymouth-set-default-theme &> /dev/null; then
    plymouth-set-default-theme -R "$THEME_NAME" 2>/dev/null || true
fi

success "Plymouth theme configured!"

#==================#
#   Update initramfs #
#==================#
info "Updating initramfs (this may take a few minutes)..."
update-initramfs -u -k all

success "Initramfs updated!"

#==================#
#   Verification   #
#==================#
echo
info "Verifying installation..."

CURRENT_THEME=$(plymouth-set-default-theme 2>/dev/null || echo "unknown")
info "Current Plymouth theme: $CURRENT_THEME"

if [ "$CURRENT_THEME" = "$THEME_NAME" ]; then
    success "✅ Plymouth theme installed successfully!"
else
    warn "Theme may not be set correctly (showing: $CURRENT_THEME)"
    warn "Expected: $THEME_NAME"
    
    info "Attempting alternative configuration method..."
    plymouth-set-default-theme "$THEME_NAME"
    update-initramfs -u
    
    CURRENT_THEME=$(plymouth-set-default-theme 2>/dev/null || echo "unknown")
    if [ "$CURRENT_THEME" = "$THEME_NAME" ]; then
        success "✅ Theme set successfully on second attempt!"
    else
        warn "Manual intervention may be required"
    fi
fi

#==================#
#   Final Info     #
#==================#
echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
success "✅ Plymouth Installation Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
info "📋 Installation Summary:"
echo "  • Theme: $THEME_NAME"
echo "  • Location: $THEME_DEST"
echo "  • Config: $PLYMOUTH_FILE_NAME"
echo
warn "⚠️  Plymouth theme will be visible on next boot"
echo
info "🧪 Test Plymouth now (will briefly show boot screen):"
echo "  sudo plymouthd"
echo "  sudo plymouth --show-splash"
echo "  sleep 5"
echo "  sudo plymouth quit"
echo
info "🔧 Troubleshooting:"
echo "  • Check available themes: plymouth-set-default-theme --list"
echo "  • Switch themes: plymouth-set-default-theme <theme-name>"
echo "  • Rebuild initramfs: update-initramfs -u"
echo