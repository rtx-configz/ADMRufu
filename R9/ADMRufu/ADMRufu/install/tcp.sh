#!/bin/bash
#19/12/2019
clear
msg -bar 
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
SCPfrm="/etc/ger-frm" && [[ ! -d ${SCPfrm} ]] && mkdir ${SCPfrm}
BARRA1="\e[0;31m--------------------------------------------------------------------\e[0m"
SCPinst="/etc/ger-inst" && [[ ! -d ${SCPfrm} ]] && mkdir ${SCPfrm}
#=================================================
#	System Required: CentOS 6/7,Debian 8/9,Ubuntu 16+
#	Description: BBR+BBR Magic Version+BBRplus+Lotserver
#	Version: 1.3.1
#	Author: Thousand Shadows,cx9208
#	Blog: https://www.94ish.me/
#=================================================

sh_ver="1.3.1"
github="raw.githubusercontent.com/cx9208/Linux-NetSpeed/master"

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[Information]${Font_color_suffix}"
Error="${Red_font_prefix}[Error]${Font_color_suffix}"
Tip="${Green_font_prefix}[Attention]${Font_color_suffix}"

#Install BBR kernel
installbbr(){
    kernel_version="4.11.8"
    if [[ "${release}" == "centos" ]]; then
        rpm --import http://${github}/bbr/${release}/RPM-GPG-KEY-elrepo.org
        yum install -y http://${github}/bbr/${release}/${version}/${bit}/kernel-ml-${kernel_version}.rpm
        yum remove -y kernel-headers
        yum install -y http://${github}/bbr/${release}/${version}/${bit}/kernel-ml-headers-${kernel_version}.rpm
        yum install -y http://${github}/bbr/${release}/${version}/${bit}/kernel-ml-devel-${kernel_version}.rpm
    elif [[ "${release}" == "debian" || "${release}" == "ubuntu" ]]; then
        mkdir bbr && cd bbr
        apt install libssl1.0.0 -y
        #wget https://debian.sipwise.com/debian-security/pool/main/o/openssl/libssl1.0.0_1.0.1t-1+deb8u10_amd64.deb
        #wget http://security.debian.org/debian-security/pool/updates/main/o/openssl/libssl1.0.0_1.0.1t-1+deb8u12_amd64.deb
        wget -N --no-check-certificate http://${github}/bbr/debian-ubuntu/linux-headers-${kernel_version}-all.deb
        wget -N --no-check-certificate http://${github}/bbr/debian-ubuntu/${bit}/linux-headers-${kernel_version}.deb
        wget -N --no-check-certificate http://${github}/bbr/debian-ubuntu/${bit}/linux-image-${kernel_version}.deb
    
        #dpkg -i libssl1.0.0_1.0.1t-1+deb8u10_amd64.deb
        dpkg -i linux-headers-${kernel_version}-all.deb
        dpkg -i linux-headers-${kernel_version}.deb
        dpkg -i linux-image-${kernel_version}.deb
        cd .. && rm -rf bbr
    fi
    detele_kernel
    BBR_grub
    msg -bar
    echo -e "${Tip} After restarting the VPS, run the script again to enable\n${Red_font_prefix} BBR/BBR Magic Version${Font_color_suffix}"
    msg -bar
    stty erase '^H' && read -p "You must restart the VPS before you can enable BBR, restart now? [Y/n] :" yn
    [ -z "${yn}" ] && yn="y"
    if [[ $yn == [Yy] ]]; then
        echo -e "${Info} VPS is restarting ..."
        reboot
    fi
}

