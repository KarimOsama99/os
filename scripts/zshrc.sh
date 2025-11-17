#!/usr/bin/env bash
#============================================================#
#                  Zsh Configuration Script                  #
#          Install Oh My Zsh + Plugins + Aliases            #
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
    # Running as root, get the real user
    REAL_USER=${SUDO_USER:-$USER}
    USER_HOME=$(eval echo ~$REAL_USER)
else
    # Running as normal user
    REAL_USER=$USER
    USER_HOME=$HOME
fi

ZSHRC="$USER_HOME/.zshrc"

echo "${CYAN}${BOLD}"
cat << "EOF"
╔═══════════════════════════════════════════════════════╗
║                                                       ║
║         🐚  Zsh Configuration & Setup  🐚            ║
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
    
    # Install as the real user
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

# 1. zsh-autosuggestions
info "Installing zsh-autosuggestions..."
if [ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    warn "zsh-autosuggestions already installed"
else
    sudo -u $REAL_USER git clone https://github.com/zsh-users/zsh-autosuggestions \
        "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    success "zsh-autosuggestions installed"
fi

# 2. zsh-syntax-highlighting
info "Installing zsh-syntax-highlighting..."
if [ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    warn "zsh-syntax-highlighting already installed"
else
    sudo -u $REAL_USER git clone https://github.com/zsh-users/zsh-syntax-highlighting \
        "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    success "zsh-syntax-highlighting installed"
fi

# 3. zsh-completions
info "Installing zsh-completions..."
if [ -d "$ZSH_CUSTOM/plugins/zsh-completions" ]; then
    warn "zsh-completions already installed"
else
    sudo -u $REAL_USER git clone https://github.com/zsh-users/zsh-completions \
        "$ZSH_CUSTOM/plugins/zsh-completions"
    success "zsh-completions installed"
fi

# 4. fast-syntax-highlighting (alternative, faster)
read -rp "Install fast-syntax-highlighting (faster alternative)? (y/n): " install_fsh
if [[ $install_fsh == [Yy]* ]]; then
    info "Installing fast-syntax-highlighting..."
    if [ -d "$ZSH_CUSTOM/plugins/fast-syntax-highlighting" ]; then
        warn "fast-syntax-highlighting already installed"
    else
        sudo -u $REAL_USER git clone https://github.com/zdharma-continuum/fast-syntax-highlighting \
            "$ZSH_CUSTOM/plugins/fast-syntax-highlighting"
        success "fast-syntax-highlighting installed"
    fi
fi

#===========================================#
#   Configure .zshrc                       #
#===========================================#
section "Configuring .zshrc"

# Backup existing .zshrc
if [ -f "$ZSHRC" ]; then
    info "Backing up existing .zshrc..."
    cp "$ZSHRC" "${ZSHRC}.backup.$(date +%Y%m%d_%H%M%S)"
    success "Backup created"
fi

# Enable plugins in .zshrc
info "Enabling plugins..."

if [[ $install_fsh == [Yy]* ]]; then
    PLUGINS="git zsh-autosuggestions zsh-completions fast-syntax-highlighting"
else
    PLUGINS="git zsh-autosuggestions zsh-completions zsh-syntax-highlighting"
fi

if [ -f "$ZSHRC" ]; then
    sed -i "s/^plugins=.*/plugins=($PLUGINS)/" "$ZSHRC"
else
    # Create basic .zshrc if it doesn't exist
    cat > "$ZSHRC" <<ZSHRCEOF
export ZSH="\$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=($PLUGINS)
source \$ZSH/oh-my-zsh.sh
ZSHRCEOF
fi

success "Plugins enabled: $PLUGINS"

#===========================================#
#   Add Custom Configurations              #
#===========================================#
section "Adding Custom Configurations"

# Marker to identify our custom config
MARKER="# --- WOLF OS Custom Configuration ---"

if grep -qF "$MARKER" "$ZSHRC"; then
    info "Custom configuration already exists"
    read -rp "Do you want to update it? (y/n): " update_config
    if [[ $update_config == [Yy]* ]]; then
        # Remove old config
        sed -i "/$MARKER/,\$d" "$ZSHRC"
    else
        info "Skipping configuration update"
        exit 0
    fi
fi

# Add custom configuration
cat >> "$ZSHRC" <<'CUSTOMEOF'

# --- WOLF OS Custom Configuration ---

# ===================================
# History Configuration
# ===================================
HISTSIZE=100000
SAVEHIST=100000
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_ALL_DUPS     # Don't record duplicates
setopt HIST_IGNORE_SPACE        # Don't record commands starting with space
setopt HIST_REDUCE_BLANKS       # Remove superfluous blanks
setopt HIST_VERIFY             # Show command with history expansion before running
setopt SHARE_HISTORY           # Share history between all sessions
setopt APPEND_HISTORY          # Append to history file
setopt INC_APPEND_HISTORY      # Write to history file immediately

# ===================================
# Completion Configuration
# ===================================
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

# ===================================
# Eza Aliases (Modern ls replacement)
# ===================================
if command -v eza &> /dev/null; then
    alias ls='eza --color=auto --icons=auto'
    alias ll='eza -lh --icons=auto'
    alias la='eza -lah --icons=auto'
    alias lt='eza -T --icons=auto'
    alias l='eza --icons=auto'
else
    # Fallback to regular ls
    alias ls='ls --color=auto'
    alias ll='ls -lh'
    alias la='ls -lah'
    alias l='ls'
fi

# ===================================
# System Update & Maintenance Aliases
# ===================================
alias update='sudo apt update && sudo apt upgrade -y'
alias upgrade='sudo apt update && sudo apt full-upgrade -y'
alias clean='sudo apt autoremove -y && sudo apt autoclean'
alias cleanup='sudo apt autoremove -y && sudo apt autoclean && sudo apt clean'

# ===================================
# Directory Navigation
# ===================================
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# ===================================
# Git Aliases
# ===================================
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'

# ===================================
# Safety Aliases
# ===================================
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# ===================================
# System Info
# ===================================
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias ports='sudo netstat -tulanp'
alias myip='curl ifconfig.me'

# ===================================
# Development
# ===================================
alias py='python3'
alias pip='pip3'

# Node.js via nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Auto-use Node.js version from .nvmrc if present
autoload -U add-zsh-hook
load-nvmrc() {
  local node_version="$(nvm version)"
  local nvmrc_path="$(nvm_find_nvmrc)"

  if [ -n "$nvmrc_path" ]; then
    local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

    if [ "$nvmrc_node_version" = "N/A" ]; then
      nvm install
    elif [ "$nvmrc_node_version" != "$node_version" ]; then
      nvm use
    fi
  elif [ "$node_version" != "$(nvm version default)" ]; then
    nvm use default
  fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc

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

# ===================================
# Custom Functions
# ===================================

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

# ===================================
# Welcome Banner (figlet + lolcat)
# ===================================
if command -v figlet &> /dev/null && command -v lolcat &> /dev/null; then
    figlet -c "W O L F - O S" | lolcat
    echo ""
fi

# ===================================
# Autosuggestions Configuration
# ===================================
# Change suggestion color
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=240'

# Accept suggestion with Ctrl+Space
bindkey '^ ' autosuggest-accept

# ===================================
# Key Bindings
# ===================================
# Ctrl+Left/Right for word navigation
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word

# Home/End keys
bindkey "^[[H" beginning-of-line
bindkey "^[[F" end-of-line

# Delete key
bindkey "^[[3~" delete-char

# ===================================
# Theme Customization (optional)
# ===================================
# Uncomment to use Powerlevel10k theme (requires installation)
# ZSH_THEME="powerlevel10k/powerlevel10k"

CUSTOMEOF

success "Custom configuration added to .zshrc"

# Set proper ownership
chown $REAL_USER:$REAL_USER "$ZSHRC"

#===========================================#
#   Install Optional Themes                #
#===========================================#
section "Optional: Install Powerlevel10k Theme"

read -rp "Install Powerlevel10k theme? (recommended) (y/n): " install_p10k
if [[ $install_p10k == [Yy]* ]]; then
    info "Installing Powerlevel10k..."
    
    if [ -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
        warn "Powerlevel10k already installed"
    else
        sudo -u $REAL_USER git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
            "$ZSH_CUSTOM/themes/powerlevel10k"
        
        # Enable the theme
        sed -i 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$ZSHRC"
        
        success "Powerlevel10k installed!"
        info "Run 'p10k configure' after restarting your terminal to customize"
    fi
fi

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
        sudo apt install -y eza || {
            warn "Eza not available in repos, trying from GitHub..."
            # Fallback installation
            sudo mkdir -p /usr/local/bin
            sudo wget -qO /usr/local/bin/eza https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz
            sudo tar xzf /usr/local/bin/eza -C /usr/local/bin
            sudo chmod +x /usr/local/bin/eza
        }
    else
        apt update
        apt install -y eza || warn "Could not install eza"
    fi
    
    success "Eza installed!"
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
echo
warn "⚠️  Important Next Steps:"
echo
echo "  1. ${CYAN}Log out and log back in${RESET} for shell change to take effect"
echo "  2. Or run: ${CYAN}exec zsh${RESET} to start using Zsh now"
if [[ $install_p10k == [Yy]* ]]; then
    echo "  3. Run: ${CYAN}p10k configure${RESET} to customize Powerlevel10k"
fi
echo
info "📚 Useful Commands:"
echo
echo "  ${CYAN}update${RESET}    - Update system packages"
echo "  ${CYAN}clean${RESET}     - Remove unused packages"
echo "  ${CYAN}ll${RESET}        - List files with details"
echo "  ${CYAN}la${RESET}        - List all files including hidden"
echo "  ${CYAN}lt${RESET}        - Show directory tree"
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
info "🎨 Customize Zsh:"
echo
echo "  Edit: ${CYAN}~/.zshrc${RESET}"
echo "  Backup: ${CYAN}~/.zshrc.backup.*${RESET}"
echo
success "🐺 Enjoy your new Zsh setup!"
echo