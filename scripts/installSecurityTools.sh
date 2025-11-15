#!/usr/bin/env bash
#============================================================#
#              Security & Penetration Testing Tools          #
#============================================================#

set -e

RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
CYAN="\033[1;36m"
MAGENTA="\033[1;35m"
RESET="\033[0m"

info()    { echo -e "${BLUE}[INFO]${RESET} $1"; }
success() { echo -e "${GREEN}[OK]${RESET} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET} $1"; }
error()   { echo -e "${RED}[ERROR]${RESET} $1"; }
section() { echo -e "${CYAN}${1}${RESET}"; }

#==================#
#   Require Root   #
#==================#
if [ "$EUID" -ne 0 ]; then
    warn "This script requires root privileges."
    read -p "Press Enter to continue... " _
    sudo -k
    exec sudo bash "$0" "$@"
fi

# Get real user info
REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(eval echo ~$REAL_USER)

echo "=============================================="
echo "   🔒 Security & Penetration Testing Tools"
echo "=============================================="
echo
warn "⚠️  These tools are for authorized security testing only!"
warn "⚠️  Misuse of these tools may be illegal!"
echo
read -p "Do you understand and agree? (yes/no): " agreement
if [[ ! $agreement =~ ^[Yy][Ee][Ss]$ ]]; then
    error "Installation cancelled."
    exit 1
fi

echo
info "Updating package lists..."
apt update

#==================#
# Network Scanning
#==================#
section "
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  📡 Network Scanning & Reconnaissance
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

read -rp "Install Nmap (network scanner)? (y/n): " answer
if [[ $answer == [Yy]* ]]; then
    apt install -y nmap
    success "Nmap installed"
fi

read -rp "Install Netcat-traditional (networking utility)? (y/n): " answer
if [[ $answer == [Yy]* ]]; then
    apt install -y netcat-traditional
    update-alternatives --set nc /bin/nc.traditional
    success "Netcat-traditional installed and set as default"
fi

read -rp "Install Subfinder (subdomain discovery)? (y/n): " answer
if [[ $answer == [Yy]* ]]; then
    if command -v subfinder &> /dev/null; then
        warn "Subfinder already installed"
    else
        info "Installing Subfinder via Go..."
        sudo -u $REAL_USER bash -c 'export PATH=$PATH:/usr/local/go/bin && go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest'
        
        # Create symlink
        ln -sf "$USER_HOME/go/bin/subfinder" /usr/local/bin/subfinder
        success "Subfinder installed"
    fi
fi

read -rp "Install Httpx (HTTP toolkit)? (y/n): " answer
if [[ $answer == [Yy]* ]]; then
    if command -v httpx &> /dev/null; then
        warn "Httpx already installed"
    else
        info "Installing Httpx via Go..."
        sudo -u $REAL_USER bash -c 'export PATH=$PATH:/usr/local/go/bin && go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest'
        
        # Create symlink
        ln -sf "$USER_HOME/go/bin/httpx" /usr/local/bin/httpx
        success "Httpx installed"
    fi
fi

#==================#
# Web Application
#==================#
section "
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🌐 Web Application Testing
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

read -rp "Install SQLMap (SQL injection tool)? (y/n): " answer
if [[ $answer == [Yy]* ]]; then
    apt install -y sqlmap
    success "SQLMap installed"
fi

read -rp "Install WPScan (WordPress scanner)? (y/n): " answer
if [[ $answer == [Yy]* ]]; then
    apt install -y wpscan
    success "WPScan installed"
fi

read -rp "Install Nikto (web server scanner)? (y/n): " answer
if [[ $answer == [Yy]* ]]; then
    apt install -y nikto
    success "Nikto installed"
fi

