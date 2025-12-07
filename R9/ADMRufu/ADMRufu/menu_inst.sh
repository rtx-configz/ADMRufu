#!/bin/bash
# Updated for Ubuntu 25.04 & 25.10 - English Version - 11-11-2025

cache_ram() {
  clear
  msg -bar
  msg -ama  "          REFRESHING CACHE AND RAM"
  msg -bar
  (
    VE="\033[1;33m" && MA="\033[1;31m" && DE="\033[1;32m"

    while [[ ! -e /tmp/abc ]]; do
      A+="#"
      echo -e "${VE}[${MA}${A}${VE}]" >&2
      sleep 0.3s
      tput cuu1 && tput dl1
    done

    echo -e "${VE}[${MA}${A}${VE}] - ${DE}[100%]" >&2
    rm /tmp/abc
    ) &

  echo 3 > /proc/sys/vm/drop_caches &>/dev/null
  sleep 1s
  sysctl -w vm.drop_caches=3 &>/dev/null
  apt-get autoclean -y &>/dev/null
  sleep 1s
  apt-get clean -y &>/dev/null
  rm /tmp/* &>/dev/null
  touch /tmp/abc
  sleep 0.5s
  msg -bar
  msg -verd "       Cache/Ram cleaned successfully!"
  msg -bar

  if [[ ! -z $(crontab -l|grep -w "vm.drop_caches=3") ]]; then
    msg -azu " Scheduled task every $(msg -verd "[ $(crontab -l|grep -w "vm.drop_caches=3"|awk '{print $2}'|sed $'s/[^[:alnum:]\t]//g')HS ]")"
    msg -bar
    while :
    do
    echo -ne "$(msg -azu " Remove scheduled task [Y/N]: ")" && read t_ram
    tput cuu1 && tput dl1
    case $t_ram in
      s|S|y|Y) crontab -l > /root/cron && sed -i '/vm.drop_caches=3/ d' /root/cron && crontab /root/cron && rm /root/cron
           msg -azu " Automatic task removed!" && msg -bar && sleep 2
           return 1;;
      n|N)return 1;;
      *)msg -azu " Select Y for yes, N for no" && sleep 2 && tput cuu1 && tput dl1;;
    esac
    done
  fi 

  echo -ne "$(msg -azu "Do you want to schedule an automatic task [y/n]:") "
  read c_ram
  if [[ $c_ram = @(s|S|y|Y) ]]; then
    tput cuu1 && tput dl1
    echo -ne "$(msg -azu " TASK EXECUTION PERIOD [1-12HS]:") "
    read ram_c
    if [[ $ram_c =~ $numero ]]; then
      crontab -l > /root/cron
      echo "0 */$ram_c * * * sudo sysctl -w vm.drop_caches=3 > /dev/null 2>&1" >> /root/cron
      crontab /root/cron
      rm /root/cron
      tput cuu1 && tput dl1
      msg -azu " Automatic task scheduled every: $(msg -verd "${ram_c}HS")" && msg -bar && sleep 2
    else
      tput cuu1 && tput dl1
      msg -verm2 " Enter only numbers between 1 and 12"
      sleep 2
      msg -bar
    fi
  fi
  return 1
}

