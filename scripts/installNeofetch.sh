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
section() { echo -e "\n${CYAN}${BOLD}━━━ $1 ━━━${RESET}\n"; }

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
    success "Created variant configurations!"

#===========================================#
#   Create Shell Aliases                   #
#===========================================#
section "Creating Shell Aliases"

ALIASES_FILE="$USER_HOME/.neofetch_aliases"

cat > "$ALIASES_FILE" << 'ALIASEOF'
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🐺 WOLF OS Neofetch Aliases
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

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
#   Create Quick Reference Guide           #
#===========================================#
section "Creating Quick Reference Guide"

GUIDE_FILE="$NEOFETCH_CONFIG/WOLF_OS_GUIDE.md"

cat > "$GUIDE_FILE" << 'GUIDEEOF'
# 🐺 WOLF OS Neofetch Guide

## Quick Commands

### Default Commands
```bash
neofetch              # System default
wolf                  # WOLF OS detailed wolf
wolf-small            # WOLF OS small wolf
wolf-text             # WOLF OS text logo
```

### Custom Options
```bash
# Use specific config
neofetch --config ~/.config/neofetch/config-wolf.conf

# Different backends (if supported)
neofetch-img          # With image
neofetch-w3m          # With w3m image backend
```

## Configuration Files

### Main Config
`~/.config/neofetch/config.conf`

### Variant Configs
- `~/.config/neofetch/config-wolf.conf` - Detailed wolf
- `~/.config/neofetch/config-wolf-small.conf` - Small wolf
- `~/.config/neofetch/config-wolf-text.conf` - Text logo

### ASCII Art Files
- `~/.config/neofetch/ascii/wolf.txt` - Detailed wolf (recommended)
- `~/.config/neofetch/ascii/wolf-small.txt` - Compact version
- `~/.config/neofetch/ascii/wolf-text.txt` - Text logo

## Customization

### Change Default ASCII Art

Edit `~/.config/neofetch/config.conf`:

```bash
# Option 1: Detailed Wolf (recommended)
ascii_distro="$HOME/.config/neofetch/ascii/wolf.txt"

# Option 2: Small Wolf
ascii_distro="$HOME/.config/neofetch/ascii/wolf-small.txt"

# Option 3: Text Logo
ascii_distro="$HOME/.config/neofetch/ascii/wolf-text.txt"

# Option 4: System Default
ascii_distro="auto"
```

### Change ASCII Colors

Edit the `ascii_colors` array:
```bash
# Default WOLF OS colors (rainbow gradient)
ascii_colors=(1 2 3 4 5 6)

# Monochrome
ascii_colors=(7 7 7 7 7 7)

# Blue theme
ascii_colors=(4 4 12 12 6 6)

# Red theme
ascii_colors=(1 1 9 9 3 3)
```

### Customize Information Display

Edit the `print_info()` function in `config.conf`:

```bash
print_info() {
    info title
    info underline
    
    info "OS" distro
    info "Host" model
    info "Kernel" kernel
    info "Uptime" uptime
    info "Packages" packages
    info "Shell" shell
    
    # Add more info
    info "Resolution" resolution
    info "Terminal Font" term_font
    
    # Custom info
    prin "Custom" "Your custom text"
    
    # Colors
    info cols
}
```

### Progress Bars

Enable/disable progress bars:
```bash
cpu_display="bar"
memory_display="bar"
disk_display="bar"
battery_display="bar"
```

Options: `off`, `bar`, `infobar`, `barinfo`, `percentage`

## Advanced Configuration

### Use Custom Image/Wallpaper

```bash
image_backend="kitty"  # or: w3m, iterm2, tycat
image_source="/path/to/wolf-wallpaper.jpg"
```

### Fast Mode (Skip GPU info)
```bash
neofetch --disable gpu
```

### Minimal Output
```bash
neofetch --disable packages theme icons font
```

### Export as Text
```bash
neofetch --stdout > system-info.txt
```

## Troubleshooting

### Neofetch not showing ASCII art
```bash
# Check if file exists
ls -la ~/.config/neofetch/ascii/

# Test specific config
neofetch --config ~/.config/neofetch/config-wolf.conf

# Check for errors
neofetch --config ~/.config/neofetch/config.conf 2>&1 | grep -i error
```

### Colors not working
```bash
# Check terminal color support
echo $TERM

# Force 256 colors
export TERM=xterm-256color
neofetch
```