read -rp "Install Ffuf (fast web fuzzer)? (y/n): " answer
if [[ $answer == [Yy]* ]]; then
    if command -v ffuf &> /dev/null; then
        warn "Ffuf already installed"
    else
        info "Installing Ffuf via Go..."
        sudo -u $REAL_USER bash -c 'export PATH=$PATH:/usr/local/go/bin && go install github.com/ffuf/ffuf/v2@latest'
        
        # Create symlink
        ln -sf "$USER_HOME/go/bin/ffuf" /usr/local/bin/ffuf
        success "Ffuf installed"
    fi
fi

read -rp "Install Gobuster (directory/file brute-forcer)? (y/n): " answer
if [[ $answer == [Yy]* ]]; then
    apt install -y gobuster
    success "Gobuster installed"
fi

read -rp "Install Nuclei (vulnerability scanner)? (y/n): " answer
if [[ $answer == [Yy]* ]]; then
    if command -v nuclei &> /dev/null; then
        warn "Nuclei already installed"
    else
        info "Installing Nuclei via Go..."
        sudo -u $REAL_USER bash -c 'export PATH=$PATH:/usr/local/go/bin && go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest'
        
        # Create symlink
        ln -sf "$USER_HOME/go/bin/nuclei" /usr/local/bin/nuclei
        
        # Update nuclei templates
        sudo -u $REAL_USER nuclei -update-templates
        
        success "Nuclei installed and templates updated"
    fi
fi

#==================#
# Wireless
#==================#
section "
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  📶 Wireless Security
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

read -rp "Install Aircrack-ng suite (wireless auditing)? (y/n): " answer
if [[ $answer == [Yy]* ]]; then
    apt install -y aircrack-ng
    success "Aircrack-ng installed"
fi

read -rp "Install Bully (WPS brute-force)? (y/n): " answer
if [[ $answer == [Yy]* ]]; then
    apt install -y bully
    success "Bully installed"
fi

read -rp "Install Reaver (WPS attack tool)? (y/n): " answer
if [[ $answer == [Yy]* ]]; then
    apt install -y reaver
    success "Reaver installed"
fi

read -rp "Install Airgeddon (wireless auditing framework)? (y/n): " answer
if [[ $answer == [Yy]* ]]; then
    info "Cloning Airgeddon..."
    if [ -d "/opt/airgeddon" ]; then
        warn "Airgeddon already exists in /opt/airgeddon"
    else
        git clone --depth 1 https://github.com/v1s1t0r1sh3r3/airgeddon.git /opt/airgeddon
        chmod +x /opt/airgeddon/airgeddon.sh
        
        # Create symlink
        ln -sf /opt/airgeddon/airgeddon.sh /usr/local/bin/airgeddon
        
        success "Airgeddon installed to /opt/airgeddon"
        info "Run with: airgeddon"
    fi
fi

#==================#
# Password Attacks
#==================#
section "
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🔐 Password Cracking
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

read -rp "Install Hydra (password brute-forcer)? (y/n): " answer
if [[ $answer == [Yy]* ]]; then
    apt install -y hydra
    success "Hydra installed"
fi

read -rp "Install John the Ripper (password cracker)? (y/n): " answer
if [[ $answer == [Yy]* ]]; then
    apt install -y john
    success "John the Ripper installed"
fi

read -rp "Install CrackMapExec (network pentesting)? (y/n): " answer
if [[ $answer == [Yy]* ]]; then
    apt install -y crackmapexec
    success "CrackMapExec installed"
fi

#==================#
# Privilege Escalation
#==================#
section "
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ⬆️  Privilege Escalation
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

read -rp "Install PEASS-ng (LinPEAS/WinPEAS)? (y/n): " answer
if [[ $answer == [Yy]* ]]; then
    info "Downloading PEASS-ng suite..."
    
    PEASS_DIR="/opt/PEASS-ng"
    mkdir -p "$PEASS_DIR"
    
    if [ -d "$PEASS_DIR/.git" ]; then
        warn "PEASS-ng already exists, updating..."
        cd "$PEASS_DIR"
        git pull
    else
        git clone https://github.com/carlospolop/PEASS-ng.git "$PEASS_DIR"
    fi
    
    # Create convenient symlinks
    ln -sf "$PEASS_DIR/linPEAS/linpeas.sh" /usr/local/bin/linpeas
    chmod +x "$PEASS_DIR/linPEAS/linpeas.sh"
    
    success "PEASS-ng installed to $PEASS_DIR"
    info "LinPEAS: linpeas or $PEASS_DIR/linPEAS/linpeas.sh"
    info "WinPEAS: $PEASS_DIR/winPEAS/winPEASany.exe"