#Install BBRplus kernel
installbbrplus(){
    kernel_version="4.14.129-bbrplus"
    if [[ "${release}" == "centos" ]]; then
        wget -N --no-check-certificate https://${github}/bbrplus/${release}/${version}/kernel-${kernel_version}.rpm
        yum install -y kernel-${kernel_version}.rpm
        rm -f kernel-${kernel_version}.rpm
        kernel_version="4.14.129_bbrplus" #fix a bug
    elif [[ "${release}" == "debian" || "${release}" == "ubuntu" ]]; then
        mkdir bbrplus && cd bbrplus
        wget -N --no-check-certificate http://${github}/bbrplus/debian-ubuntu/${bit}/linux-headers-${kernel_version}.deb
        wget -N --no-check-certificate http://${github}/bbrplus/debian-ubuntu/${bit}/linux-image-${kernel_version}.deb
        dpkg -i linux-headers-${kernel_version}.deb
        dpkg -i linux-image-${kernel_version}.deb
        cd .. && rm -rf bbrplus
    fi
    detele_kernel
    BBR_grub
    msg -bar
    echo -e "${Tip} After restarting the VPS, run the script again to enable\n${Red_font_prefix} BBRplus${Font_color_suffix}"
    msg -bar
    stty erase '^H' && read -p "You must restart the VPS before you can enable BBRplus, restart now? [Y/n] :" yn
    [ -z "${yn}" ] && yn="y"
    if [[ $yn == [Yy] ]]; then
        echo -e "${Info} VPS is restarting ..."
        reboot
    fi
}

#Install Lotserver kernel
installlot(){
    if [[ "${release}" == "centos" ]]; then
        rpm --import http://${github}/lotserver/${release}/RPM-GPG-KEY-elrepo.org
        yum remove -y kernel-firmware
        yum install -y http://${github}/lotserver/${release}/${version}/${bit}/kernel-firmware-${kernel_version}.rpm
        yum install -y http://${github}/lotserver/${release}/${version}/${bit}/kernel-${kernel_version}.rpm
        yum remove -y kernel-headers
        yum install -y http://${github}/lotserver/${release}/${version}/${bit}/kernel-headers-${kernel_version}.rpm
        yum install -y http://${github}/lotserver/${release}/${version}/${bit}/kernel-devel-${kernel_version}.rpm
    elif [[ "${release}" == "ubuntu" ]]; then
        bash <(wget --no-check-certificate -qO- "http://${github}/Debian_Kernel.sh")
    elif [[ "${release}" == "debian" ]]; then
        bash <(wget --no-check-certificate -qO- "http://${github}/Debian_Kernel.sh")
    fi
    detele_kernel
    BBR_grub
    msg -bar
    echo -e "${Tip} After restarting the VPS, run the script again to enable\n${Red_font_prefix}Lotserver${Font_color_suffix}"
    msg -bar
    stty erase '^H' && read -p "You need to restart the VPS before you can enable Lotserver, restart now? [Y/n] :" yn
    [ -z "${yn}" ] && yn="y"
    if [[ $yn == [Yy] ]]; then
        echo -e "${Info} VPS is restarting ..."
        reboot
    fi
}

# Enable BBR
startbbr(){
    remove_all
    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    sysctl -p
    echo -e "${Info}BBR started successfully!"
    msg -bar
}

#Enable BBRplus
startbbrplus(){
    remove_all
    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbrplus" >> /etc/sysctl.conf
    sysctl -p
    echo -e "${Info}BBRplus started successfully!"
    msg -bar
}

# Compile and enable BBR magic mod
startbbrmod(){
    remove_all
    if [[ "${release}" == "centos" ]]; then
        yum install -y make gcc
        mkdir bbrmod && cd bbrmod
        wget -N --no-check-certificate http://${github}/bbr/tcp_tsunami.c
        echo "obj-m:=tcp_tsunami.o" > Makefile
        make -C /lib/modules/$(uname -r)/build M=`pwd` modules CC=/usr/bin/gcc
        chmod +x ./tcp_tsunami.ko
        cp -rf ./tcp_tsunami.ko /lib/modules/$(uname -r)/kernel/net/ipv4
        insmod tcp_tsunami.ko
        depmod -a
    else
        apt-get update
        if [[ "${release}" == "ubuntu" && "${version}" = "14" ]]; then
            apt-get -y install build-essential
            apt-get -y install software-properties-common
            add-apt-repository ppa:ubuntu-toolchain-r/test -y
            apt-get update
        fi
        apt-get -y install make gcc
        mkdir bbrmod && cd bbrmod
        wget -N --no-check-certificate http://${github}/bbr/tcp_tsunami.c
        echo "obj-m:=tcp_tsunami.o" > Makefile
        ln -s /usr/bin/gcc /usr/bin/gcc-4.9
        make -C /lib/modules/$(uname -r)/build M=`pwd` modules CC=/usr/bin/gcc-4.9
        install tcp_tsunami.ko /lib/modules/$(uname -r)/kernel
        cp -rf ./tcp_tsunami.ko /lib/modules/$(uname -r)/kernel/net/ipv4
        depmod -a
    fi
    

    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=tsunami" >> /etc/sysctl.conf
    sysctl -p
    cd .. && rm -rf bbrmod
    echo -e "${Info}BBR magic version started successfully!"
    msg -bar
}

