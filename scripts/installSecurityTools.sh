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
BOLD="\033[1m"
RESET="\033[0m"

info()    { echo -e "${BLUE}[INFO]${RESET} $1"; }
success() { echo -e "${GREEN}[OK]${RESET} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET} $1"; }
error()   { echo -e "${RED}[ERROR]${RESET} $1"; }
section() { echo -e "${CYAN}┌── $1 ──┐${RESET}"; }

# Ask user function with clear prompt
ask_user() {
    local prompt="$1"
    local options="$2"
    local response
    
    echo ""
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${YELLOW}${BOLD}❓ ${prompt}${RESET}"
    if [ -n "$options" ]; then
        echo ""
        echo -e "$options"
    fi
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
    read -rp "👉 Your choice: " response
    echo ""
    
    echo "$response"
}

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

echo ""
echo -e "${CYAN}${BOLD}╔═══════════════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}${BOLD}║                                                       ║${RESET}"
echo -e "${CYAN}${BOLD}║     🛡️  Security & Penetration Testing Tools 🛡️      ║${RESET}"
echo -e "${CYAN}${BOLD}║                                                       ║${RESET}"
echo -e "${CYAN}${BOLD}╚═══════════════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "${RED}${BOLD}╔═══════════════════════════════════════════════════════╗${RESET}"
echo -e "${RED}${BOLD}║                                                       ║${RESET}"
echo -e "${RED}${BOLD}║                   ⚠️  WARNING ⚠️                      ║${RESET}"
echo -e "${RED}${BOLD}║                                                       ║${RESET}"
echo -e "${RED}${BOLD}║  These tools are for AUTHORIZED testing ONLY!        ║${RESET}"
echo -e "${RED}${BOLD}║  Misuse may be ILLEGAL and result in prosecution!    ║${RESET}"
echo -e "${RED}${BOLD}║                                                       ║${RESET}"
echo -e "${RED}${BOLD}╚═══════════════════════════════════════════════════════╝${RESET}"
echo ""

agreement=$(ask_user "Do you understand and agree to use these tools legally?" "${GREEN}Type 'yes' to continue${RESET}")

if [[ ! $agreement =~ ^[Yy][Ee][Ss]$ ]]; then
    error "Installation cancelled."
    exit 1
fi

echo ""
info "Updating package lists..."
apt update -qq

#===========================================#
#   Essential Network Tools                #
#===========================================#
section "🌐 Essential Network Tools"

info "Installing essential network tools..."
apt install -y \
    wget \
    curl \
    net-tools \
    dnsutils \
    iputils-ping \
    traceroute \
    unzip

success "Essential network tools installed"

#===========================================#
#   PostgreSQL Database                    #
#===========================================#
section "🗄️  PostgreSQL Database"

info "Installing PostgreSQL..."
apt install -y postgresql postgresql-contrib
success "PostgreSQL installed"

info "Starting and enabling PostgreSQL service..."
systemctl enable postgresql
systemctl start postgresql
success "PostgreSQL service is running"

#===========================================#
#   Tor Network                            #
#===========================================#
section "🧅 Tor Network Configuration"

info "Checking Tor installation..."
if ! command -v tor &> /dev/null; then
    warn "Tor not found, installing..."
    apt install -y tor
    systemctl enable tor
    systemctl start tor
    success "Tor installed and started"
else
    success "Tor is already installed"
    systemctl is-active --quiet tor || systemctl start tor
fi

#===========================================#
#   IPTables & Firewall Configuration      #
#===========================================#
section "🔥 IPTables Firewall Configuration"

info "Installing iptables and iptables-persistent..."
apt install -y iptables iptables-persistent
success "IPTables installed"

OPTIONS="
${GREEN}${BOLD}1)${RESET} ${GREEN}Basic${RESET}      - Permissive (allows most traffic)
${YELLOW}${BOLD}2)${RESET} ${YELLOW}Medium${RESET}     - Balanced (⭐ RECOMMENDED for daily use)
${RED}${BOLD}3)${RESET} ${RED}Tails-like${RESET} - Strict (⚠️  Forces ALL traffic through Tor)
${CYAN}${BOLD}4)${RESET} ${CYAN}Custom${RESET}     - Configure manually
${BLUE}${BOLD}5)${RESET} ${BLUE}Skip${RESET}       - Don't configure firewall
"

iptables_level=$(ask_user "Choose IPTables security level [1-5]" "$OPTIONS")

