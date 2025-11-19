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

info()    { echo -e "${BLUE}${BOLD}ℹ${RESET} $1"; }
success() { echo -e "${GREEN}${BOLD}✓${RESET} $1"; }
warn()    { echo -e "${YELLOW}${BOLD}⚠${RESET} $1"; }
error()   { echo -e "${RED}${BOLD}✗${RESET} $1"; }
section() { echo -e "\n${CYAN}${BOLD}┌── $1 ──┐${RESET}\n"; }

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

echo "${CYAN}${BOLD}"
cat << "EOF"
╔═══════════════════════════════════════════════════════╗
║                                                       ║
║       🐺  WOLF OS Neofetch Configuration  🐺         ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝
EOF
echo "${RESET}"

info "User: $REAL_USER"
info "Config directory: $NEOFETCH_CONFIG"
echo

#===========================================#
#   Install Neofetch                       #
#===========================================#
section "Installing Neofetch"

if command -v neofetch &> /dev/null; then
    success "Neofetch is already installed"
    NEOFETCH_VERSION=$(neofetch --version 2>/dev/null | head -1 || echo "unknown")
    info "Version: $NEOFETCH_VERSION"
else
    info "Installing Neofetch..."
    
    if [ "$EUID" -ne 0 ]; then
        sudo apt update
        sudo apt install -y neofetch
    else
        apt update
        apt install -y neofetch
    fi
    
    if command -v neofetch &> /dev/null; then
        success "Neofetch installed successfully!"
    else
        error "Failed to install Neofetch"
        exit 1
    fi
fi

#===========================================#
#   Backup Existing Configuration          #
#===========================================#
section "Configuration Setup"

mkdir -p "$NEOFETCH_CONFIG"
chown -R $REAL_USER:$REAL_USER "$NEOFETCH_CONFIG"

if [ -f "$NEOFETCH_CONF_FILE" ]; then
    BACKUP_FILE="${NEOFETCH_CONF_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    info "Backing up existing config..."
    cp "$NEOFETCH_CONF_FILE" "$BACKUP_FILE"
    success "Backup saved: $BACKUP_FILE"
fi

#===========================================#
#   Create WOLF OS ASCII Art Files         #
#===========================================#
section "Creating WOLF OS ASCII Art"

# Create ASCII art directory
ASCII_DIR="$NEOFETCH_CONFIG/ascii"
mkdir -p "$ASCII_DIR"

# Wolf ASCII Art (Default)
cat > "$ASCII_DIR/wolf.txt" << 'WOLFEOF'
${c1}                   ⢀⡀                
${c1}                  ⸸⠸⢳⡄              
${c1}                 ⢠⠃  ⢸⠸ ⡠⣄          
${c1}                ⡠⠃  ⢀⣞⣀⡿  ⣧          
${c2}             ⣀⣠⡖   ⢸⠈⢈⡇ ⢀⡠         
${c2}           ⡴⠩⢠⡴   ⠈⡶⠉ ⡸            
${c2}          ⢀⠎⢠⣇⠀      ⣆⣀⢾⢟⠴⡇          
${c2}         ⢀⣿ ⠠⣄⠸⢹⣦ ⡄  ⢋⡟  ⠀⣇          
${c3}        ⢀⡾⠀⢠ ⣿⠃⠘⢹⣦⢠⣼  ⠉    ⢸⡀        
${c3}      ⢀⣴⫠⤣⣶⣿⢀⡠  ⠘⢸⡟⠋        ⢳        
${c4}   ⠀⠿⢿⣿⣤⣴⣿⣣⢾⡄        ⠳      ⢀⡀⣾⡇     
${c4}     ⣨⣟⡠⠉⠚⠹⣇⡄         ⠈⢦  ⢀⡀⣾⣧⣯⢻     
${c5}    ⢠⠟⣹⣧⠃  ⢿⢻⡀⢄    ⠀⣦⡀⣸⣆ ⣾⣧⡎⠻⣆    
${c5}    ⡟⡿⢿⡿⡄    ⠳⣼⢦⡘⣄  ⡟⡷⠃⠘⢶⣿⡎⠻⣆   
${c6}     ⡇⣿⡅     ⠙ ⻢⢷⣼⠀   ⠙⢿⡄⡈⢆  
${c6}      ⠀⠛⠓                 ⠼⠇⠀
WOLFEOF

