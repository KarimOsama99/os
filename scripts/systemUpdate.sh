#!/usr/bin/env bash
#============================================================#
#              System Update & Base Tools                    #
#============================================================#

RED="\033[1;31m"
GREEN="\033[1;32m"
BLUE="\033[1;34m"
RESET="\033[0m"

info()    { echo -e "${BLUE}[INFO]${RESET} $1"; }
success() { echo -e "${GREEN}[OK]${RESET} $1"; }

if [ "$EUID" -ne 0 ]; then
    echo "This script requires root privileges."
    read -p "Press Enter to continue with sudo... " _
    exec sudo bash "$0" "$@"
fi

info "Updating system..."
apt update && apt upgrade -y
success "System updated!"

info "Installing base tools..."
apt install -y curl wget git rsync unzip
success "Base tools installed!"