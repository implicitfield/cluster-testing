#!/usr/bin/env bash
set -euo pipefail

mkdir -p generated
cat << EOF >> generated/start_auxiliary_services.sh
#!/usr/bin/env bash
set -euxo pipefail
source local_port.sh
EOF

for i in $(seq 0 $2); do
cat << EOF >> generated/start_auxiliary_services.sh
if [[ "\$1" -eq $i ]]; then
  export PRIVATE_KEY=\$INSTANCE_${i}_PRIVATE_KEY
fi
EOF
done

# NOTE: Placing the EOF in quotes prevents variable expansion.
cat << 'EOF' >> generated/start_auxiliary_services.sh
sudo mkdir -p /etc/wireguard
sudo rm -f /etc/wireguard/wg0.conf
# Local source port
cat wg0-auxiliary.conf | perl -pe 's/PRIVATE_KEY/$ENV{PRIVATE_KEY}/' | perl -pe 's/LOCAL_PORT/$ENV{LOCAL_PORT}/' | perl -pe 's/PRIMARY_PUBLIC_KEY/$ENV{PRIMARY_PUBLIC_KEY}/' | sudo tee /etc/wireguard/wg0.conf
PATH=/usr/lib/llvm-20/bin:$PATH distccd --daemon --allow-private
IP=$(dig +short txt ch whoami.cloudflare @1.0.0.1 | sed 's/"//g')
# See start_primary_services.sh
echo "::add-mask::$IP"
STUN_OUTPUT="$(stun stun.l.google.com:19302 -v -p $LOCAL_PORT 1 2>&1)"
# External port
OUTPORT=$(echo "$STUN_OUTPUT" | awk '/MappedAddress/ {print $3; exit}' | cut -d ':' -f2)
# Start hole punching to keep the mapping active
sudo nping --udp --ttl 4 --no-capture --source-port $LOCAL_PORT --count 60 --delay 10s --dest-port 1024 3.3.3.3 &
echo $IP:$OUTPORT:$LOCAL_PORT | openssl enc -aes-256-cbc -pbkdf2 -iter 20000 -out "Auxiliary${1}IP.txt" -k "${ENCRYPTION_KEY}"
EOF

chmod +x generated/start_auxiliary_services.sh
cat generated/start_auxiliary_services.sh