# Compile and enable BBR magic mod
startbbrmod_nanqinlang(){
    remove_all
    if [[ "${release}" == "centos" ]]; then
        yum install -y make gcc
        mkdir bbrmod && cd bbrmod
        wget -N --no-check-certificate https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/bbr/centos/tcp_nanqinlang.c
        echo "obj-m := tcp_nanqinlang.o" > Makefile
        make -C /lib/modules/$(uname -r)/build M=`pwd` modules CC=/usr/bin/gcc
        chmod +x ./tcp_nanqinlang.ko
        cp -rf ./tcp_nanqinlang.ko /lib/modules/$(uname -r)/kernel/net/ipv4
        insmod tcp_nanqinlang.ko
        depmod -a
    else
        apt-get update
        if [[ "${release}" == "ubuntu" && "${version}" = "14" ]]; then
            apt-get -y install build-essential
            apt-get -y install software-properties-common
            add-apt-repository ppa:ubuntu-toolchain-r/test -y
            apt-get update
        fi
        apt-get -y install make gcc-4.9
        mkdir bbrmod && cd bbrmod
        wget -N --no-check-certificate https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/bbr/tcp_nanqinlang.c
        echo "obj-m := tcp_nanqinlang.o" > Makefile
        make -C /lib/modules/$(uname -r)/build M=`pwd` modules CC=/usr/bin/gcc-4.9
        install tcp_nanqinlang.ko /lib/modules/$(uname -r)/kernel
        cp -rf ./tcp_nanqinlang.ko /lib/modules/$(uname -r)/kernel/net/ipv4
        depmod -a
    fi
    

    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=nanqinlang" >> /etc/sysctl.conf
    sysctl -p
    echo -e "${Info}BBR magic version started successfully!"
    msg -bar
}

