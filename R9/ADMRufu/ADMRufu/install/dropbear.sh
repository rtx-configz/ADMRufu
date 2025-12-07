#!/bin/bash
# Updated for Ubuntu 24.04 and 25.04 - 13-11-2025

fun_dropbear(){
  clear
  [[ -e /etc/default/dropbear ]] && {
    msg -bar
    print_center -ama "REMOVING DROPBEAR"
    msg -bar
    systemctl stop dropbear &>/dev/null 2>&1
    systemctl disable dropbear &>/dev/null 2>&1
    fun_bar "apt-get remove dropbear -y"
    fun_bar "apt-get purge dropbear -y"
    fun_bar "apt-get autoremove -y"
    msg -bar
    print_center -verd "Dropbear Removed"
    msg -bar
    [[ -e /etc/default/dropbear ]] && rm /etc/default/dropbear &>/dev/null
    [[ -e /etc/dropbear ]] && rm -rf /etc/dropbear &>/dev/null
    [[ -d /etc/systemd/system/dropbear.service.d ]] && rm -rf /etc/systemd/system/dropbear.service.d &>/dev/null
    [[ -e /etc/systemd/system/dropbear.service ]] && rm /etc/systemd/system/dropbear.service &>/dev/null
    systemctl daemon-reload
    sleep 2
    return 1
  }
  msg -bar
  print_center -ama "DROPBEAR INSTALLER"
  msg -bar
  echo -e " $(msg -verm2 "Enter Your Ports:") $(msg -verd "80 90 109 110 143 443")"
  msg -bar
  msg -ne " Type Ports: " && read DPORT
  tput cuu1 && tput dl1
  TTOTAL=($DPORT)
  for((i=0; i<${#TTOTAL[@]}; i++)); do
    [[ $(mportas|grep "${TTOTAL[$i]}") = "" ]] && {
      echo -e "\033[1;33m Selected Port:\033[1;32m ${TTOTAL[$i]} OK"
      PORT="$PORT ${TTOTAL[$i]}"
    } || {
      echo -e "\033[1;33m Selected Port:\033[1;31m ${TTOTAL[$i]} FAIL"
    }
  done
  [[ -z $PORT ]] && {
    echo -e "\033[1;31m No Valid Port Was Selected\033[0m"
    return 1
  }

  [[ ! $(cat /etc/shells|grep "/bin/false") ]] && echo -e "/bin/false" >> /etc/shells
  msg -bar
  print_center -ama "Installing dropbear"
  msg -bar
  
  # Stop and mask service before installation
  systemctl stop dropbear &>/dev/null 2>&1
  systemctl mask dropbear &>/dev/null 2>&1
  
  fun_bar "DEBIAN_FRONTEND=noninteractive apt-get install -y dropbear"
  
  # Unmask after installation
  systemctl unmask dropbear &>/dev/null 2>&1
  
  msg -bar
  chk=$(cat /etc/ssh/sshd_config | grep Banner)
  if [ "$(echo "$chk" | grep -v "#Banner" | grep Banner)" != "" ]; then
    local=$(echo "$chk" |grep -v "#Banner" | grep Banner | awk '{print $2}')
  else
    local="/etc/bannerssh"
  fi
  touch $local
  print_center -ama "Configuring dropbear"

  # Ensure dropbear directory exists
  mkdir -p /etc/dropbear
  chmod 700 /etc/dropbear
  
  # Generate host keys
  [[ ! -f /etc/dropbear/dropbear_rsa_host_key ]] && dropbearkey -t rsa -s 2048 -f /etc/dropbear/dropbear_rsa_host_key &>/dev/null
  [[ ! -f /etc/dropbear/dropbear_ecdsa_host_key ]] && dropbearkey -t ecdsa -s 521 -f /etc/dropbear/dropbear_ecdsa_host_key &>/dev/null
  [[ ! -f /etc/dropbear/dropbear_ed25519_host_key ]] && dropbearkey -t ed25519 -f /etc/dropbear/dropbear_ed25519_host_key &>/dev/null

cat <<EOF > /etc/default/dropbear
NO_START=0
DROPBEAR_PORT=VAR1
DROPBEAR_EXTRA_ARGS="VAR"
DROPBEAR_BANNER="$local"
DROPBEAR_RECEIVE_WINDOW=65536
DROPBEAR_KEY_DIR=/etc/dropbear
EOF

  n=0
  for i in $(echo $PORT); do
  	p[$n]=$i
  	let n++
  done

  sed -i "s/VAR1/${p[0]}/g" /etc/default/dropbear

  if [[ ! -z ${p[1]} ]]; then
  	for (( i = 0; i < ${#p[@]}; i++ )); do
  		[[ "$i" = "0" ]] && continue
  		sed -i "s/VAR/-p ${p[$i]} VAR/g" /etc/default/dropbear
  	done
  fi
  sed -i "s/VAR//g" /etc/default/dropbear

  # Build port arguments for systemd service
  PORT_ARGS=""
  for port in ${p[@]}; do
    PORT_ARGS="${PORT_ARGS}-p ${port} "
  done
  PORT_ARGS=$(echo "$PORT_ARGS" | sed 's/ $//')

  # Create systemd service file
  cat > /etc/systemd/system/dropbear.service << EOFSERVICE
[Unit]
Description=Dropbear SSH server
After=network.target
Documentation=man:dropbear(8)

[Service]
Type=simple
ExecStart=/usr/sbin/dropbear ${PORT_ARGS} -F -E -w -g
Restart=on-failure
RestartSec=3s

[Install]
WantedBy=multi-user.target
EOFSERVICE

  systemctl daemon-reload
  systemctl enable dropbear &>/dev/null
  systemctl restart ssh > /dev/null 2>&1
  timeout 10 systemctl start dropbear > /dev/null 2>&1
  sleep 1
  msg -bar3
  print_center -verd "Dropbear configured successfully"
  msg -bar
  #UFW
  for ufww in $(mportas|awk '{print $2}'); do
    ufw allow $ufww > /dev/null 2>&1
  done
  sleep 2
  return 1
}

fun_dropbear