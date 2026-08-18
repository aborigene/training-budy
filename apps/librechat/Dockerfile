FROM ghcr.io/danny-avila/librechat-dev:latest

USER root

# Instala o Tailscale via gerenciador oficial do Alpine e libera permissões
RUN apk update && \
    apk add --no-cache tailscale && \
    mkdir -p /var/run/tailscale /var/cache/tailscale /var/lib/tailscale

WORKDIR /app

COPY librechat.yaml /app/librechat.yaml
COPY start.sh /app/start.sh

RUN chmod +x /app/start.sh

CMD ["/app/start.sh"]
