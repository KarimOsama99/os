#!/usr/bin/env bash
# ==========================================
# 🧩  Ordered Script Runner (Enhanced)
# Runs setup scripts in the order you define,
# asks Y/N per script with a default value.
# ==========================================

set -e  # stop on error

# --- Colors ---
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
RED="\e[31m"
CYAN="\e[36m"
MAGENTA="\e[35m"
BOLD="\e[1m"
RESET="\e[0m"

# --- Directory setup ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"
LOG_DIR="$SCRIPT_DIR/logs"
LOG_FILE="$LOG_DIR/installation_$(date +%Y%m%d_%H%M%S).log"

# Create logs directory
mkdir -p "$LOG_DIR"

# --- Command line arguments ---
AUTO_YES=false
SKIP_LIST=()

while [[ $# -gt 0 ]]; do
    case $1 in
        -y|--yes)
            AUTO_YES=true
            shift
            ;;
        --skip)
            SKIP_LIST+=("$2")
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -y, --yes          Auto-accept all scripts (skip prompts)"
            echo "  --skip <script>    Skip specific script"
            echo "  -h, --help         Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 --yes                          # Install everything"
            echo "  $0 --skip installSecurityTools.sh # Skip security tools"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# --- Logging function ---
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# --- Ordered list: "script|description|default"
SCRIPTS=(
    "swayInstall.sh|Install base system packages and tools|Y"
    "swayConfig.sh|Configure Sway window manager and related settings|Y"
    "installFirefox.sh|Install Firefox|Y"
    "installApps.sh|Install additional applications (Browsers, IDE, etc)|Y"
    "installSecurityTools.sh|Install security & penetration testing tools|N"
    "installFonts.sh|Install system fonts|Y"
    "updateConfig.sh|Copy and update .config|Y"
    "bashrc.sh|Update bashrc|Y"
    "installThemes.sh|Install GRUB and Plymouth themes|Y"
    "catppuccinGTK.sh|Install Catppuccin GTK|Y"
    "catppuccinQT.sh|Install Catppuccin QT|Y"
    "bibataCursor.sh|Install Bibata Cursors|Y"
    "addUserToGroups.sh|Add your user to the needed groups|Y"
    "chromeWaylandFix.sh|Apply a fix for Chrome on Wayland for older systems|N"
)