# Enable Lotserver
startlotserver(){
    remove_all
    if [[ "${release}" == "centos" ]]; then
        yum install ethtool
    else
        apt-get update
        apt-get install ethtool
    fi
    bash <(wget --no-check-certificate -qO- https://github.com/MoeClub/lotServer/raw/master/Install.sh) install
    start_menu
}

# Uninstall all acceleration
remove_all(){
    rm -rf bbrmod
    sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
    sed -i '/fs.file-max/d' /etc/sysctl.conf
    sed -i '/net.core.rmem_max/d' /etc/sysctl.conf
    sed -i '/net.core.wmem_max/d' /etc/sysctl.conf
    sed -i '/net.core.rmem_default/d' /etc/sysctl.conf
    sed -i '/net.core.wmem_default/d' /etc/sysctl.conf
    sed -i '/net.core.netdev_max_backlog/d' /etc/sysctl.conf
    sed -i '/net.core.somaxconn/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_syncookies/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_tw_reuse/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_tw_recycle/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_fin_timeout/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_keepalive_time/d' /etc/sysctl.conf
    sed -i '/net.ipv4.ip_local_port_range/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_max_syn_backlog/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_max_tw_buckets/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_rmem/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_wmem/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_mtu_probing/d' /etc/sysctl.conf
    sed -i '/net.ipv4.ip_forward/d' /etc/sysctl.conf
    sed -i '/fs.inotify.max_user_instances/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_syncookies/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_fin_timeout/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_tw_reuse/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_max_syn_backlog/d' /etc/sysctl.conf
    sed -i '/net.ipv4.ip_local_port_range/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_max_tw_buckets/d' /etc/sysctl.conf
    sed -i '/net.ipv4.route.gc_timeout/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_synack_retries/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_syn_retries/d' /etc/sysctl.conf
    sed -i '/net.core.somaxconn/d' /etc/sysctl.conf
    sed -i '/net.core.netdev_max_backlog/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_timestamps/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_max_orphans/d' /etc/sysctl.conf
    if [[ -e /appex/bin/lotServer.sh ]]; then
        bash <(wget --no-check-certificate -qO- https://github.com/MoeClub/lotServer/raw/master/Install.sh) uninstall
    fi
    clear
    echo -e "${Info}: Acceleration has been uninstalled."
    sleep 1s
}

#Optimize system configuration
optimizing_system(){
    sed -i '/fs.file-max/d' /etc/sysctl.conf
    sed -i '/fs.inotify.max_user_instances/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_syncookies/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_fin_timeout/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_tw_reuse/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_max_syn_backlog/d' /etc/sysctl.conf
    sed -i '/net.ipv4.ip_local_port_range/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_max_tw_buckets/d' /etc/sysctl.conf
    sed -i '/net.ipv4.route.gc_timeout/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_synack_retries/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_syn_retries/d' /etc/sysctl.conf
    sed -i '/net.core.somaxconn/d' /etc/sysctl.conf
    sed -i '/net.core.netdev_max_backlog/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_timestamps/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_max_orphans/d' /etc/sysctl.conf
    sed -i '/net.ipv4.ip_forward/d' /etc/sysctl.conf
    echo "fs.file-max = 1000000
fs.inotify.max_user_instances = 8192
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_tw_reuse = 1
net.ipv4.ip_local_port_range = 1024 65000
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.tcp_max_tw_buckets = 6000
net.ipv4.route.gc_timeout = 100
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_synack_retries = 1
net.core.somaxconn = 32768
net.core.netdev_max_backlog = 32768
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_max_orphans = 32768
# forward ipv4
net.ipv4.ip_forward = 1">>/etc/sysctl.conf
    sysctl -p
    echo "*               soft    nofile           1000000
*               hard    nofile          1000000">/etc/security/limits.conf
    echo "ulimit -SHn 1000000">>/etc/profile
    read -p "After applying the configuration to the VPS you need to restart, restart now? [Y/n] :" yn
    msg -bar 
    [ -z "${yn}" ] && yn="y"
    if [[ $yn == [Yy] ]]; then
        echo -e "${Info} VPS restarting..."
        reboot
    fi
}
# Script update
Update_Shell(){
    echo -e "Current version is [ ${sh_ver} ], Starting to detect the latest version..."
    sh_new_ver=$(wget --no-check-certificate -qO- "http://${github}/tcp.sh"|grep 'sh_ver="'|awk -F "=" '{print $NF}'|sed 's/\"//g'|head -1)
    [[ -z ${sh_new_ver} ]] && echo -e "${Error} Error detecting the latest version !" && start_menu
    if [[ ${sh_new_ver} != ${sh_ver} ]]; then
        echo -e "New version discovered [ ${sh_new_ver} ], Whether to update? [Y/n]"
        read -p "(Default: y):" yn
        [[ -z "${yn}" ]] && yn="y"
        if [[ ${yn} == [Yy] ]]; then
            wget -N --no-check-certificate http://${github}/tcp.sh && chmod +x tcp.sh
            echo -e "The script has been updated to the latest version. [ ${sh_new_ver} ] !"
        else
            echo && echo "	Cancelled ..." && echo
        fi
    else
        echo -e "Currently the latest version [ ${sh_new_ver} ] !"
        sleep 5s
    fi
}

# Start menu
start_menu(){
clear
msg -bar
echo -e " TCP Acceleration (BBR/Plus) MOD By @Rufu99 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
$(msg -bar)
 ${Green_font_prefix}0.${Font_color_suffix} Script update
——————————————————Kernel Management—————————————————
 ${Green_font_prefix}1.${Font_color_suffix} Install BBR/BBR Magic Kernel
 ${Green_font_prefix}2.${Font_color_suffix} Install BBRplus Kernel 
 ${Green_font_prefix}3.${Font_color_suffix} Install Lotserver Kernel (Sharp Speed)
——————————————————Acceleration Management——————————————————
 ${Green_font_prefix}4.${Font_color_suffix} Use BBR Acceleration
 ${Green_font_prefix}5.${Font_color_suffix} Use BBR Magic Version Speed
 ${Green_font_prefix}6.${Font_color_suffix} Use BBR Violent Magic Version Acceleration
 ${Green_font_prefix}7.${Font_color_suffix} Use BBRplus Acceleration
 ${Green_font_prefix}8.${Font_color_suffix} Use Lotserver (Sharp Speed) Acceleration
——————————————————Miscellaneous Management——————————————————
 ${Green_font_prefix}9.${Font_color_suffix} Uninstall All Accelerations
 ${Green_font_prefix}10.${Font_color_suffix} System Configuration Optimization.
 ${Green_font_prefix}11.${Font_color_suffix} Exit Script
—————————————————————————————————————————————————————" && msg -bar

    check_status
    if [[ ${kernel_status} == "noinstall" ]]; then
        echo -e " Current status: ${Green_font_prefix}Not installed\n${Font_color_suffix} Accelerated Kernel ${Red_font_prefix}Please install the Kernel first.${Font_color_suffix}"
    else
        echo -e " Current status: ${Green_font_prefix}Installed\n${Font_color_suffix} ${_font_prefix}${kernel_status}${Font_color_suffix} Accelerated Kernel, ${Green_font_prefix}${run_status}${Font_color_suffix}"
        
    fi
msg -bar
read -p " Please enter a number [0-11]:" num
case "$num" in
    0)
    Update_Shell
    ;;
    1)
    check_sys_bbr
    ;;
    2)
    check_sys_bbrplus
    ;;
    3)
    check_sys_Lotsever
    ;;
    4)
    startbbr
    ;;
    5)
    startbbrmod
    ;;
    6)
    startbbrmod_nanqinlang
    ;;
    7)
    startbbrplus
    ;;
    8)
    startlotserver
    ;;
    9)
    remove_all
    ;;
    10)
    optimizing_system
    ;;
    11)
    exit 1
    ;;
    *)
    clear
    echo -e "${Error}: Please enter the correct number [0-11]"
    sleep 5s
    start_menu
    ;;
