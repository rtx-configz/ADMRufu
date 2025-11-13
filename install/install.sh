#!/bin/bash
# AUTO INSTALL ADMRufu - UPDATED 11-12-2025 -- By @rtx-configz (Ubuntu 25 Compatible - English Version)
clear && clear

#-- VERIFY ROOT USER
if [ $(whoami) != 'root' ]; then
  echo ""
  echo -e "\e[1;31m YOU MUST BE ROOT USER TO RUN THIS SCRIPT \n\n\e[97m                TYPE: \e[1;32m sudo su\n"
  exit
fi

# Load colors
colores="$(pwd)/colores"
rm -rf ${colores}
wget -O ${colores} "https://raw.githubusercontent.com/rtx-configz/ADMRufu/main/Otros/colores" &>/dev/null
[[ ! -e ${colores} ]] && exit
chmod +x ${colores} &>/dev/null
source ${colores}

CTRL_C() {
  rm -rf ${colores}
  rm -rf /root/LATAM
  exit
}
trap "CTRL_C" INT TERM EXIT

os_system() {
  system=$(cat -n /etc/issue | grep 1 | cut -d ' ' -f6,7,8 | sed 's/1//' | sed 's/      //')
  distro=$(echo "$system" | awk '{print $1}')

  case $distro in
  Debian) vercion=$(echo $system | awk '{print $3}' | cut -d '.' -f1) ;;
  Ubuntu) 
    # Updated to support Ubuntu 25 and newer versions
    vercion=$(lsb_release -rs 2>/dev/null || echo "$system" | awk '{print $2}' | cut -d '.' -f1,2)
    ;;
  esac
}

# Function to get public IP with multiple fallback methods
get_public_ip() {
  local ip=""
  
  # Method 1: Try ipinfo.io
  ip=$(curl -s --max-time 5 ipinfo.io/ip 2>/dev/null)
  [[ -n "$ip" ]] && echo "$ip" && return 0
  
  # Method 2: Try ifconfig.me with plain text
  ip=$(curl -s --max-time 5 ifconfig.me/ip 2>/dev/null)
  [[ -n "$ip" ]] && echo "$ip" && return 0
  
  # Method 3: Try icanhazip.com
  ip=$(curl -s --max-time 5 icanhazip.com 2>/dev/null)
  [[ -n "$ip" ]] && echo "$ip" && return 0
  
  # Method 4: Try api.ipify.org
  ip=$(curl -s --max-time 5 api.ipify.org 2>/dev/null)
  [[ -n "$ip" ]] && echo "$ip" && return 0
  
  # Method 5: Try ident.me
  ip=$(curl -s --max-time 5 ident.me 2>/dev/null)
  [[ -n "$ip" ]] && echo "$ip" && return 0
  
  # Method 6: Try with wget as fallback
  ip=$(wget -qO- --timeout=5 ipinfo.io/ip 2>/dev/null)
  [[ -n "$ip" ]] && echo "$ip" && return 0
  
  # Method 7: Try hostname -I (local IP as last resort)
  ip=$(hostname -I 2>/dev/null | awk '{print $1}')
  [[ -n "$ip" ]] && echo "$ip" && return 0
  
  # If all methods fail
  echo "Unable to detect"
  return 1
}

# STEP 1: UPDATE SYSTEM REPOSITORIES
update_repo() {
  echo -e "\e[1;97m"
  msgi -bar2
  echo -e "\e[1;96m STEP 1: UPDATING SYSTEM REPOSITORIES"
  msgi -bar2
  
  link="https://raw.githubusercontent.com/rtx-configz/ADMRufu/main/Source-List/$1.list"
  
  case $1 in
  8 | 9 | 10 | 11 | 16.04 | 18.04 | 20.04 | 20.10 | 21.04 | 21.10 | 22.04 | 24.04 | 25.04 | 25.10) 
    echo -e "\e[1;97m Updating repository sources for $distro $1..."
    wget -O /etc/apt/sources.list ${link} &>/dev/null
    echo -e "\e[1;92m ✓ Repository sources updated"
    ;;
  *)
    echo -e "\e[1;93m Using default repository sources for $distro $1"
    ;;
  esac
  
  echo -e "\e[1;97m Running apt update..."
  apt update -y
  echo -e "\e[1;92m ✓ System repositories updated successfully"
  
  echo -e "\e[1;97m Running apt upgrade (this may take several minutes)..."
  DEBIAN_FRONTEND=noninteractive apt upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
  echo -e "\e[1;92m ✓ System upgraded successfully"
  msgi -bar2
}

