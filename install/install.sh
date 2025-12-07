#!/bin/bash
# AUTO INSTALL ADMRufu - UPDATED 12-12-2025 -- By @rtx-configz (Ubuntu 25 Compatible - English Version)
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
wget -q -O ${colores} "https://raw.githubusercontent.com/rtx-configz/ADMRufu/main/Otros/colores" &>/dev/null
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
  Ubuntu) vercion=$(lsb_release -rs 2>/dev/null || echo "$system" | awk '{print $2}' | cut -d '.' -f1,2) ;;
  esac
}

get_public_ip() {
  local ip=""
  ip=$(curl -s --max-time 5 ipinfo.io/ip 2>/dev/null)
  [[ -n "$ip" ]] && echo "$ip" && return 0
  ip=$(curl -s --max-time 5 ifconfig.me/ip 2>/dev/null)
  [[ -n "$ip" ]] && echo "$ip" && return 0
  ip=$(hostname -I 2>/dev/null | awk '{print $1}')
  [[ -n "$ip" ]] && echo "$ip" && return 0
  echo "127.0.0.1"
  return 1
}

# --- LOCK CHECKER ---
wait_for_lock() {
  while fuser /var/lib/dpkg/lock >/dev/null 2>&1 || fuser /var/lib/apt/lists/lock >/dev/null 2>&1 || fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
    echo -e "\e[1;93m ⚠ Waiting for apt/dpkg lock..."
    sleep 3
  done
}

# STEP 1: UPDATE REPOS
update_repo() {
  echo -e "\e[1;97m"
  msgi -bar2
  echo -e "\e[1;96m STEP 1: UPDATING SYSTEM REPOSITORIES"
  msgi -bar2
  wait_for_lock
  
  if [[ -f "/etc/apt/sources.list.d/ubuntu.sources" ]]; then
      echo -e "\e[1;93m Detected modern Ubuntu sources. Skipping legacy list update."
  else
      link="https://raw.githubusercontent.com/rtx-configz/ADMRufu/main/Source-List/$1.list"
      case $1 in
      8 | 9 | 10 | 11 | 16.04 | 18.04 | 20.04 | 20.10 | 21.04 | 21.10 | 22.04) 
        wget -q -O /etc/apt/sources.list ${link} &>/dev/null ;;
      *) echo -e "\e[1;93m Using default repository sources for $distro $1" ;;
      esac
  fi
  
  echo -e "\e[1;97m Running apt update..."
  apt update -y -o Dir::Etc::sourcelist="sources.list" -o Dir::Etc::sourceparts="sources.list.d" -o APT::Get::List-Cleanup="0" > /dev/null 2>&1
  echo -e "\e[1;92m ✓ System repositories updated successfully"
  
  echo -e "\e[1;97m Running apt upgrade..."
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
  wait_for_lock
  rm -rf /root/paknoinstall.log >/dev/null 2>&1
  dpkg --configure -a >/dev/null 2>&1
  apt -f install -y >/dev/null 2>&1
  
  # Added: at, whois, cmake, build-essential
  soft="sudo bsdmainutils zip screen unzip ufw curl python3 dropbear python3-pip openssl cron iptables lsof pv at gawk bc jq socat netcat-openbsd net-tools apache2 cmake build-essential figlet lolcat whois"

  echo -e "\e[1;97m Installing required packages..."
  for i in $soft; do
    echo -e "\e[1;97m   → Installing package: \e[36m$i\e[97m"
    apt-get install $i -y >/dev/null 2>&1
  done
  
  echo -e "\e[1;92m ✓ All dependencies installed"
  msgi -bar2
}