fi

#==================#
# Exploitation
#==================#
section "
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  💣 Exploitation Frameworks
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

read -rp "Install Metasploit Framework? (y/n): " answer
if [[ $answer == [Yy]* ]]; then
    if command -v msfconsole &> /dev/null; then
        warn "Metasploit already installed"
    else
        info "Installing Metasploit Framework (this may take a while)..."
        apt install -y metasploit-framework
        
        # Initialize database
        msfdb init
        
        success "Metasploit Framework installed"
        info "Run with: msfconsole"
    fi
fi

read -rp "Install ExploitDB & SearchSploit? (y/n): " answer
if [[ $answer == [Yy]* ]]; then
    apt install -y exploitdb
    success "ExploitDB & SearchSploit installed"
fi

read -rp "Install Social Engineer Toolkit (SET)? (y/n): " answer
if [[ $answer == [Yy]* ]]; then
    apt install -y set
    success "Social Engineer Toolkit installed"
    info "Run with: setoolkit"
fi

#==================#
# Post-Exploitation
#==================#
section "
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🎯 Post-Exploitation Frameworks
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

read -rp "Install Empire & Starkiller (post-exploitation)? (y/n): " answer
if [[ $answer == [Yy]* ]]; then
    info "Installing Empire & Starkiller..."
    
    EMPIRE_DIR="/opt/Empire"
    
    if [ -d "$EMPIRE_DIR" ]; then
        warn "Empire already exists in $EMPIRE_DIR"
    else
        # Install dependencies
        apt install -y python3-pip docker.io docker-compose
        
        # Clone Empire
        git clone --recursive https://github.com/BC-SECURITY/Empire.git "$EMPIRE_DIR"
        cd "$EMPIRE_DIR"
        
        # Install Empire
        info "Installing Empire dependencies..."
        pip3 install -r requirements.txt --break-system-packages
        
        # Setup Empire
        ./setup/install.sh
        
        success "Empire installed to $EMPIRE_DIR"
        info "Start Empire server: cd $EMPIRE_DIR && ./ps-empire server"
        info "Start Empire client: cd $EMPIRE_DIR && ./ps-empire client"
    fi
    
    # Install Starkiller (GUI client)
    read -rp "Install Starkiller (Empire GUI)? (y/n): " starkiller_ans
    if [[ $starkiller_ans == [Yy]* ]]; then
        info "Downloading Starkiller..."
        
        STARKILLER_VERSION="2.5.1"
        STARKILLER_URL="https://github.com/BC-SECURITY/Starkiller/releases/download/v${STARKILLER_VERSION}/starkiller-${STARKILLER_VERSION}.AppImage"
        
        wget -O /opt/starkiller.AppImage "$STARKILLER_URL" --progress=bar:force
        chmod +x /opt/starkiller.AppImage
        
        # Create desktop entry
        cat > /usr/share/applications/starkiller.desktop <<EOF
[Desktop Entry]
Name=Starkiller
Comment=Empire GUI Client
Exec=/opt/starkiller.AppImage
Icon=/opt/Empire/empire/server/data/empire-logo.png
Type=Application
Categories=Security;Network;
EOF
        
        success "Starkiller installed to /opt/starkiller.AppImage"
        info "Run with: /opt/starkiller.AppImage"
    fi
fi

#==================#
# Network Tools
#==================#
section "
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🌐 Network Attack Tools
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

read -rp "Install Bettercap (network attack framework)? (y/n): " answer
if [[ $answer == [Yy]* ]]; then
    apt install -y bettercap
    success "Bettercap installed"
