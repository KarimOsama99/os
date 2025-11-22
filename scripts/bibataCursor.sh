#!/usr/bin/env bash
set -euo pipefail

RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
CYAN="\033[1;36m"
BOLD="\033[1m"
RESET="\033[0m"

info()    { echo -e "${BLUE}[INFO]${RESET} $1"; }
success() { echo -e "${GREEN}[OK]${RESET} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET} $1"; }
error()   { echo -e "${RED}[ERROR]${RESET} $1"; }

# Check dependencies
for cmd in curl tar; do
  if ! command -v "$cmd" &> /dev/null; then
    error "Missing dependency: $cmd"
    echo "Install with: sudo apt install curl tar"
    exit 1
  fi
done

# Install to BOTH locations for maximum compatibility
CURSOR_DIR_USER="$HOME/.local/share/icons"
CURSOR_DIR_SYSTEM="/usr/share/icons"
mkdir -p "$CURSOR_DIR_USER"

# Available styles and colors
STYLES=("Modern" "Original")
COLORS=("Amber" "Classic" "Ice")

echo ""
echo -e "${CYAN}${BOLD}╔═══════════════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}${BOLD}║                                                       ║${RESET}"
echo -e "${CYAN}${BOLD}║       🖱️  Bibata Cursor Theme Installer 🖱️           ║${RESET}"
echo -e "${CYAN}${BOLD}║                                                       ║${RESET}"
echo -e "${CYAN}${BOLD}╚═══════════════════════════════════════════════════════╝${RESET}"
echo ""

# Function to ask user
ask_user() {
    local prompt="$1"
    local response
    
    echo ""
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${YELLOW}${BOLD}❓ ${prompt}${RESET}"
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
    read -rp "👉 Your choice: " response
    echo ""
    
    echo "$response"
}

# Step 1: Choose style
echo -e "${GREEN}${BOLD}📋 Available Styles:${RESET}"
echo ""
for i in "${!STYLES[@]}"; do
  echo -e "  ${GREEN}$((i+1)))${RESET} ${STYLES[$i]}"
done
echo -e "  ${GREEN}$((${#STYLES[@]}+1)))${RESET} ${BOLD}Install ALL themes${RESET}"
echo ""

