#!/bin/bash
#19/12/2019

drop_port(){
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
            cupsd)continue;;
            systemd-r)continue;;
            stunnel4|stunnel)continue;;
            *)DPB+=" $reQ:$Port";;
        esac
    done <<< "${portasVAR}"
 }

ssl_stunel(){
    [[ $(mportas|grep stunnel4|head -1) ]] && {
        clear
        msg -bar
        print_center -ama "Stopping Stunnel"
        msg -bar
        service stunnel4 stop & >/dev/null 2>&1
        fun_bar 'apt-get purge stunnel4 -y' 'UNINSTALL STUNNEL4 '
        msg -bar
        print_center -verd "Stunnel stopped successfully!"
        msg -bar
        sleep 2
        return 1
    }
    title "SSL INSTALLER By @Rufu99"
    print_center -azu "Select traffic redirection port"
    msg -bar
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

    title "SSL INSTALLER By @Rufu99"
    echo -e "\033[1;33m Traffic redirection port: \033[1;32m${drop[$opc]}"
    msg -bar
    while [[ -z $opc2 ]]; do
        echo -ne "\033[1;37m Enter an SSL port: " && read opc2
        tput cuu1 && tput dl1

        [[ $(mportas|grep -w "${opc2}") = "" ]] && {
            echo -e "\033[1;33m SSL port:\033[1;32m ${opc2} OK"
        } || {
            echo -e "\033[1;33m SSL port:\033[1;31m ${opc2} FAIL" && sleep 2
            tput cuu1 && tput dl1
            unset opc2
        }
    done

    # openssl x509 -in 2.crt -text -noout |grep -w 'Issuer'|awk -F 'O = ' '{print $2}'|cut -d ',' -f1

    msg -bar
    fun_bar 'apt-get install stunnel4 -y' 'INSTALL STUNNEL4 '
    echo -e "client = no\n[SSL]\ncert = /etc/stunnel/stunnel.pem\naccept = ${opc2}\nconnect = 127.0.0.1:${drop[$opc]}" > /etc/stunnel/stunnel.conf

    db="$(ls ${ADM_crt})"
    opcion="n"
    if [[ ! "$(echo "$db"|grep ".crt")" = "" ]]; then
        cert=$(echo "$db"|grep ".crt")
        key=$(echo "$db"|grep ".key")
        msg -bar
        print_center -azu "SSL CERTIFICATE FOUND"
        msg -bar
        echo -e "$(msg -azu "CERT:") $(msg -ama "$cert")"
        echo -e "$(msg -azu "KEY:")  $(msg -ama "$key")"
        msg -bar
        msg -ne "Continue using this certificate [Y/N]: "
        read opcion
        if [[ $opcion != @(n|N) ]]; then
            cp ${ADM_crt}/$cert ${ADM_tmp}/stunnel.crt
            cp ${ADM_crt}/$key ${ADM_tmp}/stunnel.key
        fi
    fi

    if [[ $opcion != @(s|S|y|Y) ]]; then
        openssl genrsa -out ${ADM_tmp}/stunnel.key 2048 > /dev/null 2>&1
        (echo "" ; echo "" ; echo "" ; echo "" ; echo "" ; echo "" ; echo "@cloudflare" )|openssl req -new -key ${ADM_tmp}/stunnel.key -x509 -days 1000 -out ${ADM_tmp}/stunnel.crt > /dev/null 2>&1
    fi
    cat ${ADM_tmp}/stunnel.key ${ADM_tmp}/stunnel.crt > /etc/stunnel/stunnel.pem
    sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4
    service stunnel4 restart > /dev/null 2>&1
    msg -bar
    print_center -verd "INSTALLED SUCCESSFULLY"
    msg -bar
    rm -rf ${ADM_tmp}/stunnel.crt > /dev/null 2>&1
    rm -rf ${ADM_tmp}/stunnel.key > /dev/null 2>&1
    sleep 3
    return 1
}

add_port(){
    title "SSL INSTALLER By @Rufu99"
    print_center -azu "Select traffic redirection port"
    msg -bar
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

    title "SSL INSTALLER By @Rufu99"
    echo -e "\033[1;33m Traffic redirection port: \033[1;32m${drop[$opc]}"
    msg -bar
    while [[ -z $opc2 ]]; do
        echo -ne "\033[1;37m Enter an SSL port: " && read opc2
        tput cuu1 && tput dl1

        [[ $(mportas|grep -w "${opc2}") = "" ]] && {
            echo -e "\033[1;33m SSL port:\033[1;32m ${opc2} OK"
        } || {
            echo -e "\033[1;33m SSL port:\033[1;31m ${opc2} FAIL" && sleep 2
            tput cuu1 && tput dl1
            unset opc2
        }
    done
    echo -e "client = no\n[SSL+]\ncert = /etc/stunnel/stunnel.pem\naccept = ${opc2}\nconnect = 127.0.0.1:${drop[$opc]}" >> /etc/stunnel/stunnel.conf
    service stunnel4 restart > /dev/null 2>&1
    msg -bar
    print_center -verd "PORT ADDED SUCCESSFULLY"
    enter
    return 1
}

start-stop(){
    clear
    msg -bar
    if [[ $(service stunnel4 status|grep -w 'Active'|awk -F ' ' '{print $2}') = 'inactive' ]]; then
        if service stunnel4 start &> /dev/null ; then
            print_center -verd "Stunnel4 service started"
        else
            print_center -verm2 "Failed to start Stunnel4 service"
        fi
    else
        if service stunnel4 stop &> /dev/null ; then
            print_center -verd "Stunnel4 service stopped"
        else
            print_center -verm2 "Failed to stop Stunnel4 service"
        fi
    fi
    enter
    return 1
}