new_banner(){
  clear
  local="/etc/bannerssh"
  chk=$(cat /etc/ssh/sshd_config | grep Banner)
  if [ "$(echo "$chk" | grep -v "#Banner" | grep Banner)" != "" ]; then
    local=$(echo "$chk" |grep -v "#Banner" | grep Banner | awk '{print $2}')
  else
    echo "" >> /etc/ssh/sshd_config
    echo "Banner /etc/bannerssh" >> /etc/ssh/sshd_config
    local="/etc/bannerssh"
  fi
  title -ama "SSH/DROPBEAR BANNER INSTALLER"
  in_opcion_down "Write your preferred BANNER in HTML"
  msg -bar
  if [[ "${opcion}" ]]; then
    rm -rf $local  > /dev/null 2>&1
    echo "$opcion" > $local
    [[ ! -e ${ADM_tmp}/message.txt ]] && echo "@Rufu99" > ${ADM_tmp}/message.txt
    credi="$(less ${ADM_tmp}/message.txt)"
    echo '<h4 style=text-align:center><font color="#00FF40">A</font><font color="#00FFBF">D</font><font color="#00FFFF">M</font><font color="#00FFFF">R</font><font color="#2ECCFA">u</font><font color="#2E9AFE">f</font><font color="#819FF7">u</font><br><font color="#819FEB">'$credi'</font></h4>' >> $local
    systemctl restart ssh 2>/dev/null
    systemctl restart dropbear 2>/dev/null
    print_center -verd "Banner Added!!!"
    enter
    return 1
  fi
  print_center -ama "Banner Edit Cancelled!"
  enter
  return 1
}

banner_edit(){
  clear
  chk=$(cat /etc/ssh/sshd_config | grep Banner)
  local=$(echo "$chk" |grep -v "#Banner" | grep Banner | awk '{print $2}')
  nano $local
  systemctl restart ssh 2>/dev/null
  systemctl restart dropbear 2>/dev/null
  msg -bar
  print_center -ama "Banner Edit Completed!"
  enter
  return 1
}

banner_reset(){
  clear
  chk=$(cat /etc/ssh/sshd_config | grep Banner)
  local=$(echo "$chk" |grep -v "#Banner" | grep Banner | awk '{print $2}')
  rm -rf $local
  touch $local
  systemctl restart ssh 2>/dev/null
  systemctl restart dropbear 2>/dev/null
  msg -bar
  print_center -ama "SSH BANNER WAS CLEARED"
  enter
  return 1
}

baner_fun(){
  chk=$(cat /etc/ssh/sshd_config | grep Banner)
  local=$(echo "$chk" |grep -v "#Banner" | grep Banner | awk '{print $2}')
  n=1
  title -ama "SSH BANNER EDIT MENU"
  echo -e " $(msg -verd "[1]") $(msg -verm2 ">") $(msg -azu "NEW SSH BANNER")"
  if [[ -e "${local}" ]]; then
    echo -e " $(msg -verd "[2]") $(msg -verm2 ">") $(msg -azu "EDIT BANNER WITH NANO")"
    echo -e " $(msg -verd "[3]") $(msg -verm2 ">") $(msg -azu "RESET SSH BANNER")"
    n=3
  fi
  back
  opcion=$(selection_fun $n)
  case $opcion in
    1)new_banner;;
    2)banner_edit;;
    3)banner_reset;;
    0)return 1;;
  esac
}

fun_autorun () {
  clear
  msg -bar
if [[ $(cat /etc/bash.bashrc | grep -w ${ADMRufu}/menu) ]]; then
  cat /etc/bash.bashrc | grep -v ${ADMRufu}/menu > /tmp/bash
  mv -f /tmp/bash /etc/bash.bashrc
  msg -ama "               AUTO-START REMOVED"
  msg -bar
else
  cp /etc/bash.bashrc /tmp/bash
  echo "${ADMRufu}/menu" >> /tmp/bash
  mv -f /tmp/bash /etc/bash.bashrc
  msg -verd "              AUTO-START ADDED"
  msg -bar
fi
return 1
}

# Configuration menu settings
#==================================================

C_MENU2(){
  unset m_conf
  m_conf="$(cat ${ADM_tmp}/style|grep -w "$1"|awk '{print $2}')"

  case $m_conf in
    0)sed -i "s;$1 0;$1 1;g" ${ADM_tmp}/style;;
    1)sed -i "s;$1 1;$1 0;g" ${ADM_tmp}/style;;
  esac
}

c_stat(){
  unset m_stat
  m_stat="$(cat ${ADM_tmp}/style|grep -w "$1"|awk '{print $2}')"
  case $m_stat in
    0)msg -verm2 "[OFF]";;
    1)msg -verd "[ON]";;
  esac
}

c_resel(){
  clear
  msg -bar
  msg -ama "               CHANGE RESELLER"
  msg -bar
  echo -ne "$(msg -azu " CHANGE RESELLER [Y/N]:") "
  read txt_r
  if [[ $txt_r = @(s|S|y|Y) ]]; then
    tput cuu1 && tput dl1
    echo -ne "$(msg -azu " WRITE YOUR RESELLER:") "
    read r_txt
    echo -e "$r_txt" > ${ADM_tmp}/message.txt
  fi
  C_MENU2 resel
}

