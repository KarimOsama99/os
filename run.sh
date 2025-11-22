#!/usr/bin/env bash
# ==========================================
# 🐺  WOLF OS Setup Script
# Desktop Environment Agnostic Setup
# Works on any Debian/Ubuntu with existing DE
# ==========================================

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

mkdir -p "$LOG_DIR" 2>/dev/null || true

# --- Command line arguments ---
MODE="manual"
SKIP_LIST=()

while [[ $# -gt 0 ]]; do
    case $1 in
        -y|--yes|--auto)
            MODE="auto"
            shift
            ;;
        -m|--manual)
            MODE="manual"
            shift
            ;;
        --skip)
            SKIP_LIST+=("$2")
            shift 2
            ;;
        -h|--help)
            echo -e "${CYAN}${BOLD}WOLF OS Installation Script${RESET}"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -m, --manual       Manual mode: Ask for confirmation (default)"
            echo "  -y, --yes, --auto  Auto mode: Install all with defaults"
            echo "  --skip <script>    Skip specific script"
            echo "  -h, --help         Show this help"
            echo ""
            echo "Examples:"
            echo "  $0                                    # Manual mode"
            echo "  $0 --auto                             # Auto install"
            echo "  $0 --skip installSecurityTools.sh     # Skip security tools"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${RESET}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# --- Logging function ---
log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $*"
    echo "$msg"
    echo "$msg" >> "$LOG_FILE" 2>/dev/null || true
}

# --- Ask user function with clear prompt ---
ask_user() {
    local script_name="$1"
    local description="$2"
    local default="$3"
    
    echo ""
    echo -e "${CYAN}${BOLD}╔═══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}${BOLD}║                                                               ║${RESET}"
    echo -e "${CYAN}${BOLD}║  📦 ${script_name}${RESET}"
    echo -e "${CYAN}${BOLD}║  📝 ${description}${RESET}"
    echo -e "${CYAN}${BOLD}║                                                               ║${RESET}"
    echo -e "${CYAN}${BOLD}╚═══════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    
    local prompt="👉 Run this script? "
    if [[ "$default" == "Y" ]]; then
        prompt="${prompt}${GREEN}[Y/n]${RESET}: "
    else
        prompt="${prompt}${YELLOW}[y/N]${RESET}: "
    fi
    
    read -rp "$(echo -e $prompt)" response
    echo ""
    
    response=${response:-$default}
    echo "${response^^}"
}

# --- Ordered list: "script|description|default" ---
# ⚠️ FIXED ORDER: System → Themes → Apps → Shell → Boot (Plymouth/GRUB last!)
SCRIPTS=(
    "systemUpdate.sh|Update system and install base tools|Y"
    "installFonts.sh|Install system fonts|Y"
    "installIcons.sh|Install icon themes|Y"
    "catppuccinGTK.sh|Install Catppuccin GTK theme|Y"
    "catppuccinQT.sh|Install Catppuccin QT theme|Y"
    "bibataCursor.sh|Install Bibata cursor theme|Y"
    "installWallpapers.sh|Install WOLF OS wallpapers|Y"
    "installFirefox.sh|Install Firefox browser|Y"
    "installApps.sh|Install applications|Y"
    "installSecurityTools.sh|Install security tools|N"
    "zshrc.sh|Configure Zsh with Oh My Zsh and plugins|Y"
    "installNeofetch.sh|Configure Neofetch with WOLF OS theme|Y"
    "installPlymouth.sh|Install Plymouth boot theme|Y"
    "installGrubTheme.sh|Install GRUB theme|Y"
    "finalSetup.sh|Final system configuration and cleanup|Y"
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
║              ⚡ Debian 13 Pro Setup & Configuration Tools ⚡                 ║
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
echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BLUE}📁 Script Directory: ${BOLD}${SCRIPT_DIR}${RESET}"
echo -e "${BLUE}📝 Log File: ${BOLD}${LOG_FILE}${RESET}"
echo -e "${BLUE}📊 Total Scripts: ${BOLD}${TOTAL_SCRIPTS}${RESET}"

if [ "$MODE" = "auto" ]; then
    echo -e "${GREEN}🤖 Mode: ${BOLD}AUTO${RESET} ${GREEN}(Installing all with defaults)${RESET}"
else
    echo -e "${YELLOW}👤 Mode: ${BOLD}MANUAL${RESET} ${YELLOW}(Asking for confirmation)${RESET}"
fi

echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n"

log "=== WOLF OS Installation started ==="
log "Mode: $MODE"
log "Script directory: $SCRIPT_DIR"
log "Total scripts: $TOTAL_SCRIPTS"

sleep 0.5

