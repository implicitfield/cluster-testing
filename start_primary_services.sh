#!/usr/bin/env bash

# WARNING: Do not add -x (or similar) here, or you'll leak the generated private key.
set -euo pipefail

export PRIVATE_KEY="$(wg genkey)"
PUBLIC_KEY=$(echo "$PRIVATE_KEY" | wg pubkey)
perl -pe 's/PRIVATE_KEY/$ENV{PRIVATE_KEY}/' -i wg0-primary.conf

STUN_OUTPUT="$(stun stun.l.google.com:19302 -v -p 1024 1 2>&1)"
IP=$(dig +short txt ch whoami.cloudflare @1.0.0.1 | sed 's/"//g')
# Hide the IP from the logs, or there wouldn't be much of a point in encrypting it.
echo "::add-mask::$IP"
OUTPORT=$(echo "$STUN_OUTPUT" | awk '/MappedAddress/ {print $3; exit}' | cut -d ':' -f2)
echo "$IP:$OUTPORT:$PUBLIC_KEY" | openssl enc -aes-256-cbc -pbkdf2 -iter 20000 -out PrimaryData.txt -pass env:ENCRYPTION_KEY
sudo nping -v-2 --udp --ttl 4 --no-capture --source-port 1024 --count 60 --delay 10s --dest-port 1024 3.3.3.3 &
