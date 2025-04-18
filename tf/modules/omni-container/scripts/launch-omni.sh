#!/bin/bash
set -e

OMNI_BIN="/root/omni"
CERT_DIR="/root/certs"
OMNI_ASC="/root/omni.asc"
LOG_FILE="/root/omni.log"
SERVICE_FILE="/etc/systemd/system/omni.service"

cd /root

rm -rf $OMNI_BIN

wget -q "https://github.com/siderolabs/omni/releases/download/v${OMNI_VERSION}/omni-${OMNI_TARGET_PLATFORM}-${OMNI_ARCH}" -O "$OMNI_BIN"
chmod +x "$OMNI_BIN"

mkdir -p /root/omnictl

# Create systemd service file
cat > $SERVICE_FILE << EOF
[Unit]
Description=Omni Service
After=network.target
StartLimitIntervalSec=300
StartLimitBurst=5

[Service]
Type=simple
User=root
WorkingDirectory=/root
Environment=OMNI_VERSION=${OMNI_VERSION}
Environment=OMNI_TARGET_PLATFORM=${OMNI_TARGET_PLATFORM}
Environment=OMNI_ARCH=${OMNI_ARCH}
Environment=OMNI_NAME=${OMNI_NAME}
Environment=OMNI_API_URL=${OMNI_API_URL}
Environment=OMNI_WG_ADDR=${OMNI_WG_ADDR}
Environment=OMNI_AUTH0_DOMAIN=${OMNI_AUTH0_DOMAIN}
Environment=OMNI_AUTH0_CLIENT_ID=${OMNI_AUTH0_CLIENT_ID}
Environment=OMNI_INITIAL_USERS=${OMNI_INITIAL_USERS}
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ExecStartPre=/bin/bash -c 'echo "Starting Omni service with environment:" >> ${LOG_FILE}'
ExecStartPre=/bin/bash -c 'env | grep OMNI_ >> ${LOG_FILE}'
ExecStart=/bin/bash -c 'echo "Executing Omni binary..." >> ${LOG_FILE} && \
  $OMNI_BIN \
  --account-id=$(uuidgen) \
  --name=onprem-omni \
  --cert=${CERT_DIR}/chain.crt \
  --key=${CERT_DIR}/tls.key \
  --machine-api-cert=${CERT_DIR}/chain.crt \
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
  --initial-users=${OMNI_INITIAL_USERS} 2>&1 | tee -a ${LOG_FILE}'
TimeoutStartSec=300
Restart=always
RestartSec=10
StandardOutput=append:${LOG_FILE}
StandardError=append:${LOG_FILE}

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and enable/start the service
systemctl daemon-reload
systemctl enable omni
systemctl start omni

echo "Omni service has been installed and started"
sleep 3
if ! systemctl is-active --quiet omni; then
    echo "⚠️ Omni service failed to start. Check ${LOG_FILE} for details."
    cat ${LOG_FILE}
    exit 1
fi
