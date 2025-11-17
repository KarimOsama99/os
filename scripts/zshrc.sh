#!/usr/bin/env bash
#============================================================#
#                  Zsh Configuration Script                  #
#          Install Oh My Zsh + Plugins + Aliases            #
#         (Fixed for Powerlevel10k instant prompt)          #
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

info()    { echo -e "${BLUE}${BOLD}➤${RESET} $1"; }
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

ZSHRC="$USER_HOME/.zshrc"

echo "${CYAN}${BOLD}"
cat << "EOF"
╔═══════════════════════════════════════════════════════╗
║                                                       ║
║          🐚  Zsh Configuration & Setup  🐚            ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝
EOF
echo "${RESET}"

info "User: $REAL_USER"
info "Home: $USER_HOME"
echo

#===========================================#
#   Install Zsh if not installed           #
#===========================================#
section "Checking Zsh Installation"

if ! command -v zsh &> /dev/null; then
    error "Zsh is not installed!"
    info "Installing Zsh..."
    
    if [ "$EUID" -ne 0 ]; then
        sudo apt update
        sudo apt install -y zsh
    else
        apt update
        apt install -y zsh
    fi
    
    success "Zsh installed!"
else
    success "Zsh is already installed"
    info "Version: $(zsh --version)"
fi

#===========================================#
#   Set Zsh as Default Shell               #
#===========================================#
section "Setting Zsh as Default Shell"

CURRENT_SHELL=$(getent passwd "$REAL_USER" | cut -d: -f7)
ZSH_PATH=$(which zsh)

if [ "$CURRENT_SHELL" = "$ZSH_PATH" ]; then
    success "Zsh is already the default shell"
else
    info "Current shell: $CURRENT_SHELL"
    info "Changing to: $ZSH_PATH"
    
    if [ "$EUID" -ne 0 ]; then
        sudo chsh -s "$ZSH_PATH" "$REAL_USER"
    else
        chsh -s "$ZSH_PATH" "$REAL_USER"
    fi
    
    success "Default shell changed to Zsh!"
    warn "⚠️  You need to log out and back in for this to take effect"
fi

#===========================================#
#   Install Oh My Zsh                      #
#===========================================#
section "Installing Oh My Zsh"

if [ -d "$USER_HOME/.oh-my-zsh" ]; then
    warn "Oh My Zsh is already installed"
    
    read -rp "Do you want to update it? (y/n): " update_omz
    if [[ $update_omz == [Yy]* ]]; then
        info "Updating Oh My Zsh..."
        sudo -u $REAL_USER bash -c 'cd ~/.oh-my-zsh && git pull' || warn "Update failed"
    fi
else
    info "Installing Oh My Zsh..."
    
    sudo -u $REAL_USER bash <<'OMZEOF'
export RUNZSH=no
export CHSH=no
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
OMZEOF
    
    success "Oh My Zsh installed!"
fi

#===========================================#
#   Install Zsh Plugins                    #
#===========================================#
section "Installing Zsh Plugins"

ZSH_CUSTOM="$USER_HOME/.oh-my-zsh/custom"

