#!/usr/bin/env bash
#============================================================#
#              WOLF OS Neofetch Configuration                #
#         Custom ASCII art + Optimized Config                #
#============================================================#

set -euo pipefail

RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
CYAN="\033[1;36m"
MAGENTA="\033[1;35m"
BOLD="\033[1m"
RESET="\033[0m"

info()    { echo -e "${BLUE}[INFO]${RESET} $1"; }
success() { echo -e "${GREEN}[OK]${RESET} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET} $1"; }
error()   { echo -e "${RED}[ERROR]${RESET} $1"; }

# Function to ask user with clear prompt
ask_user() {
    local prompt="$1"
    local default="${2:-}"
    local response
    
    echo ""
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${YELLOW}${BOLD}❓ ${prompt}${RESET}"
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
    read -rp "👉 Your choice: " response
    echo ""
    
    echo "${response:-$default}"
}

#==================#
#   Get User Info  #
#==================#
if [ "$EUID" -eq 0 ]; then
    REAL_USER=${SUDO_USER:-$USER}
    USER_HOME=$(eval echo ~$REAL_USER)
else
    REAL_USER=$USER
    USER_HOME=$HOME
fi

NEOFETCH_CONFIG="$USER_HOME/.config/neofetch"
NEOFETCH_CONF_FILE="$NEOFETCH_CONFIG/config.conf"

info "Configuring Neofetch for user: $REAL_USER"

#===========================================#
#   Install Neofetch                       #
#===========================================#
if command -v neofetch &> /dev/null; then
    info "Neofetch already installed"
else
    info "Installing Neofetch..."
    
    if [ "$EUID" -ne 0 ]; then
        sudo apt update -qq
        sudo apt install -y neofetch >/dev/null 2>&1
    else
        apt update -qq
        apt install -y neofetch >/dev/null 2>&1
    fi
    
    if command -v neofetch &> /dev/null; then
        success "Neofetch installed"
    else
        error "Failed to install Neofetch"
        exit 1
    fi
fi

#===========================================#
#   Backup Existing Configuration          #
#===========================================#
mkdir -p "$NEOFETCH_CONFIG"
chown -R $REAL_USER:$REAL_USER "$NEOFETCH_CONFIG"

if [ -f "$NEOFETCH_CONF_FILE" ]; then
    BACKUP_FILE="${NEOFETCH_CONF_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$NEOFETCH_CONF_FILE" "$BACKUP_FILE"
    info "Existing config backed up"
fi

#===========================================#
#   Create WOLF OS ASCII Art Files         #
#===========================================#
ASCII_DIR="$NEOFETCH_CONFIG/ascii"
mkdir -p "$ASCII_DIR"

