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