### Wrong distro detected
```bash
# Force specific distro
neofetch --ascii_distro debian
neofetch --ascii_distro arch
```

## Integration with Shell

### Zsh Integration
Add to `~/.zshrc`:
```bash
# Run on shell start
neofetch --config ~/.config/neofetch/config-wolf.conf

# Or conditionally
if [[ $- == *i* ]]; then
    wolf
fi
```

### Bash Integration
Add to `~/.bashrc`:
```bash
# Run on interactive shells
if [[ $- == *i* ]]; then
    neofetch --config ~/.config/neofetch/config.conf
fi
```

## Tips & Tricks

### Create Custom Alias
```bash
# Add to ~/.zshrc or ~/.bashrc
alias myinfo='neofetch --disable packages shell --ascii_distro arch'
```

### Random ASCII on Each Launch
```bash
ascii_files=(
    "$HOME/.config/neofetch/ascii/wolf.txt"
    "$HOME/.config/neofetch/ascii/wolf-small.txt"
    "$HOME/.config/neofetch/ascii/wolf-text.txt"
)
random_ascii=${ascii_files[$RANDOM % ${#ascii_files[@]}]}
neofetch --ascii "$random_ascii"
```

### Benchmark System Info Speed
```bash
time neofetch --stdout
```

## Resources