success "Created: wolf.txt (default)"

# Alternative Wolf ASCII (smaller)
cat > "$ASCII_DIR/wolf-small.txt" << 'WOLFSMALLEOF'
${c1}       /\___/\
${c1}      /       \
${c2}     |  ^   ^  |
${c2}     |    <    |
${c3}      \  ___  /
${c3}       \_____/
${c4}      /|     |\
${c4}     / |  W  | \
${c5}    /  |  O  |  \
${c5}   /   |  L  |   \
${c6}  /    |  F  |    \
${c6} /____ |     | ____\
WOLFSMALLEOF

success "Created: wolf-small.txt (alternative)"

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

success "Created: wolf-text.txt (text logo)"

chown -R $REAL_USER:$REAL_USER "$ASCII_DIR"

#===========================================#
#   Create Optimized Neofetch Config       #
#===========================================#
section "Creating WOLF OS Configuration"

cat > "$NEOFETCH_CONF_FILE" << 'CONFIGEOF'
# ┌────────────────────────────────────────────────────────┐
# │ 🐺 WOLF OS Neofetch Configuration                     │
# └────────────────────────────────────────────────────────┘

print_info() {
    # ┌─────────────────────────────────────┐
    # │ Header                              │
    # └─────────────────────────────────────┘
    
    prin "╭────────────────────────────────────────╮"
    info title
    prin "╰────────────────────────────────────────╯"
    prin
    
    # ┌─────────────────────────────────────┐
    # │ System Information                  │
    # └─────────────────────────────────────┘
    
    prin "$(color 1)┌─ System"
    info "$(color 7)│  OS" distro
    info "$(color 7)│  Host" model
    info "$(color 7)│  Kernel" kernel
    info "$(color 7)│  Uptime" uptime
    info "$(color 7)│  Packages" packages
    info "$(color 7)└  Shell" shell
    prin
    
    # ┌─────────────────────────────────────┐
    # │ Hardware Information                │
    # └─────────────────────────────────────┘
    
    prin "$(color 2)┌─ Hardware"
    info "$(color 7)│  CPU" cpu
    info "$(color 7)│  GPU" gpu
    info "$(color 7)│  Memory" memory
    info "$(color 7)└  Disk" disk
    prin
    
    # ┌─────────────────────────────────────┐
    # │ Desktop Environment                 │
    # └─────────────────────────────────────┘
    
    prin "$(color 3)┌─ Desktop"
    info "$(color 7)│  DE" de
    info "$(color 7)│  WM" wm
    info "$(color 7)│  Theme" theme
    info "$(color 7)│  Icons" icons
    info "$(color 7)│  Terminal" term
    info "$(color 7)└  Font" font
    prin
    
    # ┌─────────────────────────────────────┐
    # │ Color Palette                       │
    # └─────────────────────────────────────┘
    
    prin "$(color 4)┌─ Colors"
    info cols
    prin "$(color 4)└────────────────────────────────────────"
}

# ┌────────────────────────────────────────────────────────┐
# │ Title Configuration                                    │
# └────────────────────────────────────────────────────────┘
title_fqdn="off"

# ┌────────────────────────────────────────────────────────┐
# │ Kernel Configuration                                   │
# └────────────────────────────────────────────────────────┘
kernel_shorthand="on"

# ┌────────────────────────────────────────────────────────┐
# │ Distro Configuration                                   │
# └────────────────────────────────────────────────────────┘
distro_shorthand="off"
os_arch="on"

# ┌────────────────────────────────────────────────────────┐
# │ Uptime Configuration                                   │
# └────────────────────────────────────────────────────────┘
uptime_shorthand="on"

# ┌────────────────────────────────────────────────────────┐
# │ Memory Configuration                                   │
# └────────────────────────────────────────────────────────┘
memory_percent="on"
memory_unit="gib"

# ┌────────────────────────────────────────────────────────┐
# │ Packages Configuration                                 │
# └────────────────────────────────────────────────────────┘
package_managers="on"