# --- Main loop ---
for ENTRY in "${SCRIPTS[@]}"; do
    SCRIPT="${ENTRY%%|*}"
    REST="${ENTRY#*|}"
    DESC="${REST%%|*}"
    DEFAULT="${REST##*|}"
    SCRIPT_PATH="$SCRIPTS_DIR/$SCRIPT"
    
    CURRENT_SCRIPT=$((CURRENT_SCRIPT + 1))
    
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${YELLOW}${BOLD}▶ [$CURRENT_SCRIPT/$TOTAL_SCRIPTS] ${SCRIPT}${RESET}"
    echo -e "   ${BLUE}${DESC}${RESET}"
    
    SHOULD_SKIP=false
    for skip_item in "${SKIP_LIST[@]}"; do
        if [[ "$SCRIPT" == "$skip_item" ]]; then
            SHOULD_SKIP=true
            break
        fi
    done
    
    if [ "$SHOULD_SKIP" = true ]; then
        echo -e "${YELLOW}   ⊘   Skipped (--skip flag)${RESET}\n"
        log "SKIP: $SCRIPT (via --skip flag)"
        SKIPPED_SCRIPTS+=("$SCRIPT")
        SKIPPED=$((SKIPPED + 1))
        continue
    fi

    if [ ! -f "$SCRIPT_PATH" ]; then
        echo -e "${RED}   ✖ Script not found: $SCRIPT_PATH${RESET}\n"
        log "ERROR: Script not found - $SCRIPT_PATH"
        FAILED_SCRIPTS+=("$SCRIPT (not found)")
        FAILED=$((FAILED + 1))
        continue
    fi

    DEFAULT=${DEFAULT^^}
    
    if [ "$MODE" = "auto" ]; then
        ANSWER="$DEFAULT"
        if [ "$DEFAULT" = "Y" ]; then
            echo -e "${GREEN}   ✓ Auto-running (default: Yes)${RESET}"
        else
            echo -e "${YELLOW}   ⊘ Auto-skipping (default: No)${RESET}"
        fi
        echo ""
    else
        ANSWER=$(ask_user "$SCRIPT" "$DESC" "$DEFAULT")
    fi

    case "${ANSWER}" in
        Y)
            echo -e "${GREEN}   ⏳ Running $SCRIPT...${RESET}"
            log "START: $SCRIPT"
            
            START_TIME=$(date +%s)
            
            if bash "$SCRIPT_PATH" 2>&1 | while IFS= read -r line; do
                echo "$line"
                echo "$line" >> "$LOG_FILE" 2>/dev/null || true
            done; then
                END_TIME=$(date +%s)
                ELAPSED=$((END_TIME - START_TIME))
                
                echo -e "${GREEN}   ✅ Done: $SCRIPT (${ELAPSED}s)${RESET}\n"
                log "SUCCESS: $SCRIPT (${ELAPSED}s)"
                SUCCESS_SCRIPTS+=("$SCRIPT")
                SUCCESSFUL=$((SUCCESSFUL + 1))
            else
                END_TIME=$(date +%s)
                ELAPSED=$((END_TIME - START_TIME))
                
                echo -e "${RED}   ✖ Failed: $SCRIPT (${ELAPSED}s)${RESET}\n"
                log "FAILED: $SCRIPT (${ELAPSED}s)"
                FAILED_SCRIPTS+=("$SCRIPT")
                FAILED=$((FAILED + 1))
                
                if [ "$MODE" = "manual" ]; then
                    echo ""
                    echo -e "${YELLOW}${BOLD}╔═══════════════════════════════════════╗${RESET}"
                    echo -e "${YELLOW}${BOLD}║  ⚠️  Script Failed!                  ║${RESET}"
                    echo -e "${YELLOW}${BOLD}╚═══════════════════════════════════════╝${RESET}"
                    echo ""
                    read -rp "$(echo -e ${YELLOW}Continue with remaining scripts? [Y/n]: ${RESET})" CONTINUE
                    echo ""
                    
                    if [[ $CONTINUE =~ ^[Nn]$ ]]; then
                        echo -e "${RED}Installation aborted by user${RESET}"
                        log "Installation aborted by user after $SCRIPT failed"
                        exit 1
                    fi
                else
                    echo -e "${YELLOW}   ⚠   Continuing in auto mode...${RESET}\n"
                fi
            fi
            ;;
        *)
            echo -e "${YELLOW}   ⊘   Skipped: $SCRIPT${RESET}\n"
            log "SKIP: $SCRIPT (user choice or default)"
            SKIPPED_SCRIPTS+=("$SCRIPT")
            SKIPPED=$((SKIPPED + 1))
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
echo -e "${YELLOW}⊘   Skipped:        ${BOLD}${SKIPPED}${RESET}\n"

if [ ${#SUCCESS_SCRIPTS[@]} -gt 0 ]; then
    echo -e "${GREEN}${BOLD}✅ Successful Scripts:${RESET}"
    for script in "${SUCCESS_SCRIPTS[@]}"; do
        echo -e "  ${GREEN}✓${RESET} $script"
    done
    echo
fi

if [ ${#FAILED_SCRIPTS[@]} -gt 0 ]; then
    echo -e "${RED}${BOLD}✖ Failed Scripts:${RESET}"
    for script in "${FAILED_SCRIPTS[@]}"; do
        echo -e "  ${RED}✖${RESET} $script"
    done
    echo
fi

if [ ${#SKIPPED_SCRIPTS[@]} -gt 0 ]; then
    echo -e "${YELLOW}${BOLD}⊘  Skipped Scripts:${RESET}"
    for script in "${SKIPPED_SCRIPTS[@]}"; do
        echo -e "  ${YELLOW}⊘ ${RESET} $script"
    done
    echo
fi

log "=== WOLF OS Installation completed ==="
log "Successful: $SUCCESSFUL, Failed: $FAILED, Skipped: $SKIPPED"

echo -e "${BLUE}📝 Full log saved to: ${BOLD}${LOG_FILE}${RESET}\n"

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}${BOLD}"
    cat << "EOF"
        ╔════════════════════════════════════════════════════╗
        ║                                                    ║
        ║      🎉  All tasks completed successfully!  🎉     ║
        ║                                                    ║
        ║          Your WOLF OS is ready to unleash! 🐺      ║
        ║                                                    ║
        ╚════════════════════════════════════════════════════╝
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
        ╔════════════════════════════════════════════════════╗
        ║                                                    ║
        ║      ⚠️  Installation completed with errors  ⚠️     ║
        ║                                                    ║
        ╚════════════════════════════════════════════════════╝
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