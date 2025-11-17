#!/usr/bin/env bash
#============================================================#
#              Bash Configuration Script                     #
#       (Fallback/Compatibility for systems using Bash)     #
#============================================================#

set -euo pipefail

RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
CYAN="\033[1;36m"
BOLD="\033[1m"
RESET="\033[0m"

info()    { echo -e "${BLUE}${BOLD}ℹ${RESET} $1"; }
success() { echo -e "${GREEN}${BOLD}✓${RESET} $1"; }
warn()    { echo -e "${YELLOW}${BOLD}⚠${RESET} $1"; }

BASHRC="$HOME/.bashrc"

echo "${CYAN}${BOLD}"
cat << "EOF"
╔═══════════════════════════════════════════════════════╗
║                                                       ║
║    ⚠️  Bash Compatibility Configuration  ⚠️          ║
║                                                       ║
║   Note: Zsh is the recommended shell for WOLF OS     ║
║   This script provides fallback Bash configuration   ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝
EOF
echo "${RESET}"
echo

warn "WOLF OS uses Zsh as the default shell"
info "This script configures Bash for compatibility purposes only"
echo

read -rp "Continue with Bash configuration? (y/n): " continue_bash
if [[ ! $continue_bash =~ ^[Yy]$ ]]; then
    info "Configuration cancelled"
    echo
    info "To configure Zsh instead, run:"
    echo "  bash scripts/zshrc.sh"
    exit 0
fi

echo

add_block() {
    local marker="$1"
    local block="$2"

    if grep -qF "$marker" "$BASHRC"; then
        info "$marker already present in $BASHRC"
    else
        echo "$block" >> "$BASHRC"
        success "Added $marker to $BASHRC"
    fi
}

#===========================================#
#   Configuration Blocks                   #
#===========================================#

# Redirect to Zsh notice
ZSH_NOTICE=$(cat <<'EOF'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# WOLF OS Notice: Zsh is the default shell
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# This system is optimized for Zsh. To switch:
# 1. Install Zsh: bash scripts/zshrc.sh
# 2. Or manually: chsh -s $(which zsh)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
)

EZA_ALIASES=$(cat <<'EOF'

# --- eza aliases (Bash compatibility) ---
if command -v eza &> /dev/null; then
    alias ls='eza --color=auto --icons=auto'
    alias eza='eza --color=auto --icons=auto'
    alias ll='eza -lh'
    alias la='eza -lah'
    alias lt='eza -T'
else
    alias ls='ls --color=auto'
    alias ll='ls -lh'
    alias la='ls -lah'
fi
EOF
)

HISTORY_BLOCK=$(cat <<'EOF'

# --- Bash history configuration ---
HISTCONTROL=ignoreboth:erasedups
HISTSIZE=100000
HISTFILESIZE=200000
shopt -s histappend
PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"
EOF
)

UPDATE_ALIASES=$(cat <<'EOF'

# --- System update and clean aliases ---
alias update='sudo apt update && sudo apt upgrade -y'
alias upgrade='sudo apt update && sudo apt full-upgrade -y'
alias clean='sudo apt autoremove -y && sudo apt autoclean'
alias cleanup='sudo apt autoremove -y && sudo apt autoclean && sudo apt clean'
EOF
)

NAVIGATION_ALIASES=$(cat <<'EOF'

# --- Directory navigation aliases ---
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
EOF
)

GIT_ALIASES=$(cat <<'EOF'

# --- Git aliases ---
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'
EOF
)

DEV_PATHS=$(cat <<'EOF'

# --- Development environment paths ---

# Node.js via nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Go language
export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin

# pipx
export PATH="$PATH:$HOME/.local/bin"

# Ruby gems
if command -v ruby &> /dev/null && command -v gem &> /dev/null; then
    GEM_PATH=$(gem environment | grep "EXECUTABLE DIRECTORY" | cut -d: -f2 | xargs)
    [ -n "$GEM_PATH" ] && export PATH="$PATH:$GEM_PATH"
fi
EOF
)

CUSTOM_FUNCTIONS=$(cat <<'EOF'

# --- Custom functions ---

# Create directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Extract any archive
extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"    ;;
            *.tar.gz)    tar xzf "$1"    ;;
            *.bz2)       bunzip2 "$1"    ;;
            *.rar)       unrar x "$1"    ;;
            *.gz)        gunzip "$1"     ;;
            *.tar)       tar xf "$1"     ;;
            *.tbz2)      tar xjf "$1"    ;;
            *.tgz)       tar xzf "$1"    ;;
            *.zip)       unzip "$1"      ;;
            *.Z)         uncompress "$1" ;;
            *.7z)        7z x "$1"       ;;
            *)           echo "'$1' cannot be extracted" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Quick backup
backup() {
    cp -r "$1" "$1.backup.$(date +%Y%m%d_%H%M%S)"
}
EOF
)

BANNER=$(cat <<'EOF'

# --- Welcome banner (Bash) ---
if command -v figlet &> /dev/null && command -v lolcat &> /dev/null; then
    figlet -c "W O L F - O S" | lolcat
    echo ""
fi
EOF
)

#===========================================#
#   Menu System                            #
#===========================================#
echo "${CYAN}Which configurations would you like to add to your ~/.bashrc?${RESET}"
echo

read -rp "1. Zsh migration notice? (y/n): " ans1
[[ $ans1 == [Yy]* ]] && add_block "WOLF OS Notice" "$ZSH_NOTICE"

read -rp "2. Eza aliases (modern ls)? (y/n): " ans2
[[ $ans2 == [Yy]* ]] && add_block "eza aliases" "$EZA_ALIASES"

read -rp "3. Enhanced history configuration? (y/n): " ans3
[[ $ans3 == [Yy]* ]] && add_block "Bash history" "$HISTORY_BLOCK"

read -rp "4. System update/clean aliases? (y/n): " ans4
[[ $ans4 == [Yy]* ]] && add_block "update aliases" "$UPDATE_ALIASES"

read -rp "5. Directory navigation aliases? (y/n): " ans5
[[ $ans5 == [Yy]* ]] && add_block "navigation aliases" "$NAVIGATION_ALIASES"

read -rp "6. Git aliases? (y/n): " ans6
[[ $ans6 == [Yy]* ]] && add_block "Git aliases" "$GIT_ALIASES"

read -rp "7. Development environment paths? (y/n): " ans7
[[ $ans7 == [Yy]* ]] && add_block "Development paths" "$DEV_PATHS"

read -rp "8. Custom functions (mkcd, extract, backup)? (y/n): " ans8
[[ $ans8 == [Yy]* ]] && add_block "Custom functions" "$CUSTOM_FUNCTIONS"

read -rp "9. WOLF OS banner? (y/n): " ans9
[[ $ans9 == [Yy]* ]] && add_block "Welcome banner" "$BANNER"

# Reload bashrc if in interactive shell
if [[ $- == *i* ]]; then
    # shellcheck source=/dev/null
    source "$BASHRC" 2>/dev/null || true
    success "🔄 Reloaded $BASHRC"
fi

echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
success "✅ Bash Configuration Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
warn "⚠️  Reminder: WOLF OS is optimized for Zsh"
echo
info "To switch to Zsh (recommended):"
echo "  1. Run: ${CYAN}bash scripts/zshrc.sh${RESET}"
echo "  2. Log out and back in"
echo
info "To use Bash configuration now:"
echo "  ${CYAN}source ~/.bashrc${RESET}"
echo