# ┌────────────────────────────────────────────────────────┐
# │ Shell Configuration                                    │
# └────────────────────────────────────────────────────────┘
shell_path="off"
shell_version="on"

# ┌────────────────────────────────────────────────────────┐
# │ CPU Configuration                                      │
# └────────────────────────────────────────────────────────┘
speed_type="bios_limit"
speed_shorthand="on"
cpu_brand="on"
cpu_speed="on"
cpu_cores="logical"
cpu_temp="off"

# ┌────────────────────────────────────────────────────────┐
# │ GPU Configuration                                      │
# └────────────────────────────────────────────────────────┘
gpu_brand="on"
gpu_type="all"

# ┌────────────────────────────────────────────────────────┐
# │ Resolution Configuration                               │
# └────────────────────────────────────────────────────────┘
refresh_rate="off"

# ┌────────────────────────────────────────────────────────┐
# │ Disk Configuration                                     │
# └────────────────────────────────────────────────────────┘
disk_show=('/')
disk_subtitle="mount"
disk_percent="on"

# ┌────────────────────────────────────────────────────────┐
# │ Text Colors                                            │
# └────────────────────────────────────────────────────────┘
colors=(distro)

# ┌────────────────────────────────────────────────────────┐
# │ Text Options                                           │
# └────────────────────────────────────────────────────────┘
bold="on"
underline_enabled="on"
underline_char="─"
separator=" ➜ "

# ┌────────────────────────────────────────────────────────┐
# │ Color Blocks                                           │
# └────────────────────────────────────────────────────────┘
block_range=(0 15)
color_blocks="on"
block_width=3
block_height=1
col_offset="auto"

# ┌────────────────────────────────────────────────────────┐
# │ Progress Bars                                          │
# └────────────────────────────────────────────────────────┘
bar_char_elapsed="━"
bar_char_total="─"
bar_border="on"
bar_length=15
bar_color_elapsed="distro"
bar_color_total="distro"

cpu_display="off"
memory_display="bar"
battery_display="off"
disk_display="bar"

# ┌────────────────────────────────────────────────────────┐
# │ Backend Settings (Image/ASCII)                         │
# └────────────────────────────────────────────────────────┘
image_backend="ascii"
image_source="auto"

# ┌────────────────────────────────────────────────────────┐
# │ ASCII Art Configuration                                │
# └────────────────────────────────────────────────────────┘
ascii_distro="auto"

# WOLF OS: Uncomment ONE of these to use WOLF OS ASCII art:
# ascii_distro="\$HOME/.config/neofetch/ascii/wolf.txt"
# ascii_distro="\$HOME/.config/neofetch/ascii/wolf-small.txt"
# ascii_distro="\$HOME/.config/neofetch/ascii/wolf-text.txt"

ascii_colors=(1 2 3 4 5 6)
ascii_bold="on"

# ┌────────────────────────────────────────────────────────┐
# │ Image Options (when using image backend)               │
# └────────────────────────────────────────────────────────┘
image_loop="off"
thumbnail_dir="${XDG_CACHE_HOME:-$HOME/.cache}/thumbnails/neofetch"
crop_mode="normal"
crop_offset="center"
image_size="auto"
gap=3
yoffset=0
xoffset=0
background_color=

# ┌────────────────────────────────────────────────────────┐
# │ Misc Options                                           │
# └────────────────────────────────────────────────────────┘
stdout="off"
CONFIGEOF

chown $REAL_USER:$REAL_USER "$NEOFETCH_CONF_FILE"
success "Configuration file created!"

#===========================================#
#   Create WOLF OS Variant Configs         #
#===========================================#
section "Creating WOLF OS Variant Configurations"

# Config with Wolf ASCII (default)
cat > "$NEOFETCH_CONFIG/config-wolf.conf" << 'WOLFCONFEOF'
# Include default config
source "$HOME/.config/neofetch/config.conf"

# Override ASCII art
ascii_distro="$HOME/.config/neofetch/ascii/wolf.txt"
ascii_colors=(1 2 3 4 5 6)
WOLFCONFEOF

# Config with small Wolf
cat > "$NEOFETCH_CONFIG/config-wolf-small.conf" << 'WOLFSMALLCONFEOF'
# Include default config
source "$HOME/.config/neofetch/config.conf"

