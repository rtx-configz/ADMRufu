#!/bin/bash
# Updated for Ubuntu 25.04 & 25.10 - 12-11-2025
# Python 3 Compatible - SystemD Fixed
# Status Detection Fixed by @wmm-x

clear
msg -bar

# Function to check Python installation
check_python() {
    if command -v python3 &> /dev/null; then
        return 0
    else
        print_center -verm "Python 3 is not installed. Please install it first."
        return 1
    fi
}

# Function to get active python services with their details
get_active_services() {
    systemctl list-units --type=service --state=active 'python.*.service' 2>/dev/null | \
    grep 'python\.' | \
    awk '{print $1}' | \
    sed 's/python\.\([0-9]*\)\.service/\1/' | \
    grep -E '^[0-9]+$'
}

# Function to get all python services (active or not)
get_all_services() {
    systemctl list-units --all 'python*.service' 2>/dev/null | \
    grep 'python\.' | \
    awk '{print $1}' | \
    sed 's/python\.\([0-9]*\)\.service/\1/' | \
    grep -E '^[0-9]+$'
}

# Function to check if a specific proxy type is active
check_proxy_type_active() {
    local proxy_type=$1
    # Check if any service description contains this proxy type
    local found=$(systemctl list-units --type=service --state=active 'python.*.service' 2>/dev/null | grep -i "$proxy_type")
    if [[ -n "$found" ]]; then
        return 0
    else
        return 1
    fi
}