esac
}
############# Kernel Management Components #############

# Delete redundant kernel
detele_kernel(){
    if [[ "${release}" == "centos" ]]; then
        rpm_total=`rpm -qa | grep kernel | grep -v "${kernel_version}" | grep -v "noarch" | wc -l`
        if [ "${rpm_total}" > "1" ]; then
            echo -e "Detected ${rpm_total} remaining kernels, starting to uninstall ..."
            for((integer = 1; integer <= ${rpm_total}; integer++)); do
                rpm_del=`rpm -qa | grep kernel | grep -v "${kernel_version}" | grep -v "noarch" | head -${integer}`
                echo -e "Starting to uninstall ${rpm_del} kernel ..."
                rpm --nodeps -e ${rpm_del}
                echo -e "Uninstalling ${rpm_del} kernel uninstall completed, continuing ..."
            done
            echo -e "Kernel uninstall completed and continuing ..."
        else
            echo -e " The number of detected kernels is incorrect, please check!" && exit 1
        fi
    elif [[ "${release}" == "debian" || "${release}" == "ubuntu" ]]; then
        deb_total=`dpkg -l | grep linux-image | awk '{print $2}' | grep -v "${kernel_version}" | wc -l`
        if [ "${deb_total}" > "1" ]; then
            echo -e "Detected ${deb_total} remaining kernels, starting to uninstall ..."
            for((integer = 1; integer <= ${deb_total}; integer++)); do
                deb_del=`dpkg -l|grep linux-image | awk '{print $2}' | grep -v "${kernel_version}" | head -${integer}`
                echo -e "Starting to uninstall ${deb_del} kernel ..."
                apt-get purge -y ${deb_del}
                echo -e "Uninstalling ${deb_del} kernel uninstall completed, continuing ..."
            done
            echo -e "Kernel uninstall completed and continuing ..."
        else
            echo -e " The number of detected kernels is incorrect, please check!" && exit 1
        fi
    fi
}

#Update boot
BBR_grub(){
    if [[ "${release}" == "centos" ]]; then
        if [[ ${version} = "6" ]]; then
            if [ ! -f "/boot/grub/grub.conf" ]; then
                echo -e "${Error} /boot/grub/grub.conf not found, please check."
                exit 1
            fi
            sed -i 's/^default=.*/default=0/g' /boot/grub/grub.conf
        elif [[ ${version} = "7" ]]; then
            if [ ! -f "/boot/grub2/grub.cfg" ]; then
                echo -e "${Error} /boot/grub2/grub.cfg not found, please check."
                exit 1
            fi
            grub2-set-default 0
        fi
    elif [[ "${release}" == "debian" || "${release}" == "ubuntu" ]]; then
        /usr/sbin/update-grub
    fi
}