# STEP 2: INSTALL DEPENDENCIES
install_dependencias() {
  echo -e "\e[1;97m"
  msgi -bar2
  echo -e "\e[1;96m STEP 2: INSTALLING DEPENDENCIES"
  msgi -bar2
  
  rm -rf /root/paknoinstall.log >/dev/null 2>&1
  rm -rf /root/packinstall.log >/dev/null 2>&1
  dpkg --configure -a >/dev/null 2>&1
  apt -f install -y >/dev/null 2>&1
  
  # Package list for dependencies
  soft="sudo bsdmainutils zip screen unzip ufw curl python3 dropbear python3-pip openssl cron iptables lsof pv boxes at gawk bc jq npm nodejs socat netcat-openbsd net-tools cowsay figlet lolcat apache2"

  echo -e "\e[1;97m Installing required packages..."
  for i in $soft; do
    echo -e "\e[1;97m   → Installing package: \e[36m$i\e[97m"
    apt-get install $i -y >/dev/null 2>&1
    if [ $? -eq 0 ]; then
      echo -e "\e[1;92m   ✓ $i installed successfully"
    else
      echo -e "\e[1;93m   ⚠ $i may have issues (continuing...)"
    fi
  done
  
  rm -rf /root/paknoinstall.log >/dev/null 2>&1
  rm -rf /root/packinstall.log >/dev/null 2>&1
  
  echo -e "\e[1;92m ✓ All dependencies installed"
  msgi -bar2
}

# STEP 3: CONFIGURE APACHE AND SYSTEM
configure_system() {
  echo -e "\e[1;97m"
  msgi -bar2
  echo -e "\e[1;96m STEP 3: CONFIGURING SYSTEM"
  msgi -bar2
  
  # Configure Apache to listen on port 81
  sed -i "s;Listen 80;Listen 81;g" /etc/apache2/ports.conf >/dev/null 2>&1
  systemctl restart apache2 >/dev/null 2>&1
  
  if [[ $(sudo lsof -i :81) ]]; then
    echo -e "\e[1;92m ✓ Apache configured and active on port 81"
  else
    echo -e "\e[1;91m ⚠ Apache installation may have issues"
  fi
  
  echo -e "\e[1;97m Removing obsolete packages..."
  apt autoremove -y &>/dev/null
  echo -e "\e[1;92m ✓ Obsolete packages removed"
  
  # Configure iptables-persistent
  echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
  echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections
  
  # Disable alphanumeric password requirement
  echo -e "\e[1;97m Configuring password policy..."
  apt-get install libpam-cracklib -y &>/dev/null
  echo -e '# Simple Pass Module
password [success=1 default=ignore] pam_unix.so obscure sha512
password requisite pam_deny.so
password required pam_permit.so' >/etc/pam.d/common-password
  chmod +x /etc/pam.d/common-password
  echo -e "\e[1;92m ✓ Password policy configured"
  
  msgi -bar2
}