# --- Statistics ---
TOTAL_SCRIPTS=${#SCRIPTS[@]}
CURRENT_SCRIPT=0
SUCCESSFUL=0
FAILED=0
SKIPPED=0

declare -a FAILED_SCRIPTS
declare -a SKIPPED_SCRIPTS
declare -a SUCCESS_SCRIPTS

# --- Banner ---
clear
echo -e "${CYAN}${BOLD}"
cat << "EOF"
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║       ██╗    ██╗ ██████╗ ██╗     ███████╗     ██████╗ ███████╗               ║
║       ██║    ██║██╔═══██╗██║     ██╔════╝    ██╔═══██╗██╔════╝               ║
║       ██║ █╗ ██║██║   ██║██║     █████╗      ██║   ██║███████╗               ║
║       ██║███╗██║██║   ██║██║     ██╔══╝      ██║   ██║╚════██║               ║
║       ╚███╔███╔╝╚██████╔╝███████╗██║         ╚██████╔╝███████║               ║
║        ╚══╝╚══╝  ╚═════╝ ╚══════╝╚═╝          ╚═════╝ ╚══════╝               ║
║                                                                              ║
║              ⚡ Debian 13 Sway Setup & Configuration Tool ⚡                 ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF
echo -e "${RESET}"

echo -e "${MAGENTA}${BOLD}"
cat << "EOF"
                        ┌─────────────────────────────┐
                        │  Made With ❤️  by k4rim0sama │
                        └─────────────────────────────┘
EOF
echo -e "${RESET}\n"

sleep 1

# --- Header Info ---
echo -e "${CYAN}${BOLD}════════════════════════════════════════════════════════════════${RESET}"
echo -e "${BLUE}📁 Script Directory: ${BOLD}${SCRIPT_DIR}${RESET}"
echo -e "${BLUE}📝 Log File: ${BOLD}${LOG_FILE}${RESET}"
echo -e "${BLUE}📊 Total Scripts: ${BOLD}${TOTAL_SCRIPTS}${RESET}"
echo -e "${CYAN}${BOLD}════════════════════════════════════════════════════════════════${RESET}\n"

log "=== WOLF OS Installation started ==="
log "Script directory: $SCRIPT_DIR"
log "Total scripts: $TOTAL_SCRIPTS"

# --- Main loop ---
for ENTRY in "${SCRIPTS[@]}"; do
    SCRIPT="${ENTRY%%|*}"             # part before first |
    REST="${ENTRY#*|}"
    DESC="${REST%%|*}"                # middle part
    DEFAULT="${REST##*|}"             # last part
    SCRIPT_PATH="$SCRIPTS_DIR/$SCRIPT"
    
    ((CURRENT_SCRIPT++))
    
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${YELLOW}${BOLD}▶ [$CURRENT_SCRIPT/$TOTAL_SCRIPTS] ${SCRIPT}${RESET}"
    echo -e "   ${BLUE}${DESC}${RESET}"
    
    # Check if script should be skipped
    SHOULD_SKIP=false
    for skip_item in "${SKIP_LIST[@]}"; do
        if [[ "$SCRIPT" == "$skip_item" ]]; then
            SHOULD_SKIP=true
            break
        fi
    done
    
    if [ "$SHOULD_SKIP" = true ]; then
        echo -e "${YELLOW}   ⚠  Skipped (--skip flag)${RESET}\n"
        log "SKIP: $SCRIPT (via --skip flag)"
        SKIPPED_SCRIPTS+=("$SCRIPT")
        ((SKIPPED++))
        continue
    fi

    if [ ! -f "$SCRIPT_PATH" ]; then
        echo -e "${RED}   ✖ Script not found: $SCRIPT_PATH${RESET}\n"
        log "ERROR: Script not found - $SCRIPT_PATH"
        FAILED_SCRIPTS+=("$SCRIPT (not found)")
        ((FAILED++))
        continue
    fi

    # Normalize default (Y/N)
    DEFAULT=${DEFAULT^^}
    
    # Auto-yes mode or prompt user
    if [ "$AUTO_YES" = true ]; then
        ANSWER="Y"
        echo -e "${GREEN}   ✓ Auto-running (--yes mode)${RESET}"
    else
        PROMPT="   ➤ Run this script? (y/N): "
        [ "$DEFAULT" == "Y" ] && PROMPT="   ➤ Run this script? (Y/n): "
        
        read -rp "$PROMPT" ANSWER
        ANSWER=${ANSWER:-$DEFAULT}  # use default if empty
    fi
    
    echo

    case "${ANSWER^^}" in
        Y)
            echo -e "${GREEN}   ⏳ Running $SCRIPT...${RESET}"
            log "START: $SCRIPT"
            
            START_TIME=$(date +%s)
            
            # Run script and capture output
            if bash "$SCRIPT_PATH" 2>&1 | tee -a "$LOG_FILE"; then
                END_TIME=$(date +%s)
                ELAPSED=$((END_TIME - START_TIME))
                
                echo -e "${GREEN}   ✅ Done: $SCRIPT (${ELAPSED}s)${RESET}\n"
                log "SUCCESS: $SCRIPT (${ELAPSED}s)"
                SUCCESS_SCRIPTS+=("$SCRIPT")
                ((SUCCESSFUL++))
            else
                END_TIME=$(date +%s)
                ELAPSED=$((END_TIME - START_TIME))
                
                echo -e "${RED}   ✖ Failed: $SCRIPT (${ELAPSED}s)${RESET}\n"
                log "FAILED: $SCRIPT (${ELAPSED}s)"
                FAILED_SCRIPTS+=("$SCRIPT")
                ((FAILED++))
                
                # Ask if user wants to continue
                if [ "$AUTO_YES" != true ]; then
                    read -rp "Continue with remaining scripts? (Y/n): " CONTINUE
                    if [[ $CONTINUE =~ ^[Nn]$ ]]; then
                        echo -e "${RED}Installation aborted by user${RESET}"
                        log "Installation aborted by user after $SCRIPT failed"
                        exit 1
                    fi
                fi
            fi
            ;;
        *)
            echo -e "${YELLOW}   ⚠  Skipped: $SCRIPT${RESET}\n"
            log "SKIP: $SCRIPT (user choice)"
            SKIPPED_SCRIPTS+=("$SCRIPT")
            ((SKIPPED++))
            ;;
    esac
