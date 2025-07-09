#!/usr/bin/env bash

set -euo pipefail
source common.sh

fetch_json

sudo mkdir -p /etc/wireguard
sudo rm -f /etc/wireguard/wg0.conf

# Generate peer entries.
for i in $(seq 0 $(($1 - 1))); do
  PUBKEY_ARTIFACT_ID=$(get_artifact_id "Auxiliary${i}PubKey")
  fetch_artifact "$PUBKEY_ARTIFACT_ID" "auxpubkey.zip"
  unzip auxpubkey.zip
  export PUBLIC_KEY="$(openssl enc -d -aes-256-cbc -pbkdf2 -iter 20000 -in Auxiliary${i}PubKey.txt -pass env:ENCRYPTION_KEY)"
  cat << EOF >> wg0-primary.conf
[Peer]
PublicKey = $PUBLIC_KEY
AllowedIPs = 192.168.166.$(($i + 2))/32
PersistentKeepalive = 25
EOF
done

sudo cp wg0-primary.conf /etc/wireguard/wg0.conf
rm wg0-primary.conf
sudo chmod 600 /etc/wireguard/wg0.conf

sudo killall nping

sudo wg-quick up wg0

# Start NAT hole punching from our side.
for i in $(seq 0 $(($1 - 1))); do
  recheck_connections
  OLD_CONNECTIONS=$CONNECTIONS

  IP_ARTIFACT_ID=$(get_artifact_id "Auxiliary${i}IP")
  fetch_artifact "$IP_ARTIFACT_ID" "auxip.zip"
  unzip auxip.zip

  IPINFO="$(openssl enc -d -aes-256-cbc -pbkdf2 -iter 20000 -in Auxiliary${i}IP.txt -pass env:ENCRYPTION_KEY)"
  IP=$(echo $IPINFO | cut -d ':' -f1)
  PORT=$(echo $IPINFO | cut -d ':' -f2)

  # Perform the hole punch.
  # TTL is set to 4 to avoid actually delivering the packet all the way (while still being high enough to hole punch).
  sudo nping -v-2 --udp --ttl 4 --no-capture --source-port 1024 --delay 10s --dest-port $PORT $IP &

  until [[ $(($OLD_CONNECTIONS + 1)) -eq $CONNECTIONS ]]; do
    sleep 1
    recheck_connections
  done

  sudo killall nping
done
