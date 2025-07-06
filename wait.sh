#!/usr/bin/env bash

set -euxo pipefail
source common.sh

# Wait for auxiliary runners to come online (if they haven't already done so).
TARGET=$((($1 * 2) + 1))
fetch_json
until [[ $(echo "${JSON}" | jq '.total_count') -eq $TARGET ]]; do
  sleep 2
  fetch_json
done

function get_artifact_id {
  while read entry; do
    if [[ $(echo "${entry}" | jq ".name" | sed 's/"//g') == "$1" ]]; then
      echo "${entry}" | jq ".id"
    fi
  done <<< $(echo "${JSON}" | jq -c '.artifacts.[]')
}

function fetch_artifact {
  curl -L \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
      "https://api.github.com/repos/$FULL_REPOSITORY_NAME/actions/artifacts/$1/zip" > "$2"
}

sudo mkdir -p /etc/wireguard
sudo rm -f /etc/wireguard/wg0.conf
perl -pe 's/PRIVATE_KEY/$ENV{PRIMARY_PRIVATE_KEY}/' -i wg0-primary.conf

# Generate peer entries.
for i in $(seq 0 $(($1 - 1))); do
  PUBKEY_ARTIFACT_ID=$(get_artifact_id "Auxiliary${i}PubKey")
  fetch_artifact "$PUBKEY_ARTIFACT_ID" "auxpubkey.zip"
  unzip auxpubkey.zip
  export PUBLIC_KEY="$(openssl enc -d -aes-256-cbc -pbkdf2 -iter 20000 -in Auxiliary${i}PubKey.txt -k ${ENCRYPTION_KEY})"
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

sudo wg-quick up wg0

# Start NAT hole punching from our side.
for i in $(seq 0 $(($1 - 1))); do
  recheck_connections
  OLD_CONNECTIONS=$CONNECTIONS

  IP_ARTIFACT_ID=$(get_artifact_id "Auxiliary${i}IP")
  fetch_artifact "$IP_ARTIFACT_ID" "auxip.zip"
  unzip auxip.zip

  IPINFO="$(openssl enc -d -aes-256-cbc -pbkdf2 -iter 20000 -in Auxiliary${i}IP.txt -k ${ENCRYPTION_KEY})"
  IP=$(echo $IPINFO | cut -d ':' -f1)
  PORT=$(echo $IPINFO | cut -d ':' -f2)

  # Perform the hole punch.
  # TTL is set to 4 to avoid actually delivering the packet all the way (while still being high enough to hole punch).
  sudo nping --udp --ttl 4 --no-capture --source-port 1024 --delay 10s --dest-port $PORT $IP &

  until [[ $(($OLD_CONNECTIONS + 1)) -eq $CONNECTIONS ]]; do
    sudo wg show
    sleep 1
    recheck_connections
  done

  sudo killall nping
done
