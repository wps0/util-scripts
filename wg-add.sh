#!/bin/bash
# CONFIGURABLE VARIABLES
SERVER_ADDR="192.168.1.1"
SERVER_PORT=51820
SERVER_PUBKEY=''

# ~~~~~~~~~~~~~~~~~~~~~~~~

# Source: https://www.oreilly.com/library/view/regular-expressions-cookbook/9780596802837/ch07s16.html
IP_REGEX_PLAIN="((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)"
IP_REGEX="^$IP_REGEX_PLAIN$"
SUBNET_REGEX="(([1-2][0-9])|[0-9]|(3[0-2]))?"
IP_LIST_REGEX="^($IP_REGEX_PLAIN\/$SUBNET_REGEX,\s?)+?$IP_REGEX_PLAIN\/$SUBNET_REGEX$"

INTERFACE_IP=''
IP_LIST=''
PRV_KEY=''
PUB_KEY=''
PSK_KEY=''

ANSI_GREEN='\033[32m'
ANSI_RESET='\033[0m'
ANSI_YELLOW='\033[33m'
ANSI_CYAN='\033[36m'
ANSI_RED='\033[31m'
ANSI_ERROR=$ANSI_RED
ANSI_WARN=$ANSI_YELLOW
ANSI_INFO=$ANSI_CYAN

log_info() {
    echo -e $ANSI_INFO $1 $ANSI_RESET
}

log_warn() {
    echo -e $ANSI_WARN $1 $ANSI_RESET
}

log_error() {
    echo -e $ANSI_ERROR $1 $ANSI_RESET
}

print_section_subheader() {
    echo -e "$ANSI_GREEN✓" $ANSI_RESET "$1"
}

# $1 - IP address string
# $2 - Subnet mask
# Returns: 0 if the addr/mask is correct
is_valid_ip_and_subnet() {
    if [[ $1 =~ $IP_REGEX ]]; then
        return $(($2 < 0 || $2 > 32))
    fi
    return 1
}

# Takes no args
# Returns the selected IP in $IP variable
read_ip() {
    log_info "To abandon entering the IP, enter -1 as an IP."
    ip=''
    smask=''

    until $(is_valid_ip_and_subnet $ip $smask); do
        read -p "Enter IP: " ip
        if [[ $ip == "-1" ]]; then
            exit
        fi

        read -p "Enter subnet mask: " smask

        is_valid_ip_and_subnet $ip $smask
        if [[ $? -ne 0 ]]; then
            log_error "Invalid IP address or subnet mask! Try again or enter -1 to exit.\n"
        fi
    done
    INTERFACE_IP=$ip/$smask
}

read_ip_list() {
    until [[ $ips =~ $IP_LIST_REGEX ]]; do
        read -p "Enter IP list: " ips
        if [[ $ips == "-1" ]]; then
            exit
        fi

        if [[ ! ($ips =~ $IP_LIST_REGEX) ]]; then
            log_error "Invalid IP list! Try again or enter -1 to exit.\n"
        fi
    done

    IP_LIST=$ip
}

gen_key_pair() {
    print_section_subheader "Generating private/public key pair"
    PRV_KEY=$(wg genkey)
    PUB_KEY=$(echo $PRV_KEY | wg pubkey)

    print_section_subheader "Generating PSK key"
    PSK_KEY=$(wg genpsk)
}

gen_client_config() {
    echo "[Interface]
Address = $INTERFACE_IP
ListenPort = 51820
PrivateKey = $PRV_KEY

[Peer]
PublicKey = $SERVER_PUBKEY
PresharedKey = $PSK_KEY
AllowedIPs = $IP_LIST
Endpoint = $SERVER_ADDR:$SERVER_PORT
"
}

gen_server_config_portion() {
    echo "[Peer]
PublicKey = $PUB_KEY
PresharedKey = $PSK_KEY
AllowedIPs = $IP_LIST
"
}

echo "~~~~~~~~~~~~~~~~~~~~~~~~"
echo "  Client configuration  "
echo "~~~~~~~~~~~~~~~~~~~~~~~~"

print_section_subheader "Interface IP"
read_ip
print_section_subheader "Allowed IPs"
read_ip_list
gen_key_pair

print_section_subheader "Server config portion"
gen_server_config_portion

print_section_subheader "Client config"
client_config=$(gen_client_config)
echo "$client_config"

print_section_subheader "Client QR"
qrencode -t ansiutf8 "$client_config"