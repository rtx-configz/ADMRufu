#!/bin/bash
clear
check_drop(){
    ins=$(dpkg --get-selections|grep -w "dropbear"|grep -v "dropbear-"|awk '{printf $2}')
    [[ -z "$ins" ]] && ins="deinstall"
    if [[ "$ins" = "deinstall" ]]; then
        encab
        print_center -ama "Dropbear is not installed"
        msg -bar
        echo -ne "\033[1;37m Do you want to install it [y/n]: "
        read opcion
        [[ $opcion = @(s|S|y|Y) ]] && clear && msg -bar && ${ADM_inst}/dropbear.sh
    fi
 }

drop_port () {
    local portasVAR=$(lsof -V -i tcp -P -n | grep -v "ESTABLISHED" |grep -v "COMMAND" | grep "LISTEN")
    local NOREPEAT
    local reQ
    local Port

    while read port; do
        reQ=$(echo ${port}|awk '{print $1}')
        Port=$(echo {$port} | awk '{print $9}' | awk -F ":" '{print $2}')
        [[ $(echo -e $NOREPEAT|grep -w "$Port") ]] && continue
        NOREPEAT+="$Port\n"

        case ${reQ} in
            dropbear)
                     if [[ ! $Port = 22 ]]; then
                     	DPB+=" $Port"
                     fi;;
        esac
    done <<< "${portasVAR}"
 }

conf(){
    check_drop
    [[ $opcion = @(n|N) ]] && return 1
    drop_port
    encab
    print_center -azu "Select traffic redirection port"
    msg -bar

    n=1
    for i in $DPB; do
        echo -e " \033[1;32m[$n] \033[1;31m> \033[1;37m$i\033[0m"
        drop[$n]=$i
        num_opc=$n
        let n++	
    done
    back
    opc=$(selection_fun $num_opc)
    [[ $opc = 0 ]] && return 1
    encab
    echo -e "\033[1;33m Traffic redirection port: \033[1;32m${drop[$opc]}"
    msg -bar
 while [[ -z $opc2 ]]; do
    echo -ne "\033[1;37m Enter a WEBSOCKET port: " && read opc2
    tput cuu1 && tput dl1

        [[ $(mportas|grep -w "${opc2}") = "" ]] && {
            echo -e "\033[1;33m Websocket port:\033[1;32m ${opc2} OK"
            msg -bar
        } || {
            echo -e "\033[1;33m Websocket port:\033[1;31m ${opc2} FAIL" && sleep 2
            tput cuu1 && tput dl1
            unset opc2
        }
 done

     while :
     do
    echo -ne "\033[1;37m Do you want to continue [y/n]: " && read start
    tput cuu1 && tput dl1
    if [[ -z $start ]]; then
        echo -e "\033[1;37m You must enter an option \033[1;32m[Y] \033[1;37mfor Yes \033[1;31m[N] \033[1;37mfor No." && sleep 2
        tput cuu1 && tput dl1
    else
        [[ $start = @(n|N) ]] && break
        if [[ $start = @(s|S|y|Y) ]]; then
            node_v="$(which nodejs)" && [[ $(ls -l ${node_v}|grep -w 'node') ]] && node_v="$(which node)"
echo -e "[Unit]
Description=P7COM-nodews1
Documentation=https://p7com.net/
After=network.target nss-lookup.target\n
[Service]
User=nobody
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=${node_v} /etc/ADMRufu/install/WS-Proxy.js -dhost 127.0.0.1 -dport ${drop[$opc]} -mport $opc2
Restart=on-failure
RestartSec=3s\n
[Install]
WantedBy=multi-user.target" > /etc/systemd/system/nodews.$opc2.service

            systemctl enable nodews.$opc2 &>/dev/null
            systemctl start nodews.$opc2 &>/dev/null
            print_center -verd "Execution successful"
            enter
            break
        fi
    fi
    done
    return 1
 }

stop_ws () {
    ck_ws=$(lsof -V -i tcp -P -n | grep -v "ESTABLISHED" |grep -v "COMMAND"|grep "node")
    if [[ -z $(echo "$ck_ws" | awk '{print $1}' | head -n 1) ]]; then
        print_center -verm2 "WEBSOCKET not found"
    else
        ck_port=$(echo "$ck_ws" | awk '{print $9}' | awk -F ":" '{print $2}')
        for i in $ck_port; do
            systemctl stop nodews.${i} &>/dev/null
            systemctl disable nodews.${1} &>/dev/null
            rm /etc/systemd/system/nodews.${i}.service &>/dev/null
        done
        print_center -verm2 "WEBSOCKET stopped"	
    fi
    enter
    return 1
 }

 stop_port () {
     clear
    STWS=$(lsof -V -i tcp -P -n | grep -v "ESTABLISHED" |grep -v "COMMAND"|grep "node" | awk '{print $9}' | awk -F ":" '{print $2}')
    title "STOP A PORT"
     n=1
    for i in $STWS; do
        echo -e " \033[1;32m[$n] \033[1;31m> \033[1;37m$i\033[0m"
        wspr[$n]=$i
        let n++	
    done
     back
     echo -ne "\033[1;37m option: " && read prws
     tput cuu1 && tput dl1
     [[ $prws = "0" ]] && return
     systemctl stop nodews.${wspr[$prws]} &>/dev/null
    systemctl disable nodews.${wspr[$prws]} &>/dev/null
    rm /etc/systemd/system/nodews.${wspr[$prws]}.service &>/dev/null
    print_center -verm2 "WEBSOCKET PORT ${wspr[$prws]} stopped"
     enter
    return 1
 }

encab(){
    title "SSH OVER WEBSOCKET CDN CLOUDFLARE"
 }

encab
menu_func "START/ADD WS CDN PROXY" "STOP WS CDN PROXY"

sf=2
[[ $(lsof -V -i tcp -P -n|grep -v "ESTABLISHED"|grep -v "COMMAND"|grep "node"|wc -l) -ge "2" ]] && echo -e "$(msg -verd " [3]") $(msg -verm2 ">") $(msg -azu "STOP A PORT")" && sf=3
back
selection=$(selection_fun ${sf})
case ${selection} in
    1) conf;;
    2) stop_ws && read foo;;
    3) stop_port;;
    0)return 1;;
esac