# STEP 4: AUTO INSTALL ADMRufu
auto_install_ADMRufu() {
  echo -e "\e[1;97m"
  msgi -bar2
  echo -e "\e[1;96m STEP 4: INSTALLING ADMRufu"
  msgi -bar2
  
  # Default slogan (can be changed)
  slogan="ADMRufu Auto Install by @rtx-configz"
  echo -e "\e[1;97m Using default slogan: \e[1;32m$slogan"
  
  clear && clear
  msgi -bar2
  echo -e "\e[1;93m Installing ADMRufu - Please wait..."
  msgi -bar2
  
  # Create directory
  mkdir /etc/ADMRufu >/dev/null 2>&1
  cd /etc
  
  # Download and extract
  echo -e "\e[1;97m Downloading ADMRufu files..."
  wget https://raw.githubusercontent.com/rtx-configz/ADMRufu/main/R9/ADMRufu.tar.xz >/dev/null 2>&1
  
  if [ $? -eq 0 ]; then
    echo -e "\e[1;92m ✓ Download completed"
  else
    echo -e "\e[1;91m ✗ Download failed"
    exit 1
  fi
  
  echo -e "\e[1;97m Extracting files..."
  tar -xf ADMRufu.tar.xz >/dev/null 2>&1
  chmod +x ADMRufu.tar.xz >/dev/null 2>&1
  rm -rf ADMRufu.tar.xz
  cd
  
  chmod -R 755 /etc/ADMRufu
  
  # Configure directories
  ADMRufu="/etc/ADMRufu" && [[ ! -d ${ADMRufu} ]] && mkdir ${ADMRufu}
  ADM_inst="${ADMRufu}/install" && [[ ! -d ${ADM_inst} ]] && mkdir ${ADM_inst}
  SCPinstal="$HOME/install"
  
  # Remove old menu commands
  rm -rf /usr/bin/menu >/dev/null 2>&1
  rm -rf /usr/bin/adm >/dev/null 2>&1
  rm -rf /usr/bin/ADMRufu >/dev/null 2>&1
  
  # Create directory for message
  mkdir -p /etc/ADMRufu/tmp >/dev/null 2>&1
  
  # Set slogan
  echo "$slogan" >/etc/ADMRufu/tmp/message.txt
  
  # Create menu commands
  echo "${ADMRufu}/menu" >/usr/bin/menu && chmod +x /usr/bin/menu
  echo "${ADMRufu}/menu" >/usr/bin/adm && chmod +x /usr/bin/adm
  echo "${ADMRufu}/menu" >/usr/bin/ADMRufu && chmod +x /usr/bin/ADMRufu
  
  echo -e "\e[1;92m ✓ Menu commands created"
  
  # Configure bash environment
  [[ -z $(echo $PATH | grep "/usr/games") ]] && echo 'if [[ $(echo $PATH|grep "/usr/games") = "" ]]; then PATH=$PATH:/usr/games; fi' >>/etc/bash.bashrc
  
  echo '[[ $UID = 0 ]] && screen -dmS up /etc/ADMRufu/chekup.sh' >>/etc/bash.bashrc
  echo 'v=$(cat /etc/ADMRufu/vercion 2>/dev/null || echo "R9")' >>/etc/bash.bashrc
  echo '[[ -e /etc/ADMRufu/new_vercion ]] && up=$(cat /etc/ADMRufu/new_vercion) || up=$v' >>/etc/bash.bashrc
  echo -e "[[ \$(date '+%s' -d \$up 2>/dev/null) -gt \$(date '+%s' -d \$(cat /etc/ADMRufu/vercion 2>/dev/null) 2>/dev/null) ]] && v2=\"New Version available: \$v >>> \$up\" || v2=\"Script Version: \$v\"" >>/etc/bash.bashrc
  echo '[[ -e "/etc/ADMRufu/tmp/message.txt" ]] && mess1="$(less /etc/ADMRufu/tmp/message.txt)"' >>/etc/bash.bashrc
  echo '[[ -z "$mess1" ]] && mess1="@rtx-configz"' >>/etc/bash.bashrc
  echo 'clear && echo -e "\n$(figlet -f big.flf "  ADMRufu" 2>/dev/null || echo "ADMRufu")\n        RESELLER : $mess1 \n\n   To start ADMRufu type:  menu \n\n   $v2\n\n"|lolcat 2>/dev/null || cat' >>/etc/bash.bashrc

  # Set locale
  update-locale LANG=en_US.UTF-8 LANGUAGE=en >/dev/null 2>&1
  
  echo -e "\e[1;92m ✓ Bash environment configured"
  
  # Copy bashrc
  /bin/cp /etc/skel/.bashrc ~/
  
  msgi -bar2
  echo -e "\e[1;92m ✓ ADMRufu installed successfully!"
  msgi -bar2
}