fi

read -rp "Install Ettercap (MITM tool)? (y/n): " answer
if [[ $answer == [Yy]* ]]; then
    apt install -y ettercap-common ettercap-graphical
    success "Ettercap installed"
fi

read -rp "Install MITMproxy (HTTPS proxy)? (y/n): " answer
if [[ $answer == [Yy]* ]]; then
    apt install -y mitmproxy
    success "MITMproxy installed"
fi

read -rp "Install Responder (LLMNR/NBT-NS poisoner)? (y/n): " answer
if [[ $answer == [Yy]* ]]; then
    apt install -y responder
    success "Responder installed"
fi

#==================#
# Utilities
#==================#
section "
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🛠️ Security Utilities
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

read -rp "Install Macchanger (MAC address spoofer)? (y/n): " answer
if [[ $answer == [Yy]* ]]; then
    apt install -y macchanger
    success "Macchanger installed"
fi

read -rp "Install Mimikatz-like tool (pypykatz)? (y/n): " answer
if [[ $answer == [Yy]* ]]; then
    apt install -y python3-pip
    pip3 install pypykatz --break-system-packages
    success "Pypykatz (Mimikatz Python version) installed"
fi

read -rp "Install Impacket (network protocols toolkit)? (y/n): " answer
if [[ $answer == [Yy]* ]]; then
    apt install -y python3-impacket impacket-scripts
    success "Impacket installed"
fi

read -rp "Install Enum4linux (SMB enumeration)? (y/n): " answer
if [[ $answer == [Yy]* ]]; then
    apt install -y enum4linux
    success "Enum4linux installed"
fi

read -rp "Install Smbclient & Smbmap (SMB tools)? (y/n): " answer
if [[ $answer == [Yy]* ]]; then
    apt install -y smbclient smbmap
    success "SMB tools installed"
fi

#==================#
# Proxy & Traffic Analysis
#==================#
section "
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🔍 Traffic Analysis & Proxies
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

read -rp "Install Burp Suite Community (web proxy)? (y/n): " answer
if [[ $answer == [Yy]* ]]; then
    if command -v burpsuite &> /dev/null; then
        warn "Burp Suite already installed"
    else
        info "Downloading Burp Suite Community..."
        
        # Get latest version
        BURP_URL="https://portswigger.net/burp/releases/download?product=community&type=Linux"
        
        wget -O /tmp/burpsuite_community.sh "$BURP_URL" --progress=bar:force
        chmod +x /tmp/burpsuite_community.sh
        
        info "Installing Burp Suite (this requires GUI interaction)..."
        /tmp/burpsuite_community.sh
        
        rm -f /tmp/burpsuite_community.sh
        success "Burp Suite Community installed"
    fi
fi

read -rp "Install OWASP ZAP (web app scanner)? (y/n): " answer
if [[ $answer == [Yy]* ]]; then
    apt install -y zaproxy
    success "OWASP ZAP installed"
fi

#==================#
# Forensics
#==================#
section "
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🔬 Forensics & Analysis
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

read -rp "Install Binwalk (firmware analysis)? (y/n): " answer
if [[ $answer == [Yy]* ]]; then
    apt install -y binwalk
    success "Binwalk installed"
fi

read -rp "Install Foremost (file carving)? (y/n): " answer
if [[ $answer == [Yy]* ]]; then
    apt install -y foremost
    success "Foremost installed"
fi

read -rp "Install Volatility (memory forensics)? (y/n): " answer
if [[ $answer == [Yy]* ]]; then
    apt install -y volatility3
    success "Volatility3 installed"
fi

read -rp "Install Autopsy (digital forensics)? (y/n): " answer
if [[ $answer == [Yy]* ]]; then
    apt install -y autopsy
    success "Autopsy installed"
fi

#==================#
# Manual Installation Tools
#==================#
section "
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  📦 Manual Installation Tools
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo
warn "The following tools require manual installation:"
echo

