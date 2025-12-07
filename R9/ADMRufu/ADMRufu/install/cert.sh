#!/bin/bash
#====FUNCTIONS==========

cert_install(){
    #apt install socat netcat -y
    if [[ ! -e $HOME/.acme.sh/acme.sh ]];then
        msg -bar3
        msg -ama " Installing acme.sh script"
        curl -s "https://get.acme.sh" | sh &>/dev/null
    fi
    if [[ ! -z "${mail}" ]]; then
        title "LOGGING INTO Zerossl"
        sleep 3
        $HOME/.acme.sh/acme.sh --register-account  -m ${mail} --server zerossl
        $HOME/.acme.sh/acme.sh --set-default-ca --server zerossl
        enter
    else
        title "APPLYING letsencrypt SERVER"
        sleep 3
        $HOME/.acme.sh/acme.sh --set-default-ca --server letsencrypt
        enter
    fi
    title "GENERATING SSL CERTIFICATE"
    sleep 3
    if "$HOME"/.acme.sh/acme.sh --issue -d "${domain}" --standalone -k ec-256 --force; then
        "$HOME"/.acme.sh/acme.sh --installcert -d "${domain}" --fullchainpath ${ADM_crt}/${domain}.crt --keypath ${ADM_crt}/${domain}.key --ecc --force &>/dev/null
        rm -rf $HOME/.acme.sh/${domain}_ecc
        msg -bar
        print_center -verd "SSL Certificate generated successfully"
        enter
        return 1
    else
        rm -rf "$HOME/.acme.sh/${domain}_ecc"
        msg -bar
        print_center -verm2 "Error generating SSL certificate"
        msg -bar
        msg -ama " Check for possible errors"
        msg -ama " and try again"
        enter
        return 1
    fi
 }

