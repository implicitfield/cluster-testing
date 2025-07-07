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
    sudo nping --udp --ttl 4 --no-capture --source-port $LOCAL_PORT --count 10 --delay 10s --dest-port $PORT $IP &
  fi
done

# Wait until the primary server has had a change to ping us (> 10s),
# since we won't be able to connect to it before that.
sleep 15

# Try to connect
sudo wg-quick up wg0