read -rp "Install Maltego? (requires manual download) (y/n): " answer
if [[ $answer == [Yy]* ]]; then
    info "Maltego installation:"
    echo "  1. Visit: https://www.maltego.com/downloads/"
    echo "  2. Download Maltego CE (Community Edition) for Linux"
    echo "  3. Run: chmod +x Maltego*.run && ./Maltego*.run"
    read -p "Press Enter when ready to continue..."
fi

echo
read -rp "Setup C2 Framework installation guide? (Havoc/Sliver/Mythic) (y/n): " answer
if [[ $answer == [Yy]* ]]; then
    C2_GUIDE="/opt/c2-installation-guide.txt"
    
    cat > "$C2_GUIDE" <<'C2EOF'
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
         C2 Framework Installation Guide
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️  WARNING: These are advanced offensive security tools.
   Use only in authorized environments!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. HAVOC C2 Framework
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

GitHub: https://github.com/HavocFramework/Havoc

Installation:
```bash
cd /opt
git clone https://github.com/HavocFramework/Havoc.git
cd Havoc
make install-all
```

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
2. SLIVER C2 Framework
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

GitHub: https://github.com/BishopFox/sliver

Installation:
```bash
curl https://sliver.sh/install | sudo bash
```

Usage:
```bash
sliver-server
```

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
3. MYTHIC C2 Framework
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

GitHub: https://github.com/its-a-feature/Mythic

Requirements:
- Docker & Docker Compose

Installation:
```bash
cd /opt
git clone https://github.com/its-a-feature/Mythic
cd Mythic
./install_docker_ubuntu.sh
make
./mythic-cli start
```

Access: https://127.0.0.1:7443

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
4. COBALT STRIKE (Commercial - Not Recommended)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Note: Cobalt Strike is a commercial product ($3,500/year)
Website: https://www.cobaltstrike.com/

Alternatives (Free):
- Havoc (similar UI to Cobalt Strike)
- Sliver (modern, active development)
- Mythic (modular, extensible)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
C2EOF

    success "C2 installation guide saved to: $C2_GUIDE"
    info "View with: cat $C2_GUIDE"
fi

#==================#
# Wordlists
#==================#
section "
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  📚 Wordlists & Dictionaries
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

read -rp "Install SecLists (wordlist collection)? (y/n): " answer
if [[ $answer == [Yy]* ]]; then
    apt install -y seclists
    success "SecLists installed to /usr/share/seclists"
fi

read -rp "Install Wordlists package? (y/n): " answer
if [[ $answer == [Yy]* ]]; then
    apt install -y wordlists
    success "Wordlists installed to /usr/share/wordlists"
fi

read -rp "Download RockYou wordlist? (y/n): " answer
if [[ $answer == [Yy]* ]]; then
    ROCKYOU_DIR="/usr/share/wordlists"
    mkdir -p "$ROCKYOU_DIR"
    
    if [ -f "$ROCKYOU_DIR/rockyou.txt" ]; then
        warn "RockYou already exists"
    else
        info "Extracting RockYou wordlist..."
        gunzip -k /usr/share/wordlists/rockyou.txt.gz 2>/dev/null || \
        wget -O "$ROCKYOU_DIR/rockyou.txt.gz" https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt && \
        gunzip "$ROCKYOU_DIR/rockyou.txt.gz"
        success "RockYou wordlist extracted to $ROCKYOU_DIR/rockyou.txt"
    fi
fi

#==================#
# Post-Install Configuration
#==================#
section "
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ⚙️  Post-Installation Configuration
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Create tools directory
TOOLS_DIR="/opt/security-tools"
mkdir -p "$TOOLS_DIR"
chown -R $REAL_USER:$REAL_USER "$TOOLS_DIR"

info "Security tools directory created: $TOOLS_DIR"

# Create aliases for common tools
ALIASES_FILE="$USER_HOME/.security_aliases"

