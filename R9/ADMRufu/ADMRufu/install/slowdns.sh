#!/bin/bash

info(){
    clear
    nodata(){
        msg -bar
        print_center -ama "NO SLOWDNS INFORMATION!!!"
        enter
    }

    if [[ -e  ${ADM_slow}/domain_ns ]]; then
        ns=$(cat ${ADM_slow}/domain_ns)
        if [[ -z "$ns" ]]; then
            nodata
            return
        fi
    else
        nodata
        return
    fi

    if [[ -e ${ADM_slow}/server.pub ]]; then
        key=$(cat ${ADM_slow}/server.pub)
        if [[ -z "$key" ]]; then
            nodata
            return
        fi
    else
        nodata
        return
    fi

    msg -bar
    print_center -ama "YOUR SLOWDNS CONNECTION DATA"
    msg -bar
    msg -ama "Your NS (Nameserver): $(cat ${ADM_slow}/domain_ns)"
    msg -bar3
    msg -ama "Your Key: $(cat ${ADM_slow}/server.pub)"
    enter
    return
}

drop_port(){
    local portasVAR=$(lsof -V -i tcp -P -n | grep -v "ESTABLISHED" |grep -v "COMMAND" | grep "LISTEN")
    local NOREPEAT
    local reQ
    local Port
    unset DPB
    while read port; do
        reQ=$(echo ${port}|awk '{print $1}')
        Port=$(echo {$port} | awk '{print $9}' | awk -F ":" '{print $2}')
        [[ $(echo -e $NOREPEAT|grep -w "$Port") ]] && continue
        NOREPEAT+="$Port\n"

        case ${reQ} in
            sshd|dropbear|stunnel4|stunnel|python|python3)DPB+=" $reQ:$Port";;
            *)continue;;
        esac
    done <<< "${portasVAR}"
 }

ini_slow(){
    title "SLOWDNS INSTALLER By @Rufu99"
    drop_port
    n=1
    for i in $DPB; do
        proto=$(echo $i|awk -F ":" '{print $1}')
        proto2=$(printf '%-12s' "$proto")
        port=$(echo $i|awk -F ":" '{print $2}')
        echo -e " $(msg -verd "[$n]") $(msg -verm2 ">") $(msg -ama "$proto2")$(msg -azu "$port")"
        drop[$n]=$port
        num_opc="$n"
        let n++ 
    done
    msg -bar
    opc=$(selection_fun $num_opc)
    echo "${drop[$opc]}" > ${ADM_slow}/puerto
    PORT=$(cat ${ADM_slow}/puerto)
    title "SLOWDNS INSTALLER By @Rufu99"
    echo -e " $(msg -ama "Connection port through SlowDNS:") $(msg -verd "$PORT")"
    msg -bar3

    unset NS
    while [[ -z $NS ]]; do
        msg -nama " Your NS domain: "
        read NS
        tput cuu1 && tput dl1
    done
    echo "$NS" > ${ADM_slow}/domain_ns
    echo -e " $(msg -ama "Your NS domain:") $(msg -verd "$NS")"
    msg -bar3

    if [[ ! -e ${ADM_inst}/dns-server ]]; then
        msg -nama " Downloading binary...."
        if wget -O ${ADM_inst}/dns-server https://github.com/rudi9999/ADMRufu/raw/main/Utils/SlowDNS/dns-server &>/dev/null ; then
            chmod +x ${ADM_inst}/dns-server
            msg -verd "[OK]"
        else
            msg -verm2 "[fail]"
            msg -bar
            print_center -ama "Could not download the binary"
            print_center -verm2 "Installation cancelled"
            enter
            return
        fi
        msg -bar3
    fi

    [[ -e "${ADM_slow}/server.pub" ]] && pub=$(cat ${ADM_slow}/server.pub)

    if [[ ! -z "$pub" ]]; then
        msg -nama " Use existing key [Y/N]: "
        read ex_key

        case $ex_key in
            s|S|y|Y) tput cuu1 && tput dl1
                 echo -e " $(msg -ama "Your key:") $(msg -verd "$(cat ${ADM_slow}/server.pub)")";;
            n|N) tput cuu1 && tput dl1
                 rm -rf ${ADM_slow}/server.key
                 rm -rf ${ADM_slow}/server.pub
                 ${ADM_inst}/dns-server -gen-key -privkey-file ${ADM_slow}/server.key -pubkey-file ${ADM_slow}/server.pub &>/dev/null
                 echo -e " $(msg -ama "Your key:") $(msg -verd "$(cat ${ADM_slow}/server.pub)")";;
            *);;
        esac
    else
        rm -rf ${ADM_slow}/server.key
        rm -rf ${ADM_slow}/server.pub
        ${ADM_inst}/dns-server -gen-key -privkey-file ${ADM_slow}/server.key -pubkey-file ${ADM_slow}/server.pub &>/dev/null
        echo -e " $(msg -ama "Your key:") $(msg -verd "$(cat ${ADM_slow}/server.pub)")"
    fi
    msg -bar
    msg -nama "    Starting SlowDNS...."

    iptables -I INPUT -p udp --dport 5300 -j ACCEPT
    iptables -t nat -I PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300

    if screen -dmS slowdns ${ADM_inst}/dns-server -udp :5300 -privkey-file ${ADM_slow}/server.key $NS 127.0.0.1:$PORT ; then
        msg -verd "Successfully!!!"
    else
        msg -verm2 "Failed!!!"
    fi
    enter
}

reset_slow(){
    clear
    msg -bar
    msg -nama "    Restarting SlowDNS...."
    screen -ls | grep slowdns | cut -d. -f1 | awk '{print $1}' | xargs kill
    NS=$(cat ${ADM_slow}/domain_ns)
    PORT=$(cat ${ADM_slow}/puerto)
    if screen -dmS slowdns /etc/slowdns/dns-server -udp :5300 -privkey-file /root/server.key $NS 127.0.0.1:$PORT ;then
        msg -verd "Successfully!!!"
    else
        msg -verm2 "Failed!!!"
    fi
    enter
}
stop_slow(){
    clear
    msg -bar
    msg -nama "    Stopping SlowDNS...."
    if screen -ls | grep slowdns | cut -d. -f1 | awk '{print $1}' | xargs kill ; then
        msg -verd "Successfully!!!"
    else
        msg -verm2 "Failed!!!"
    fi
    enter
}

while :
do
    clear
    msg -bar
    print_center -ama "SLOWDNS INSTALLER By @Rufu99"
    msg -bar
    menu_func "View Information\n$(msg -bar3)" "$(msg -verd "Start SlowDNS")" "$(msg -ama "Restart SlowDNS")" "$(msg -verm2 "Stop SlowDNS")" 
    back
    opcion=$(selection_fun 5)

    case $opcion in
        1)info;;
        2)ini_slow;;
        3)reset_slow;;
        4)stop_slow;;
        0)break;;
    esac
done
return 1