info "Installing zsh-autosuggestions..."
if [ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    warn "zsh-autosuggestions already installed"
else
    sudo -u $REAL_USER git clone https://github.com/zsh-users/zsh-autosuggestions \
        "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    success "zsh-autosuggestions installed"
fi

info "Installing zsh-syntax-highlighting..."
if [ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    warn "zsh-syntax-highlighting already installed"
else
    sudo -u $REAL_USER git clone https://github.com/zsh-users/zsh-syntax-highlighting \
        "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    success "zsh-syntax-highlighting installed"
fi

info "Installing zsh-completions..."
if [ -d "$ZSH_CUSTOM/plugins/zsh-completions" ]; then
    warn "zsh-completions already installed"
else
    sudo -u $REAL_USER git clone https://github.com/zsh-users/zsh-completions \
        "$ZSH_CUSTOM/plugins/zsh-completions"
    success "zsh-completions installed"
fi

#===========================================#
#   Install Powerlevel10k Theme            #
#===========================================#
section "Installing Powerlevel10k Theme"

read -rp "Install Powerlevel10k theme? (recommended) (y/n): " install_p10k
if [[ $install_p10k == [Yy]* ]]; then
    info "Installing Powerlevel10k..."
    
    if [ -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
        warn "Powerlevel10k already installed"
    else
        sudo -u $REAL_USER git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
            "$ZSH_CUSTOM/themes/powerlevel10k"
        
        success "Powerlevel10k installed!"
        info "Run 'p10k configure' after restarting your terminal to customize"
    fi
fi

#===========================================#
#   Configure .zshrc                       #
#===========================================#
section "Configuring .zshrc"

if [ -f "$ZSHRC" ]; then
    info "Backing up existing .zshrc..."
    cp "$ZSHRC" "${ZSHRC}.backup.$(date +%Y%m%d_%H%M%S)"
    success "Backup created"
fi

info "Creating optimized .zshrc configuration..."

# Create the new .zshrc with proper Powerlevel10k support
cat > "$ZSHRC" <<'ZSHRCEOF'
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Oh My Zsh Configuration
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
export ZSH="$HOME/.oh-my-zsh"

# Set theme
ZSH_THEME="THEME_PLACEHOLDER"

# Plugins
plugins=(
    git
    zsh-autosuggestions
    zsh-completions
    zsh-syntax-highlighting
)

# Load Oh My Zsh
source $ZSH/oh-my-zsh.sh

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# History Configuration
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
HISTSIZE=100000
SAVEHIST=100000
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY
setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Completion Configuration
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
autoload -Uz compinit
compinit

# Case insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Colored completion
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Better completion menu
zstyle ':completion:*' menu select

# Cache completions
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Path Configuration (SILENT - No console output)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Node.js via nvm - LAZY LOADING (fixes instant prompt warning)
export NVM_DIR="$HOME/.nvm"

# Lazy load nvm (loads only when called)
nvm() {
    unset -f nvm
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    nvm "$@"
}

# Lazy load node
node() {
    unset -f node
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    node "$@"
}

# Lazy load npm
npm() {
    unset -f npm
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    npm "$@"
}

# Lazy load npx
npx() {
    unset -f npx
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    npx "$@"
}

# Go language
export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin

# pipx
export PATH="$PATH:$HOME/.local/bin"

# Ruby gems (silent)
if command -v ruby &> /dev/null && command -v gem &> /dev/null; then
    GEM_PATH=$(gem environment 2>/dev/null | grep "EXECUTABLE DIRECTORY" | cut -d: -f2 | xargs)
    [ -n "$GEM_PATH" ] && export PATH="$PATH:$GEM_PATH"
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Eza Aliases (Modern ls replacement)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -v eza &> /dev/null; then
    alias ls='eza --color=auto --icons=auto'
    alias ll='eza -lh --icons=auto'
    alias la='eza -lah --icons=auto'
    alias lt='eza -T --icons=auto'
    alias l='eza --icons=auto'
else
    alias ls='ls --color=auto'
    alias ll='ls -lh'
    alias la='ls -lah'
    alias l='ls'
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# System Update & Maintenance Aliases
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
alias update='sudo apt update && sudo apt upgrade -y'
alias upgrade='sudo apt update && sudo apt full-upgrade -y'
alias clean='sudo apt autoremove -y && sudo apt autoclean'
alias cleanup='sudo apt autoremove -y && sudo apt autoclean && sudo apt clean'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Directory Navigation
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Git Aliases
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Safety Aliases
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# System Info
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias ports='sudo netstat -tulanp'
alias myip='curl -s ifconfig.me'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Development
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
alias py='python3'
alias pip='pip3'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Custom Functions
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

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
            *)           echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Quick backup
backup() {
    cp -r "$1" "$1.backup.$(date +%Y%m%d_%H%M%S)"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Autosuggestions Configuration
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=240'
bindkey '^ ' autosuggest-accept

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Key Bindings
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word
bindkey "^[[H" beginning-of-line
bindkey "^[[F" end-of-line
bindkey "^[[3~" delete-char

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Powerlevel10k Configuration
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
ZSHRCEOF

# Set the theme based on whether P10k was installed
if [[ $install_p10k == [Yy]* ]]; then
    sed -i 's/ZSH_THEME="THEME_PLACEHOLDER"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$ZSHRC"
else
    sed -i 's/ZSH_THEME="THEME_PLACEHOLDER"/ZSH_THEME="robbyrussell"/' "$ZSHRC"
fi

chown $REAL_USER:$REAL_USER "$ZSHRC"

success "Optimized .zshrc configuration created!"
info "✨ Lazy loading enabled for nvm (fixes instant prompt)"

#===========================================#
#   Install Eza (modern ls)                #
#===========================================#
section "Installing Eza (Modern ls Replacement)"

if command -v eza &> /dev/null; then
    success "Eza is already installed"
else
    info "Installing Eza..."
    
    if [ "$EUID" -ne 0 ]; then
        sudo apt update
        sudo apt install -y eza 2>/dev/null || {
            warn "Eza not available in repos, skipping..."
        }
    else
        apt update
        apt install -y eza 2>/dev/null || {
            warn "Eza not available in repos, skipping..."
        }
    fi
    
    if command -v eza &> /dev/null; then
        success "Eza installed!"
    fi
fi

#===========================================#
#   Summary                                #
#===========================================#
echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
success "✅ Zsh Configuration Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
info "📋 Installation Summary:"
echo
echo "  ✓ Zsh installed and set as default shell"
echo "  ✓ Oh My Zsh installed"
echo "  ✓ Plugins: zsh-autosuggestions, zsh-syntax-highlighting, zsh-completions"
if [[ $install_p10k == [Yy]* ]]; then
    echo "  ✓ Powerlevel10k theme installed"
fi
echo "  ✓ Custom aliases and functions configured"
echo "  ✓ History and completion optimized"
echo "  ✓ Development environment paths configured"
echo "  ✓ NVM lazy loading enabled (no more instant prompt warnings!)"
echo
warn "⚠️  Important Next Steps:"
echo
echo "  1. ${CYAN}Log out and log back in${RESET} for shell change to take effect"
echo "  2. Or run: ${CYAN}exec zsh${RESET} to start using Zsh now"
if [[ $install_p10k == [Yy]* ]]; then
    echo "  3. Run: ${CYAN}p10k configure${RESET} to customize Powerlevel10k"
fi
echo
info "🔧 Fixed Issues:"
echo
echo "  ✅ No more instant prompt warnings"
echo "  ✅ NVM loads only when needed (lazy loading)"
echo "  ✅ Fast terminal startup"
echo "  ✅ All paths configured silently"
echo
info "📚 Useful Commands:"
echo
echo "  ${CYAN}update${RESET}    - Update system packages"
echo "  ${CYAN}clean${RESET}     - Remove unused packages"
echo "  ${CYAN}ll${RESET}        - List files with details"
echo "  ${CYAN}la${RESET}        - List all files including hidden"
echo "  ${CYAN}mkcd <dir>${RESET} - Create and enter directory"
echo "  ${CYAN}extract <file>${RESET} - Extract any archive"
echo "  ${CYAN}backup <file>${RESET} - Quick backup with timestamp"
echo
info "⌨️  Key Bindings:"
echo
echo "  ${CYAN}Ctrl + Space${RESET}  - Accept autosuggestion"
echo "  ${CYAN}Ctrl + Left/Right${RESET} - Navigate words"
echo "  ${CYAN}↑/↓${RESET} - History search"
echo
success "🐺 Enjoy your new Zsh setup!"
echo