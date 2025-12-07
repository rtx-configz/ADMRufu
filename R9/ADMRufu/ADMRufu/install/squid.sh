#!/bin/bash
lshost(){
  n=1
    for i in `cat $payload|awk -F "/" '{print $1,$2,$3,$4}'`; do
      echo -e " $(msg -verd "$n)") $(msg -verm2 ">") $(msg -teal "$i")"
      pay[$n]=$i
      let n++
    done
}

lsexpre(){
    n=1
    while read line; do
        echo -e " $(msg -verd "$n)") $(msg -verm2 ">") $(msg -teal "$line")"
        pay[$n]=$line
        let n++
    done <<< $(cat $payload2)
}

fun_squid(){
  if [[ -e /etc/squid/squid.conf ]]; then
    var_squid="/etc/squid/squid.conf"
    mipatch="/etc/squid"
  elif [[ -e /etc/squid3/squid.conf ]]; then
    var_squid="/etc/squid3/squid.conf"
    mipatch="/etc/squid3"
  fi

  [[ -e $var_squid ]] && {
    clear
    msg -bar
    print_center -ama "REMOVING SQUID"
    print_center -ama "Please wait a moment!!!"
    msg -bar

    [[ -d "/etc/squid" ]] && {
      service squid stop > /dev/null 2>&1
      apt-get remove squid -y >/dev/null 2>&1
      apt-get purge squid -y >/dev/null 2>&1
      rm -rf /etc/squid >/dev/null 2>&1
    }

    [[ -d "/etc/squid3" ]] && {
      service squid3 stop > /dev/null 2>&1
      apt-get remove squid3 -y >/dev/null 2>&1
      apt-get purge squid3 -y >/dev/null 2>&1
      rm -rf /etc/squid3 >/dev/null 2>&1
    }
    clear
    msg -bar
    print_center -verd "Squid removed"
    [[ -e $var_squid ]] && rm -rf $var_squid
    [[ -e /etc/dominio-denie ]] && rm -rf /etc/dominio-denie
    enter
    return 1
  }

  clear
  msg -bar
  print_center -ama "SQUID INSTALLER ADMRufu"
  msg -bar
  print_center -ama " Select ports in sequential order"
  print_center -ama "      Example: \e[32m80 8080 8799 3128"
  msg -bar
  while [[ -z $PORT ]]; do
        msg -ne " Enter the Ports: "; read PORT
        tput cuu1 && tput dl1

        [[ $(mportas|grep -w "${PORT}") = "" ]] && {
            echo -e "\033[1;33m Squid Port:\033[1;32m ${PORT} OK"
        } || {
            echo -e "\033[1;33m Squid Port:\033[1;31m ${PORT} FAIL" && sleep 2
            tput cuu1 && tput dl1
            unset PORT
        }
  done

  msg -bar
  print_center -ama " INSTALLING SQUID"
  msg -bar
  fun_bar "apt-get install squid3 -y"
  msg -bar
  print_center -ama " STARTING CONFIGURATION"
 
cat <<-EOF > /etc/dominio-denie
.example.com/  
EOF

cat <<-EOF > /etc/exprecion-denie
torrent  
EOF

  unset var_squid
  if [[ -d /etc/squid ]]; then
    var_squid="/etc/squid/squid.conf"
  elif [[ -d /etc/squid3 ]]; then
    var_squid="/etc/squid3/squid.conf"
  fi

  ip=$(fun_ip)

cat <<-EOF > $var_squid
#Squid Configuration
acl localhost src 127.0.0.1/32 ::1
acl to_localhost dst 127.0.0.0/8 0.0.0.0/32 ::1
acl SSL_ports port 443
acl Safe_ports port 80
acl Safe_ports port 21
acl Safe_ports port 443
acl Safe_ports port 70
acl Safe_ports port 210
acl Safe_ports port 1025-65535
acl Safe_ports port 280
acl Safe_ports port 488
acl Safe_ports port 591
acl Safe_ports port 777
acl CONNECT method CONNECT
acl SSH dst $ip-$ip/255.255.255.255
acl exprecion-denie url_regex '/etc/exprecion-denie'
acl dominio-denie dstdomain '/etc/dominio-denie'
http_access deny exprecion-denie
http_access deny dominio-denie
http_access allow SSH
http_access allow manager localhost
http_access deny manager
http_access allow localhost

#ports
EOF

for pts in $(echo -e $PORT); do
  echo -e "http_port $pts" >> $var_squid
  [[ -f "/usr/sbin/ufw" ]] && ufw allow $pts/tcp &>/dev/null 2>&1
done

cat <<-EOF >> $var_squid
http_access allow all
coredump_dir /var/spool/squid
refresh_pattern ^ftp: 1440 20% 10080
refresh_pattern ^gopher: 1440 0% 1440
refresh_pattern -i (/cgi-bin/|\?) 0 0% 0
refresh_pattern . 0 20% 4320

#Squid Name
visible_hostname ADMRufu
EOF

print_center -ama "RESTARTING SERVICES"

[[ -d "/etc/squid/" ]] && {
  service ssh restart > /dev/null 2>&1
  /etc/init.d/squid start > /dev/null 2>&1
  service squid restart > /dev/null 2>&1
}

[[ -d "/etc/squid3/" ]] && {
  service ssh restart > /dev/null 2>&1
  /etc/init.d/squid3 start > /dev/null 2>&1
  service squid3 restart > /dev/null 2>&1
}

sleep 2s
tput cuu1 && tput dl1
print_center -verd "SQUID CONFIGURED"
enter
}

