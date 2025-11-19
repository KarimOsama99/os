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
section() { echo -e "${CYAN}$1${RESET}"; }

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
echo "   🔐 Security & Penetration Testing Tools"
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

#===========================================#
#   Essential Network Tools                #
#===========================================#
section "
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🌐 Essential Network Tools
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

info "Installing essential network tools..."
apt install -y \
    wget \
    curl \
    net-tools \
    dnsutils \
    iputils-ping \
    traceroute

success "Essential network tools installed"

#===========================================#
#   PostgreSQL Database                    #
#===========================================#
section "
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🗄️  PostgreSQL Database
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

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
section "
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🧅 Tor Network Configuration
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

info "Tor service should already be installed from installApps.sh"
if ! command -v tor &> /dev/null; then
    warn "Tor not found, installing..."
    apt install -y tor
    systemctl enable tor
    systemctl start tor
    success "Tor installed and started"
else
    success "Tor is already installed"
fi

#===========================================#
#   IPTables & Firewall Configuration      #
#===========================================#
section "
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🔥 IPTables Firewall Configuration
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

info "Installing iptables and iptables-persistent..."
apt install -y iptables iptables-persistent
success "IPTables installed"

info "Configuring IPTables rules (Tails-like configuration)..."

# Backup existing rules
iptables-save > /etc/iptables/rules.v4.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
ip6tables-save > /etc/iptables/rules.v6.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true

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

# Set default policies
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

ip6tables -P INPUT DROP
ip6tables -P FORWARD DROP
ip6tables -P OUTPUT DROP

# Allow loopback
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

ip6tables -A INPUT -i lo -j ACCEPT
ip6tables -A OUTPUT -o lo -j ACCEPT

# Allow established connections
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

ip6tables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
ip6tables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow DNS through Tor (port 53 to Tor DNS port)
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT

# Allow Tor connections
# Tor SOCKS port (9050)
iptables -A OUTPUT -p tcp --dport 9050 -j ACCEPT

# Tor Control port (9051) - localhost only
iptables -A OUTPUT -d 127.0.0.1 -p tcp --dport 9051 -j ACCEPT

# Tor Directory servers (80, 443)
iptables -A OUTPUT -p tcp --dport 80 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 443 -j ACCEPT

# Tor relay ports (9001, 9030)
iptables -A OUTPUT -p tcp --dport 9001 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 9030 -j ACCEPT

# Allow ICMP (ping) - optional, comment out for maximum privacy
iptables -A OUTPUT -p icmp -j ACCEPT
iptables -A INPUT -p icmp -j ACCEPT

# Block all IPv6 traffic (force IPv4 through Tor)
ip6tables -P INPUT DROP
ip6tables -P FORWARD DROP
ip6tables -P OUTPUT DROP

# Log dropped packets (optional, for debugging)
iptables -A INPUT -j LOG --log-prefix "IPT-INPUT-DROP: " --log-level 4
iptables -A OUTPUT -j LOG --log-prefix "IPT-OUTPUT-DROP: " --log-level 4

# Save rules
info "Saving IPTables rules..."
iptables-save > /etc/iptables/rules.v4
ip6tables-save > /etc/iptables/rules.v6

# Make rules persistent
systemctl enable netfilter-persistent
systemctl start netfilter-persistent

success "IPTables configured with Tails-like rules"
info "✓ Default policy: DROP all"
info "✓ Loopback: ALLOWED"
info "✓ Established connections: ALLOWED"
info "✓ Tor connections: ALLOWED (ports 9050, 9051, 80, 443, 9001, 9030)"
info "✓ DNS: ALLOWED"
info "✓ IPv6: BLOCKED (all traffic)"
info "✓ ICMP: ALLOWED (can be disabled for more privacy)"

#===========================================#
#   Network Scanning & Reconnaissance      #
#===========================================#
section "
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🔍 Network Scanning & Reconnaissance
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

info "Installing Nmap..."
apt install -y nmap
success "Nmap installed"

info "Installing Netcat..."
apt install -y netcat-traditional
update-alternatives --set nc /bin/nc.traditional
success "Netcat-traditional installed and set as default"

info "Installing Subfinder (subdomain discovery)..."
if command -v subfinder &> /dev/null; then
    warn "Subfinder already installed"
else
    sudo -u $REAL_USER bash -c 'export PATH=$PATH:/usr/local/go/bin && go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest'
    ln -sf "$USER_HOME/go/bin/subfinder" /usr/local/bin/subfinder
    success "Subfinder installed"
fi

