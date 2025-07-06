#!/usr/bin/env bash

set -euo pipefail

STUN_OUTPUT="$(stun stun.l.google.com:19302 -v -p 1024 1 2>&1)"
IP=$(dig +short txt ch whoami.cloudflare @1.0.0.1 | sed 's/"//g')
# Hide the IP from the logs, or there wouldn't be much of a point in encrypting it.
echo "::add-mask::$IP"
OUTPORT=$(echo "$STUN_OUTPUT" | awk '/MappedAddress/ {print $3; exit}' | cut -d ':' -f2)
echo "$IP:$OUTPORT:1024" | openssl enc -aes-256-cbc -pbkdf2 -iter 20000 -out PrimaryIP.txt -k "${ENCRYPTION_KEY}"
