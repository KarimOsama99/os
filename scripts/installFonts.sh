#!/usr/bin/env bash
# Arabic + English Noto Fonts + JetBrainsMono Nerd Font setup

set -e

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
CYAN="\e[36m"
BOLD="\e[1m"
RESET="\e[0m"

info()    { echo -e "${BLUE}${BOLD}➤${RESET} $1"; }
success() { echo -e "${GREEN}${BOLD}✓${RESET} $1"; }
warn()    { echo -e "${YELLOW}${BOLD}⚠ ${RESET} $1"; }
error()   { echo -e "${RED}${BOLD}✖${RESET} $1"; }

echo ""
echo -e "${CYAN}${BOLD}╔═══════════════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}${BOLD}║                                                       ║${RESET}"
echo -e "${CYAN}${BOLD}║          🔤 Installing System Fonts 🔤                ║${RESET}"
echo -e "${CYAN}${BOLD}║                                                       ║${RESET}"
echo -e "${CYAN}${BOLD}╚═══════════════════════════════════════════════════════╝${RESET}"
echo ""

# Step 1: Install Noto Fonts
info "Installing Font Awesome and Noto fonts (English + Arabic)..."
sudo apt update -qq
sudo apt install -y fonts-font-awesome fonts-noto-core fonts-noto-unhinted curl
success "Noto fonts installed"

# Step 2: Create fontconfig directory
info "Creating fontconfig directory..."
mkdir -p ~/.config/fontconfig
success "~/.config/fontconfig ready"

# Step 3: Write fonts.conf
FONTCONF=~/.config/fontconfig/fonts.conf
info "Writing fonts.conf..."
cat > "$FONTCONF" <<'EOF'
<?xml version='1.0'?>
<!DOCTYPE fontconfig SYSTEM 'fonts.dtd'>
<fontconfig>
  <!-- Defaults -->
  <alias>
    <family>serif</family>
    <prefer>
      <family>Noto Serif</family>
      <family>Noto Sans Arabic</family>
    </prefer>
  </alias>
  <alias>
    <family>sans-serif</family>
    <prefer>
      <family>Noto Sans</family>
      <family>Noto Sans Arabic</family>
    </prefer>
  </alias>
  <alias>
    <family>sans</family>
    <prefer>
      <family>Noto Sans</family>
      <family>Noto Sans Arabic</family>
    </prefer>
  </alias>
  <alias>
    <family>monospace</family>
    <prefer>
      <family>JetBrainsMono Nerd Font Mono</family>
      <family>Noto Sans Mono</family>
    </prefer>
  </alias>
  <!-- Arial -->
  <alias>
    <family>Arial</family>
    <prefer>
      <family>Noto Sans</family>
      <family>Noto Sans Arabic</family>
    </prefer>
  </alias>
</fontconfig>
EOF
success "fonts.conf written to $FONTCONF"

# Step 4: Install JetBrainsMono Nerd Font
info "Installing JetBrainsMono Nerd Font..."
mkdir -p ~/.local/share/fonts
pushd ~/.local/share/fonts > /dev/null

info "Downloading JetBrainsMono Nerd Font..."
curl -sLO https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz

info "Extracting JetBrainsMono..."
bash -c 'mkdir -p "${1%.tar.xz}" && tar -xf "$1" -C "${1%.tar.xz}"' _ JetBrainsMono.tar.xz
rm JetBrainsMono.tar.xz

popd > /dev/null
success "JetBrainsMono Nerd Font installed"

# Step 5: Refresh font cache
info "Refreshing font cache (this may take a moment)..."
fc-cache -fv > /dev/null 2>&1
success "Font cache updated"

echo ""
echo -e "${CYAN}${BOLD}╔═══════════════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}${BOLD}║                                                       ║${RESET}"
echo -e "${CYAN}${BOLD}║              ✅ Font Setup Complete! ✅               ║${RESET}"
echo -e "${CYAN}${BOLD}║                                                       ║${RESET}"
echo -e "${CYAN}${BOLD}╚═══════════════════════════════════════════════════════╝${RESET}"
echo ""
info "📋 Installed fonts:"
echo "  ✓ Noto Sans (English)"
echo "  ✓ Noto Sans Arabic"
echo "  ✓ JetBrainsMono Nerd Font"
echo "  ✓ Font Awesome icons"
echo ""
info "🧪 Test your fonts:"
echo "  • Arabic: fc-match 'Noto Sans Arabic'"
echo "  • Mono:   fc-match 'JetBrainsMono Nerd Font Mono'"
echo ""