- [Neofetch Wiki](https://github.com/dylanaraps/neofetch/wiki)
- [ASCII Art Generator](https://www.asciiart.eu/)
- [Color Reference](https://github.com/dylanaraps/neofetch/wiki/Customizing-Info#color-blocks)

## WOLF OS Community

Share your neofetch configs with the WOLF OS community!

```bash
# Share your config
cat ~/.config/neofetch/config.conf

# Screenshot
neofetch | cat > neofetch-output.txt
```

---

**🐺 Made with ❤️ by WOLF OS Team**
GUIDEEOF

chown $REAL_USER:$REAL_USER "$GUIDE_FILE"
success "Quick reference guide created!"
info "View guide: cat $GUIDE_FILE"

#===========================================#
#   Summary Report                         #
#===========================================#
echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
success "✅ WOLF OS Neofetch Configuration Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
info "📋 Installation Summary:"
echo
echo "  ${GREEN}✓${RESET} Neofetch installed"
echo "  ${GREEN}✓${RESET} WOLF OS configuration created"
echo "  ${GREEN}✓${RESET} 3 ASCII art variants installed"
echo "  ${GREEN}✓${RESET} Shell aliases configured"
if [[ $auto_run == [Yy]* ]]; then
    echo "  ${GREEN}✓${RESET} Auto-run on shell startup enabled"
fi
echo "  ${GREEN}✓${RESET} Quick reference guide created"
echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
info "📂 Configuration Files:"
echo
echo "  Main config:    ${CYAN}~/.config/neofetch/config.conf${RESET}"
echo "  ASCII art:      ${CYAN}~/.config/neofetch/ascii/${RESET}"
echo "  Aliases:        ${CYAN}~/.neofetch_aliases${RESET}"
echo "  Guide:          ${CYAN}~/.config/neofetch/WOLF_OS_GUIDE.md${RESET}"
echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
info "🎨 Available Commands:"
echo
echo "  ${CYAN}neofetch${RESET}         - Default neofetch"
echo "  ${CYAN}wolf${RESET}             - WOLF OS detailed wolf"
echo "  ${CYAN}wolf-small${RESET}       - WOLF OS small wolf"
echo "  ${CYAN}wolf-text${RESET}        - WOLF OS text logo"
echo "  ${CYAN}sysinfo${RESET}          - Quick system info"
echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
info "🛠️  Customization:"
echo
echo "  Edit config:    ${CYAN}nano ~/.config/neofetch/config.conf${RESET}"
echo "  View guide:     ${CYAN}cat ~/.config/neofetch/WOLF_OS_GUIDE.md${RESET}"
echo "  Test config:    ${CYAN}neofetch${RESET}"
echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
warn "⚠️  Important:"
echo
echo "  • Restart your terminal to apply changes"
echo "  • Or reload shell: ${CYAN}source ~/.$(basename $SHELL)rc${RESET}"
if [[ $auto_run == [Yy]* ]]; then
    echo "  • Neofetch will run automatically on new shell sessions"
fi
echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
info "🎯 Try it now:"
echo
echo "  ${MAGENTA}${BOLD}wolf${RESET}"
echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
success "🐺 Enjoy your WOLF OS themed neofetch!"
echo
echo "${MAGENTA}${BOLD}"
cat << "EOF"
                    ┌─────────────────────────────┐
                    │  Made With ❤️  by k4rim0sama │
                    └─────────────────────────────┘
EOF
echo "${RESET}"Neofetch is already installed"
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
${c1}⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
${c1}⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⠁⠸⢳⡄⠀⠀⠀⠀⠀⠀⠀⠀
${c1}⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⠃⠀⠀⢸⠸⠀⡠⣄⠀⠀⠀⠀⠀
${c1}⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡠⠃⠀⠀⢠⣞⣀⡿⠀⠀⣧⠀⠀⠀⠀
${c2}⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣠⡖⠁⠀⠀⠀⢸⠈⢈⡇⠀⢀⡏⠀⠀⠀⠀
${c2}⠀⠀⠀⠀⠀⠀⠀⠀⠀⡴⠩⢠⡴⠀⠀⠀⠀⠀⠈⡶⠉⠀⠀⡸⠀⠀⠀⠀⠀
${c2}⠀⠀⠀⠀⠀⠀⠀⢀⠎⢠⣇⠏⠀⠀⠀⠀⠀⠀⠀⠁⠀⢀⠄⡇⠀⠀⠀⠀⠀
${c2}⠀⠀⠀⠀⠀⠀⢠⠏⠀⢸⣿⣴⠀⠀⠀⠀⠀⠀⣆⣀⢾⢟⠴⡇⠀⠀⠀⠀⠀
${c3}⠀⠀⠀⠀⠀⢀⣿⠀⠠⣄⠸⢹⣦⠀⠀⡄⠀⠀⢋⡟⠀⠀⠁⣇⠀⠀⠀⠀⠀
${c3}⠀⠀⠀⠀⢀⡾⠁⢠⠀⣿⠃⠘⢹⣦⢠⣼⠀⠀⠉⠀⠀⠀⠀⢸⡀⠀⠀⠀⠀
${c3}⠀⠀⢀⣴⠫⠤⣶⣿⢀⡏⠀⠀⠘⢸⡟⠋⠀⠀⠀⠀⠀⠀⠀⠀⢳⠀⠀⠀⠀
${c4}⠐⠿⢿⣿⣤⣴⣿⣣⢾⡄⠀⠀⠀⠀⠳⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢣⠀⠀⠀
${c4}⠀⠀⠀⣨⣟⡍⠉⠚⠹⣇⡄⠀⠀⠀⠀⠀⠀⠀⠀⠈⢦⠀⠀⢀⡀⣾⡇⠀⠀
${c4}⠀⠀⢠⠟⣹⣧⠃⠀⠀⢿⢻⡀⢄⠀⠀⠀⠀⠐⣦⡀⣸⣆⠀⣾⣧⣯⢻⠀⠀
${c5}⠀⠀⠘⣰⣿⣿⡄⡆⠀⠀⠀⠳⣼⢦⡘⣄⠀⠀⡟⡷⠃⠘⢶⣿⡎⠻⣆⠀⠀
${c5}⠀⠀⠀⡟⡿⢿⡿⠀⠀⠀⠀⠀⠙⠀⠻⢯⢷⣼⠁⠁⠀⠀⠀⠙⢿⡄⡈⢆⠀
${c6}⠀⠀⠀⠀⡇⣿⡅⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⠦⠀⠀⠀⠀⠀⠀⡇⢹⢿⡀
${c6}⠀⠀⠀⠀⠁⠛⠓⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠼⠇⠁
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
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🐺 WOLF OS Neofetch Configuration
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# See this wiki page for more info:
# https://github.com/dylanaraps/neofetch/wiki/Customizing-Info

print_info() {
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # Header
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    prin "╭────────────────────────────────────────╮"
    info title
    prin "╰────────────────────────────────────────╯"
    prin
    
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # System Information
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    prin "$(color 1)┌─ System"
    info "$(color 7)│  OS" distro
    info "$(color 7)│  Host" model
    info "$(color 7)│  Kernel" kernel
    info "$(color 7)│  Uptime" uptime
    info "$(color 7)│  Packages" packages
    info "$(color 7)└  Shell" shell
    prin
    
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # Hardware Information
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    prin "$(color 2)┌─ Hardware"
    info "$(color 7)│  CPU" cpu
    info "$(color 7)│  GPU" gpu
    info "$(color 7)│  Memory" memory
    info "$(color 7)└  Disk" disk
    prin
    
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # Desktop Environment
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    prin "$(color 3)┌─ Desktop"
    info "$(color 7)│  DE" de
    info "$(color 7)│  WM" wm
    info "$(color 7)│  Theme" theme
    info "$(color 7)│  Icons" icons
    info "$(color 7)│  Terminal" term
    info "$(color 7)└  Font" font
    prin
    
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # Color Palette
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    prin "$(color 4)┌─ Colors"
    info cols
    prin "$(color 4)└────────────────────────────────────────"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Title Configuration
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Hide/Show Fully qualified domain name.
title_fqdn="off"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Kernel Configuration
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Shorten the output of the kernel function.
kernel_shorthand="on"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Distro Configuration
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Shorten the output of the distro function
distro_shorthand="off"

# Show/Hide OS Architecture.
os_arch="on"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Uptime Configuration
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Shorten the output of the uptime function
uptime_shorthand="on"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Memory Configuration
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Show memory percentage in output.
memory_percent="on"

# Change memory output unit.
memory_unit="gib"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Packages Configuration
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Show/Hide Package Manager names.
package_managers="on"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Shell Configuration
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Show the path to $SHELL
shell_path="off"

# Show $SHELL version
shell_version="on"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CPU Configuration
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# CPU speed type
speed_type="bios_limit"

# CPU speed shorthand
speed_shorthand="on"

# Enable/Disable CPU brand in output.
cpu_brand="on"

# CPU Speed
cpu_speed="on"

# CPU Cores
cpu_cores="logical"

# CPU Temperature
cpu_temp="off"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# GPU Configuration
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Enable/Disable GPU Brand
gpu_brand="on"

# Which GPU to display
gpu_type="all"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Resolution Configuration
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Display refresh rate next to each monitor
refresh_rate="off"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Disk Configuration
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Which disks to show
disk_show=('/')

# Disk subtitle
disk_subtitle="mount"

# Disk percent
disk_percent="on"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Text Colors
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Text Colors
colors=(distro)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Text Options
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Toggle bold text
bold="on"

# Enable/Disable Underline
underline_enabled="on"

# Underline character
underline_char="─"

# Info Separator
separator=" ➜ "

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Color Blocks
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Color block range
block_range=(0 15)

# Toggle color blocks
color_blocks="on"

# Color block width in spaces
block_width=3

# Color block height in lines
block_height=1

# Color Alignment
col_offset="auto"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Progress Bars
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Bar characters
bar_char_elapsed="━"
bar_char_total="─"

# Toggle Bar border
bar_border="on"

# Progress bar length in spaces
bar_length=15

# Progress bar colors
bar_color_elapsed="distro"
bar_color_total="distro"

# Info display
cpu_display="off"
memory_display="bar"
battery_display="off"
disk_display="bar"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Backend Settings (Image/ASCII)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Image backend.
image_backend="ascii"

# Image Source (for image backend)
image_source="auto"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ASCII Art Configuration
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ASCII distro
# Use 'auto' to use distro's default ASCII art
# Use path to custom ASCII file: ascii_distro="path/to/ascii"
ascii_distro="auto"

# WOLF OS: Uncomment ONE of these to use WOLF OS ASCII art:
# ascii_distro="$HOME/.config/neofetch/ascii/wolf.txt"
# ascii_distro="$HOME/.config/neofetch/ascii/wolf-small.txt"
# ascii_distro="$HOME/.config/neofetch/ascii/wolf-text.txt"

# ASCII Colors
ascii_colors=(1 2 3 4 5 6)

# Bold ascii logo
ascii_bold="on"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Image Options (when using image backend)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Image loop
image_loop="off"

# Thumbnail directory
thumbnail_dir="${XDG_CACHE_HOME:-$HOME/.cache}/thumbnails/neofetch"

# Crop mode
crop_mode="normal"

# Crop offset
crop_offset="center"

# Image size
image_size="auto"

# Gap between image and text
gap=3

# Image offsets
yoffset=0
xoffset=0

# Image background color
background_color=

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Misc Options
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Stdout mode
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

success "