cat > "$ALIASES_FILE" <<'ALIASEOF'
# Security Tools Aliases
alias msf='msfconsole'
alias msfdb-start='systemctl start postgresql && msfdb init'
alias search-exploit='searchsploit'
alias web-scan='nikto -h'
alias port-scan='nmap -sV -sC'
alias vuln-scan='nuclei -u'
alias fuzz='ffuf -w'
alias subdomain='subfinder -d'
alias http-probe='httpx -l'
alias wifi-mon='airmon-ng start wlan0'
alias wifi-stop='airmon-ng stop wlan0mon'
alias hydra-ssh='hydra -L users.txt -P pass.txt ssh://'
alias crack-hash='john --wordlist=rockyou.txt'
alias priv-esc='linpeas'
alias empire-server='cd /opt/Empire && ./ps-empire server'
alias empire-client='cd /opt/Empire && ./ps-empire client'
ALIASEOF

chown $REAL_USER:$REAL_USER "$ALIASES_FILE"

# Add to bashrc/zshrc
for rc_file in "$USER_HOME/.bashrc" "$USER_HOME/.zshrc"; do
    if [ -f "$rc_file" ] && ! grep -q "security_aliases" "$rc_file"; then
        echo "[ -f ~/.security_aliases ] && source ~/.security_aliases" >> "$rc_file"
    fi
done

success "Security aliases created: $ALIASES_FILE"

