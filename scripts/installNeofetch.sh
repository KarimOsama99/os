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

# Wolf ASCII Art (Braille - رسمة الذئب بالنقاط)
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

# Wolf Text Art (الكتابة)
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
    
    # عرض معلومات WOLF OS
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

# Backend Settings - CRITICAL: تعطيل auto detection
image_backend="ascii"

# ASCII - هنا الحل الأساسي
ascii_distro="auto"
ascii_colors=(1 2 3 4 5 6)
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
#   ASCII Art Selection (خيارين بس)       #
#===========================================#
echo
echo -e "${CYAN}${BOLD}Choose WOLF OS ASCII art:${RESET}"
echo
echo "1) Wolf ASCII Art"
echo "2) Wolf Text"
echo

read -rp "Select [1-2]: " ascii_choice

case $ascii_choice in
    1)
        # Wolf ASCII (Braille)
        sed -i 's|^ascii_distro="auto"|ascii_distro="'"$ASCII_DIR/wolf.txt"'"|' "$NEOFETCH_CONF_FILE"
        success "Wolf ASCII (Braille) enabled ✓"
        ;;
    2)
        # Wolf Text
        sed -i 's|^ascii_distro="auto"|ascii_distro="'"$ASCII_DIR/wolf-text.txt"'"|' "$NEOFETCH_CONF_FILE"
        success "Wolf Text logo enabled ✓"
        ;;
    *)
        # Default to Wolf ASCII
        sed -i 's|^ascii_distro="auto"|ascii_distro="'"$ASCII_DIR/wolf.txt"'"|' "$NEOFETCH_CONF_FILE"
        warn "Invalid choice, using Wolf ASCII by default"
        ;;
esac

#===========================================#
#   إنشاء Wrapper Script (الحل النهائي)   #
#===========================================#
info "Creating neofetch wrapper to force WOLF OS ASCII..."

WRAPPER_SCRIPT="$USER_HOME/.local/bin/neofetch"
mkdir -p "$USER_HOME/.local/bin"

cat > "$WRAPPER_SCRIPT" << 'WRAPPEREOF'
#!/usr/bin/env bash
# WOLF OS Neofetch Wrapper - يجبر neofetch على استخدام التكوين الصحيح

CONFIG_FILE="$HOME/.config/neofetch/config.conf"

# تشغيل neofetch مع التكوين المخصص
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
        # Check if PATH already includes ~/.local/bin
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

# Export for current session
export PATH="$USER_HOME/.local/bin:$PATH"

success "PATH configuration complete"

#===========================================#
#   Shell Integration (اختياري)           #
#===========================================#
echo
read -rp "Auto-run neofetch on shell startup? (y/n): " auto_run

if [[ $auto_run == [Yy]* ]]; then
    for rc_file in "$USER_HOME/.bashrc" "$USER_HOME/.zshrc"; do
        if [ -f "$rc_file" ]; then
            # حذف الإدخالات القديمة
            sed -i '/^neofetch$/d' "$rc_file" 2>/dev/null || true
            sed -i '/^# Run neofetch/d' "$rc_file" 2>/dev/null || true
            sed -i '/# WOLF OS neofetch/d' "$rc_file" 2>/dev/null || true
            
            # إضافة إدخال جديد يستخدم الـ wrapper
            if ! grep -q "neofetch --config" "$rc_file" 2>/dev/null; then
                cat >> "$rc_file" << 'AUTORUNEOF'

# WOLF OS neofetch - استخدام التكوين المخصص
if command -v neofetch &> /dev/null && [[ $- == *i* ]]; then
    neofetch
fi
AUTORUNEOF
            fi
        fi
    done
    success "Auto-run configured (using wrapper)"
fi

#===========================================#
#   Test Configuration (اختبار)           #
#===========================================#
echo
info "Testing neofetch configuration..."
echo

# تأكد من أن PATH يتضمن ~/.local/bin
export PATH="$USER_HOME/.local/bin:$PATH"

# اختبر الـ wrapper
sudo -u $REAL_USER bash -c "export PATH=\"$USER_HOME/.local/bin:\$PATH\"; neofetch" 2>/dev/null || {
    warn "Could not test neofetch (this is normal if running via sudo)"
}

#===========================================#
#   Add neofetch alias (optional)          #
#===========================================#
info "Adding neofetch alias..."

ALIAS_LINE="alias neofetch='neofetch --ascii \$HOME/.config/neofetch/ascii/wolf.txt'"

for rc_file in "$USER_HOME/.zshrc" "$USER_HOME/.bashrc"; do
    if [ -f "$rc_file" ]; then
        # Remove old occurrences
        sed -i "/alias neofetch=.*ascii/d" "$rc_file"
        sed -i "/# WOLF OS neofetch alias/d" "$rc_file"

        # Add the alias only if not exists
        if ! grep -q "alias neofetch=" "$rc_file"; then
            echo "" >> "$rc_file"
            echo "# WOLF OS neofetch alias" >> "$rc_file"
            echo "$ALIAS_LINE" >> "$rc_file"
        fi
    fi
done

success "Alias added successfully"

#===========================================#
#   Final Instructions                     #
#===========================================#
echo
echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
success "✅ Neofetch configured successfully!"
echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo
info "📋 What was configured:"
echo
echo "  ✓ Neofetch installed and configured"
echo "  ✓ WOLF OS custom ASCII art created"
echo "  ✓ Custom config with 'WOLF OS (Debian 13)'"
echo "  ✓ Wrapper script created to force correct ASCII"
echo "  ✓ PATH includes ~/.local/bin"
echo
info "🎨 Your ASCII choice:"
case $ascii_choice in
    1) echo "  ✓ Wolf ASCII (Braille art)" ;;
    2) echo "  ✓ Wolf Text logo" ;;
    *) echo "  ✓ Wolf ASCII (default)" ;;
esac
echo
info "🚀 How to use:"
echo
echo "  Just run:  ${CYAN}neofetch${RESET}"
echo
echo "  The wrapper automatically uses your WOLF OS config!"
echo
info "🔧 Manual override (if needed):"
echo
echo "  Change ASCII:  Edit ${CYAN}~/.config/neofetch/config.conf${RESET}"
echo "  Line to edit:  ${CYAN}ascii_distro=\"...\"${RESET}"
echo
echo "  Wolf ASCII:    ${CYAN}ascii_distro=\"$ASCII_DIR/wolf.txt\"${RESET}"
echo "  Wolf Text:     ${CYAN}ascii_distro=\"$ASCII_DIR/wolf-text.txt\"${RESET}"
echo
warn "⚠️  Important:"
echo
echo "  • Restart your terminal for changes to take effect"
echo "  • The wrapper at ~/.local/bin/neofetch overrides system neofetch"
echo "  • If you want system neofetch: /usr/bin/neofetch"
echo
success "🐺 Enjoy your WOLF OS neofetch!"
echo