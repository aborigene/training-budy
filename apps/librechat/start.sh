#!/bin/sh

echo "Starting Tailscale daemon..."
tailscaled --tun=userspace-networking --socks5-server=localhost:1055 --socket=/tmp/tailscaled.sock &

# Aguardando daemon
sleep 5

if [ -n "$TAILSCALE_AUTHKEY" ]; then
    echo "Authenticating Tailscale..."
    tailscale --socket=/tmp/tailscaled.sock up --authkey=${TAILSCALE_AUTHKEY} --hostname=librechat-gcp

    echo "Setting up reverse proxy to LibreChat..."
    # O Tailscale recebe tráfego VPN na 3080 e joga na 8080 (a porta raiz onde o Node.js subirá nativamente com a Cloud Run)
    tailscale --socket=/tmp/tailscaled.sock serve --bg --http=3080 http://127.0.0.1:8080
else
    echo "Warning: TAILSCALE_AUTHKEY not set."
fi

echo "Starting LibreChat backend..."
# Liga o node herdando dinamicamente a porta do ambiente (8080) pra satisfazer os healthchecks
npm run backend