#==================#
# Summary
#==================#
echo
section "━━━━━━━━━━━━━━━━━━━━━━━━━━"
success "✅ Security Tools Installation Complete!"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
info "📋 Installed Tools Summary:"
echo
echo "🔍 Reconnaissance & Scanning:"
echo "  • Nmap - Network scanner"
echo "  • Subfinder - Subdomain discovery"
echo "  • Httpx - HTTP toolkit"
echo "  • Netcat - Networking utility"
echo
echo "🌐 Web Application Testing:"
echo "  • SQLMap - SQL injection"
echo "  • WPScan - WordPress scanner"
echo "  • Nikto - Web server scanner"
echo "  • Ffuf - Fast web fuzzer"
echo "  • Gobuster - Directory brute-forcer"
echo "  • Nuclei - Vulnerability scanner"
echo
echo "📶 Wireless Security:"
echo "  • Aircrack-ng - Wireless auditing suite"
echo "  • Bully - WPS brute-force"
echo "  • Reaver - WPS attacks"
echo "  • Airgeddon - Wireless framework"
echo
echo "🔐 Password & Authentication:"
echo "  • Hydra - Password brute-forcer"
echo "  • John the Ripper - Password cracker"
echo "  • CrackMapExec - Network pentesting"
echo
echo "⬆️  Privilege Escalation:"
echo "  • PEASS-ng (LinPEAS/WinPEAS)"
echo
echo "💣 Exploitation:"
echo "  • Metasploit Framework"
echo "  • ExploitDB & SearchSploit"
echo "  • Social Engineer Toolkit (SET)"
echo
echo "🎯 Post-Exploitation:"
echo "  • Empire & Starkiller"
echo
echo "🌐 Network Attacks:"
echo "  • Bettercap - Network attack framework"
echo "  • Ettercap - MITM tool"
echo "  • MITMproxy - HTTPS proxy"
echo "  • Responder - LLMNR/NBT-NS poisoner"
echo
echo "🛠️  Utilities:"
echo "  • Macchanger - MAC spoofer"
echo "  • Pypykatz - Mimikatz alternative"
echo "  • Impacket - Network protocols"
echo "  • Enum4linux - SMB enumeration"
echo
echo "🔍 Traffic Analysis:"
echo "  • Burp Suite Community"
echo "  • OWASP ZAP"
echo
echo "🔬 Forensics:"
echo "  • Binwalk - Firmware analysis"
echo "  • Foremost - File carving"
echo "  • Volatility - Memory forensics"
echo "  • Autopsy - Digital forensics"
echo
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
info "📝 Common Commands (via aliases):"
echo
echo "  • msf                  → Launch Metasploit"
echo "  • search-exploit       → Search ExploitDB"
echo "  • port-scan <target>   → Nmap scan with service detection"
echo "  • vuln-scan <target>   → Nuclei vulnerability scan"
echo "  • fuzz <wordlist>      → Ffuf fuzzing"
echo "  • subdomain <domain>   → Subfinder subdomain discovery"
echo "  • http-probe <file>    → Httpx probe URLs"
echo "  • wifi-mon             → Enable monitor mode"
echo "  • priv-esc             → Run LinPEAS"
echo "  • empire-server        → Start Empire server"
echo "  • empire-client        → Start Empire client"
echo
info "🔧 Direct Commands:"
echo
echo "  • nuclei -u <url>                    → Scan single target"
echo "  • nuclei -l urls.txt                 → Scan multiple targets"
echo "  • ffuf -w wordlist.txt -u URL/FUZZ   → Directory fuzzing"
echo "  • subfinder -d example.com           → Find subdomains"
echo "  • httpx -l subdomains.txt            → Probe HTTP services"
echo "  • nmap -sV -sC <target>              → Service version scan"
echo "  • hydra -L users.txt -P pass.txt <service>://<target>"
echo "  • john --wordlist=rockyou.txt hash.txt"
echo "  • sqlmap -u <url> --dbs              → Enumerate databases"
echo "  • wpscan --url <target>              → Scan WordPress site"
echo "  • airmon-ng start wlan0              → Enable monitor mode"
echo "  • linpeas                            → Linux privilege escalation"
echo "  • /opt/Empire/ps-empire server       → Empire server"
echo "  • /opt/starkiller.AppImage           → Starkiller GUI"
echo
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
warn "⚠️  CRITICAL SECURITY REMINDERS:"
echo
echo "  1. ✅ ALWAYS get written authorization before testing"
echo "  2. 🚫 NEVER use these tools on systems you don't own"
echo "  3. 📜 Unauthorized access is ILLEGAL in most countries"
echo "  4. 🎓 Use for learning in controlled lab environments"
echo "  5. 📖 Read tool documentation before use"
echo "  6. 🔒 Keep tools updated regularly"
echo "  7. 💾 Document all authorized testing activities"
echo
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
info "📚 Learning Resources:"
echo
echo "  • Exploit-DB:         https://www.exploit-db.com"
echo "  • HackTricks:         https://book.hacktricks.xyz"
echo "  • OWASP:              https://owasp.org"
echo "  • Metasploit:         https://www.offensive-security.com/metasploit-unleashed"
echo "  • TryHackMe:          https://tryhackme.com"
echo "  • HackTheBox:         https://www.hackthebox.com"
echo "  • PortSwigger Academy: https://portswigger.net/web-security"
echo "  • PentesterLab:       https://pentesterlab.com"
echo
info "🗂️  Important Paths:"
echo
echo "  • Security tools:     /opt/security-tools"
echo "  • PEASS-ng:           /opt/PEASS-ng"
echo "  • Empire:             /opt/Empire"
echo "  • Starkiller:         /opt/starkiller.AppImage"
echo "  • Airgeddon:          /opt/airgeddon"
echo "  • SecLists:           /usr/share/seclists"
echo "  • Wordlists:          /usr/share/wordlists"
echo "  • RockYou:            /usr/share/wordlists/rockyou.txt"
echo "  • C2 Guide:           /opt/c2-installation-guide.txt"
echo "  • Security aliases:   ~/.security_aliases"
echo
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
info "🔄 Next Steps:"
echo
echo "  1. Restart your terminal to load aliases"
echo "  2. Update Nuclei templates: nuclei -update-templates"
echo "  3. Initialize Metasploit database: msfdb init"
echo "  4. Test Empire setup: empire-server"
echo "  5. Review C2 installation guide: cat /opt/c2-installation-guide.txt"
echo
warn "⚠️  Some tools may require additional configuration"
warn "⚠️  Check individual tool documentation for setup details"
echo
success "🎉 Happy (Ethical) Hacking!"
echo
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"