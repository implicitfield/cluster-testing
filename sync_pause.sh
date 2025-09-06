#!/usr/bin/env bash

set -euo pipefail
source common.sh

# Wait for auxiliary runners to come online (if they haven't already done so).
TARGET=$(($1 + 1))
fetch_json
until [[ $(echo "${JSON}" | jq '.total_count') -eq $TARGET ]]; do
  sleep 2
  fetch_json
done

# Generate peer entries.
for i in $(seq 0 $(($1 - 1))); do
  ARTIFACT_ID=$(get_artifact_id "Auxiliary${i}Data")
  fetch_artifact "$ARTIFACT_ID" "auxdata.zip"
  unzip auxdata.zip
  export PUBLIC_KEY="$(openssl enc -d -aes-256-cbc -pbkdf2 -iter 20000 -in Auxiliary${i}Data.txt -pass env:ENCRYPTION_KEY | cut -d ':' -f3)"
  cat << EOF >> wg0-primary.conf
[Peer]
PublicKey = $PUBLIC_KEY
AllowedIPs = 192.168.166.$(($i + 2))/32
PersistentKeepalive = 25
EOF
done