# Wolf ASCII Art (Braille)
cat > "$ASCII_DIR/wolf.txt" << 'WOLFEOF'
${c1}⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
${c2}⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⠁⠸⢳⡄⠀⠀⠀⠀⠀⠀⠀⠀
${c3}⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⠃⠀⠀⢸⠸⠀⡠⣄⠀⠀⠀⠀⠀
${c4}⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡠⠃⠀⠀⢠⣞⣀⡿⠀⠀⣧⠀⠀⠀⠀
${c5}⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣠⡖⠁⠀⠀⠀⢸⠈⢈⡇⠀⢀⡏⠀⠀⠀⠀
${c6}⠀⠀⠀⠀⠀⠀⠀⠀⠀⡴⠩⢠⡴⠀⠀⠀⠀⠀⠈⡶⠉⠀⠀⡸⠀⠀⠀⠀⠀
${c1}⠀⠀⠀⠀⠀⠀⠀⢀⠎⢠⣇⠏⠀⠀⠀⠀⠀⠀⠀⠁⠀⢀⠄⡇⠀⠀⠀⠀⠀
${c2}⠀⠀⠀⠀⠀⠀⢠⠏⠀⢸⣿⣴⠀⠀⠀⠀⠀⠀⣆⣀⢾⢟⠴⡇⠀⠀⠀⠀⠀
${c3}⠀⠀⠀⠀⠀⢀⣿⠀⠠⣄⠸⢹⣦⠀⠀⡄⠀⠀⢋⡟⠀⠀⠁⣇⠀⠀⠀⠀⠀
${c4}⠀⠀⠀⠀⢀⡾⠁⢠⠀⣿⠃⠘⢹⣦⢠⣼⠀⠀⠉⠀⠀⠀⠀⢸⡀⠀⠀⠀⠀
${c5}⠀⠀⢀⣴⠫⠤⣶⣿⢀⡏⠀⠀⠘⢸⡟⠋⠀⠀⠀⠀⠀⠀⠀⠀⢳⠀⠀⠀⠀
${c6}⠐⠿⢿⣿⣤⣴⣿⣣⢾⡄⠀⠀⠀⠀⠳⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢣⠀⠀⠀
${c1}⠀⠀⠀⣨⣟⡍⠉⠚⠹⣇⡄⠀⠀⠀⠀⠀⠀⠀⠀⠈⢦⠀⠀⢀⡀⣾⡇⠀⠀
${c2}⠀⠀⢠⠟⣹⣧⠃⠀⠀⢿⢻⡀⢄⠀⠀⠀⠀⠐⣦⡀⣸⣆⠀⣾⣧⣯⢻⠀⠀
${c3}⠀⠀⠘⣰⣿⣿⡄⡆⠀⠀⠀⠳⣼⢦⡘⣄⠀⠀⡟⡷⠃⠘⢶⣿⡎⠻⣆⠀⠀
${c4}⠀⠀⠀⡟⡿⢿⡿⠀⠀⠀⠀⠀⠙⠀⠻⢯⢷⣼⠁⠁⠀⠀⠀⠙⢿⡄⡈⢆⠀
${c5}⠀⠀⠀⠀⡇⣿⡅⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⠦⠀⠀⠀⠀⠀⠀⡇⢹⢿⡀
${c6}⠀⠀⠀⠀⠁⠛⠓⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠼⠇⠁
WOLFEOF

# Wolf Text Art
cat > "$ASCII_DIR/wolf-text.txt" << 'WOLFTEXTEOF'
${c1} ██╗    ██╗ ██████╗ ██╗     ███████╗
${c2} ██║    ██║██╔═══██╗██║     ██╔════╝
${c3} ██║ █╗ ██║██║   ██║██║     █████╗  
${c4} ██║███╗██║██║   ██║██║     ██╔══╝  
${c5} ╚███╔███╔╝╚██████╔╝███████╗██║     
${c6}  ╚══╝╚══╝  ╚═════╝ ╚══════╝╚═╝     
${c1}                                     
${c2}  ██████╗ ███████╗
${c3} ██╔═══██╗██╔════╝
${c4} ██║   ██║███████╗
${c5} ██║   ██║╚════██║
${c6} ╚██████╔╝███████║
${c1}  ╚═════╝ ╚══════╝
WOLFTEXTEOF

chown -R $REAL_USER:$REAL_USER "$ASCII_DIR"
success "ASCII art files created"

#===========================================#
#   Create WOLF OS Neofetch Config         #
#===========================================#
info "Creating configuration..."

cat > "$NEOFETCH_CONF_FILE" << 'CONFIGEOF'
# WOLF OS Neofetch Configuration

print_info() {
    info title
    info underline
    
    prin "OS" "WOLF OS"
    
    info "Host" model
    info "Kernel" kernel
    info "Uptime" uptime
    info "Packages" packages
    info "Shell" shell
    info "Resolution" resolution
    info "DE" de
    info "WM" wm
    info "WM Theme" wm_theme
    info "Theme" theme
    info "Icons" icons
    info "Terminal" term
    info "Terminal Font" term_font
    info "CPU" cpu
    info "GPU" gpu
    info "Memory" memory
    
    info cols
}

