#!/bin/sh

# Inicia o daemon do Tailscale em background explicitando os sockets onde tem acesso de gravação
echo "Starting Tailscale daemon..."
tailscaled --tun=userspace-networking --socks5-server=localhost:1055 --socket=/tmp/tailscaled.sock &

# Aguarda mais tempo para o daemon estabilizar (o Alpine demora um pouco)
sleep 5

if [ -n "$TAILSCALE_AUTHKEY" ]; then
    echo "Authenticating Tailscale..."
    tailscale --socket=/tmp/tailscaled.sock up --authkey=${TAILSCALE_AUTHKEY} --hostname=librechat-gcp --accept-routes
else
    echo "Warning: TAILSCALE_AUTHKEY not set."
fi

echo "Starting LibreChat backend..."
npm run backend