add_host(){
  clear
  msg -bar
  print_center -ama "Current Hosts Within Squid"
  msg -bar
  lshost
  back

  while [[ $hos != \.* ]]; do
      msg -nazu " Enter a new host: " && read hos
      [[ $hos = 0 ]] && return 1
      tput cuu1 && tput dl1
      [[ $hos = \.* ]] && continue
      print_center -ama "The host must start with .example.com"
      sleep 3s
      tput cuu1 && tput dl1
  done

  host="$hos/"
  [[ -z $host ]] && return 1

  if [[ `grep -c "^$host" $payload` -eq 1 ]]; then
      print_center -ama " The host already exists"
      enter
      return 1
  fi

  echo "$host" >> $payload && grep -v "^$" $payload > /tmp/a && mv /tmp/a $payload
  clear
  msg -bar
  print_center -ama "Host Added Successfully"
  msg -bar
  lshost
  msg -bar
  print_center -ama "Restarting services"

  if [[ ! -f "/etc/init.d/squid" ]]; then
      service squid3 reload &>/dev/null
      service squid3 restart &>/dev/null
   else
      /etc/init.d/squid reload &>/dev/null
      service squid restart &>/dev/null
  fi

  tput cuu1 && tput dl1
  tput cuu1 && tput dl1
  enter
  return 1
}

add_expre(){
  clear
  msg -bar
  print_center -ama "Regular Expressions Within Squid"
  msg -bar
  lsexpre
  back

  while [[ -z $hos ]]; do
      msg -nazu " Enter a word: " && read hos
      [[ $hos = 0 ]] && return 1
      tput cuu1 && tput dl1
      [[ $hos != "" ]] && continue
      print_center -ama "Write a regular word Example: torrent"
      sleep 3s
      tput cuu1 && tput dl1
  done

  host="$hos"
  [[ -z $host ]] && return 1

  if [[ `grep -c "^$host" $payload2` -eq 1 ]]; then
      print_center -ama " Regular expression already exists"
      enter
      return 1
  fi

  echo "$host" >> $payload2 && grep -v "^$" $payload2 > /tmp/a && mv -f /tmp/a $payload2
  clear
  msg -bar
  print_center -ama "Regular Expression Added Successfully"
  msg -bar
  lsexpre
  msg -bar
  print_center -ama "Restarting services"

  if [[ ! -f "/etc/init.d/squid" ]]; then
      service squid3 reload &>/dev/null
      service squid3 restart &>/dev/null
   else
      /etc/init.d/squid reload &>/dev/null
      service squid restart &>/dev/null
  fi

  tput cuu1 && tput dl1
  tput cuu1 && tput dl1
  enter
  return 1
}