ext_cert(){
    unset cert
    declare -A cert
    title "EXTERNAL CERTIFICATE INSTALLER"
    print_center -azu "You need to have your SSL certificate ready"
    print_center -azu "along with its corresponding private key"
    msg -bar
    msg -ne " Continue...[Y/N]: "
    read opcion
    [[ $opcion != @(S|s|Y|y) ]] && return 1

    title "ENTER YOUR SSL CERTIFICATE CONTENT"
    msg -ama ' the nano text editor will open below
 enter the content of your certificate
 save by pressing "CTRL+x"
 then "Y" or "S" depending on your language
 and finally "enter"'
     msg -bar
     msg -ne " Continue...[Y/N]: "
    read opcion
    [[ $opcion != @(S|s|Y|y) ]] && return 1
    rm -rf ${ADM_tmp}/tmp.crt
    clear
    nano ${ADM_tmp}/tmp.crt

    title "ENTER YOUR PRIVATE KEY CONTENT"
    msg -ama ' the nano text editor will open below
 enter the content of your private key
 save by pressing "CTRL+x"
 then "Y" or "S" depending on your language
 and finally "enter"'
     msg -bar
     msg -ne " Continue...[Y/N]: "
    read opcion
    [[ $opcion != @(S|s|Y|y) ]] && return 1
    ${ADM_tmp}/tmp.key
    clear
    nano ${ADM_tmp}/tmp.key

    if openssl x509 -in ${ADM_tmp}/tmp.crt -text -noout &>/dev/null ; then
        DNS=$(openssl x509 -in ${ADM_tmp}/tmp.crt -text -noout | grep 'DNS:'|sed 's/, /\n/g'|sed 's/DNS:\| //g')
        rm -rf ${ADM_crt}/*
        if [[ $(echo "$DNS"|wc -l) -gt "1" ]]; then
            DNS="multi-domain"
        fi
        mv ${ADM_tmp}/tmp.crt ${ADM_crt}/$DNS.crt
        mv ${ADM_tmp}/tmp.key ${ADM_crt}/$DNS.key

        title "INSTALLATION COMPLETE"
        echo -e "$(msg -verm2 "Domain: ")$(msg -ama "$DNS")"
        echo -e "$(msg -verm2 "Issued: ")$(msg -ama "$(openssl x509 -noout -in ${ADM_crt}/$DNS.crt -startdate|sed 's/notBefore=//g')")"
        echo -e "$(msg -verm2 "Expires: ")$(msg -ama "$(openssl x509 -noout -in ${ADM_crt}/$DNS.crt -enddate|sed 's/notAfter=//g')")"
        echo -e "$(msg -verm2 "Issuer: ")$(msg -ama "$(openssl x509 -noout -in ${ADM_crt}/$DNS.crt -issuer|sed 's/issuer=//g'|sed 's/ = /=/g'|sed 's/, /\n      /g')")"
        msg -bar
        echo "$DNS" > ${ADM_src}/dominio.txt
        read foo
    else
        rm -rf ${ADM_tmp}/tmp.crt
        rm -rf ${ADM_tmp}/tmp.key
        clear
        msg -bar
        print_center -verm2 "DATA ERROR"
        msg -bar
        msg -ama " The entered data is not valid.\n Please verify.\n and try again!!"
        msg -bar
        read foo
    fi
    return 1
}

stop_port(){
    msg -bar3
    msg -ama " Checking ports..."
    ports=('80' '443')

    for i in ${ports[@]}; do
        if [[ 0 -ne $(lsof -i:$i | grep -i -c "listen") ]]; then
            msg -bar3
            echo -ne "$(msg -ama " Freeing port: $i")"
            lsof -i:$i | awk '{print $2}' | grep -v "PID" | xargs kill -9
            sleep 2s
            if [[ 0 -ne $(lsof -i:$i | grep -i -c "listen") ]];then
                tput cuu1 && tput dl1
                print_center -verm2 "ERROR FREEING PORT $i"
                msg -bar3
                msg -ama " Port $i in use."
                msg -ama " auto-free failed"
                msg -ama " stop port $i manually"
                msg -ama " and try again..."
                msg -bar
                read foo
                return 1			
            fi
        fi
    done
 }

ger_cert(){
    clear
    case $1 in
        1)title "Let's Encrypt Certificate Generator";;
        2)title "Zerossl Certificate Generator";;
    esac
    print_center -ama "You need to enter a domain."
    print_center -ama "It must only resolve DNS and point"
    print_center -ama "to this server's IP address."
    msg -bar3
    print_center -ama "Temporarily you need to have"
    print_center -ama "ports 80 and 443 free."
    if [[ $1 = 2 ]]; then
        msg -bar3
        print_center -ama "You need to have a Zerossl account."
    fi
    msg -bar
     msg -ne " Continue [Y/N]: "
    read opcion
    [[ $opcion != @(s|S|y|Y) ]] && return 1

    if [[ $1 = 2 ]]; then
     while [[ -z $mail ]]; do
         clear
        msg -bar
        print_center -ama "Enter your email used in Zerossl"
        msg -bar3
        msg -ne " >>> "
        read mail
     done
    fi

    if [[ -e ${ADM_src}/dominio.txt ]]; then
        domain=$(cat ${ADM_src}/dominio.txt)
        [[ $domain = "multi-domain" ]] && unset domain
        if [[ ! -z $domain ]]; then
            clear
            msg -bar
            print_center -azu "Domain associated with this IP"
            msg -bar3
            echo -e "$(msg -verm2 " >>> ") $(msg -ama "$domain")"
            msg -ne "Continue using this domain? [Y/N]: "
            read opcion
            tput cuu1 && tput dl1
            [[ $opcion != @(S|s|Y|y) ]] && unset domain
        fi
    fi

    while [[ -z $domain ]]; do
        clear
        msg -bar
        print_center -ama "Enter your domain"
        msg -bar3
        msg -ne " >>> "
        read domain
    done
    msg -bar3
    msg -ama " Checking IP address..."
    local_ip=$(wget -qO- ipv4.icanhazip.com)
    domain_ip=$(ping "${domain}" -c 1 | sed '1{s/[^(]*(//;s/).*//;q}')
    sleep 3
    [[ -z "${domain_ip}" ]] && domain_ip="IP not found"
    if [[ $(echo "${local_ip}" | tr '.' '+' | bc) -ne $(echo "${domain_ip}" | tr '.' '+' | bc) ]]; then
        clear
        msg -bar
        print_center -verm2 "IP ADDRESS ERROR"
        msg -bar
        msg -ama " Your domain's IP address\n does not match your server's IP."
        msg -bar3
        echo -e " $(msg -azu "Domain IP:  ")$(msg -verm2 "${domain_ip}")"
        echo -e " $(msg -azu "Server IP: ")$(msg -verm2 "${local_ip}")"
        msg -bar3
        msg -ama " Verify your domain and try again."
        msg -bar
        read foo
        return 1
    fi

    
    stop_port
    cert_install
    echo "$domain" > ${ADM_src}/dominio.txt
    return 1
}