# MAIN EXECUTION
main() {
  clear && clear
  msgi -bar2
  echo -e " \e[5m\e[1;100m   =====>> ►►  AUTO INSTALL ADMRufu  ◄◄ <<=====   \e[1;37m"
  msgi -bar2
  
  # Get version
  v1=$(curl -sSL "https://raw.githubusercontent.com/rtx-configz/ADMRufu/main/Vercion" 2>/dev/null || echo "1.0")
  echo "$v1" >/etc/version_instalacion
  v22=$(cat /etc/version_instalacion)
  vesaoSCT="\e[1;31m [ \e[1;32m( $v22 )\e[1;97m\e[1;31m ]"
  
  echo -e "\e[1;93m AUTOMATED INSTALLATION VERSION: $vesaoSCT"
  msgi -bar2
  
  # Detect OS
  os_system
  echo -e "\e[1;97m Detected System: \e[1;32m$distro $vercion"
  msgi -bar2
  
  # Get public IP with improved method
  echo -e "\e[1;97m Detecting public IP address..."
  TUIP=$(get_public_ip)
  
  if [[ "$TUIP" != "Unable to detect" ]]; then
    # Validate IP format
    if [[ "$TUIP" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
      mkdir -p /root/.ssh >/dev/null 2>&1
      echo "$TUIP" >/root/.ssh/authrized_key.reg
      echo -e "\e[1;92m ✓ Your public IP: \e[1;97m$TUIP"
    else
      echo -e "\e[1;93m ⚠ IP detection returned invalid format: $TUIP"
      echo -e "\e[1;93m   Continuing installation anyway..."
    fi
  else
    echo -e "\e[1;93m ⚠ Unable to detect public IP address"
    echo -e "\e[1;93m   Continuing installation anyway..."
  fi
  
  msgi -bar2
  
  echo -e "\e[1;93m Starting automated installation in 5 seconds..."
  echo -e "\e[1;93m Press Ctrl+C to cancel"
  msgi -bar2
  sleep 5
  
  # Execute installation steps
  update_repo "${vercion}"
  sleep 2
  
  install_dependencias
  sleep 2
  
  configure_system
  sleep 2
  
  auto_install_ADMRufu
  
  # Final message
  clear && clear
  msgi -bar2
  echo -e "\e[1;92m"
  echo -e "  ╔════════════════════════════════════════════════════╗"
  echo -e "  ║                                                    ║"
  echo -e "  ║        ✓ INSTALLATION COMPLETED SUCCESSFULLY!     ║"
  echo -e "  ║                                                    ║"
  echo -e "  ╚════════════════════════════════════════════════════╝"
  echo -e "\e[1;97m"
  msgi -bar2
  echo -e "\e[1;96m MAIN COMMANDS TO ACCESS THE PANEL:"
  echo -e "\e[1;97m"
  echo -e "    • Type: \e[1;41m menu \e[0m"
  echo -e "    • Type: \e[1;41m adm \e[0m"
  echo -e "    • Type: \e[1;41m ADMRufu \e[0m"
  echo -e "\e[1;97m"
  msgi -bar2
  echo -e "\e[1;93m System will apply changes. Please logout and login again"
  echo -e "\e[1;93m or run: \e[1;97msource ~/.bashrc"
  msgi -bar2
  
  # Clean up
  rm -rf ${colores}
}

# Run main function
main
exit 0