# STEP 3: CONFIGURE SYSTEM
configure_system() {
  
  
  echo -e "\e[1;96m STEP 3: CONFIGURING SYSTEM"
  
  
  systemctl stop dropbear &>/dev/null 2>&1
  sed -i "s;Listen 80;Listen 81;g" /etc/apache2/ports.conf >/dev/null 2>&1
  if [[ -d "/etc/apache2/sites-enabled" ]]; then
     sed -i "s;*:80;*:81;g" /etc/apache2/sites-enabled/*.conf >/dev/null 2>&1
  fi
  systemctl restart apache2 >/dev/null 2>&1
  
  wait_for_lock
  apt autoremove -y &>/dev/null
  echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
  echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections
  
  # Ensure valid shells for Dropbear
  if ! grep -q "/bin/false" /etc/shells; then echo "/bin/false" >> /etc/shells; fi
  if ! grep -q "/usr/sbin/nologin" /etc/shells; then echo "/usr/sbin/nologin" >> /etc/shells; fi
  
  # Passwd lib
  apt-get install libpam-cracklib -y >/dev/null 2>&1
  echo -e '# Simple Pass Module
password [success=1 default=ignore] pam_unix.so obscure sha512
password requisite pam_deny.so
password required pam_permit.so' >/etc/pam.d/common-password
  chmod +x /etc/pam.d/common-password
  
  msgi -bar2
}

# STEP 4: CONFIGURE DROPBEAR
configure_dropbear() {
  echo -e "\e[1;97m"
  msgi -bar2
  echo -e "\e[1;96m STEP 4: CONFIGURING DROPBEAR (PORT 444)"
  msgi -bar2
  systemctl stop dropbear &>/dev/null 2>&1
  mkdir -p /etc/dropbear
  chmod 700 /etc/dropbear
  [[ ! -f /etc/dropbear/dropbear_rsa_host_key ]] && dropbearkey -t rsa -s 2048 -f /etc/dropbear/dropbear_rsa_host_key &>/dev/null
  [[ ! -f /etc/dropbear/dropbear_ecdsa_host_key ]] && dropbearkey -t ecdsa -s 521 -f /etc/dropbear/dropbear_ecdsa_host_key &>/dev/null
  [[ ! -f /etc/dropbear/dropbear_ed25519_host_key ]] && dropbearkey -t ed25519 -f /etc/dropbear/dropbear_ed25519_host_key &>/dev/null
  
  touch /etc/bannerssh
  cat <<EOF > /etc/default/dropbear
NO_START=0
DROPBEAR_PORT=444
DROPBEAR_EXTRA_ARGS="-p 444 -w -g"
DROPBEAR_BANNER="/etc/bannerssh"
DROPBEAR_RECEIVE_WINDOW=65536
DROPBEAR_KEY_DIR=/etc/dropbear
EOF
  systemctl unmask dropbear &>/dev/null 2>&1
  systemctl enable dropbear &>/dev/null
  systemctl restart dropbear > /dev/null 2>&1
  ufw allow 444/tcp > /dev/null 2>&1
  
  sleep 2
  if [[ $(lsof -i :444 | grep -i dropbear) ]] || systemctl is-active --quiet dropbear; then
     echo -e "\e[1;92m ✓ Dropbear active on port 444"
  else
     echo -e "\e[1;93m ⚠ Dropbear starting (Force Mode)..."
     /usr/sbin/dropbear -p 444 -F -E -w -g &
  fi
  msgi -bar2
}

# STEP 5: AUTO INSTALL ADMRufu
auto_install_ADMRufu() {
  echo -e "\e[1;97m"
  msgi -bar2
  echo -e "\e[1;96m STEP 5: INSTALLING ADMRufu"
  msgi -bar2
  
  slogan="ADMRufu Auto Install by @rtx-configz"
  mkdir /etc/ADMRufu >/dev/null 2>&1
  cd /etc
  
  wget -q https://raw.githubusercontent.com/rtx-configz/ADMRufu/main/R9/ADMRufu.tar.xz >/dev/null 2>&1
  
  if [ $? -eq 0 ]; then
    echo -e "\e[1;92m ✓ Download completed"
    tar -xf ADMRufu.tar.xz >/dev/null 2>&1
    chmod +x ADMRufu.tar.xz >/dev/null 2>&1
    rm -rf ADMRufu.tar.xz
    cd
    chmod -R 755 /etc/ADMRufu
    
    ADMRufu="/etc/ADMRufu" && [[ ! -d ${ADMRufu} ]] && mkdir ${ADMRufu}
    ADM_inst="${ADMRufu}/install" && [[ ! -d ${ADM_inst} ]] && mkdir ${ADM_inst}
    
    rm -rf /usr/bin/menu /usr/bin/adm /usr/bin/ADMRufu
    mkdir -p /etc/ADMRufu/tmp >/dev/null 2>&1
    echo "$slogan" >/etc/ADMRufu/tmp/message.txt
    
    echo "${ADMRufu}/menu" >/usr/bin/menu && chmod +x /usr/bin/menu
    echo "${ADMRufu}/menu" >/usr/bin/adm && chmod +x /usr/bin/adm
    echo "${ADMRufu}/menu" >/usr/bin/ADMRufu && chmod +x /usr/bin/ADMRufu
    
    update-locale LANG=en_US.UTF-8 LANGUAGE=en >/dev/null 2>&1
    
    # --- PATCH USER CREATION (Fix Incorrect Password) ---
    if [[ -f "/etc/ADMRufu/userSSH" ]]; then
       sed -i 's/pass=$(openssl passwd -1 $2)/pass=$(openssl passwd -6 $2)/g' /etc/ADMRufu/userSSH
       sed -i 's/if \[\[ ${vercion} = "16" \]\]; then//g' /etc/ADMRufu/userSSH
    fi

    # --- BASHRC FIX (Use 'cat' not 'less') ---
    /bin/cp /etc/skel/.bashrc /root/.bashrc
    cat <<'EOF' >> /root/.bashrc

if [[ $(echo $PATH|grep "/usr/games") = "" ]]; then PATH=$PATH:/usr/games; fi
[[ $UID = 0 ]] && screen -dmS up /etc/ADMRufu/chekup.sh
v=$(cat /etc/ADMRufu/vercion 2>/dev/null || echo "R9")
[[ -e "/etc/ADMRufu/tmp/message.txt" ]] && mess1="$(cat /etc/ADMRufu/tmp/message.txt)"
[[ -z "$mess1" ]] && mess1="@rtx-configz"
if [ -t 0 ]; then
    clear
    echo -e "\n$(figlet -f big.flf "  ADMRufu" 2>/dev/null || echo "  ADMRufu")\n        RESELLER : $mess1 \n\n   To start ADMRufu type:  menu \n\n   Script Version: $v\n" | lolcat 2>/dev/null || cat
fi
EOF
    echo -e "\e[1;92m ✓ ADMRufu installed successfully!"
  else
    echo -e "\e[1;91m ✗ Download failed"
    exit 1
  fi
  msgi -bar2
}

# STEP 6: CONFIGURE BADVPN
configure_badvpn() {
  echo -e "\e[1;97m"
  msgi -bar2
  echo -e "\e[1;96m STEP 6: CONFIGURING BADVPN (UDP 7300)"
  msgi -bar2
  if [[ -f /usr/bin/badvpn-udpgw ]]; then
     echo -e "\e[1;92m ✓ BadVPN already installed"
  else
     echo -e "\e[1;97m Downloading/Compiling BadVPN..."
     cd /etc
     wget -q https://github.com/rudi9999/ADMRufu/raw/main/Utils/badvpn/badvpn-master.zip
     if [[ -f badvpn-master.zip ]]; then
         unzip -q badvpn-master.zip
         cd badvpn-master
         mkdir build
         cd build
         cmake .. -DCMAKE_INSTALL_PREFIX="/" -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1 >/dev/null 2>&1
         make install >/dev/null 2>&1
         cd /etc
         rm -rf badvpn-master.zip badvpn-master
         echo -e "\e[1;92m ✓ BadVPN Compiled"
     else
         echo -e "\e[1;91m ✗ BadVPN Download failed"
     fi
  fi
  cat > /etc/systemd/system/badvpn.service <<EOF
[Unit]
Description=BadVPN UDPGW Service
After=network.target
[Service]
Type=simple
User=root
ExecStart=/usr/bin/badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 1000 --max-connections-for-client 10
Restart=always
RestartSec=3s
[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload &>/dev/null
  systemctl enable badvpn &>/dev/null
  systemctl restart badvpn &>/dev/null
  sleep 1
  if systemctl is-active --quiet badvpn; then
      echo -e "\e[1;92m ✓ BadVPN Running on Port 7300"
  else
      echo -e "\e[1;91m ⚠ BadVPN Failed to Start"
  fi
  msgi -bar2
}

# STEP 7: CONFIGURE PYTHON SOCKET
configure_python_socket() {
  echo -e "\e[1;97m"
  msgi -bar2
  echo -e "\e[1;96m STEP 7: CONFIGURING PYTHON SOCKET (Port 80 -> 444)"
  msgi -bar2
  fuser -k 80/tcp >/dev/null 2>&1
  systemctl stop apache2 >/dev/null 2>&1
  script_path="/etc/ADMRufu/install/PDirect.py"
  if [[ ! -f "$script_path" ]]; then
      echo -e "\e[1;93m ⚠ PDirect.py missing. Downloading fallback..."
      mkdir -p /etc/ADMRufu/install
      wget -q -O "$script_path" "https://raw.githubusercontent.com/rtx-configz/ADMRufu/main/install/PDirect.py"
  fi
  if [[ -f "$script_path" ]]; then
      cat > /etc/systemd/system/python.80.service <<EOF
[Unit]
Description=Python Direct Proxy (Port: 80)
After=network.target
[Service]
Type=simple
User=root
ExecStart=/usr/bin/python3 ${script_path} -p 80 -l 444 -r 101 -t "RTX"
Restart=always
RestartSec=3s
[Install]
WantedBy=multi-user.target
EOF
      systemctl daemon-reload &>/dev/null
      systemctl enable python.80.service &>/dev/null
      systemctl start python.80.service &>/dev/null
      ufw allow 80/tcp >/dev/null 2>&1
      sleep 2
      if [[ $(lsof -i :80 | grep python) ]] || systemctl is-active --quiet python.80.service; then
          echo -e "\e[1;92m ✓ Python Socket running on Port 80"
          echo -e "\e[1;92m   → Forward: 444 | Resp: 101 | Banner: RTX"
      else
          echo -e "\e[1;91m ⚠ Python Socket failed to start."
      fi
  else
      echo -e "\e[1;91m ✗ PDirect.py could not be found."
  fi
  msgi -bar2
}

# MAIN EXECUTION
main() {
  clear && clear
  msgi -bar2
  echo -e " \e[5m\e[1;100m   =====>> ►►  AUTO INSTALL ADMRufu  ◄◄ <<=====   \e[1;37m"
  msgi -bar2
  
  # Version Check
  v1=$(curl -sSL "https://raw.githubusercontent.com/rtx-configz/ADMRufu/main/Vercion" 2>/dev/null || echo "1.0")
  echo "$v1" >/etc/version_instalacion
  
  os_system
  echo -e "\e[1;97m Detected System: \e[1;32m$distro $vercion"
  msgi -bar2
  
  echo -e "\e[1;97m Detecting public IP address..."
  TUIP=$(get_public_ip)
  echo -e "\e[1;92m ✓ Your public IP: \e[1;97m$TUIP"
  msgi -bar2
  
  echo -e "\e[1;93m Starting automated installation in 5 seconds..."
  sleep 5
  
  update_repo "${vercion}"
  sleep 1
  install_dependencias
  sleep 1
  configure_system
  sleep 1
  configure_dropbear
  sleep 1
  configure_badvpn
  sleep 1
  auto_install_ADMRufu
  sleep 1
  configure_python_socket
  
  clear && clear
  msgi -bar2
  echo -e "\e[1;92m"
  echo -e "  ╔════════════════════════════════════════════════════╗"
  echo -e "  ║                                                    ║"
  echo -e "  ║        ✓ INSTALLATION COMPLETED SUCCESSFULLY!      ║"
  echo -e "  ║                                                    ║"
  echo -e "  ╚════════════════════════════════════════════════════╝"
  echo -e "\e[1;97m"
  msgi -bar2
  echo -e "\e[1;96m MAIN COMMANDS:"
  echo -e "    • Type: \e[1;41m menu \e[0m"
  echo -e "    • Port: \e[1;41m 444 \e[0m (Dropbear)"
  echo -e "    • Proxy:\e[1;41m 80  \e[0m (Python -> 444 | 101 | RTX)"
  echo -e "    • UDPGW:\e[1;41m 7300 \e[0m (BadVPN)"
  echo -e "\e[1;97m"
  msgi -bar2
  echo -e "\e[1;93m System will apply changes. Please logout and login again"
  msgi -bar2
  
  rm -rf ${colores}
}

main
exit 0