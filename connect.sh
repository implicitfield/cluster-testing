#!/usr/bin/env bash

set -euo pipefail

source local_port.sh

function fetch_json {
  JSON=$(curl -L \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/$FULL_REPOSITORY_NAME/actions/runs/$RUN_ID/artifacts")
}

# Wait for all runners to come online (we could wait for just the primary one, but this is easier).
TARGET=$(($1 + 1))
fetch_json
until [[ $(echo "${JSON}" | jq '.total_count') -eq $TARGET ]]; do
  sleep 2
  fetch_json
done

echo "${JSON}" | jq -c '.artifacts.[]' | while read entry; do
  if [[ $(echo "${entry}" | jq ".name" | sed 's/"//g') == "PrimaryIP" ]]; then
    ARTIFACT_ID=$(echo "${entry}" | jq ".id")
    curl -L \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer $GITHUB_TOKEN" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
        "https://api.github.com/repos/$FULL_REPOSITORY_NAME/actions/artifacts/$ARTIFACT_ID/zip" > primary.zip
    unzip primary.zip
    IPINFO="$(openssl enc -d -aes-256-cbc -pbkdf2 -iter 20000 -in PrimaryIP.txt -k ${ENCRYPTION_KEY})"
    IP=$(echo "$IPINFO" | cut -d ':' -f1)
    PORT=$(echo "$IPINFO" | cut -d ':' -f2)
    sudo sed "s/PRIMARY_IP/$IP/" -i /etc/wireguard/wg0.conf
    sudo sed "s/PRIMARY_EXTERNAL_PORT/$PORT/" -i /etc/wireguard/wg0.conf
    sudo nping --udp --ttl 4 --no-capture --source-port $LOCAL_PORT --count 3 --delay 10s --dest-port $PORT $IP
  fi
done

# Wait until the primary server has had a change to ping us (> 10s),
# since we won't be able to connect to it before that.
sleep 15

# Try to connect
sudo wg-quick up wg0
