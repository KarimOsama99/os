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
RESET="\033[0m"

info()    { echo -e "${BLUE}[INFO]${RESET} $1"; }
success() { echo -e "${GREEN}[OK]${RESET} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET} $1"; }
error()   { echo -e "${RED}[ERROR]${RESET} $1"; }

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

# Wolf ASCII Art (Default)
cat > "$ASCII_DIR/wolf.txt" << 'WOLFEOF'
${c1}                   ▄▀▄                
${c1}                  ¸¸ ¸▸ ▗▄              
${c1}                 ▄  ƒ  ▸ ¸ ▗▇▄          
${c1}                ▇  ƒ  ▀▇▞▄▇  ▇▧          
${c2}             ▄▇ ▇▗   ▸ ˆ█▇ ▀▇          
${c2}           ▇´ ©▄▇´   ˆ▇¶ ‰ ▇¸            
${c2}          ▀ Ž▄▇ €      ▇▄▀¾▟ ´▇          
${c2}         ▀▇ €  ▇▄ ¸▹▇▦ ▇▄  ▀‹▇Ÿ  € ▇          
${c3}        ▀▇¾ €▀  ▇▇ƒ ˆ ˜▹▇▦▄▇¼  ‰    ▸▇▀        
${c3}      ▀▇´«¤▇▇¶▇▇▀▇   ˜▸▇Ÿ‹        △        
${c4}   € ¿▀▇¿▇▇¤▇´▇▇£▾▇▄        ³      ▀▇▀▇¾▇     
${c4}     ▇¨▇£▇  ‰ š¹▇▇▄         ˆ▦  ▀▇▀▇¾▇▧▇¯▻     
${c5}    ▄ Ÿ▇¹▇▧ƒ  ▿▻▇▀▄    € ▇▦▇▀▇¸▇¾ ▇¾▇▧▇Ž »▇▆    
${c5}    ▇Ÿ▇¿▿▇¿▇▄    ³▇¼▀▦▇˜▇▄  ▇Ÿ▇·ƒ ˜▶▇▇¿▇Ž »▇▆   
${c6}     ▇▇▇¿▇…     ™ »¢▀·▇¼ €   ™▀▇¿▇▄▇ˆ▀▆  
${c6}      € ›" "                 ¼ ‡€
WOLFEOF

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
#   Create Standard Neofetch Config        #
#===========================================#
info "Creating configuration..."

cat > "$NEOFETCH_CONF_FILE" << 'CONFIGEOF'
# WOLF OS Neofetch Configuration

print_info() {
    info title
    info underline
    
    info "OS" distro
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

# Title
title_fqdn="off"

# Kernel
kernel_shorthand="on"

# Distro
distro_shorthand="off"
os_arch="on"

# Uptime
uptime_shorthand="on"

# Memory
memory_percent="on"
memory_unit="gib"

# Packages
package_managers="on"

# Shell
shell_path="off"
shell_version="on"

# CPU
speed_type="bios_limit"
speed_shorthand="on"
cpu_brand="on"
cpu_speed="on"
cpu_cores="logical"
cpu_temp="off"

# GPU
gpu_brand="on"
gpu_type="all"

# Resolution
refresh_rate="off"

# Disk
disk_show=('/')
disk_subtitle="mount"
disk_percent="on"

# Text Colors
colors=(distro)

# Text Options
bold="on"
underline_enabled="on"
underline_char="-"
separator=":"

# Color Blocks
block_range=(0 15)
color_blocks="on"
block_width=3
block_height=1
col_offset="auto"

# Progress Bars
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

# Backend Settings
image_backend="ascii"
image_source="auto"

# ASCII
ascii_distro="auto"
ascii_colors=(distro)
ascii_bold="on"

# Image Options
image_loop="off"
thumbnail_dir="${XDG_CACHE_HOME:-$HOME/.cache}/thumbnails/neofetch"
crop_mode="normal"
crop_offset="center"
image_size="auto"
gap=3
yoffset=0
xoffset=0
background_color=

# Misc
stdout="off"
CONFIGEOF

chown $REAL_USER:$REAL_USER "$NEOFETCH_CONF_FILE"

#===========================================#
#   ASCII Art Selection (Interactive)      #
#===========================================#
echo
echo "Choose WOLF OS ASCII art:"
echo "1) Wolf (detailed)"
echo "2) Wolf (small)"
echo "3) Wolf (text logo)"
echo "4) Default (distro logo)"
echo

read -rp "Select [1-4]: " ascii_choice

case $ascii_choice in
    1)
        sed -i 's|^ascii_distro="auto"|ascii_distro="'"$ASCII_DIR/wolf.txt"'"|' "$NEOFETCH_CONF_FILE"
        sed -i 's|^ascii_colors=(distro)|ascii_colors=(1 2 3 4 5 6)|' "$NEOFETCH_CONF_FILE"
        success "Detailed Wolf ASCII enabled"
        ;;
    2)
        sed -i 's|^ascii_distro="auto"|ascii_distro="'"$ASCII_DIR/wolf-small.txt"'"|' "$NEOFETCH_CONF_FILE"
        sed -i 's|^ascii_colors=(distro)|ascii_colors=(1 2 3 4 5 6)|' "$NEOFETCH_CONF_FILE"
        success "Small Wolf ASCII enabled"
        ;;
    3)
        sed -i 's|^ascii_distro="auto"|ascii_distro="'"$ASCII_DIR/wolf-text.txt"'"|' "$NEOFETCH_CONF_FILE"
        sed -i 's|^ascii_colors=(distro)|ascii_colors=(1 2 3 4 5 6)|' "$NEOFETCH_CONF_FILE"
        success "Wolf text logo enabled"
        ;;
    *)
        info "Using default distro logo"
        ;;
esac

#===========================================#
#   Shell Integration (Optional)           #
#===========================================#
echo
read -rp "Auto-run neofetch on shell startup? (y/n): " auto_run

if [[ $auto_run == [Yy]* ]]; then
    for rc_file in "$USER_HOME/.bashrc" "$USER_HOME/.zshrc"; do
        if [ -f "$rc_file" ]; then
            # Remove old entries
            sed -i '/^neofetch$/d' "$rc_file" 2>/dev/null || true
            sed -i '/^# Run neofetch/d' "$rc_file" 2>/dev/null || true
            sed -i '/# WOLF OS neofetch/d' "$rc_file" 2>/dev/null || true
            
            # Add new entry
            if ! grep -q "neofetch --config" "$rc_file" 2>/dev/null; then
                cat >> "$rc_file" << 'AUTORUNEOF'

# WOLF OS neofetch
if command -v neofetch &> /dev/null && [[ $- == *i* ]]; then
    neofetch --config ~/.config/neofetch/config.conf
fi
AUTORUNEOF
            fi
        fi
    done
    success "Auto-run configured"
fi

#===========================================#
#   Test Configuration                     #
#===========================================#
echo
info "Testing neofetch..."
echo

sudo -u $REAL_USER neofetch --config "$NEOFETCH_CONF_FILE" 2>/dev/null || true

echo
success "Neofetch configured successfully!"
info "Run 'neofetch' to see your new configuration"