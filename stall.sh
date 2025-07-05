#!/usr/bin/env bash

set -euo pipefail

function fetch_json {
  JSON=$(curl -L \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/$FULL_REPOSITORY_NAME/actions/runs/$RUN_ID/artifacts")
}

function exit_if_released {
  echo "${JSON}" | jq -c '.artifacts.[]' | while read entry; do
    if [[ $(echo "${entry}" | jq ".name" | sed 's/"//g') == "LLVM-20.1.7" ]]; then
      exit 0
    fi
  done
}

while true; do
  fetch_json
  exit_if_released
  sleep 60
done