case $iptables_level in
    5)
        info "Skipping IPTables configuration"
        ;;
    *)
        info "Configuring IPTables rules..."
        
        # Backup existing rules
        mkdir -p /etc/iptables/backups
        iptables-save > "/etc/iptables/backups/rules.v4.backup.$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
        ip6tables-save > "/etc/iptables/backups/rules.v6.backup.$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
        
        # Flush existing rules
        iptables -F
        iptables -X
        iptables -t nat -F
        iptables -t nat -X
        iptables -t mangle -F
        iptables -t mangle -X
        
        ip6tables -F
        ip6tables -X
        ip6tables -t nat -F
        ip6tables -t nat -X
        ip6tables -t mangle -F
        ip6tables -t mangle -X
        
        case $iptables_level in
            1) # BASIC - Permissive
                info "Applying BASIC security rules..."
                
                iptables -P INPUT ACCEPT
                iptables -P FORWARD DROP
                iptables -P OUTPUT ACCEPT
                
                ip6tables -P INPUT ACCEPT
                ip6tables -P FORWARD DROP
                ip6tables -P OUTPUT ACCEPT
                
                # Block common attacks
                iptables -A INPUT -m conntrack --ctstate INVALID -j DROP
                iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
                iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
                
                # Rate limiting SSH
                iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --set
                iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --update --seconds 60 --hitcount 4 -j DROP
                
                success "BASIC rules applied"
                ;;
                
            2) # MEDIUM - Balanced (RECOMMENDED)
                info "Applying MEDIUM security rules (Recommended)..."
                
                iptables -P INPUT DROP
                iptables -P FORWARD DROP
                iptables -P OUTPUT ACCEPT
                
                ip6tables -P INPUT DROP
                ip6tables -P FORWARD DROP
                ip6tables -P OUTPUT ACCEPT
                
                # Allow loopback
                iptables -A INPUT -i lo -j ACCEPT
                iptables -A OUTPUT -o lo -j ACCEPT
                
                ip6tables -A INPUT -i lo -j ACCEPT
                ip6tables -A OUTPUT -o lo -j ACCEPT
                
                # Allow established connections
                iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
                ip6tables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
                
                # Allow DNS
                iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
                iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT
                
                # Allow HTTP/HTTPS
                iptables -A OUTPUT -p tcp --dport 80 -j ACCEPT
                iptables -A OUTPUT -p tcp --dport 443 -j ACCEPT
                
                # Allow SSH outbound
                iptables -A OUTPUT -p tcp --dport 22 -j ACCEPT
                
                # Allow ICMP (ping) - limited
                iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 1/s -j ACCEPT
                iptables -A OUTPUT -p icmp -j ACCEPT
                
                # Block invalid packets
                iptables -A INPUT -m conntrack --ctstate INVALID -j DROP
                
                # Protection against port scanning
                iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
                iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
                
                success "MEDIUM rules applied (Recommended for daily use)"
                ;;
                
            3) # TAILS-LIKE - Strict
                echo ""
                echo -e "${RED}${BOLD}╔═══════════════════════════════════════════════════════╗${RESET}"
                echo -e "${RED}${BOLD}║                                                       ║${RESET}"
                echo -e "${RED}${BOLD}║               ⚠️  CRITICAL WARNING ⚠️                 ║${RESET}"
                echo -e "${RED}${BOLD}║                                                       ║${RESET}"
                echo -e "${RED}${BOLD}║  TAILS-LIKE mode will:                                ║${RESET}"
                echo -e "${RED}${BOLD}║  • Block ALL normal internet traffic                  ║${RESET}"
                echo -e "${RED}${BOLD}║  • Force everything through Tor (slower)              ║${RESET}"
                echo -e "${RED}${BOLD}║  • Break most regular applications                    ║${RESET}"
                echo -e "${RED}${BOLD}║  • Block ALL IPv6 traffic                             ║${RESET}"
                echo -e "${RED}${BOLD}║                                                       ║${RESET}"
                echo -e "${RED}${BOLD}║  Only choose this if you know what you're doing!      ║${RESET}"
                echo -e "${RED}${BOLD}║                                                       ║${RESET}"
                echo -e "${RED}${BOLD}╚═══════════════════════════════════════════════════════╝${RESET}"
                echo ""
                
                confirm=$(ask_user "Are you ABSOLUTELY sure you want TAILS-LIKE mode?" "${RED}Type 'YES' in capital letters${RESET}")
                
                if [[ "$confirm" != "YES" ]]; then
                    warn "TAILS-LIKE mode cancelled. Falling back to MEDIUM security."
                    iptables_level=2
                    
                    # Apply medium rules instead
                    iptables -P INPUT DROP
                    iptables -P FORWARD DROP
                    iptables -P OUTPUT ACCEPT
                    
                    ip6tables -P INPUT DROP
                    ip6tables -P FORWARD DROP
                    ip6tables -P OUTPUT ACCEPT
                    
                    iptables -A INPUT -i lo -j ACCEPT
                    iptables -A OUTPUT -o lo -j ACCEPT
                    ip6tables -A INPUT -i lo -j ACCEPT
                    ip6tables -A OUTPUT -o lo -j ACCEPT
                    
                    iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
                    ip6tables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
                    
                    iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
                    iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT
                    iptables -A OUTPUT -p tcp --dport 80 -j ACCEPT
                    iptables -A OUTPUT -p tcp --dport 443 -j ACCEPT
                    iptables -A OUTPUT -p tcp --dport 22 -j ACCEPT
                    iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 1/s -j ACCEPT
                    iptables -A OUTPUT -p icmp -j ACCEPT
                    iptables -A INPUT -m conntrack --ctstate INVALID -j DROP
                    iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
                    iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
                    
                    success "MEDIUM rules applied instead"
                else
                    info "Applying TAILS-LIKE security rules (Strict)..."
                    
                    iptables -P INPUT DROP
                    iptables -P FORWARD DROP
                    iptables -P OUTPUT DROP
                    
                    # Block ALL IPv6
                    ip6tables -P INPUT DROP
                    ip6tables -P FORWARD DROP
                    ip6tables -P OUTPUT DROP
                    
                    # Allow loopback
                    iptables -A INPUT -i lo -j ACCEPT
                    iptables -A OUTPUT -o lo -j ACCEPT
                    
                    # Allow established connections
                    iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
                    iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
                    
                    # Allow DNS
                    iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
                    iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT
                    
                    # Allow Tor connections
                    iptables -A OUTPUT -p tcp --dport 9050 -j ACCEPT
                    iptables -A OUTPUT -d 127.0.0.1 -p tcp --dport 9051 -j ACCEPT
                    iptables -A OUTPUT -p tcp --dport 80 -j ACCEPT
                    iptables -A OUTPUT -p tcp --dport 443 -j ACCEPT
                    iptables -A OUTPUT -p tcp --dport 9001 -j ACCEPT
                    iptables -A OUTPUT -p tcp --dport 9030 -j ACCEPT
                    
                    # Log dropped packets
                    iptables -A INPUT -j LOG --log-prefix "IPT-INPUT-DROP: " --log-level 4
                    iptables -A OUTPUT -j LOG --log-prefix "IPT-OUTPUT-DROP: " --log-level 4
                    
                    warn "⚠️  STRICT MODE ENABLED!"
                    warn "⚠️  All traffic MUST go through Tor"
                    success "TAILS-LIKE rules applied"
                fi
                ;;
                
            4) # CUSTOM
                info "Custom configuration - please edit /etc/iptables/rules.v4 manually"
                success "IPTables installed, configure manually"
                ;;
        esac
        
        # Save rules if configured
        if [ "$iptables_level" != "4" ]; then
            info "Saving IPTables rules..."
            iptables-save > /etc/iptables/rules.v4
            ip6tables-save > /etc/iptables/rules.v6
            
            systemctl enable netfilter-persistent
            systemctl start netfilter-persistent
            
            success "IPTables rules saved and will persist after reboot"
        fi
        ;;
