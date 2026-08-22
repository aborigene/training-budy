#!/bin/sh

# Inicia o daemon do Tailscale no background
echo "Starting Tailscale daemon..."
tailscaled --tun=userspace-networking --socks5-server=localhost:1055 --outbound-http-proxy-listen=localhost:1055 --socket=/tmp/tailscaled.sock &

sleep 5

if [ -n "$TAILSCALE_AUTHKEY" ]; then
    echo "Authenticating Tailscale..."
    tailscale --socket=/tmp/tailscaled.sock up --authkey=${TAILSCALE_AUTHKEY} --hostname=librechat-gcp

    # O Mágico: Faz o Tailscale escutar na rede VPN (porta 3080) e encaminhar direto pro LibreChat local (3080)
        echo "Setting up reverse proxy to LibreChat..."
    tailscale --socket=/tmp/tailscaled.sock serve --bg --http=8080 http://127.0.0.1:3080


else
    echo "Warning: TAILSCALE_AUTHKEY not set."
fi

echo "Starting LibreChat backend..."
PORT=3080 npm run backend