del_host(){
  unset opcion
  clear
  msg -bar
  print_center -ama "Current Hosts Within Squid"
  msg -bar
  lshost
  back
  while [[ -z $opcion ]]; do
      msg -ne " Delete host number: "
      read opcion
      if [[ ! $opcion =~ $numero ]]; then
        tput cuu1 && tput dl1
        print_center -verm2 "enter only numbers"
        sleep 2s
        tput cuu1 && tput dl1
        unset opcion
      elif [[ $opcion -gt ${#pay[@]} ]]; then
        tput cuu1 && tput dl1
        print_center -ama "only numbers between 0 and ${#pay[@]}"
        sleep 2s
        tput cuu1 && tput dl1
        unset opcion
      fi
  done
  [[ $opcion = 0 ]] && return 1
  host="${pay[$opcion]}/"
  [[ -z $host ]] && return 1
  [[ `grep -c "^$host" $payload` -ne 1 ]] && print_center -ama "Host Not Found" && return 1
  grep -v "^$host" $payload > /tmp/a && mv /tmp/a $payload
  clear
  msg -bar
  print_center -ama "Host Removed Successfully"
  msg -bar
  lshost
  msg -bar
  print_center -ama "Restarting services"

  if [[ ! -f "/etc/init.d/squid" ]]; then
      service squid3 reload &>/dev/null
      service squid3 restart &>/dev/null
  else
      /etc/init.d/squid reload &>/dev/null
      service squid restart &>/dev/null
  fi

  tput cuu1 && tput dl1
  tput cuu1 && tput dl1
  enter
  return 1
}

del_expre(){
  unset opcion
  clear
  msg -bar
  print_center -ama "Regular Expression Within Squid"
  msg -bar
  lsexpre
  back
  while [[ -z $opcion ]]; do
      msg -ne " Delete word number: " && read opcion
      if [[ ! $opcion =~ $numero ]]; then
        tput cuu1 && tput dl1
        print_center -verm2 "enter only numbers"
        sleep 2s
        tput cuu1 && tput dl1
        unset opcion
      elif [[ $opcion -gt ${#pay[@]} ]]; then
        tput cuu1 && tput dl1
        print_center -ama "only numbers between 0 and ${#pay[@]}"
        sleep 2s
        tput cuu1 && tput dl1
        unset opcion
      fi
  done
  [[ $opcion = 0 ]] && return 1
  host="${pay[$opcion]}"
  [[ -z $host ]] && return 1
  [[ `grep -c "^$host" $payload2` -ne 1 ]] && print_center -ama "Word Not Found" && return 1
  grep -v "^$host" $payload2 > /tmp/a && mv -f /tmp/a $payload2
  clear
  msg -bar
  print_center -ama "Word Removed Successfully"
  msg -bar
  lsexpre
  msg -bar
  print_center -ama "Restarting services"
  if [[ ! -f "/etc/init.d/squid" ]]; then
      service squid3 reload &>/dev/null
      service squid3 restart &>/dev/null
  else
      /etc/init.d/squid reload &>/dev/null
      service squid restart &>/dev/null
  fi
  tput cuu1 && tput dl1
  tput cuu1 && tput dl1
  enter
  return 1
}

add_port(){
    if [[ -e /etc/squid/squid.conf ]]; then
        local CONF="/etc/squid/squid.conf"
      elif [[ -e /etc/squid3/squid.conf ]]; then
        local CONF="/etc/squid3/squid.conf"
      fi
      local miport=$(cat ${CONF}|grep -w 'http_port'|awk -F ' ' '{print $2}'|tr '\n' ' ')
      local line="$(cat ${CONF}|sed -n '/http_port/='|head -1)"
      local NEWCONF="$(cat ${CONF}|sed "$line c ADMR_port"|sed '/http_port/d')"
      title -ama "ADD A SQUID PORT"
     echo -e " $(msg -verm2 "Enter Your Ports:") $(msg -verd "80 8080 8799 3128")"
      msg -bar
      msg -ne " Enter Ports: " && read DPORT
      tput cuu1 && tput dl1
      TTOTAL=($DPORT)
      for((i=0; i<${#TTOTAL[@]}; i++)); do
          [[ $(mportas|grep -v squid|grep -v '>'|grep -w "${TTOTAL[$i]}") = "" ]] && {
              echo -e "\033[1;33m Selected Port:\033[1;32m ${TTOTAL[$i]} OK"
              PORT="$PORT ${TTOTAL[$i]}"
        } || {
              echo -e "\033[1;33m Selected Port:\033[1;31m ${TTOTAL[$i]} FAIL"
        }
      done
      [[  -z $PORT ]] && {
        msg -bar
        print_center -verm2 "No Valid Port"
        return 1
      }
      PORT="$miport $PORT"
      rm ${CONF}
      while read varline; do
          if [[ ! -z "$(echo "$varline"|grep 'ADMR_port')" ]]; then
              for i in `echo $PORT`; do
            echo -e "http_port ${i}" >> ${CONF}
            ufw allow $i/tcp &>/dev/null 2>&1
              done
              continue
        fi
        echo -e "${varline}" >> ${CONF}
      done <<< "${NEWCONF}"
      msg -bar
      print_center -azu "PLEASE WAIT RESTARTING SERVICES"
      [[ -d "/etc/squid/" ]] && {
        service ssh restart > /dev/null 2>&1
        /etc/init.d/squid start > /dev/null 2>&1
        service squid restart > /dev/null 2>&1
      }
      [[ -d "/etc/squid3/" ]] && {
        service ssh restart > /dev/null 2>&1
        /etc/init.d/squid3 start > /dev/null 2>&1
        service squid3 restart > /dev/null 2>&1
      }
      sleep 2s
      tput cuu1 && tput dl1
      print_center -verd "PORTS ADDED"
      enter
      return 1
}

del_port(){
    squidport=$(lsof -V -i tcp -P -n | grep -v "ESTABLISHED" |grep -v "COMMAND" | grep "LISTEN"|grep -E 'squid|squid3')

    if [[ $(echo "$squidport"|wc -l) -lt '2' ]];then
        clear
        msg -bar
        print_center -ama "Only one port to delete\ndo you want to stop the service?"
        msg -bar
        msg -ne " option [Y/N]: " && read a

        if [[ "$a" = @(S|s|Y|y) ]]; then
            title -ama "PLEASE WAIT STOPPING SERVICES"
            [[ -d "/etc/squid/" ]] && {
                if service squid stop &> /dev/null ; then
                    print_center -verd "Squid service stopped"
                else
                    print_center -verm2 "Failed to stop Squid service"
                fi
            }
            [[ -d "/etc/squid3/" ]] && {
                if service squid3 stop &> /dev/null ; then
                    print_center -verd "Squid3 service stopped"
                else
                    print_center -verm2 "Failed to stop Squid3 service"
                fi
            }		
        fi
        enter
        return 1
    fi

    if [[ -e /etc/squid/squid.conf ]]; then
        local CONF="/etc/squid/squid.conf"
      elif [[ -e /etc/squid3/squid.conf ]]; then
        local CONF="/etc/squid3/squid.conf"
      fi
    title -ama "Remove a squid port"
    n=1
    while read i; do
        port=$(echo $i|awk -F ' ' '{print $9}'|cut -d ':' -f2)
        echo -e " $(msg -verd "[$n]") $(msg -verm2 ">") $(msg -azu "$port")"
        drop[$n]=$port
        num_opc="$n"
        let n++ 
    done <<< $(echo "$squidport")
    back
    while [[ -z $opc ]]; do
        msg -ne " option: "
        read opc
        tput cuu1 && tput dl1
        if [[ -z $opc ]]; then
            msg -verm2 " select an option between 1 and $num_opc"
            unset opc
            sleep 2
            tput cuu1 && tput dl1
            continue
        elif [[ ! $opc =~ $numero ]]; then
            msg -verm2 " select only numbers between 1 and $num_opc"
            unset opc
            sleep 2
            tput cuu1 && tput dl1
            continue
        elif [[ "$opc" -gt "$num_opc" ]]; then
            msg -verm2 " select an option between 1 and $num_opc"
            sleep 2
            tput cuu1 && tput dl1
            unset opc
            continue
        fi
    done
    sed -i "/http_port ${drop[$opc]}/d" $CONF
      print_center -azu "PLEASE WAIT RESTARTING SERVICES"
      [[ -d "/etc/squid/" ]] && {
        service ssh restart > /dev/null 2>&1
        /etc/init.d/squid start > /dev/null 2>&1
        service squid restart > /dev/null 2>&1
      }
      [[ -d "/etc/squid3/" ]] && {
        service ssh restart > /dev/null 2>&1
        /etc/init.d/squid3 start > /dev/null 2>&1
        service squid3 restart > /dev/null 2>&1
      }
      sleep 2s
      tput cuu1 && tput dl1
      print_center -verd "PORT REMOVED"
      enter
      return 1	
}

restart_squid(){
    title -ama "PLEASE WAIT RESTARTING SERVICES"
      [[ -d "/etc/squid/" ]] && {
        service ssh restart > /dev/null 2>&1
        /etc/init.d/squid start > /dev/null 2>&1
        service squid restart > /dev/null 2>&1
      }
      [[ -d "/etc/squid3/" ]] && {
        service ssh restart > /dev/null 2>&1
        /etc/init.d/squid3 start > /dev/null 2>&1
        service squid3 restart > /dev/null 2>&1
      }
      sleep 2s
      tput cuu1 && tput dl1
      print_center -verd "SERVICE RESTARTING"
      enter
      return 1
}


online_squid(){
  payload="/etc/dominio-denie"
  payload2="/etc/exprecion-denie"
  clear
  msg -bar
  print_center -ama "SQUID CONFIGURATION"
  msg -bar
  menu_func "Block a host" \
  "-bar3 Unblock a host" \
  "Block regular expression" \
  "-bar3 Unblock regular expression" \
  "Add port" \
  "-bar Remove port" \
  "\e[31mUninstall Squid" \
  "\e[33mRestart squid"
  back
  opcion=$(selection_fun 8)

  case $opcion in
    1)add_host;;
    2)del_host;;
    3)add_expre;;
    4)del_expre;;
    5)add_port;;
    6)del_port;;
    7)fun_squid;;
    8)restart_squid;;
    0)return 1;;
  esac
}

if [[ -e /etc/squid/squid.conf ]]; then
  online_squid
elif [[ -e /etc/squid3/squid.conf ]]; then
  online_squid
else
  fun_squid
  return 1
fi