esac

#===========================================#
#   Network Scanning & Reconnaissance      #
#===========================================#
section "🔍 Network Scanning & Reconnaissance"

info "Installing Nmap..."
apt install -y nmap
success "Nmap installed"

info "Installing Netcat..."
apt install -y netcat-traditional
update-alternatives --set nc /bin/nc.traditional 2>/dev/null || true
success "Netcat-traditional installed"

info "Installing Subfinder (subdomain discovery)..."
if command -v subfinder &> /dev/null; then
    warn "Subfinder already installed"
else
    sudo -u $REAL_USER bash -c 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin && go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest'
    ln -sf "$USER_HOME/go/bin/subfinder" /usr/local/bin/subfinder 2>/dev/null || true
    success "Subfinder installed"
fi

info "Installing Httpx (HTTP toolkit)..."
if command -v httpx &> /dev/null; then
    warn "Httpx already installed"
else
    sudo -u $REAL_USER bash -c 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin && go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest'
    ln -sf "$USER_HOME/go/bin/httpx" /usr/local/bin/httpx 2>/dev/null || true
    success "Httpx installed"
fi

#===========================================#
#   Web Application Testing                #
#===========================================#
section "🌐 Web Application Testing"

info "Installing SQLMap..."
apt install -y sqlmap
success "SQLMap installed"