gen_domi(){
    title "SUB-DOMAIN GENERATOR"
    msg -ama " Verifying IP address..."
    sleep 2

    ls_dom=$(curl -s -X GET "$url/$_dns/dns_records?per_page=100" \
     -H "Authorization: Bearer $apikey" \
     -H "Content-Type: application/json" | jq '.')

    num_line=$(echo $ls_dom | jq '.result | length')
    ls_domi=$(echo $ls_dom | jq -r '.result[].name')
    ls_ip=$(echo $ls_dom | jq -r '.result[].content')
    my_ip=$(wget -qO- ipv4.icanhazip.com)

    if [[ $(echo "$ls_ip"|grep -w "$my_ip") = "$my_ip" ]];then
        for (( i = 0; i < $num_line; i++ )); do
            if [[ $(echo "$ls_dom" | jq -r ".result[$i].content"|grep -w "$my_ip") = "$my_ip" ]]; then
                domain=$(echo "$ls_dom" | jq -r ".result[$i].name")
                echo "$domain" > ${ADM_src}/dominio.txt
                break
            fi
        done
        tput cuu1 && tput dl1
        print_center -azu "A sub-domain is already associated with this IP"
        msg -bar
        echo -e " $(msg -verm2 "sub-domain:") $(msg -ama "$domain")"
        enter
        return 1
    fi

    if [[ -z $name ]]; then
        tput cuu1 && tput dl1
        echo -e " $(msg -azu "The main domain is:") $(msg -ama "$_domain")\n $(msg -azu "The sub-domain will be:") $(msg -ama "example.$_domain")"
        msg -bar
        while [[ -z "$name" ]]; do
            msg -ne " Name (ex: vpsfull) >>> "
            read name
            tput cuu1 && tput dl1

            name=$(echo "$name" | tr -d '[[:space:]]')

            if [[ -z $name ]]; then
                msg -verm2 " Enter a name...!"
                unset name
                sleep 2
                tput cuu1 && tput dl1
                continue
            elif [[ ! $name =~ $tx_num ]]; then
                msg -verm2 " Enter only letters and numbers...!"
                unset name
                sleep 2
                tput cuu1 && tput dl1
                continue
            elif [[ "${#name}" -lt "4" ]]; then
                msg -verm2 " Name too short!"
                sleep 2
                tput cuu1 && tput dl1
                unset name
                continue
            else
                domain="$name.$_domain"
                msg -ama " Checking availability..."
                sleep 2
                tput cuu1 && tput dl1
                if [[ $(echo "$ls_domi" | grep "$domain") = "" ]]; then
                    echo -e " $(msg -verd "[ok]") $(msg -azu "sub-domain available")"
                    sleep 2
                else
                    echo -e " $(msg -verm2 "[fail]") $(msg -azu "sub-domain NOT available")"
                    unset name
                    sleep 2
                    tput cuu1 && tput dl1
                    continue
                fi
            fi
        done
    fi
    tput cuu1 && tput dl1
    echo -e " $(msg -azu "The sub-domain will be:") $(msg -verd "$domain")"
    msg -bar
    msg -ne " Continue...[Y/N]: "
    read opcion
    [[ $opcion = @(n|N) ]] && return 1
    tput cuu1 && tput dl1
    print_center -azu "Creating sub-domain"
    sleep 1

    var=$(cat <<EOF
{
  "type": "A",
  "name": "$name",
  "content": "$my_ip",
  "ttl": 1,
  "priority": 10,
  "proxied": false
}
EOF
)
    chek_domain=$(curl -s -X POST "$url/$_dns/dns_records" \
    -H "Authorization: Bearer $apikey" \
    -H "Content-Type: application/json" \
    -d $(echo $var|jq -c '.')|jq '.')

    tput cuu1 && tput dl1
    if [[ "$(echo $chek_domain|jq -r '.success')" = "true" ]]; then
        echo "$(echo $chek_domain|jq -r '.result.name')" > ${ADM_src}/dominio.txt
        print_center -verd "Sub-domain created successfully!"
    else
        echo "" > ${ADM_src}/dominio.txt
        print_center -ama "Failed to create sub-domain!" 	
    fi
    enter
    return 1
}

ger_cert_z(){
    echo ""
}

#======MENU======
menu_cert(){
title "SUB-DOMAIN AND SSL CERTIFICATE"
menu_func "GENERATE SSL CERT (Let's Encrypt)" "GENERATE SSL CERT (Zerossl)" "ENTER EXTERNAL SSL CERTIFICATE" "GENERATE SUB-DOMAIN"
back
in_opcion "Option"

case $opcion in
    1)ger_cert 1;;
    2)ger_cert 2;;
    3)ext_cert;;
    4)gen_domi;;
    0)return 1;;
esac
}

menu_cert