title_fqdn="off"
kernel_shorthand="on"
distro_shorthand="off"
os_arch="on"
uptime_shorthand="on"
memory_percent="on"
memory_unit="gib"
package_managers="on"
shell_path="off"
shell_version="on"
speed_type="bios_limit"
speed_shorthand="on"
cpu_brand="on"
cpu_speed="on"
cpu_cores="logical"
cpu_temp="off"
gpu_brand="on"
gpu_type="all"
refresh_rate="off"
disk_show=('/')
disk_subtitle="mount"
disk_percent="on"
colors=(distro)
bold="on"
underline_enabled="on"
underline_char="-"
separator=":"
block_range=(0 15)
color_blocks="on"
block_width=3
block_height=1
col_offset="auto"
bar_char_elapsed="-"
bar_char_total="="
bar_border="on"
bar_length=15
bar_color_elapsed="distro"
bar_color_total="distro"
cpu_display="off"
memory_display="bar"
battery_display="off"
disk_display="bar"
image_backend="ascii"
ascii_distro="auto"
ascii_colors=(1 2 3 4 5 6)
ascii_bold="on"
image_loop="off"
thumbnail_dir="${XDG_CACHE_HOME:-$HOME/.cache}/thumbnails/neofetch"
crop_mode="normal"
crop_offset="center"
image_size="auto"
gap=3
yoffset=0
xoffset=0
background_color=
stdout="off"
CONFIGEOF

chown $REAL_USER:$REAL_USER "$NEOFETCH_CONF_FILE"

#===========================================#
#   ASCII Art Selection                    #
#===========================================#
echo ""
echo -e "${CYAN}${BOLD}╔═══════════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}${BOLD}║                                                   ║${RESET}"
echo -e "${CYAN}${BOLD}║       🎨 Choose WOLF OS ASCII Art Style 🎨       ║${RESET}"
echo -e "${CYAN}${BOLD}║                                                   ║${RESET}"
echo -e "${CYAN}${BOLD}╚═══════════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "${GREEN}${BOLD}1)${RESET} Wolf ASCII Art ${YELLOW}(Braille dots - Detailed)${RESET}"
echo -e "${GREEN}${BOLD}2)${RESET} Wolf Text Logo ${YELLOW}(Block letters - Bold)${RESET}"
echo ""

ascii_choice=$(ask_user "Select option [1-2]" "1")

case $ascii_choice in
    1)
        sed -i 's|^ascii_distro="auto"|ascii_distro="'"$ASCII_DIR/wolf.txt"'"|' "$NEOFETCH_CONF_FILE"
        success "✓ Wolf ASCII (Braille) enabled"
        ;;
    2)
        sed -i 's|^ascii_distro="auto"|ascii_distro="'"$ASCII_DIR/wolf-text.txt"'"|' "$NEOFETCH_CONF_FILE"
        success "✓ Wolf Text logo enabled"
        ;;
    *)
        sed -i 's|^ascii_distro="auto"|ascii_distro="'"$ASCII_DIR/wolf.txt"'"|' "$NEOFETCH_CONF_FILE"
        warn "Invalid choice, using Wolf ASCII by default"
        ;;
esac

#===========================================#
#   Create Wrapper Script                  #
#===========================================#
info "Creating neofetch wrapper..."

WRAPPER_SCRIPT="$USER_HOME/.local/bin/neofetch"
mkdir -p "$USER_HOME/.local/bin"

cat > "$WRAPPER_SCRIPT" << 'WRAPPEREOF'
#!/usr/bin/env bash
# WOLF OS Neofetch Wrapper

CONFIG_FILE="$HOME/.config/neofetch/config.conf"
/usr/bin/neofetch --config "$CONFIG_FILE" "$@"
WRAPPEREOF

chmod +x "$WRAPPER_SCRIPT"
chown $REAL_USER:$REAL_USER "$WRAPPER_SCRIPT"

success "Neofetch wrapper created at ~/.local/bin/neofetch"