info "Installing Httpx (HTTP toolkit)..."
if command -v httpx &> /dev/null; then
    warn "Httpx already installed"
else
    sudo -u $REAL_USER bash -c 'export PATH=$PATH:/usr/local/go/bin && go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest'
    ln -sf "$USER_HOME/go/bin/httpx" /usr/local/bin/httpx
    success "Httpx installed"
fi

#===========================================#
#   Web Application Testing                #
#===========================================#
section "
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🌐 Web Application Testing
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

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
    sudo -u $REAL_USER bash -c 'export PATH=$PATH:/usr/local/go/bin && go install github.com/ffuf/ffuf/v2@latest'
    ln -sf "$USER_HOME/go/bin/ffuf" /usr/local/bin/ffuf
    success "Ffuf installed"
fi

info "Installing Gobuster..."
apt install -y gobuster
success "Gobuster installed"

info "Installing Nuclei (vulnerability scanner)..."
if command -v nuclei &> /dev/null; then
    warn "Nuclei already installed"
else
    sudo -u $REAL_USER bash -c 'export PATH=$PATH:/usr/local/go/bin && go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest'
    ln -sf "$USER_HOME/go/bin/nuclei" /usr/local/bin/nuclei
    sudo -u $REAL_USER nuclei -update-templates
    success "Nuclei installed and templates updated"
fi

#===========================================#
#   Wireless Security                      #
#===========================================#
section "
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  📶 Wireless Security
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

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
    info "Run with: airgeddon"
fi

#===========================================#
#   Password Attacks                       #
#===========================================#
section "
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🔓 Password Cracking
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

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
section "
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ⬆️  Privilege Escalation
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

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
info "LinPEAS: linpeas or $PEASS_DIR/linPEAS/linpeas.sh"
info "WinPEAS: $PEASS_DIR/winPEAS/winPEASany.exe"

#===========================================#
#   Exploitation Frameworks                #
#===========================================#
section "
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  💣 Exploitation Frameworks
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

info "Installing Metasploit Framework..."
if command -v msfconsole &> /dev/null; then
    warn "Metasploit already installed"
else
    info "This may take a while..."
    apt install -y metasploit-framework
    
    info "Initializing Metasploit database..."
    msfdb init
    
    success "Metasploit Framework installed"
    info "Run with: msfconsole"
fi

info "Installing ExploitDB & SearchSploit..."
apt install -y exploitdb
success "ExploitDB & SearchSploit installed"

#===========================================#
#   Network Attack Tools                   #
#===========================================#
section "
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🌍 Network Attack Tools
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

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
section "
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🛠️  Security Utilities
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

info "Installing Macchanger..."
apt install -y macchanger
success "Macchanger installed"

info "Installing Pypykatz (Mimikatz Python alternative)..."
apt install -y python3-pip
pip3 install pypykatz --break-system-packages
success "Pypykatz installed"

info "Downloading Mimikatz (Windows binary)..."
MIMIKATZ_DIR="/opt/mimikatz"
mkdir -p "$MIMIKATZ_DIR"

if [ -f "$MIMIKATZ_DIR/mimikatz.exe" ]; then
    warn "Mimikatz already downloaded"
else
    info "Fetching latest Mimikatz release..."
    MIMIKATZ_URL=$(curl -s https://api.github.com/repos/gentilkiwi/mimikatz/releases/latest | \
        grep "browser_download_url.*mimikatz_trunk.zip" | cut -d '"' -f 4)
    
    if [ -n "$MIMIKATZ_URL" ]; then
        wget -O /tmp/mimikatz.zip "$MIMIKATZ_URL" --progress=bar:force
        unzip -o /tmp/mimikatz.zip -d "$MIMIKATZ_DIR"
        rm -f /tmp/mimikatz.zip
        success "Mimikatz downloaded to $MIMIKATZ_DIR"
        info "Usage: wine $MIMIKATZ_DIR/x64/mimikatz.exe"
    else
        warn "Could not fetch Mimikatz URL automatically"
        info "Download manually from: https://github.com/gentilkiwi/mimikatz/releases"
    fi
fi

# Install wine for running Mimikatz
info "Installing Wine (to run Mimikatz)..."
dpkg --add-architecture i386
apt update
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
section "
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  📚 Wordlists & Dictionaries
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

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
        wget -O "$ROCKYOU_DIR/rockyou.txt.gz" https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt
        gunzip "$ROCKYOU_DIR/rockyou.txt.gz"
        success "RockYou wordlist downloaded and extracted"
    fi
fi