#############Kernel Management Component#############



#############System Detection Components#############

#System inspection
check_sys(){
    if [[ -f /etc/redhat-release ]]; then
        release="centos"
    elif cat /etc/issue | grep -q -E -i "debian"; then
        release="debian"
    elif cat /etc/issue | grep -q -E -i "ubuntu"; then
        release="ubuntu"
    elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
        release="centos"
    elif cat /proc/version | grep -q -E -i "debian"; then
        release="debian"
    elif cat /proc/version | grep -q -E -i "ubuntu"; then
        release="ubuntu"
    elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
        release="centos"
    fi
}

#Check Linux version
check_version(){
    if [[ -s /etc/redhat-release ]]; then
        version=`grep -oE  "[0-9.]+" /etc/redhat-release | cut -d . -f 1`
    else
        version=`grep -oE  "[0-9.]+" /etc/issue | cut -d . -f 1`
    fi
    bit=`uname -m`
    if [[ ${bit} = "x86_64" ]]; then
        bit="x64"
    else
        bit="x32"
    fi
}

#Check system requirements for installing bbr
check_sys_bbr(){
    check_version
    if [[ "${release}" == "centos" ]]; then
        if [[ ${version} -ge "6" ]]; then
            installbbr
        else
            echo -e "${Error} BBR kernel is not compatible with the current system ${release} ${version} ${bit} !" && exit 1
        fi
    elif [[ "${release}" == "debian" ]]; then
        if [[ ${version} -ge "8" ]]; then
            installbbr
        else
            echo -e "${Error} BBR kernel is not compatible with the current system ${release} ${version} ${bit} !" && exit 1
        fi
    elif [[ "${release}" == "ubuntu" ]]; then
        if [[ ${version} -ge "14" ]]; then
            installbbr
        else
            echo -e "${Error} BBR kernel is not compatible with the current system ${release} ${version} ${bit} !" && exit 1
        fi
    else
        echo -e "${Error} BBR kernel is not compatible with the current system ${release} ${version} ${bit} !" && exit 1
    fi
}

check_sys_bbrplus(){
    check_version
    if [[ "${release}" == "centos" ]]; then
        if [[ ${version} -ge "6" ]]; then
            installbbrplus
        else
            echo -e "${Error} BBRplus kernel is not compatible with the current system ${release} ${version} ${bit} !" && exit 1
        fi
    elif [[ "${release}" == "debian" ]]; then
        if [[ ${version} -ge "8" ]]; then
            installbbrplus
        else
            echo -e "${Error} BBRplus kernel is not compatible with the current system ${release} ${version} ${bit} !" && exit 1
        fi
    elif [[ "${release}" == "ubuntu" ]]; then
        if [[ ${version} -ge "14" ]]; then
            installbbrplus
        else
            echo -e "${Error} BBRplus kernel is not compatible with the current system ${release} ${version} ${bit} !" && exit 1
        fi
    else
        echo -e "${Error} BBRplus kernel is not compatible with the current system ${release} ${version} ${bit} !" && exit 1
    fi
}


#Check system requirements for installing Lotsever
check_sys_Lotsever(){
    check_version
    if [[ "${release}" == "centos" ]]; then
        if [[ ${version} == "6" ]]; then
            kernel_version="2.6.32-504"
            installlot
        elif [[ ${version} == "7" ]]; then
            yum -y install net-tools
            kernel_version="3.10.0-327"
            installlot
        else
            echo -e "${Error} Lotsever is not compatible with the current system ${release} ${version} ${bit} !" && exit 1
        fi
    elif [[ "${release}" == "debian" ]]; then
        if [[ ${version} = "7" || ${version} = "8" ]]; then
            if [[ ${bit} == "x64" ]]; then
                kernel_version="3.16.0-4"
                installlot
            elif [[ ${bit} == "x32" ]]; then
                kernel_version="3.2.0-4"
                installlot
            fi
        elif [[ ${version} = "9" ]]; then
            if [[ ${bit} == "x64" ]]; then
                kernel_version="4.9.0-4"
                installlot
            fi
        else
            echo -e "${Error} Lotsever is not compatible with the current system ${release} ${version} ${bit} !" && exit 1
        fi
    elif [[ "${release}" == "ubuntu" ]]; then
        if [[ ${version} -ge "12" ]]; then
            if [[ ${bit} == "x64" ]]; then
                kernel_version="4.4.0-47"
                installlot
            elif [[ ${bit} == "x32" ]]; then
                kernel_version="3.13.0-29"
                installlot
            fi
        else
            echo -e "${Error} Lotsever is not compatible with the current system ${release} ${version} ${bit} !" && exit 1
        fi
    else
        echo -e "${Error} Lotsever is not compatible with the current system ${release} ${version} ${bit} !" && exit 1
    fi
}