del_port(){
    sslport=$(lsof -V -i tcp -P -n | grep -v "ESTABLISHED" |grep -v "COMMAND" | grep "LISTEN"|grep -E 'stunnel|stunnel4')
    if [[ $(echo "$sslport"|wc -l) -lt '2' ]];then
        clear
        msg -bar
        print_center -ama "Only one port to delete\ndo you want to stop the service?"
        msg -bar
        msg -ne " option [Y/N]: " && read a

        if [[ "$a" = @(S|s|Y|y) ]]; then
            clear
            msg -bar
            if service stunnel4 stop &> /dev/null ; then
                print_center -verd "Stunnel4 service stopped"
            else
                print_center -verm2 "Failed to stop Stunnel4 service"
            fi		
        fi
        enter
        return 1
    fi

    title "Select the port number to remove"
    n=1
    while read i; do
        port=$(echo $i|awk -F ' ' '{print $9}'|cut -d ':' -f2)
        echo -e " $(msg -verd "[$n]") $(msg -verm2 ">") $(msg -azu "$port")"
        drop[$n]=$port
        num_opc="$n"
        let n++ 
    done <<< $(echo "$sslport")
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

    in=$(( $(cat "/etc/stunnel/stunnel.conf"|grep -n "accept = ${drop[$opc]}"|cut -d ':' -f1) - 3 ))
    en=$(( $in + 4))
    sed -i "$in,$en d" /etc/stunnel/stunnel.conf
    sed -i '2 s/\[SSL+\]/\[SSL\]/' /etc/stunnel/stunnel.conf

    title "SSL port ${drop[$opc]} removed"

    if service stunnel4 restart &> /dev/null ; then
        print_center -verd "Stunnel4 service restarted"
    else
        print_center -verm2 "Failed to restart Stunnel4 service"
    fi
    enter
    return 1

}

edit_port(){
    sslport=$(lsof -V -i tcp -P -n | grep -v "ESTABLISHED" |grep -v "COMMAND" | grep "LISTEN"|grep -E 'stunnel|stunnel4')
    title "Select the port number to edit"
    n=1
    while read i; do
        port=$(echo $i|awk -F ' ' '{print $9}'|cut -d ':' -f2)
        echo -e " $(msg -verd "[$n]") $(msg -verm2 ">") $(msg -azu "$port")"
        drop[$n]=$port
        num_opc="$n"
        let n++ 
    done <<< $(echo "$sslport")
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
    title "Current configuration"
    in=$(( $(cat "/etc/stunnel/stunnel.conf"|grep -n "accept = ${drop[$opc]}"|cut -d ':' -f1) + 1 ))
    en=$(sed -n "${in}p" /etc/stunnel/stunnel.conf|cut -d ':' -f2)
    print_center -ama "${drop[$opc]} >>> $en"
    msg -bar
    drop_port
    n=1
    for i in $DPB; do
        port=$(echo $i|awk -F ":" '{print $2}')
        [[ "$port" = "$en" ]] && continue
        proto=$(echo $i|awk -F ":" '{print $1}')
        proto2=$(printf '%-12s' "$proto")
        echo -e " $(msg -verd "[$n]") $(msg -verm2 ">") $(msg -ama "$proto2")$(msg -azu "$port")"
        drop[$n]=$port
        num_opc="$n"
        let n++ 
    done
    msg -bar
    unset opc
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
    sed -i "$in s/$en/${drop[$opc]}/" /etc/stunnel/stunnel.conf
    title "Redirection port modified"
    if service stunnel4 restart &> /dev/null ; then
        print_center -verd "Stunnel4 service restarted"
    else
        print_center -verm2 "Failed to restart Stunnel4 service"
    fi
    enter
    return 1
}

restart(){
    clear && msg -bar
    if service stunnel4 restart &> /dev/null ; then
        print_center -verd "Stunnel4 service restarted"
    else
        print_center -verm2 "Failed to restart Stunnel4 service"
    fi
    enter
    return 1
}

edit_nano(){
    nano /etc/stunnel/stunnel.conf
    restart
    return 1
}




title "SSL INSTALLER By @Rufu99"
echo -e "$(msg -verd " [1]") $(msg -verm2 ">") $(msg -verd "INSTALL") $(msg -ama "-") $(msg -verm2 "UNINSTALL")"
n=1
if [[ $(dpkg -l|grep 'stunnel'|awk -F ' ' '{print $2}') ]]; then
    msg -bar3
    echo -e "$(msg -verd " [2]") $(msg -verm2 ">") $(msg -verd "ADD SSL PORTS")"
    echo -e "$(msg -verd " [3]") $(msg -verm2 ">") $(msg -verm2 "REMOVE SSL PORTS")"
    msg -bar3
    echo -e "$(msg -verd " [4]") $(msg -verm2 ">") $(msg -ama "EDIT REDIRECTION PORT")"
    echo -e "$(msg -verd " [5]") $(msg -verm2 ">") $(msg -azu "EDIT MANUAL (NANO)")"
    msg -bar3
    echo -e "$(msg -verd " [6]") $(msg -verm2 ">") $(msg -azu "START/STOP SSL SERVICE")"
    echo -e "$(msg -verd " [7]") $(msg -verm2 ">") $(msg -azu "RESTART SSL SERVICE")"
    n=7
fi
back
opcion=$(selection_fun $n)
case $opcion in
    1)ssl_stunel;;
    2)add_port;;
    3)del_port;;
    4)edit_port;;
    5)edit_nano;;
    6)start-stop;;
    7)restart;;
    0) return 1;;
esac