# Function to check if a specific port service is active
check_port_active() {
    local port=$1
    if systemctl is-active --quiet python.${port}.service 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

stop_all () {
    ck_py=$(lsof -V -i tcp -P -n 2>/dev/null | grep -v "ESTABLISHED" | grep -v "COMMAND" | grep "python" | awk '{print $2}')

    if [[ -z $ck_py ]]; then
        print_center -verm "No Python processes found on ports"
        msg -bar
    else
        ck_port=$(lsof -V -i tcp -P -n 2>/dev/null | grep -v "ESTABLISHED" | grep -v "COMMAND" | grep "python" | awk '{print $9}' | awk -F ":" '{print $2}' | sort -u)
        
        for i in $ck_port; do
            if systemctl is-active --quiet python.${i}.service 2>/dev/null; then
                systemctl stop python.${i}.service &>/dev/null
                systemctl disable python.${i}.service &>/dev/null
            fi
            rm -f /etc/systemd/system/python.${i}.service &>/dev/null
        done
        
        systemctl daemon-reload &>/dev/null
        print_center -verd "All Python ports have been stopped"
        msg -bar    
    fi
    sleep 3
}

stop_port () {
    clear
    STPY=$(lsof -V -i tcp -P -n 2>/dev/null | grep -v "ESTABLISHED" | grep -v "COMMAND" | grep "python" | awk '{print $9}' | awk -F ":" '{print $2}' | sort -u)

    if [[ -z $STPY ]]; then
        print_center -verm "No Python processes found"
        msg -bar
        sleep 2
        return 1
    fi

    msg -bar
    print_center -ama "STOP A PORT"
    msg -bar

    n=1
    for i in $STPY; do
        # Check service status for display
        if check_port_active $i; then
            status="\033[1;32m[ACTIVE]"
            # Get service type from description
            svc_type=$(systemctl show python.${i}.service -p Description --no-pager 2>/dev/null | cut -d'=' -f2 | awk '{print $1}')
            [[ -n "$svc_type" ]] && status="$status \033[1;36m($svc_type)"
        else
            status="\033[1;31m[INACTIVE]"
        fi
        echo -e " \033[1;32m[$n] \033[1;31m> \033[1;37mPort: $i $status\033[0m"
        pypr[$n]=$i
        ((n++))
    done

    msg -bar
    echo -ne "$(msg -verd "  [0]") $(msg -verm2 ">") " && msg -bra "\033[1;41mRETURN"
    msg -bar
    echo -ne "\033[1;37m Option: " && read prpy
    tput cuu1 && tput dl1

    [[ $prpy = "0" ]] && return 1

    if [[ -n ${pypr[$prpy]} ]]; then
        systemctl stop python.${pypr[$prpy]}.service &>/dev/null
        systemctl disable python.${pypr[$prpy]}.service &>/dev/null
        rm -f /etc/systemd/system/python.${pypr[$prpy]}.service &>/dev/null
        systemctl daemon-reload &>/dev/null
        print_center -verd "Python PORT ${pypr[$prpy]} stopped"
        msg -bar
    else
        print_center -verm "Invalid option selected"
        msg -bar
    fi
    sleep 3
    return 1
}

colector(){
    clear
    msg -bar
    print_center -azu "Select Main Port for Proxy"
    msg -bar

    # Python port selection
    while [[ -z $porta_socket ]]; do
        echo -ne "\033[1;37m Enter the Port: " && read porta_socket
        tput cuu1 && tput dl1

        if [[ $(mportas|grep -w "${porta_socket}") = "" ]]; then
            echo -e "\033[1;33m Python Port:\033[1;32m ${porta_socket} OK"
            msg -bar3
        else
            echo -e "\033[1;33m Python Port:\033[1;31m ${porta_socket} FAIL" && sleep 2
            tput cuu1 && tput dl1
            unset porta_socket
        fi
    done

    if [[ $1 = "PDirect" ]]; then
        print_center -azu "Select Local SSH/DROPBEAR/OPENVPN Port"
        msg -bar3

        while [[ -z $local ]]; do
            echo -ne "\033[1;97m Enter the Port: \033[0m" && read local
            tput cuu1 && tput dl1

            if [[ $(mportas|grep -w "${local}") != "" ]]; then
                echo -e "\033[1;33m Local Port:\033[1;32m ${local} OK"
                msg -bar3
            else
                echo -e "\033[1;33m Local Port:\033[1;31m ${local} FAIL" && sleep 2
                tput cuu1 && tput dl1
                unset local
            fi
        done
        
        print_center -azu "Custom Response (press enter for default 200)"
        print_center -ama "NOTE: For OVER WEBSOCKET type (101)"
        msg -bar3
        echo -ne "\033[1;97m Enter a Response: \033[0m" && read response
        tput cuu1 && tput dl1
        
        if [[ -z $response ]]; then
            response="200"
            echo -e "\033[1;33m Response:\033[1;32m ${response} OK"
        else
            echo -e "\033[1;33m Response:\033[1;32m ${response} OK"
        fi
        msg -bar3
    fi

    if [[ ! $1 = "PGet" ]] && [[ ! $1 = "POpen" ]]; then
        print_center -azu "Enter your Mini-Banner"
        msg -bar3
        print_center -azu "Enter text [Plain] or [HTML]"
        echo ""
        read texto_soket
    fi

    # Python version selection and configuration
    if [[ $1 = "PPriv" ]]; then
        py="python3"
        IP=$(fun_ip)
    elif [[ $1 = "PGet" ]]; then
        echo "master=NetVPS" > ${ADM_tmp}/pwd.pwd
        while read service; do
            [[ -z $service ]] && break
            echo "127.0.0.1:$(echo $service|cut -d' ' -f2)=$(echo $service|cut -d' ' -f1)" >> ${ADM_tmp}/pwd.pwd
        done <<< "$(mportas)"
        porta_bind="0.0.0.0:$porta_socket"
        pass_file="${ADM_tmp}/pwd.pwd"
        py="python3"
    else
        py="python3"
    fi

    # Build configuration parameters
    [[ ! -z $porta_bind ]] && conf="-b $porta_bind " || conf="-p $porta_socket "
    [[ ! -z $pass_file ]] && conf+="-p $pass_file "
    [[ ! -z $local ]] && conf+="-l $local "
    [[ ! -z $response ]] && conf+="-r $response "
    [[ ! -z $IP ]] && conf+="-i $IP "
    [[ ! -z $texto_soket ]] && conf+="-t '$texto_soket'"

    # Create systemd service file with proxy type identifier
    cat > /etc/systemd/system/python.${porta_socket}.service <<EOF
[Unit]
Description=$1 Python Proxy Service (Port: ${porta_socket})
After=network.target
StartLimitIntervalSec=0
StartLimitBurst=0

[Service]
Type=simple
User=root
WorkingDirectory=/root
ExecStart=/usr/bin/${py} ${ADM_inst}/$1.py ${conf}
Restart=always
RestartSec=3s
StandardOutput=journal
StandardError=journal
SyslogIdentifier=python-$1-${porta_socket}

# Service metadata for identification
Environment="PROXY_TYPE=$1"
Environment="PROXY_PORT=${porta_socket}"

[Install]
WantedBy=multi-user.target
EOF

    # Enable and start the service
    systemctl daemon-reload &>/dev/null
    systemctl enable python.${porta_socket}.service &>/dev/null
    systemctl start python.${porta_socket}.service &>/dev/null

    # Wait a moment for service to start
    sleep 2

    # Verify service is running
    if systemctl is-active --quiet python.${porta_socket}.service; then
        if [[ $1 = "PGet" ]]; then
            print_center -verd "Gettunel Started Successfully" 
            print_center -azu "Your Gettunel Password is: $(msg -ama "NetVPS")"
            msg -bar3
        fi
        print_center -verd "Python Service Started Successfully on Port ${porta_socket}!!!"
        msg -bar
        print_center -ama "Service: python.${porta_socket}.service"
    else
        print_center -verm "Python Service failed to start"
        msg -bar
        echo "Service status:"
        systemctl status python.${porta_socket}.service --no-pager -l
    fi
    msg -bar
    sleep 3
}

iniciarsocks () {
    # Get list of active python services
    active_ports=$(get_active_services)
    
    # Count active services properly
    if [[ -z "$active_ports" ]]; then
        active_count=0
    else
        active_count=$(echo "$active_ports" | wc -l)
    fi

    # Check individual proxy types
    check_proxy_type_active "PPub" && P1="\033[1;32m[ON]" || P1="\033[1;31m[OFF]"
    check_proxy_type_active "PPriv" && P2="\033[1;32m[ON]" || P2="\033[1;31m[OFF]"
    check_proxy_type_active "PDirect" && P3="\033[1;32m[ON]" || P3="\033[1;31m[OFF]"
    check_proxy_type_active "POpen" && P4="\033[1;32m[ON]" || P4="\033[1;31m[OFF]"
    check_proxy_type_active "PGet" && P5="\033[1;32m[ON]" || P5="\033[1;31m[OFF]"

    clear
    msg -bar
    print_center -ama "PYTHON SOCKS INSTALLER"
    msg -bar
    
    # Show active services if any
    if [[ $active_count -gt 0 ]]; then
        active_list=$(echo "$active_ports" | tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g')
        print_center -ama "Active Services: $active_count"
        print_center -verd "Ports: $active_list"
        msg -bar
    fi
    
    echo -ne "$(msg -verd "  [1]") $(msg -verm2 ">") " && msg -azu "Simple Python Socks      $P1"
    echo -ne "$(msg -verd "  [2]") $(msg -verm2 ">") " && msg -azu "Secure Python Socks      $P2"
    echo -ne "$(msg -verd "  [3]") $(msg -verm2 ">") " && msg -azu "Direct Python Socks      $P3"
    echo -ne "$(msg -verd "  [4]") $(msg -verm2 ">") " && msg -azu "OpenVPN Python Socks     $P4"
    echo -ne "$(msg -verd "  [5]") $(msg -verm2 ">") " && msg -azu "Gettunel Python Socks    $P5"
    msg -bar

    # Count total services (active + inactive)
    all_services=$(get_all_services)
    
    # Count total services properly
    if [[ -z "$all_services" ]]; then
        total_count=0
    else
        total_count=$(echo "$all_services" | wc -l)
    fi
    
    py=6
    
    if [[ $total_count -ge 2 ]]; then
        echo -e "$(msg -verd "  [6]") $(msg -verm2 ">") $(msg -azu "STOP ALL") $(msg -verd "  [7]") $(msg -verm2 ">") $(msg -azu "STOP ONE PORT")"
        py=7
    elif [[ $total_count -eq 1 ]]; then
        echo -e "$(msg -verd "  [6]") $(msg -verm2 ">") $(msg -azu "STOP ALL")"
    else
        echo -e "$(msg -verd "  [6]") $(msg -verm2 ">") $(msg -azu "STOP ALL") $(msg -verm "  [No services running]")"
    fi

    msg -bar
    echo -ne "$(msg -verd "  [0]") $(msg -verm2 ">") " && msg -bra "   \033[1;41m RETURN \033[0m"
    msg -bar

    selection=$(selection_fun ${py})
    case ${selection} in
        1) colector PPub ;;
        2) colector PPriv ;;
        3) colector PDirect ;;
        4) colector POpen ;;
        5) colector PGet ;;
        6) stop_all ;;
        7) stop_port ;;
        0) return 0 ;;
    esac
    return 1
}

# Main execution
check_python || exit 1

# Loop to keep menu active - this matches the pattern in menu_inst.sh
while [[ ${back} != @(0) ]]; do
    iniciarsocks
    back="$?"
    [[ ${back} != @(0|[1]) ]] && msg -azu " Press Enter to continue..." && read foo
done