# Override ASCII art
ascii_distro="$HOME/.config/neofetch/ascii/wolf-small.txt"
ascii_colors=(1 2 3 4 5 6)
WOLFSMALLCONFEOF

# Config with Wolf text logo
cat > "$NEOFETCH_CONFIG/config-wolf-text.conf" << 'WOLFTEXTCONFEOF'
# Include default config
source "$HOME/.config/neofetch/config.conf"

# Override ASCII art
ascii_distro="$HOME/.config/neofetch/ascii/wolf-text.txt"
ascii_colors=(1 2 3 4 5 6)
WOLFTEXTCONFEOF

chown -R $REAL_USER:$REAL_USER "$NEOFETCH_CONFIG"

success "Created variant configurations!"

#===========================================#
#   Create Shell Aliases                   #
#===========================================#
section "Creating Shell Aliases"

ALIASES_FILE="$USER_HOME/.neofetch_aliases"

cat > "$ALIASES_FILE" << 'ALIASEOF'
# ┌────────────────────────────────────────────────────────┐
# │ 🐺 WOLF OS Neofetch Aliases                           │
# └────────────────────────────────────────────────────────┘

# Default neofetch (uses system default)
alias neofetch='neofetch'

# WOLF OS variants
alias wolf='neofetch --config ~/.config/neofetch/config-wolf.conf'
alias wolf-small='neofetch --config ~/.config/neofetch/config-wolf-small.conf'
alias wolf-text='neofetch --config ~/.config/neofetch/config-wolf-text.conf'

# Quick system info
alias sysinfo='neofetch --config ~/.config/neofetch/config-wolf.conf'

# Neofetch with custom backend
alias neofetch-img='neofetch --backend kitty --source auto'
alias neofetch-w3m='neofetch --backend w3m --source auto'
ALIASEOF

chown $REAL_USER:$REAL_USER "$ALIASES_FILE"
success "Aliases created: $ALIASES_FILE"

# Add to shell profiles
info "Integrating with shell profiles..."

for rc_file in "$USER_HOME/.bashrc" "$USER_HOME/.zshrc"; do
    if [ -f "$rc_file" ]; then
        if ! grep -q "neofetch_aliases" "$rc_file" 2>/dev/null; then
            echo "" >> "$rc_file"
            echo "# WOLF OS Neofetch aliases" >> "$rc_file"
            echo "[ -f ~/.neofetch_aliases ] && source ~/.neofetch_aliases" >> "$rc_file"
            success "Added to: $(basename $rc_file)"
        else
            info "Already integrated: $(basename $rc_file)"
        fi
    fi
done

#===========================================#
#   Interactive Selection                  #
#===========================================#
section "WOLF OS ASCII Art Selection"

echo "Which WOLF OS ASCII art would you like as default?"
echo
echo "1) Wolf (detailed) - Recommended"
echo "2) Wolf (small)"
echo "3) Wolf (text logo)"
echo "4) Keep system default"
echo

read -rp "Select option [1-4]: " ascii_choice

case $ascii_choice in
    1)
        info "Setting detailed Wolf ASCII as default..."
        sed -i 's|^ascii_distro="auto"|ascii_distro="$HOME/.config/neofetch/ascii/wolf.txt"|' "$NEOFETCH_CONF_FILE"
        success "✓ Detailed Wolf ASCII enabled!"
        ;;
    2)
        info "Setting small Wolf ASCII as default..."
        sed -i 's|^ascii_distro="auto"|ascii_distro="$HOME/.config/neofetch/ascii/wolf-small.txt"|' "$NEOFETCH_CONF_FILE"
        success "✓ Small Wolf ASCII enabled!"
        ;;
    3)
        info "Setting Wolf text logo as default..."
        sed -i 's|^ascii_distro="auto"|ascii_distro="$HOME/.config/neofetch/ascii/wolf-text.txt"|' "$NEOFETCH_CONF_FILE"
        success "✓ Wolf text logo enabled!"
        ;;
    4)
        info "Keeping system default ASCII..."
        success "✓ System default preserved"
        ;;
    *)
        warn "Invalid choice, keeping system default"
        ;;
esac

