#!/usr/bin/env bash

set -euo pipefail
source common.sh
source local_port.sh

function fetch_jobs_json {
  JOBS_JSON=$(curl -L \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/$FULL_REPOSITORY_NAME/actions/runs/$RUN_ID/attempts/$RUN_ATTEMPT/jobs")
}

if [[ "$1" -eq 0 ]]; then
  TARGET_WORKFLOW="Primary"
  TARGET_JOB="Wait for auxiliary runners"
else
  TARGET_WORKFLOW="Auxiliary ($(($1 - 1)))"
  TARGET_JOB="Connect to the primary runner"
fi

READY=0
fetch_jobs_json
until [[ "$READY" -eq 1 ]]; do
  while read entry; do
    if [[ $(echo "${entry}" | jq ".name" | sed 's/"//g' | cut -d '/' -f1 | awk '{$1=$1;print}') == "$TARGET_WORKFLOW" ]]; then
      while read step; do
        if [[ $(echo "${step}" | jq ".name" | sed 's/"//g') == "$TARGET_JOB" && $(echo "${step}" | jq ".status" | sed 's/"//g') == "completed" ]]; then
          READY=1
          if [[ $(echo "${step}" | jq ".conclusion" | sed 's/"//g') != "success" ]]; then
            echo "ERROR: Target stage failed, exiting" >&2
            exit 1
          fi
        fi
      done <<< $(echo "${entry}" | jq -c '.steps.[]')
    fi
  done <<< $(echo "${JOBS_JSON}" | jq -c '.jobs.[]')
  if [[ "$READY" -ne 1 ]]; then
    sleep 2
    fetch_jobs_json
  fi
done

fetch_json

PUBKEY_ARTIFACT_ID=$(get_artifact_id "PrimaryPubKey")
fetch_artifact "$PUBKEY_ARTIFACT_ID" "primarypubkey.zip"
unzip primarypubkey.zip
PRIMARY_PUBLIC_KEY="$(openssl enc -d -aes-256-cbc -pbkdf2 -iter 20000 -in PrimaryPubKey.txt -pass env:ENCRYPTION_KEY)"

IP_ARTIFACT_ID=$(get_artifact_id "PrimaryIP")
fetch_artifact "$IP_ARTIFACT_ID" "primaryip.zip"
unzip primaryip.zip
IPINFO="$(openssl enc -d -aes-256-cbc -pbkdf2 -iter 20000 -in PrimaryIP.txt -pass env:ENCRYPTION_KEY)"
IP=$(echo "$IPINFO" | cut -d ':' -f1)
PORT=$(echo "$IPINFO" | cut -d ':' -f2)
sudo IP="$IP" perl -pe 's/PRIMARY_IP/$ENV{IP}/' -i /etc/wireguard/wg0.conf
sudo PORT="$PORT" perl -pe 's/PRIMARY_EXTERNAL_PORT/$ENV{PORT}/' -i /etc/wireguard/wg0.conf
sudo PRIMARY_PUBLIC_KEY="$PRIMARY_PUBLIC_KEY" perl -pe 's/PRIMARY_PUBLIC_KEY/$ENV{PRIMARY_PUBLIC_KEY}/' -i /etc/wireguard/wg0.conf

# Wait until the primary server has had a change to ping us (> 10s),
# since we won't be able to connect to it before that.
sleep 15

# Try to connect
sudo wg-quick up wg0
