#!/usr/bin/env bash

set -euo pipefail

sudo mkdir -p /etc/wireguard
sudo rm -f /etc/wireguard/wg0.conf
cat wg0-primary.conf | perl -pe 's/PRIVATE_KEY/$ENV{PRIMARY_PRIVATE_KEY}/' | perl -pe 's/INSTANCE_0_PUBLIC_KEY/$ENV{INSTANCE_0_PUBLIC_KEY}/' | sudo tee /etc/wireguard/wg0.conf
sudo wg-quick up wg0
IP=$(dig +short txt ch whoami.cloudflare @1.0.0.1 | sed 's/"//g')
# Hide the IP from the logs, or there wouldn't be much of a point in encrypting it.
echo "::add-mask::$IP"
echo "${IP}" | openssl enc -aes-256-cbc -pbkdf2 -iter 20000 -out PrimaryIP.txt -k "${ENCRYPTION_KEY}"