#===========================================#
#   Ensure ~/.local/bin in PATH            #
#===========================================#
info "Ensuring ~/.local/bin is in PATH..."

for rc_file in "$USER_HOME/.bashrc" "$USER_HOME/.zshrc"; do
    if [ -f "$rc_file" ]; then
        if ! grep -q 'PATH.*\.local/bin' "$rc_file" 2>/dev/null; then
            cat >> "$rc_file" <<'PATHEOF'

# Add ~/.local/bin to PATH for user scripts
export PATH="$HOME/.local/bin:$PATH"
PATHEOF
            success "Added ~/.local/bin to PATH in $(basename $rc_file)"
        else
            info "PATH already includes ~/.local/bin in $(basename $rc_file)"
        fi
    fi
done

export PATH="$USER_HOME/.local/bin:$PATH"
success "PATH configuration complete"

#===========================================#
#   Shell Integration                      #
#===========================================#
auto_run=$(ask_user "Auto-run neofetch on shell startup? (y/n)" "n")

if [[ $auto_run == [Yy]* ]]; then
    for rc_file in "$USER_HOME/.bashrc" "$USER_HOME/.zshrc"; do
        if [ -f "$rc_file" ]; then
            sed -i '/^neofetch$/d' "$rc_file" 2>/dev/null || true
            sed -i '/^# Run neofetch/d' "$rc_file" 2>/dev/null || true
            sed -i '/# WOLF OS neofetch/d' "$rc_file" 2>/dev/null || true
            
            if ! grep -q "neofetch --config" "$rc_file" 2>/dev/null; then
                cat >> "$rc_file" << 'AUTORUNEOF'

# WOLF OS neofetch
if command -v neofetch &> /dev/null && [[ $- == *i* ]]; then
    neofetch
fi
AUTORUNEOF
            fi
        fi
    done
    success "Auto-run configured"
else
    info "Skipped auto-run configuration"
fi

#===========================================#
#   Test Configuration                     #
#===========================================#
echo ""
info "Testing neofetch configuration..."
echo ""

export PATH="$USER_HOME/.local/bin:$PATH"
sudo -u $REAL_USER bash -c "export PATH=\"$USER_HOME/.local/bin:\$PATH\"; neofetch" 2>/dev/null || {
    warn "Could not test neofetch (normal if running via sudo)"
}

#===========================================#
#   Final Instructions                     #
#===========================================#
echo ""
echo -e "${CYAN}${BOLD}╔═══════════════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}${BOLD}║                                                       ║${RESET}"
echo -e "${CYAN}${BOLD}║         ✅ Neofetch configured successfully!          ║${RESET}"
echo -e "${CYAN}${BOLD}║                                                       ║${RESET}"
echo -e "${CYAN}${BOLD}╚═══════════════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "${GREEN}${BOLD}📋 What was configured:${RESET}"
echo ""
echo "  ✓ Neofetch installed and configured"
echo "  ✓ WOLF OS custom ASCII art created"
echo "  ✓ Custom config with 'WOLF OS (Debian 13)'"
echo "  ✓ Wrapper script created"
echo "  ✓ PATH includes ~/.local/bin"
echo ""
echo -e "${GREEN}${BOLD}🎨 Your ASCII choice:${RESET}"
case $ascii_choice in
    1) echo "  ✓ Wolf ASCII (Braille art)" ;;
    2) echo "  ✓ Wolf Text logo" ;;
    *) echo "  ✓ Wolf ASCII (default)" ;;
esac
echo ""
echo -e "${GREEN}${BOLD}🚀 How to use:${RESET}"
echo ""
echo -e "  Just run:  ${CYAN}neofetch${RESET}"
echo ""
echo -e "${YELLOW}${BOLD}⚠️  Important:${RESET}"
echo ""
echo "  • Restart your terminal for changes to take effect"
echo "  • The wrapper overrides system neofetch"
echo ""
success "🐺 Enjoy your WOLF OS neofetch!"
echo ""