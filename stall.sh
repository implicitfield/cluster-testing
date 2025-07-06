#!/usr/bin/env bash

set -euo pipefail
source common.sh

function exit_if_released {
  while read entry; do
    if [[ $(echo "${entry}" | jq ".name" | sed 's/"//g') == "ungoogled-chromium" ]]; then
      exit 0
    fi
  done <<< $(echo "${JSON}" | jq -c '.artifacts.[]')
}

tail -f $HOME/distccd.log &

while true; do
  fetch_json 2>/dev/null
  exit_if_released
  sleep 60
done