info "Installing WPScan..."
apt install -y wpscan
success "WPScan installed"

info "Installing Nikto..."
apt install -y nikto
success "Nikto installed"

info "Installing Ffuf (fast web fuzzer)..."
if command -v ffuf &> /dev/null; then
    warn "Ffuf already installed"
else
    sudo -u $REAL_USER bash -c 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin && go install github.com/ffuf/ffuf/v2@latest'
    ln -sf "$USER_HOME/go/bin/ffuf" /usr/local/bin/ffuf 2>/dev/null || true
    success "Ffuf installed"
fi

info "Installing Gobuster..."
apt install -y gobuster
success "Gobuster installed"

info "Installing Nuclei (vulnerability scanner)..."
if command -v nuclei &> /dev/null; then
    warn "Nuclei already installed"
else
    sudo -u $REAL_USER bash -c 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin && go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest'
    ln -sf "$USER_HOME/go/bin/nuclei" /usr/local/bin/nuclei 2>/dev/null || true
    sudo -u $REAL_USER nuclei -update-templates
    success "Nuclei installed and templates updated"
fi

#===========================================#
#   Wireless Security                      #
#===========================================#
section "📶 Wireless Security"

info "Installing Aircrack-ng suite..."
apt install -y aircrack-ng
success "Aircrack-ng installed"

info "Installing Reaver (WPS attack tool)..."
apt install -y reaver
success "Reaver installed"

info "Installing Airgeddon (wireless auditing framework)..."
if [ -d "/opt/airgeddon" ]; then
    warn "Airgeddon already exists in /opt/airgeddon"
else
    git clone --depth 1 https://github.com/v1s1t0r1sh3r3/airgeddon.git /opt/airgeddon
    chmod +x /opt/airgeddon/airgeddon.sh
    ln -sf /opt/airgeddon/airgeddon.sh /usr/local/bin/airgeddon
    success "Airgeddon installed to /opt/airgeddon"
fi

#===========================================#
#   Password Attacks                       #
#===========================================#
section "🔓 Password Cracking"

info "Installing Hydra..."
apt install -y hydra
success "Hydra installed"

info "Installing John the Ripper..."
apt install -y john
success "John the Ripper installed"

info "Installing CrackMapExec..."
apt install -y crackmapexec
success "CrackMapExec installed"

#===========================================#
#   Privilege Escalation                   #
#===========================================#
section "⬆️  Privilege Escalation"

info "Installing PEASS-ng (LinPEAS/WinPEAS)..."

PEASS_DIR="/opt/PEASS-ng"
mkdir -p "$PEASS_DIR"

if [ -d "$PEASS_DIR/.git" ]; then
    warn "PEASS-ng already exists, updating..."
    cd "$PEASS_DIR"
    git pull
else
    git clone https://github.com/carlospolop/PEASS-ng.git "$PEASS_DIR"
fi

ln -sf "$PEASS_DIR/linPEAS/linpeas.sh" /usr/local/bin/linpeas
chmod +x "$PEASS_DIR/linPEAS/linpeas.sh"

success "PEASS-ng installed to $PEASS_DIR"

#===========================================#
#   Exploitation Frameworks                #
#===========================================#
section "💣 Exploitation Frameworks"

info "Installing Metasploit Framework..."
if command -v msfconsole &> /dev/null; then
    warn "Metasploit already installed"
else
    info "This may take a while..."
    apt install -y metasploit-framework
    
    info "Initializing Metasploit database..."
    msfdb init
    
    success "Metasploit Framework installed"
fi

info "Installing ExploitDB & SearchSploit..."
apt install -y exploitdb
success "ExploitDB & SearchSploit installed"

#===========================================#
#   Network Attack Tools                   #
#===========================================#
section "🌐 Network Attack Tools"

info "Installing Bettercap..."
apt install -y bettercap
success "Bettercap installed"

info "Installing Ettercap..."
apt install -y ettercap-common ettercap-graphical
success "Ettercap installed"

info "Installing MITMproxy..."
apt install -y mitmproxy
success "MITMproxy installed"

