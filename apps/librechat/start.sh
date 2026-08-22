#!/bin/sh

echo "Starting LibreChat backend..."
# Lançamos o Node em background primeiro (para que as portas fiquem vivas)
PORT=8080 npm run backend &

sleep 5

echo "Starting Tailscale daemon..."
tailscaled --tun=userspace-networking --socks5-server=localhost:1055 --outbound-http-proxy-listen=localhost:1055 --socket=/tmp/tailscaled.sock &

sleep 5

if [ -n "$TAILSCALE_AUTHKEY" ]; then
    echo "Authenticating Tailscale..."
    tailscale --socket=/tmp/tailscaled.sock up --authkey=${TAILSCALE_AUTHKEY} --hostname=librechat-gcp
    
    echo "Setting up reverse proxy to LibreChat..."
    # Configura proxy HTTP super rápido do Tailscale que escuta na porta padrão e roda pro Node
    tailscale --socket=/tmp/tailscaled.sock serve --bg http://127.0.0.1:8080
else
    echo "Warning: TAILSCALE_AUTHKEY not set."
fi

# Mantém o contêiner vivo amarrado ao log do Node
wait
