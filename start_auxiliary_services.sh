#!/usr/bin/env bash

# WARNING: Do not add -x (or similar) here, or you'll leak the generated private key.
set -euo pipefail

source common.sh
source local_port.sh

sudo mkdir -p /etc/wireguard
sudo rm -f /etc/wireguard/wg0.conf

export IP_ON_PRIMARY="192.168.166.$((2 + $1))"

export PRIVATE_KEY="$(wg genkey)"
PUBLIC_KEY="$(echo $PRIVATE_KEY | wg pubkey)"

sudo touch /etc/wireguard/wg0.conf
sudo chmod 600 /etc/wireguard/wg0.conf

cat wg0-auxiliary.conf | \
  perl -pe 's/PRIVATE_KEY/$ENV{PRIVATE_KEY}/' | \
  perl -pe 's/LOCAL_PORT/$ENV{LOCAL_PORT}/' | \
  perl -pe 's/IP_ON_PRIMARY/$ENV{IP_ON_PRIMARY}/' | \
  sudo tee -a /etc/wireguard/wg0.conf > /dev/null

rm wg0-auxiliary.conf

export DISTCC_CMDLIST=$PWD/DISTCC_CMDLIST
distccd --daemon --allow-private --log-level=notice --log-file $HOME/distccd.log

IP=$(dig +short txt ch whoami.cloudflare @1.0.0.1 | sed 's/"//g')
# See start_primary_services.sh
echo "::add-mask::$IP"

STUN_OUTPUT="$(stun stun.l.google.com:19302 -v -p $LOCAL_PORT 1 2>&1)"
# External port
OUTPORT=$(echo "$STUN_OUTPUT" | awk '/MappedAddress/ {print $3; exit}' | cut -d ':' -f2)

# Start hole punching to keep the mapping active
sudo nping -v-2 --udp --ttl 4 --no-capture --source-port $LOCAL_PORT --count 60 --delay 10s --dest-port 1024 3.3.3.3 &
echo $IP:$OUTPORT:$PUBLIC_KEY | openssl enc -aes-256-cbc -pbkdf2 -iter 20000 -out "Auxiliary${1}Data.txt" -pass env:ENCRYPTION_KEY
