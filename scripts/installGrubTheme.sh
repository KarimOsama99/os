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
    success "Theme includes its own background"
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

#===========================================#
#   Copy Theme Background to GRUB Boot Dir #
#   (FIX: Debian default background issue) #
#===========================================#
echo
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
info "🔧 Fixing GRUB Fallback Background"
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

# Find background in theme (prioritize common names)
THEME_BG=""
for bg_name in "background.png" "background.jpg" "bg.png" "bg.jpg" "wallpaper.png" "wallpaper.jpg"; do
    if [ -f "$THEME_DEST/$bg_name" ]; then
        THEME_BG="$THEME_DEST/$bg_name"
        break
    fi
done

# If not found by name, search
if [ -z "$THEME_BG" ]; then
    THEME_BG=$(find "$THEME_DEST" -type f \( \
        -iname "background.*" -o \
        -iname "bg.*" -o \
        -iname "*wallpaper*" \
    \) | head -1)
fi

if [ -n "$THEME_BG" ]; then
    info "Found theme background: $(basename "$THEME_BG")"
    
    # Copy to GRUB directory
    GRUB_BG_DIR="/boot/grub"
    mkdir -p "$GRUB_BG_DIR"
    
    # Determine extension
    BG_EXT="${THEME_BG##*.}"
    GRUB_BG_FILE="$GRUB_BG_DIR/wolf-background.$BG_EXT"
    
    info "Copying to: $GRUB_BG_FILE"
    cp "$THEME_BG" "$GRUB_BG_FILE"
    chmod 644 "$GRUB_BG_FILE"
    
    # Remove old GRUB_BACKGROUND lines
    sed -i '/^GRUB_BACKGROUND=/d' "$GRUB_CONFIG"
    sed -i '/^#GRUB_BACKGROUND=/d' "$GRUB_CONFIG"
    
    # Add GRUB_BACKGROUND to config
    echo "GRUB_BACKGROUND=\"$GRUB_BG_FILE\"" >> "$GRUB_CONFIG"
    
    success "✅ GRUB fallback background configured!"
    info "Background file: $GRUB_BG_FILE"
    
    # Also remove Debian default backgrounds if they exist
    info "Removing Debian default backgrounds..."
    for debian_bg in /boot/grub/debian-theme/grub-4x3.png /boot/grub/debian-theme/grub-16x9.png; do
        if [ -f "$debian_bg" ]; then
            mv "$debian_bg" "${debian_bg}.disabled" 2>/dev/null || true
            info "  • Disabled: $(basename "$debian_bg")"
        fi
    done
    
    success "✅ Debian default backgrounds disabled"
else
    warn "⚠️  No background found in theme"
    info "Theme will use text-based menu only"
fi

echo

#==================#
#   Verification   #
#==================#
echo
info "Verifying GRUB configuration..."
echo "┌────────────────────────────────────────┐"
grep "GRUB_THEME\|GRUB_GFXMODE\|GRUB_GFXPAYLOAD\|GRUB_BACKGROUND" "$GRUB_CONFIG" | while read -r line; do
    echo -e "${GREEN}  $line${RESET}"
done
echo "└────────────────────────────────────────┘"

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
echo "┌────────────────────────────────────────────────────────────┐"
success "✅ GRUB Theme Installed Successfully!"
echo "└────────────────────────────────────────────────────────────┘"
echo
info "📋 Installation Summary:"
echo
echo "  • Theme: $THEME_NAME"
echo "  • Location: $THEME_DEST"
echo "  • Config: $THEME_DEST/theme.txt"
if [ -n "$THEME_BG" ]; then
    echo "  • Menu Background: Using theme's background"
    echo "  • Fallback Background: $GRUB_BG_FILE"
    echo "  • Debian backgrounds: DISABLED"
else
    echo "  • Background: Text-based menu"
fi
echo
success "🎯 Fixed Issues:"
echo
echo "  ✅ Theme background displayed in menu"
echo "  ✅ Fallback background set (no more Debian default)"
echo "  ✅ Background persists after OS selection"
echo "  ✅ Debian default backgrounds disabled"
echo
warn "⚠️  GRUB theme will be visible on next reboot"
echo
info "🧪 Test GRUB Theme (optional):"
echo
echo "  View current GRUB config:"
echo "    cat /boot/grub/grub.cfg | grep -A5 'set theme'"
echo
echo "  Check background file:"
echo "    ls -lh $GRUB_BG_FILE"
echo
info "🔧 Troubleshooting:"
echo
echo "  • Restore backup: cp $GRUB_CONFIG.backup.* $GRUB_CONFIG"
echo "  • Update GRUB manually: sudo update-grub"
echo "  • Check theme files: ls -la $THEME_DEST"
echo "  • View GRUB config: cat $GRUB_CONFIG | grep GRUB_"
echo "  • Re-enable Debian bg: mv /boot/grub/debian-theme/*.disabled /boot/grub/debian-theme/"
echo