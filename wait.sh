#!/usr/bin/env bash

set -euxo pipefail

function fetch_json {
  JSON=$(curl -L \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/$FULL_REPOSITORY_NAME/actions/runs/$RUN_ID/artifacts")
}

function recheck_connections {
  CONNECTIONS="$(sudo wg show | grep 'latest handshake' | wc -l | tr -d ' ')" || true
}

# Wait for auxiliary runners to come online (if they haven't already done so).
TARGET=$(($1 + 1))
fetch_json
until [[ $(echo "${JSON}" | jq '.total_count') -eq $TARGET ]]; do
  sleep 2
  fetch_json
done

# Start NAT hole punching from our side.
for i in $(seq 0 $(($1 - 1))); do
  echo "${JSON}" | jq -c '.artifacts.[]' | while read entry; do
    if [[ $(echo "${entry}" | jq ".name" | sed 's/"//g') == "Auxiliary${i}IP" ]]; then
      recheck_connections
      OLD_CONNECTIONS=$CONNECTIONS
      ARTIFACT_ID=$(echo "${entry}" | jq ".id")
      curl -L \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer $GITHUB_TOKEN" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
          "https://api.github.com/repos/$FULL_REPOSITORY_NAME/actions/artifacts/$ARTIFACT_ID/zip" > auxip.zip
      unzip auxip.zip
      IPINFO="$(openssl enc -d -aes-256-cbc -pbkdf2 -iter 20000 -in Auxiliary${i}IP.txt -k ${ENCRYPTION_KEY})"
      IP=$(echo $IPINFO | cut -d ':' -f1)
      PORT=$(echo $IPINFO | cut -d ':' -f2)
      # Perform the hole punch.
      # TTL is set to 4 to avoid actually delivering the packet all the way (while still being high enough to hole punch).
      sudo nping --udp --ttl 4 --no-capture --source-port 1024 --count 60 --delay 10s --dest-port $PORT $IP &
      until [[ $(($OLD_CONNECTIONS + 1)) -eq $CONNECTIONS ]]; do
        sudo wg show
        sleep 1
        recheck_connections
      done
      sudo killall nping
    fi
  done
done