conf_menu(){
  while :
  do
    clear
    msg -bar
    msg -ama "        MAIN MENU CONFIGURATION"
    msg -bar
    echo -ne "$(msg -verd "  [1]") $(msg -verm2 ">") " && msg -azu "SYSTEM INFO (SYS/MEM/CPU) $(c_stat infsys)"
    echo -ne "$(msg -verd "  [2]") $(msg -verm2 ">") " && msg -azu "ACTIVE PORTS               $(c_stat port)"
    echo -ne "$(msg -verd "  [3]") $(msg -verm2 ">") " && msg -azu "RESELLER                  $(c_stat resel)"
    echo -ne "$(msg -verd "  [4]") $(msg -verm2 ">") " && msg -azu "COUNTER (Only/Exp/Total)  $(c_stat contador)"
    msg -bar
    echo -ne "$(msg -verd "  [0]") $(msg -verm2 ">") " && msg -bra "   \033[1;41m RETURN \033[0m"
    msg -bar
    echo -ne "$(msg -azu " option: ")"
    read C_MENU

    case $C_MENU in
      1)C_MENU2 infsys;;
      2)C_MENU2 port;;
      3)c_resel;;
      4)C_MENU2 contador;;
      0)break;;
      esac
  done
  return 0
}
#================================================

root_acces () {
	sed -i '/PermitRootLogin/d' /etc/ssh/sshd_config
	echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config

	sed -i '/PasswordAuthentication/d' /etc/ssh/sshd_config
	echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config

	systemctl restart ssh
}

root_pass () {
  clear
  msg -bar
  [[ -z $1 ]] && msg -ama "             CHANGE ROOT PASSWORD" || msg -ama "               ACTIVATE ROOT ACCESS"
  msg -bar
  msg -azu "    This will change the root access password"
  msg -bar3
  msg -azu "    This password can be used to\n    access the vps as root user."
  msg -bar
  echo -ne " $(msg -azu "Change root password? [Y/N]:") "; read x
  tput cuu1 && tput dl1
  [[ $x = @(n|N) ]] && msg -bar && return
  if [[ ! -z $1 ]]; then
    msg -azu "    Activating root access..."
    root_acces
    sleep 3
    tput cuu1 && tput dl1
    msg -azu "    Root access activated..."
    msg -bar
  fi
  echo -ne "\033[1;37m New password: \033[0;31m"
  read pass
  tput cuu1 && tput dl1
  (echo $pass; echo $pass)|passwd root 2>/dev/null
  sleep 1s
  msg -azu "    Root password updated!"
  msg -azu "    Current password:\033[0;31m $pass"
  msg -bar
  enter
  return 1
}

pid_inst(){
  v_node="$(which nodejs)" && [[ $(ls -l ${node_v}|grep -w 'node') ]] && v_node="nodejs" || v_node="node"
  proto="dropbear python stunnel4 v2ray $v_node badvpn squid openvpn dns-serve"
  portas=$(lsof -V -i -P -n | grep -v "ESTABLISHED" |grep -v "COMMAND")
  for list in $proto; do
    case $list in
      dropbear|stunnel4|v2ray|badvpn|squid|openvpn|"$v_node") 
        portas2=$(echo "$portas"|grep -w "LISTEN"|grep -w "$list") && [[ $(echo "${portas2}"|grep "$list") ]] && inst[$list]="\033[1;32m[ON] " || inst[$list]="\033[1;31m[OFF]";;
      python)
        # Check for any active python.*.service OR python processes on ports
        if systemctl list-units --type=service --state=active 'python.*.service' 2>/dev/null | grep -q 'python\.'; then
          inst[$list]="\033[1;32m[ON] "
        elif echo "$portas" | grep -w "LISTEN" | grep -qw "python"; then
          inst[$list]="\033[1;32m[ON] "
        else
          inst[$list]="\033[1;31m[OFF]"
        fi;;
      dns-serve) 
        portas2=$(echo "$portas"|grep -w "$list") && [[ $(echo "${portas2}"|grep "$list") ]] && inst[$list]="\033[1;32m[ON] " || inst[$list]="\033[1;31m[OFF]";;
    esac
  done
}

