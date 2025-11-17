#!/usr/bin/env bash
#============================================================#
#          GRUB Theme Installation (Dynamic)                 #
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
GRUB_THEMES_DIR="/boot/grub/themes"

echo "======================================"
echo "  GRUB Theme Installation"
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
#   Discover GRUB Themes Dynamically       #
#===========================================#
info "Scanning for GRUB themes..."
echo

declare -a GRUB_THEMES=()
declare -a GRUB_THEME_PATHS=()

# Search for theme.txt files in themes directory
while IFS= read -r -d '' theme_file; do
    theme_dir="$(dirname "$theme_file")"
    theme_name="$(basename "$theme_dir")"
    
    # Verify it's a valid GRUB theme
    if [ -f "$theme_file" ]; then
        GRUB_THEMES+=("$theme_name")
        GRUB_THEME_PATHS+=("$theme_dir")
    fi
done < <(find "$THEMES_DIR" -name "theme.txt" -type f -print0 2>/dev/null)

#==================#
#   Theme Selection #
#==================#
if [ ${#GRUB_THEMES[@]} -eq 0 ]; then
    error "No GRUB themes found in $THEMES_DIR"
    echo
    info "Expected structure:"
    echo "  themes/"
    echo "  └── your-grub-theme/"
    echo "      ├── theme.txt"
    echo "      └── [theme files...]"
    exit 1
fi

echo -e "${CYAN}Found ${#GRUB_THEMES[@]} GRUB theme(s):${RESET}"
echo

if [ ${#GRUB_THEMES[@]} -eq 1 ]; then
    # Only one theme found, use it automatically
    SELECTED_INDEX=0
    THEME_NAME="${GRUB_THEMES[0]}"
    THEME_PATH="${GRUB_THEME_PATHS[0]}"
    
    info "Auto-selecting: ${THEME_NAME}"
else
    # Multiple themes found, let user choose
    for i in "${!GRUB_THEMES[@]}"; do
        printf "%2d) %s\n" $((i+1)) "${GRUB_THEMES[$i]}"
    done
    
    echo
    read -rp "Select theme number [1-${#GRUB_THEMES[@]}]: " theme_choice
    
    # Validate input
    if ! [[ "$theme_choice" =~ ^[0-9]+$ ]] || \
       [ "$theme_choice" -lt 1 ] || \
       [ "$theme_choice" -gt ${#GRUB_THEMES[@]} ]; then
        error "Invalid selection"
        exit 1
    fi
    
    SELECTED_INDEX=$((theme_choice - 1))
    THEME_NAME="${GRUB_THEMES[$SELECTED_INDEX]}"
    THEME_PATH="${GRUB_THEME_PATHS[$SELECTED_INDEX]}"
fi

echo
info "Selected theme: ${THEME_NAME}"
info "Theme path: ${THEME_PATH}"

#==================#
#   Verify theme.txt #
#==================#
THEME_FILE="$THEME_PATH/theme.txt"

if [ ! -f "$THEME_FILE" ]; then
    error "theme.txt not found in GRUB theme directory!"
    error "Path checked: $THEME_FILE"
    exit 1
fi

info "Found theme configuration: theme.txt"

# Display theme info if available
if grep -q "^title:" "$THEME_FILE"; then
    THEME_TITLE=$(grep "^title:" "$THEME_FILE" | cut -d: -f2- | xargs)
    info "Theme title: $THEME_TITLE"
fi

#==================#
#   Install Theme  #
#==================#
THEME_DEST="$GRUB_THEMES_DIR/$THEME_NAME"

# Create GRUB themes directory if not exists
mkdir -p "$GRUB_THEMES_DIR"

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
#   Detect and List Theme Background       #
#===========================================#
info "Analyzing theme background..."

BACKGROUND_FILES=$(find "$THEME_DEST" -type f \( \
    -iname "background.*" -o \
    -iname "bg.*" -o \
    -iname "*wallpaper*" -o \
    -iname "*backdrop*" \
\) 2>/dev/null)

if [ -n "$BACKGROUND_FILES" ]; then
    echo
    echo -e "${CYAN}Found theme background(s):${RESET}"
    echo "$BACKGROUND_FILES" | while read -r bg; do
        echo "  • $(basename "$bg")"
    done
    success "Theme includes its own background - using theme's background"
else
    warn "No background image found in theme"
    info "Theme will use GRUB's default background"
fi

#===========================================#
#   Update GRUB Configuration              #
#===========================================#
GRUB_CONFIG="/etc/default/grub"

info "Backing up GRUB configuration..."
cp "$GRUB_CONFIG" "${GRUB_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"

info "Updating GRUB configuration..."

# Remove old GRUB_THEME lines
sed -i '/^GRUB_THEME=/d' "$GRUB_CONFIG"
sed -i '/^#GRUB_THEME=/d' "$GRUB_CONFIG"

# Add new GRUB_THEME line
echo "GRUB_THEME=\"$THEME_DEST/theme.txt\"" >> "$GRUB_CONFIG"

# Configure GRUB_GFXMODE for better graphics
if ! grep -q "^GRUB_GFXMODE=" "$GRUB_CONFIG"; then
    info "Setting GRUB graphics mode to 1920x1080..."
    echo "GRUB_GFXMODE=1920x1080" >> "$GRUB_CONFIG"
else
    info "GRUB_GFXMODE already configured"
fi

# Ensure GRUB_GFXPAYLOAD_LINUX is set
if ! grep -q "^GRUB_GFXPAYLOAD_LINUX=" "$GRUB_CONFIG"; then
    info "Setting GRUB graphics payload..."
    echo "GRUB_GFXPAYLOAD_LINUX=keep" >> "$GRUB_CONFIG"
else
    info "GRUB_GFXPAYLOAD_LINUX already configured"
fi

success "GRUB configuration updated!"

#==================#
#   Verification   #
#==================#
echo
info "Verifying GRUB configuration..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
grep "GRUB_THEME\|GRUB_GFXMODE\|GRUB_GFXPAYLOAD" "$GRUB_CONFIG" | while read -r line; do
    echo -e "${GREEN}  $line${RESET}"
done
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

#==================#
#   Update GRUB    #
#==================#
echo
info "Updating GRUB (this may take a moment)..."

if command -v update-grub &> /dev/null; then
    update-grub
elif command -v grub-mkconfig &> /dev/null; then
    grub-mkconfig -o /boot/grub/grub.cfg
else
    error "Could not find GRUB update command!"
    error "Manually run: update-grub or grub-mkconfig"
    exit 1
fi

success "GRUB updated successfully!"

#==================#
#   Final Info     #
#==================#
echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
success "✅ GRUB Theme Installed Successfully!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
info "📋 Installation Summary:"
echo "  • Theme: $THEME_NAME"
echo "  • Location: $THEME_DEST"
echo "  • Config: $THEME_DEST/theme.txt"
if [ -n "$BACKGROUND_FILES" ]; then
    echo "  • Background: Using theme's own background"
else
    echo "  • Background: Using GRUB default"
fi
echo
warn "⚠️  GRUB theme will be visible on next reboot"
echo
info "🔧 Troubleshooting:"
echo "  • Restore backup: cp $GRUB_CONFIG.backup.* $GRUB_CONFIG"
echo "  • Update GRUB manually: sudo update-grub"
echo "  • Check theme files: ls -la $THEME_DEST"
echo "  • View GRUB config: cat $GRUB_CONFIG | grep GRUB_THEME"
echo