#===========================================#
#   Auto-run on Shell Startup (Optional)   #
#===========================================#
echo
section "Shell Startup Configuration"

read -rp "Run neofetch automatically on shell startup? (y/n): " auto_run

if [[ $auto_run == [Yy]* ]]; then
    info "Configuring auto-run..."
    
    for rc_file in "$USER_HOME/.bashrc" "$USER_HOME/.zshrc"; do
        if [ -f "$rc_file" ]; then
            # Remove old neofetch calls
            sed -i '/^neofetch$/d' "$rc_file" 2>/dev/null || true
            sed -i '/^# Run neofetch/d' "$rc_file" 2>/dev/null || true
            
            # Add new auto-run with WOLF OS
            if ! grep -q "# WOLF OS neofetch auto-run" "$rc_file" 2>/dev/null; then
                cat >> "$rc_file" << 'AUTORUNEOF'

# WOLF OS neofetch auto-run
if command -v neofetch &> /dev/null; then
    # Run neofetch on interactive shells only
    if [[ $- == *i* ]]; then
        neofetch --config ~/.config/neofetch/config.conf
    fi
fi
AUTORUNEOF
                success "Auto-run enabled in: $(basename $rc_file)"
            else
                info "Auto-run already configured: $(basename $rc_file)"
            fi
        fi
    done
    
    success "✓ Neofetch will run on shell startup!"
else
    info "Auto-run skipped. Run manually with: neofetch or wolf"
fi

#===========================================#
#   Test Neofetch Configuration            #
#===========================================#
section "Testing Configuration"

info "Running neofetch test..."
echo

# Test as the real user
if sudo -u $REAL_USER neofetch --config "$NEOFETCH_CONF_FILE" 2>/dev/null; then
    echo
    success "✓ Neofetch is working correctly!"
else
    warn "Test completed (some features may require terminal restart)"
fi

#===========================================#
#   Summary Report                         #
#===========================================#
echo
echo "┌──────────────────────────────────────────────────────┐"
success "✅ WOLF OS Neofetch Configuration Complete!"
echo "└──────────────────────────────────────────────────────┘"
echo
info "📋 Installation Summary:"
echo
echo "  ✓ Neofetch installed"
echo "  ✓ WOLF OS configuration created"
echo "  ✓ 3 ASCII art variants installed"
echo "  ✓ Shell aliases configured"
if [[ $auto_run == [Yy]* ]]; then
    echo "  ✓ Auto-run on shell startup enabled"
fi
echo
echo "┌──────────────────────────────────────────────────────┐"
echo
info "📂 Configuration Files:"
echo
echo "  Main config:    ${CYAN}~/.config/neofetch/config.conf${RESET}"
echo "  ASCII art:      ${CYAN}~/.config/neofetch/ascii/${RESET}"
echo "  Aliases:        ${CYAN}~/.neofetch_aliases${RESET}"
echo
echo "┌──────────────────────────────────────────────────────┐"
echo
info "🎨 Available Commands:"
echo
echo "  ${CYAN}neofetch${RESET}         - Default neofetch"
echo "  ${CYAN}wolf${RESET}             - WOLF OS detailed wolf"
echo "  ${CYAN}wolf-small${RESET}       - WOLF OS small wolf"
echo "  ${CYAN}wolf-text${RESET}        - WOLF OS text logo"
echo "  ${CYAN}sysinfo${RESET}          - Quick system info"
echo
echo "┌──────────────────────────────────────────────────────┐"
echo
warn "⚠️  Important:"
echo
echo "  • Restart your terminal to apply changes"
echo "  • Or reload shell: ${CYAN}source ~/.$(basename $SHELL)rc${RESET}"
if [[ $auto_run == [Yy]* ]]; then
    echo "  • Neofetch will run automatically on new shell sessions"
fi
echo
info "🎯 Try it now:"
echo
echo "  ${MAGENTA}${BOLD}wolf${RESET}"
echo
success "🐺 Enjoy your WOLF OS themed neofetch!"
echo
echo "${MAGENTA}${BOLD}"
cat << "EOF"
                    ┌─────────────────────────────┐
                    │  Made With ❤️  by k4rim0sama │
                    └─────────────────────────────┘
EOF
echo "${RESET}"