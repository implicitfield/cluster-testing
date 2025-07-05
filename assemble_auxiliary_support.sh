#!/usr/bin/env bash
set -euo pipefail
mkdir -p generated
cat << EOF >> generated/start_auxiliary_services.sh
#!/usr/bin/env bash
set -euo pipefail
EOF

for i in $(seq 0 $2); do
cat << EOF >> generated/start_auxiliary_services.sh
if [[ "\$1" -eq $i ]]; then
  export PRIVATE_KEY=\$INSTANCE_${i}_PRIVATE_KEY
fi
EOF
done

cat << EOF >> generated/start_auxiliary_services.sh
sudo mkdir -p /etc/wireguard
sudo rm -f /etc/wireguard/wg0.conf
cat wg0-auxiliary.conf | perl -pe 's/PRIVATE_KEY/\$ENV{PRIVATE_KEY}/' | perl -pe 's/PRIMARY_PUBLIC_KEY/\$ENV{PRIMARY_PUBLIC_KEY}/' | sudo tee /etc/wireguard/wg0.conf
distccd --daemon --allow-private
IP=\$(dig +short txt ch whoami.cloudflare @1.0.0.1 | sed 's/"//g')
# See start_primary_services.sh
echo "::add-mask::\$IP"
echo \$IP | openssl enc -aes-256-cbc -pbkdf2 -iter 20000 -out "Auxiliary${1}IP.txt" -k "\${ENCRYPTION_KEY}"
EOF
chmod +x generated/start_auxiliary_services.sh
cat generated/start_auxiliary_services.sh