info "Installing Responder..."
apt install -y responder
success "Responder installed"

#===========================================#
#   Security Utilities                     #
#===========================================#
section "🛠️  Security Utilities"

info "Installing Macchanger..."
apt install -y macchanger
success "Macchanger installed"

info "Installing Pypykatz..."
pip3 install pypykatz --break-system-packages 2>/dev/null || pip3 install pypykatz
success "Pypykatz installed"

info "Downloading Mimikatz (Windows binary)..."
MIMIKATZ_DIR="/opt/mimikatz"
mkdir -p "$MIMIKATZ_DIR"

if [ -f "$MIMIKATZ_DIR/mimikatz.exe" ]; then
    warn "Mimikatz already downloaded"
else
    info "Fetching latest Mimikatz release..."
    MIMIKATZ_URL=$(curl -s https://api.github.com/repos/gentilkiwi/mimikatz/releases/latest | grep "browser_download_url.*mimikatz_trunk.zip" | cut -d '"' -f 4)
    
    if [ -n "$MIMIKATZ_URL" ]; then
        wget -q -O /tmp/mimikatz.zip "$MIMIKATZ_URL"
        unzip -q -o /tmp/mimikatz.zip -d "$MIMIKATZ_DIR"
        rm -f /tmp/mimikatz.zip
        success "Mimikatz downloaded to $MIMIKATZ_DIR"
    else
        warn "Could not fetch Mimikatz, download manually from GitHub"
    fi
fi

info "Installing Wine (to run Mimikatz)..."
dpkg --add-architecture i386
apt update -qq
apt install -y wine wine32 wine64
success "Wine installed"

info "Installing Impacket..."
apt install -y python3-impacket impacket-scripts
success "Impacket installed"

info "Installing Enum4linux..."
apt install -y enum4linux
success "Enum4linux installed"

info "Installing SMB tools..."
apt install -y smbclient smbmap
success "SMB tools installed"

#===========================================#
#   Wordlists & Dictionaries               #
#===========================================#
section "📚 Wordlists & Dictionaries"

info "Installing SecLists..."
apt install -y seclists
success "SecLists installed to /usr/share/seclists"

info "Installing Wordlists package..."
apt install -y wordlists
success "Wordlists installed to /usr/share/wordlists"

info "Extracting RockYou wordlist..."
ROCKYOU_DIR="/usr/share/wordlists"
mkdir -p "$ROCKYOU_DIR"

if [ -f "$ROCKYOU_DIR/rockyou.txt" ]; then
    warn "RockYou already extracted"
else
    if [ -f "/usr/share/wordlists/rockyou.txt.gz" ]; then
        gunzip -k /usr/share/wordlists/rockyou.txt.gz
        success "RockYou wordlist extracted"
    else
        info "Downloading RockYou wordlist..."
        wget -q -O "$ROCKYOU_DIR/rockyou.txt" https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt
        success "RockYou wordlist downloaded"
    fi
fi

#===========================================#
#   Post-Install Configuration             #
#===========================================#
section "⚙️  Post-Installation Configuration"

TOOLS_DIR="/opt/security-tools"
mkdir -p "$TOOLS_DIR"
chown -R $REAL_USER:$REAL_USER "$TOOLS_DIR"

info "Security tools directory created: $TOOLS_DIR"

# Create aliases
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
alias crack-hash='john --wordlist=/usr/share/wordlists/rockyou.txt'
alias priv-esc='linpeas'
ALIASEOF

chown $REAL_USER:$REAL_USER "$ALIASES_FILE"

# Add to shell profiles
for rc_file in "$USER_HOME/.bashrc" "$USER_HOME/.zshrc"; do
    if [ -f "$rc_file" ] && ! grep -q "security_aliases" "$rc_file"; then
        echo "[ -f ~/.security_aliases ] && source ~/.security_aliases" >> "$rc_file"
    fi
done

success "Security aliases created: $ALIASES_FILE"

#===========================================#
#   Summary                                #
#===========================================#
echo ""
echo -e "${CYAN}${BOLD}╔═══════════════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}${BOLD}║                                                       ║${RESET}"
echo -e "${CYAN}${BOLD}║      ✅ Security Tools Installation Complete! ✅      ║${RESET}"
echo -e "${CYAN}${BOLD}║                                                       ║${RESET}"
echo -e "${CYAN}${BOLD}╚═══════════════════════════════════════════════════════╝${RESET}"
echo ""
info "📋 Installed Tools Summary:"
echo ""
echo "🌐 Essential: wget, curl, net-tools, dnsutils"
echo "🗄️  Database: PostgreSQL"
echo "🔥 Firewall: IPTables configured"
echo "🧅 Privacy: Tor Network"
echo "🔍 Recon: Nmap, Netcat, Subfinder, Httpx"
echo "🌐 Web: SQLMap, WPScan, Nikto, Ffuf, Gobuster, Nuclei"
echo "📶 Wireless: Aircrack-ng, Reaver, Airgeddon"
echo "🔓 Password: Hydra, John, CrackMapExec"
echo "⬆️  PrivEsc: PEASS-ng (LinPEAS/WinPEAS)"
echo "💣 Exploit: Metasploit, ExploitDB"
echo "🌐 Network: Bettercap, Ettercap, MITMproxy, Responder"
echo "🛠️  Utils: Macchanger, Pypykatz, Mimikatz, Impacket, SMB tools"
echo "📚 Wordlists: SecLists, RockYou"
echo ""
info "🎯 Quick Commands:"
echo "  • Port scan:     nmap -sV -sC <target>"
echo "  • Vuln scan:     nuclei -u <url>"
echo "  • Subdomain:     subfinder -d example.com"
echo "  • Directory:     ffuf -w wordlist.txt -u URL/FUZZ"
echo "  • Metasploit:    msfconsole"
echo "  • WiFi monitor:  airmon-ng start wlan0"
echo "  • Crack hash:    john --wordlist=rockyou.txt hash.txt"
echo ""
info "📂 Important Paths:"
echo "  • Tools:         /opt/security-tools"
echo "  • PEASS-ng:      /opt/PEASS-ng"
echo "  • Mimikatz:      /opt/mimikatz"
echo "  • Airgeddon:     /opt/airgeddon"
echo "  • SecLists:      /usr/share/seclists"
echo "  • Wordlists:     /usr/share/wordlists"
echo "  • RockYou:       /usr/share/wordlists/rockyou.txt"
echo "  • Aliases:       ~/.security_aliases"
echo ""
warn "⚠️  CRITICAL REMINDERS:"
echo ""
echo "  1. ✅ ALWAYS get written authorization before testing"
echo "  2. 🚫 NEVER use these tools on systems you don't own"
echo "  3. 📜 Unauthorized access is ILLEGAL in most countries"
echo "  4. 🎓 Use for learning in controlled lab environments"
echo "  5. 📖 Read tool documentation before use"
echo ""

if [ "$iptables_level" == "3" ]; then
    echo -e "${RED}${BOLD}╔═══════════════════════════════════════════════════════╗${RESET}"
    echo -e "${RED}${BOLD}║                                                       ║${RESET}"
    echo -e "${RED}${BOLD}║           🔥 FIREWALL IN STRICT MODE 🔥               ║${RESET}"
    echo -e "${RED}${BOLD}║                                                       ║${RESET}"
    echo -e "${RED}${BOLD}║  All traffic is routed through Tor!                   ║${RESET}"
    echo -e "${RED}${BOLD}║  Regular apps may not work properly.                  ║${RESET}"
    echo -e "${RED}${BOLD}║                                                       ║${RESET}"
    echo -e "${RED}${BOLD}║  To disable: systemctl stop netfilter-persistent      ║${RESET}"
    echo -e "${RED}${BOLD}║                                                       ║${RESET}"
    echo -e "${RED}${BOLD}╚═══════════════════════════════════════════════════════╝${RESET}"
    echo ""
fi

info "📄 Next Steps:"
echo "  1. Restart your terminal to load aliases"
echo "  2. Test Tor connection: curl --socks5 127.0.0.1:9050 https://check.torproject.org"
echo "  3. Update Nuclei templates: nuclei -update-templates"
echo "  4. Initialize Metasploit DB: msfdb init"
echo "  5. Review firewall rules: iptables -L -v"
echo ""
info "🛠️  Manage IPTables:"
echo "  • View rules:       iptables -L -v -n"
echo "  • View IPv6:        ip6tables -L -v -n"
echo "  • Restore backup:   iptables-restore < /etc/iptables/backups/rules.v4.backup.*"
echo "  • Edit rules:       nano /etc/iptables/rules.v4"
echo "  • Reload:           systemctl restart netfilter-persistent"
echo "  • Disable firewall: systemctl stop netfilter-persistent"
echo ""
success "🎉 Happy (Ethical) Hacking!"
echo ""
echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"