done

# --- Summary Report ---
echo -e "${CYAN}${BOLD}"
cat << "EOF"
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║                          📊 Installation Summary                            ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF
echo -e "${RESET}\n"

echo -e "${BLUE}Total Scripts:     ${BOLD}${TOTAL_SCRIPTS}${RESET}"
echo -e "${GREEN}✅ Successful:     ${BOLD}${SUCCESSFUL}${RESET}"
echo -e "${RED}✖  Failed:         ${BOLD}${FAILED}${RESET}"
echo -e "${YELLOW}⚠  Skipped:        ${BOLD}${SKIPPED}${RESET}\n"

# Show successful scripts
if [ ${#SUCCESS_SCRIPTS[@]} -gt 0 ]; then
    echo -e "${GREEN}${BOLD}✅ Successful Scripts:${RESET}"
    for script in "${SUCCESS_SCRIPTS[@]}"; do
        echo -e "  ${GREEN}✓${RESET} $script"
    done
    echo
fi

# Show failed scripts
if [ ${#FAILED_SCRIPTS[@]} -gt 0 ]; then
    echo -e "${RED}${BOLD}✖ Failed Scripts:${RESET}"
    for script in "${FAILED_SCRIPTS[@]}"; do
        echo -e "  ${RED}✖${RESET} $script"
    done
    echo
fi

# Show skipped scripts
if [ ${#SKIPPED_SCRIPTS[@]} -gt 0 ]; then
    echo -e "${YELLOW}${BOLD}⚠ Skipped Scripts:${RESET}"
    for script in "${SKIPPED_SCRIPTS[@]}"; do
        echo -e "  ${YELLOW}⚠${RESET} $script"
    done
    echo
fi

log "=== WOLF OS Installation completed ==="
log "Successful: $SUCCESSFUL, Failed: $FAILED, Skipped: $SKIPPED"

echo -e "${BLUE}📝 Full log saved to: ${BOLD}${LOG_FILE}${RESET}\n"

# --- Final status ---
if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}${BOLD}"
    cat << "EOF"
        ╔════════════════════════════════════════════════════════╗
        ║                                                        ║
        ║     🎉  All tasks completed successfully!  🎉         ║
        ║                                                        ║
        ║        Your WOLF OS is ready to unleash! 🐺          ║
        ║                                                        ║
        ╚════════════════════════════════════════════════════════╝
EOF
    echo -e "${RESET}\n"
    echo -e "${YELLOW}⚠️  Please ${BOLD}reboot${RESET}${YELLOW} your system to apply all changes${RESET}\n"
    
    echo -e "${MAGENTA}${BOLD}"
    cat << "EOF"
                    ┌─────────────────────────────┐
                    │  Made With ❤️  by k4rim0sama │
                    └─────────────────────────────┘
EOF
    echo -e "${RESET}"
    exit 0
else
    echo -e "${RED}${BOLD}"
    cat << "EOF"
        ╔════════════════════════════════════════════════════════╗
        ║                                                        ║
        ║      ⚠️  Installation completed with errors  ⚠️       ║
        ║                                                        ║
        ╚════════════════════════════════════════════════════════╝
EOF
    echo -e "${RESET}\n"
    echo -e "${YELLOW}📋 Check the log file for details: ${BOLD}${LOG_FILE}${RESET}\n"
    
    echo -e "${MAGENTA}${BOLD}"
    cat << "EOF"
                    ┌─────────────────────────────┐
                    │  Made With ❤️  by k4rim0sama │
                    └─────────────────────────────┘
EOF
    echo -e "${RESET}"
    exit 1
fi