ALL_OPTION=$((${#STYLES[@]}+1))

SN=$(ask_user "Choose style number [1-${ALL_OPTION}]")

if [[ "$SN" == "$ALL_OPTION" ]]; then
  echo -e "${CYAN}${BOLD}🎯 Installing ALL Bibata cursor themes...${RESET}"
  echo ""
  
  declare -a ALL_THEMES=(
    "Bibata-Modern-Amber"
    "Bibata-Modern-Classic" 
    "Bibata-Modern-Ice"
    "Bibata-Original-Amber"
    "Bibata-Original-Classic"
    "Bibata-Original-Ice"
  )
  
  success_count=0
  for theme in "${ALL_THEMES[@]}"; do
    echo -e "${BLUE}📥 Downloading ${theme}...${RESET}"
    
    TEMP_DIR="/tmp/bibata-${theme}-$$"
    mkdir -p "$TEMP_DIR"
    
    URL="https://github.com/ful1e5/Bibata_Cursor/releases/latest/download/${theme}.tar.xz"
    
    if curl -L -o "$TEMP_DIR/${theme}.tar.xz" "$URL" --progress-bar --fail; then
      echo -e "${BLUE}📦 Extracting ${theme}...${RESET}"
      cd "$TEMP_DIR"
      
      if tar -xf "${theme}.tar.xz"; then
        EXTRACTED_DIR=$(find . -maxdepth 1 -type d -name "*Bibata*" | head -1)
        
        if [[ -n "$EXTRACTED_DIR" ]]; then
          # Install to user directory
          DEST_DIR_USER="$CURSOR_DIR_USER/$theme"
          if [[ -d "$DEST_DIR_USER" ]]; then
            rm -rf "$DEST_DIR_USER"
          fi
          cp -r "$EXTRACTED_DIR" "$DEST_DIR_USER"
          
          # Install to system directory (with sudo)
          if [ "$EUID" -eq 0 ]; then
            DEST_DIR_SYSTEM="$CURSOR_DIR_SYSTEM/$theme"
            if [[ -d "$DEST_DIR_SYSTEM" ]]; then
              rm -rf "$DEST_DIR_SYSTEM"
            fi
            cp -r "$EXTRACTED_DIR" "$DEST_DIR_SYSTEM"
          else
            sudo cp -r "$EXTRACTED_DIR" "$CURSOR_DIR_SYSTEM/$theme" 2>/dev/null || warn "Could not install to system directory (needs sudo)"
          fi
          
          success "Installed: ${theme}"
          ((success_count++))
        else
          error "Could not find extracted directory for ${theme}"
        fi
      else
        error "Failed to extract ${theme}"
      fi
    else
      error "Failed to download ${theme}"
    fi
    
    rm -rf "$TEMP_DIR"
  done
  
  echo ""
  echo -e "${GREEN}${BOLD}🎉 Installation complete!${RESET}"
  echo -e "   Successfully installed: ${BOLD}${success_count}/${#ALL_THEMES[@]}${RESET} themes"
  
else
  # Single theme selection
  if [[ "$SN" -lt 1 ]] || [[ "$SN" -gt ${#STYLES[@]} ]]; then
    error "Invalid style selection"
    exit 1
  fi
  
  STYLE="${STYLES[$((SN-1))]}"
  
  # Step 2: Choose color
  echo -e "${GREEN}${BOLD}🎨 Available Colors:${RESET}"
  echo ""
  for i in "${!COLORS[@]}"; do
    echo -e "  ${GREEN}$((i+1)))${RESET} ${COLORS[$i]}"
  done
  echo ""
  
  CN=$(ask_user "Choose color number [1-${#COLORS[@]}]")
  
  if [[ "$CN" -lt 1 ]] || [[ "$CN" -gt ${#COLORS[@]} ]]; then
    error "Invalid color selection"
    exit 1
  fi
  
  COLOR="${COLORS[$((CN-1))]}"
  
  # Step 3: Download and install
  THEME_NAME="Bibata-${STYLE}-${COLOR}"
  echo -e "${BLUE}📥 Downloading ${THEME_NAME}...${RESET}"
  
  TEMP_DIR="/tmp/bibata-${THEME_NAME}-$$"
  mkdir -p "$TEMP_DIR"
  
  URL="https://github.com/ful1e5/Bibata_Cursor/releases/latest/download/${THEME_NAME}.tar.xz"
  
  if ! curl -L -o "$TEMP_DIR/${THEME_NAME}.tar.xz" "$URL" --progress-bar --fail; then
    error "Failed to download ${THEME_NAME}"
    echo "   URL: $URL"
    rm -rf "$TEMP_DIR"
    exit 1
  fi
  
  echo -e "${BLUE}📦 Extracting ${THEME_NAME}...${RESET}"
  cd "$TEMP_DIR"
  
  if ! tar -xf "${THEME_NAME}.tar.xz"; then
    error "Failed to extract ${THEME_NAME}"
    rm -rf "$TEMP_DIR"
    exit 1
  fi
  
  EXTRACTED_DIR=$(find . -maxdepth 1 -type d -name "*Bibata*" | head -1)
  
  if [[ -z "$EXTRACTED_DIR" ]]; then
    error "Could not find extracted theme directory"
    rm -rf "$TEMP_DIR"
    exit 1
  fi
  
  # Install to user directory
  DEST_DIR_USER="$CURSOR_DIR_USER/$THEME_NAME"
  if [[ -d "$DEST_DIR_USER" ]]; then
    warn "Overwriting existing theme: ${THEME_NAME}"
    rm -rf "$DEST_DIR_USER"
  fi
  cp -r "$EXTRACTED_DIR" "$DEST_DIR_USER"
  
  # Install to system directory
  if [ "$EUID" -eq 0 ]; then
    DEST_DIR_SYSTEM="$CURSOR_DIR_SYSTEM/$THEME_NAME"
    if [[ -d "$DEST_DIR_SYSTEM" ]]; then
      rm -rf "$DEST_DIR_SYSTEM"
    fi
    cp -r "$EXTRACTED_DIR" "$DEST_DIR_SYSTEM"
  else
    sudo cp -r "$EXTRACTED_DIR" "$CURSOR_DIR_SYSTEM/$THEME_NAME" 2>/dev/null || warn "Could not install to system directory"
  fi
  
  success "Theme '${THEME_NAME}' installed!"
  
  rm -rf "$TEMP_DIR"
fi

# CRITICAL: Refresh icon cache
echo ""
info "Refreshing icon cache..."
gtk-update-icon-cache -f "$CURSOR_DIR_USER" 2>/dev/null || true
if [ "$EUID" -eq 0 ]; then
    gtk-update-icon-cache -f "$CURSOR_DIR_SYSTEM" 2>/dev/null || true
else
    sudo gtk-update-icon-cache -f "$CURSOR_DIR_SYSTEM" 2>/dev/null || true
fi
success "Icon cache refreshed"

# Set default cursor theme (optional)
echo ""
DEFAULT_THEME=$(ask_user "Set Bibata-Modern-Classic as default cursor? (y/n)")
if [[ "$DEFAULT_THEME" =~ ^[Yy]$ ]]; then
    mkdir -p "$HOME/.icons/default"
    cat > "$HOME/.icons/default/index.theme" <<EOF
[Icon Theme]
Name=Default
Comment=Default Cursor Theme
Inherits=Bibata-Modern-Classic
EOF
    success "Default cursor theme set to Bibata-Modern-Classic"
fi

echo ""
echo -e "${CYAN}${BOLD}╔═══════════════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}${BOLD}║                                                       ║${RESET}"
echo -e "${CYAN}${BOLD}║            ✅ Installation Complete! ✅               ║${RESET}"
echo -e "${CYAN}${BOLD}║                                                       ║${RESET}"
echo -e "${CYAN}${BOLD}╚═══════════════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "${GREEN}${BOLD}📍 Next steps:${RESET}"
echo ""
echo "  1️⃣  Open your system settings"
echo "  2️⃣  Go to: ${BOLD}Appearance → Cursor Theme${RESET}"
echo "     Or: ${BOLD}Mouse & Touchpad → Cursor Theme${RESET}"
echo "  3️⃣  Select your new Bibata cursor"
echo "  4️⃣  Log out and back in if needed"
echo ""
echo -e "${BLUE}📂 Cursor themes installed in:${RESET}"
echo "  • $CURSOR_DIR_USER"
echo "  • $CURSOR_DIR_SYSTEM"
echo ""
echo -e "${YELLOW}💡 Tip: If cursors don't appear immediately:${RESET}"
echo "  • Run: ${CYAN}gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Classic'${RESET}"
echo "  • Or restart your desktop environment"
echo ""