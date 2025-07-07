#!/usr/bin/env bash

set -euo pipefail
source common.sh

function exit_if_released {
  echo "${JSON}" | jq -c '.artifacts.[]' | while read entry; do
    if [[ $(echo "${entry}" | jq ".name" | sed 's/"//g') == "LLVM-20.1.7" ]]; then
      exit 0
    fi
  done
}

tail -f $HOME/distccd.log &

while true; do
  fetch_json 2>/dev/null
  exit_if_released
  sleep 60
done