menu_inst () {
clear
declare -A inst
pid_inst

if [[ $(cat /etc/bash.bashrc | grep -w ${ADMRufu}/menu) ]]; then
  AutoRun="\033[1;32m[ON]"
else
  AutoRun="\033[1;31m[OFF]"
fi

v=$(cat $ADMRufu/vercion)

msg -bar
echo -e "\033[1;93m      SYSTEM INFORMATION AND ACTIVE PORTS"
msg -bar
info_sys
msg -bar
mine_port
echo -e "\e[0m\e[31m================ \e[1;33mPROTOCOL MENU\e[0m\e[31m =================\e[0m"
echo -ne "$(msg -verd "  [1]")$(msg -verm2 ">") $(msg -azu "DROPBEAR      ${inst[dropbear]}")" && echo -e "$(msg -verd "  [7]")$(msg -verm2 ">") $(msg -azu "SQUID         ${inst[squid]}")"
echo -ne "$(msg -verd "  [2]")$(msg -verm2 ">") $(msg -azu "SOCKS PYTHON  ${inst[python]}")" && echo -e "$(msg -verd "  [8]")$(msg -verm2 ">") $(msg -azu "OPENVPN       ${inst[openvpn]}")"
echo -ne "$(msg -verd "  [3]")$(msg -verm2 ">") $(msg -azu "SSL           ${inst[stunnel4]}")" && echo -e "$(msg -verd "  [9]")$(msg -verm2 ">") $(msg -azu "SlowDNS       ${inst[dns-serve]}")"
echo -e "$(msg -verd "  [4]")$(msg -verm2 ">") $(msg -azu "V2RAY         ${inst[v2ray]}")"
echo -e "$(msg -verd "  [5]")$(msg -verm2 ">") $(msg -azu "OVER WEBSOCKET${inst[$v_node]}")"
echo -e "$(msg -verd "  [6]")$(msg -verm2 ">") $(msg -azu "BADVPN-UDP    ${inst[badvpn]}")"
echo -e "\e[31m============== \e[1;33mQUICK CONFIGURATIONS\e[0m\e[31m ==============\e[0m"
echo -ne "$(msg -verd " [12]")$(msg -verm2 ">") $(msg -azu "SSH BANNER")" && echo -e "$(msg -verd "          [17]")$(msg -verm2 ">") $(msg -azu "TCP (BBR/PLUS)")"
echo -ne "$(msg -verd " [13]")$(msg -verm2 ">") $(msg -azu "REFRESH CACHE/RAM") $(crontab -l|grep -w "vm.drop_caches=3" > /dev/null && echo -e "\033[1;32m◉ " || echo -e "\033[1;31m○ ")" && echo -e "$(msg -verd "[18]")$(msg -verm2 ">") $(msg -azu "CHANGE ROOT PASSWORD")"
echo -ne "$(msg -verd " [14]")$(msg -verm2 ">") $(msg -azu "SWAP MEMORY")  $([[ $(cat /proc/swaps | wc -l) -le 1 ]] && echo -e "\033[1;31m○ " || echo -e "\033[1;32m◉ ")" && echo -e "$(msg -verd "    [19]")$(msg -verm2 ">") $(msg -azu "ACTIVATE ROOT ACCESS")"
echo -ne "$(msg -verd " [15]")$(msg -verm2 ">") $(msg -azu "ADMIN ACTIVE PORTS")" && echo -e "$(msg -verd " [20]")$(msg -verm2 ">") $(msg -azu "CONFIG MAIN MENU")"
echo -e "$(msg -verd " [16]")$(msg -verm2 ">") $(msg -azu "GEN DOMAIN/CERT-SSL") $([[ -z $(ls "${ADM_crt}") ]] && echo -e "\033[1;31m○ " || echo -e "\033[1;32m◉ ")"
msg -bar
echo -e "$(msg -verd " [21]") $(msg -verm2 ">") $(msg -azu "TOOLS AND EXTRAS")"
msg -bar
echo -ne "$(msg -verd "  [0]") $(msg -verm2 ">") " && msg -bra "   \033[1;41m RETURN \033[0m $(msg -verd "       [22]") $(msg -verm2 ">") $(msg -azu AUTO-START) ${AutoRun}" 
msg -bar
selection=$(selection_fun 22)
case $selection in
  0)return 0;;
  1)${ADM_inst}/dropbear.sh;;
  2)${ADM_inst}/sockspy.sh;;
  3)${ADM_inst}/ssl.sh;;
  4)${ADM_inst}/v2ray.sh;;
  5)${ADM_inst}/ws-cdn.sh;;
  6)${ADM_inst}/budp.sh;;
  7)${ADM_inst}/squid.sh;;
  8)${ADM_inst}/openvpn.sh;;
  9)${ADM_inst}/slowdns.sh;;
  12)baner_fun;;
  13)cache_ram;;
  14)${ADM_inst}/swapfile.sh;;
  15)${ADM_inst}/ports.sh;;
  16)${ADM_inst}/cert.sh;;
  17)${ADM_inst}/tcp.sh;;
  18)root_pass;;
  19)root_pass 1;;
  20)conf_menu;;
  21)${ADMRufu}/tool_extras.sh;;
  22)fun_autorun;;
esac
}

while [[ ${back} != @(0) ]]; do
  menu_inst
  back="$?"
  [[ ${back} != @(0|[1]) ]] && msg -azu " Press Enter to continue..." && read foo
done