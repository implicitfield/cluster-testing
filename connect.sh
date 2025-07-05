#!/usr/bin/env bash

set -euo pipefail

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

# Start NAT hole punching.
echo "${JSON}" | jq -c '.artifacts.[]' | while read entry; do
  if [[ $(echo "${entry}" | jq ".name" | sed 's/"//g') == "PrimaryIP" ]]; then
    ARTIFACT_ID=$(echo "${entry}" | jq ".id")
    curl -L \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer $GITHUB_TOKEN" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
        "https://api.github.com/repos/$FULL_REPOSITORY_NAME/actions/artifacts/$ARTIFACT_ID/zip" > primary.zip
    unzip primary.zip
    IP="$(openssl enc -d -aes-256-cbc -pbkdf2 -iter 20000 -in PrimaryIP.txt -k ${ENCRYPTION_KEY})"
    # Perform the hole punch.
    # TTL is set to 4 to avoid actually delivering the packet all the way (while still being high enough to hole punch).
    sudo nping --udp --ttl 4 --no-capture --source-port 1024 --count 20 --delay 28s --dest-port 1024 $IP &
    sudo sed "s/PRIMARY_IP/$IP/" -i /etc/wireguard/wg0.conf
  fi
done

# Wait to make sure we actually sent the ping.
sleep 5

# Try to connect
sudo wg-quick up wg0
