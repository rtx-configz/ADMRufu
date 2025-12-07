#!/bin/bash

funcion_crear(){
    if [[ -e "/swapfile" ]]; then
        title "STOPPING SWAP MEMORY"
        fun_bar 'swapoff -a' 'STOP SWAPFILE  '
        fun_bar 'sed -i '/swap/d' /etc/fstab' 'REMOVE AUTO-RUN '
        fun_bar 'sed -i '/vm.swappiness/d' /etc/sysctl.conf' 'REMOVE PRIORITY  '
        fun_bar 'sysctl -p' 'RELOAD CONFIG   '
        fun_bar 'rm -rf /swapfile' 'REMOVE SWAPFILE '
        msg -bar
        print_center -verd "SWAPFILE STOPPED"
        msg -bar
        read foo
        return
    fi

    memoria=$(dmidecode --type memory | grep ' MB'|awk '{print $2}')
    if [[ "$memoria" -gt "2048" ]]; then
        msg -azu " Your system has more than 2GB of RAM\n Swap memory creation is not necessary" 
        msg -bar
        read foo
        return 1
    fi
    title "INSTALLING SWAP MEMORY"
    fun_bar 'fallocate -l 2G /swapfile' 'CREATE SWAPFILE    '
    #fun_bar "dd if=/dev/zero of=$swap bs=1MB count=2048" 'CREATE SWAPFILE    '
    fun_bar 'ls -lh /swapfile' 'VERIFY SWAPFILE '
    fun_bar 'chmod 600 /swapfile' 'ASSIGN PERMISSIONS  '
    fun_bar 'mkswap /swapfile' 'ASSIGN FORMAT   '
    msg -bar
    print_center -verd "SWAPFILE CREATED SUCCESSFULLY"
    msg -bar
    read foo	
}

funcion_activar(){
    title "ACTIVATE SWAPFILE"
    menu_func "PERMANENT" "UNTIL NEXT REBOOT"
    back
    opcion=$(selection_fun 2)
    case $opcion in
          1)sed -i '/swap/d' $fstab
            echo "$swap none swap sw 0 0" >> $fstab
            swapon $swap
            print_center -verd "SWAPFILE ACTIVE"
            msg -bar
            sleep 2;;
          2)swapon $swap
            print_center -verd "SWAPFILE ACTIVE"
            msg -bar
            sleep 2;;
          0)return;;
    esac
}


funcion_prio(){
    title "SWAP PRIORITY"
    menu_func "10" "20 (recommended)" "30" "40" "50" "60" "70" "80" "90" "100"
    back
    opcion=$(selection_fun 10)
    case $opcion in
        0)return;;
        *)
if [[ $(cat "$sysctl"|grep "vm.swappiness") = "" ]]; then
    echo "vm.swappiness=${opcion}0" >> $sysctl
    sysctl -p &>/dev/null
else
    sed -i '/vm.swappiness=/d' $sysctl
    echo "vm.swappiness=${opcion}0" >> $sysctl
    sysctl -p &>/dev/null
fi
print_center -verd "SWAP PRIORITY SET TO ${opcion}0"
msg -bar
sleep 2;;
    esac
}

while :
do
    title 'SWAP MANAGER By @Rufu99'
    menu_func "CREATE/DEACTIVATE /SWAPFILE" \
    "ACTIVATE SWAP" \
    "SWAP PRIORITY"
    back
    opcion="$(selection_fun 3)"

    case $opcion in
        1)funcion_crear;;
        2)funcion_activar;;
        3)funcion_prio;;
        0)break;;
    esac
    [[ "$?" = "1" ]] && break
done
return 1