#===========================================#
#   Post-Install Configuration             #
#===========================================#
section "
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ⚙️  Post-Installation Configuration
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

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
alias crack-hash='john --wordlist=rockyou.txt'
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
echo
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
success "✅ Security Tools Installation Complete!"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
info "📋 Installed Tools Summary:"
echo
echo "🌐 Essential Network Tools:"
echo "  ✓ wget, curl, net-tools, dnsutils"
echo
echo "🗄️  Database:"
echo "  ✓ PostgreSQL (running)"
echo
echo "🔥 Firewall & Privacy:"
echo "  ✓ IPTables (Tails-like configuration)"
echo "  ✓ Tor Network (integrated)"
echo
echo "🔍 Reconnaissance & Scanning:"
echo "  ✓ Nmap, Netcat, Subfinder, Httpx"
echo
echo "🌐 Web Application Testing:"
echo "  ✓ SQLMap, WPScan, Nikto, Ffuf, Gobuster, Nuclei"
echo
echo "📶 Wireless Security:"
echo "  ✓ Aircrack-ng, Reaver, Airgeddon"
echo
echo "🔓 Password & Authentication:"
echo "  ✓ Hydra, John the Ripper, CrackMapExec"
echo
echo "⬆️  Privilege Escalation:"
echo "  ✓ PEASS-ng (LinPEAS/WinPEAS)"
echo
echo "💣 Exploitation:"
echo "  ✓ Metasploit Framework, ExploitDB"
echo
echo "🌍 Network Attacks:"
echo "  ✓ Bettercap, Ettercap, MITMproxy, Responder"
echo
echo "🛠️  Utilities:"
echo "  ✓ Macchanger, Pypykatz, Mimikatz, Impacket, Enum4linux, SMB tools, Wine"
echo
echo "📚 Wordlists:"
echo "  ✓ SecLists, Wordlists, RockYou"
echo
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
info "🔥 IPTables Configuration:"
echo "  ✓ Default policy: DROP all traffic"
echo "  ✓ Tor connections: ALLOWED"
echo "  ✓ IPv6: BLOCKED (forces IPv4 through Tor)"
echo "  ✓ Established connections: ALLOWED"
echo "  ✓ Similar to Tails OS firewall setup"
echo
info "🎯 Quick Test Commands:"
echo
echo "  Check Tor IP:        curl --socks5 127.0.0.1:9050 https://check.torproject.org/api/ip"
echo "  Port scan:           nmap -sV -sC <target>"
echo "  Vulnerability scan:  nuclei -u <url>"
echo "  Directory fuzzing:   ffuf -w wordlist.txt -u URL/FUZZ"
echo "  Subdomain discovery: subfinder -d example.com"
echo "  HTTP probing:        httpx -l subdomains.txt"
echo "  Metasploit:          msfconsole"
echo "  WiFi monitor mode:   airmon-ng start wlan0"
echo "  Password cracking:   john --wordlist=/usr/share/wordlists/rockyou.txt hash.txt"
echo "  Mimikatz:            wine /opt/mimikatz/x64/mimikatz.exe"
echo
info "📂 Important Paths:"
echo "  • Security tools:     /opt/security-tools"
echo "  • PEASS-ng:           /opt/PEASS-ng"
echo "  • Mimikatz:           /opt/mimikatz"
echo "  • Airgeddon:          /opt/airgeddon"
echo "  • SecLists:           /usr/share/seclists"
echo "  • Wordlists:          /usr/share/wordlists"
echo "  • RockYou:            /usr/share/wordlists/rockyou.txt"
echo "  • Security aliases:   ~/.security_aliases"
echo
warn "⚠️  CRITICAL REMINDERS:"
echo
echo "  1. ✅ ALWAYS get written authorization before testing"
echo "  2. 🚫 NEVER use these tools on systems you don't own"
echo "  3. 📜 Unauthorized access is ILLEGAL in most countries"
echo "  4. 🎓 Use for learning in controlled lab environments"
echo "  5. 🔥 IPTables rules active - traffic routed through Tor by default"
echo "  6. 📖 Read tool documentation before use"
echo
info "🔄 Next Steps:"
echo "  1. Restart your terminal to load aliases"
echo "  2. Update Nuclei templates: nuclei -update-templates"
echo "  3. Initialize Metasploit database: msfdb init"
echo "  4. Test Tor connection: curl --socks5 127.0.0.1:9050 https://check.torproject.org"
echo "  5. Review IPTables rules: iptables -L -v"
echo
success "🎉 Happy (Ethical) Hacking!"
echo
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"