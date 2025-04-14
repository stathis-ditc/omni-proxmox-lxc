#!/bin/bash
set -e

OMNI_BIN="/root/omni"
CERT_DIR="/root/certs"
OMNI_ASC="/root/omni.asc"
LOG_FILE="/root/omni.log"

cd /root

rm -rf $OMNI_BIN

wget -q "https://github.com/siderolabs/omni/releases/download/v${OMNI_VERSION}/omni-${OMNI_TARGET_PLATFORM}-${OMNI_ARCH}" -O "$OMNI_BIN"
chmod +x "$OMNI_BIN"

mkdir -p /root/omnictl

echo "Run Omni in the background, detach from SSH session"
nohup  "$OMNI_BIN" \
  --account-id=$(uuidgen) \
  --name=onprem-omni \
  --cert=${CERT_DIR}/tls.crt \
  --key=${CERT_DIR}/tls.key \
  --machine-api-cert=${CERT_DIR}/tls.crt \
  --machine-api-key=${CERT_DIR}/tls.key  \
  --private-key-source=file://${OMNI_ASC} \
  --event-sink-port=8091 \
  --bind-addr=0.0.0.0:443 \
  --machine-api-bind-addr=0.0.0.0:8090 \
  --k8s-proxy-bind-addr=0.0.0.0:8100 \
  --advertised-api-url=${OMNI_API_URL} \
  --siderolink-api-advertised-url=${OMNI_API_URL}:8090 \
  --siderolink-wireguard-advertised-addr=${OMNI_WG_ADDR}:50180 \
  --advertised-kubernetes-proxy-url=${OMNI_API_URL}:8100/ \
  --auth-auth0-enabled=true \
  --auth-auth0-domain=${OMNI_AUTH0_DOMAIN} \
  --auth-auth0-client-id=${OMNI_AUTH0_CLIENT_ID} \
  --initial-users=${OMNI_INITIAL_USERS} > "$LOG_FILE" 2>&1 < /dev/null &

echo "Omni runs in the background"
sleep 3
pgrep -af omni || echo "⚠️ Omni failed to start."
