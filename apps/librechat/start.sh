#!/bin/sh

echo "Starting Tailscale..."
tailscaled --tun=userspace-networking --socks5-server=localhost:1055 &
sleep 3

if [ -n "$TAILSCALE_AUTHKEY" ]; then
    tailscale up --authkey=${TAILSCALE_AUTHKEY} --hostname=librechat-gcp
else
    echo "Warning: TAILSCALE_AUTHKEY not set. Tailscale will not authenticate."
fi

echo "Starting LibreChat..."
npm run backend