check_status(){
    kernel_version=`uname -r | awk -F "-" '{print $1}'`
    kernel_version_full=`uname -r`
    if [[ ${kernel_version_full} = "4.14.129-bbrplus" ]]; then
        kernel_status="BBRplus"
    elif [[ ${kernel_version} = "3.10.0" || ${kernel_version} = "3.16.0" || ${kernel_version} = "3.2.0" || ${kernel_version} = "4.4.0" || ${kernel_version} = "3.13.0"  || ${kernel_version} = "2.6.32" || ${kernel_version} = "4.9.0" ]]; then
        kernel_status="Lotserver"
    elif [[ `echo ${kernel_version} | awk -F'.' '{print $1}'` == "4" ]] && [[ `echo ${kernel_version} | awk -F'.' '{print $2}'` -ge 9 ]] || [[ `echo ${kernel_version} | awk -F'.' '{print $1}'` == "5" ]]; then
        kernel_status="BBR"
    else 
        kernel_status="noinstall"
    fi

    if [[ ${kernel_status} == "Lotserver" ]]; then
        if [[ -e /appex/bin/lotServer.sh ]]; then
            run_status=`bash /appex/bin/lotServer.sh status | grep "LotServer" | awk  '{print $3}'`
            if [[ ${run_status} = "running!" ]]; then
                run_status="Started successfully"
            else 
                run_status="Failed to start"
            fi
        else 
            run_status="No acceleration module installed"
        fi
    elif [[ ${kernel_status} == "BBR" ]]; then
        run_status=`grep "net.ipv4.tcp_congestion_control" /etc/sysctl.conf | awk -F "=" '{print $2}'`
        if [[ ${run_status} == "bbr" ]]; then
            run_status=`lsmod | grep "bbr" | awk '{print $1}'`
            if [[ ${run_status} == "tcp_bbr" ]]; then
                run_status="BBR started successfully"
            else 
                run_status="BBR started successfully"
            fi
        elif [[ ${run_status} == "tsunami" ]]; then
            run_status=`lsmod | grep "tsunami" | awk '{print $1}'`
            if [[ ${run_status} == "tcp_tsunami" ]]; then
                run_status="BBR magic version launched successfully"
            else 
                run_status="BBR magic version startup failed"
            fi
        elif [[ ${run_status} == "nanqinlang" ]]; then
            run_status=`lsmod | grep "nanqinlang" | awk '{print $1}'`
            if [[ ${run_status} == "tcp_nanqinlang" ]]; then
                run_status="BBR violent magic version launched successfully"
            else 
                run_status="BBR violent magic version failed to start"
            fi
        else 
            run_status="No acceleration module installed"
        fi
    elif [[ ${kernel_status} == "BBRplus" ]]; then
        run_status=`grep "net.ipv4.tcp_congestion_control" /etc/sysctl.conf | awk -F "=" '{print $2}'`
        if [[ ${run_status} == "bbrplus" ]]; then
            run_status=`lsmod | grep "bbrplus" | awk '{print $1}'`
            if [[ ${run_status} == "tcp_bbrplus" ]]; then
                run_status="BBRplus started successfully"
            else 
                run_status="BBRplus started successfully"
            fi
        else 
            run_status="No acceleration module installed"
        fi
    fi
}

#############System Detection Components#############
check_sys
check_version
[[ ${release} != "debian" ]] && [[ ${release} != "ubuntu" ]] && [[ ${release} != "centos" ]] && echo -e "${Error} This script is not compatible with the current system. ${release} !" && exit 1
start_menu