FROM ghcr.io/danny-avila/librechat-dev:latest

USER root
RUN apt-get update && apt-get install -y tailscale && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY librechat.yaml /app/librechat.yaml
COPY start.sh /app/start.sh

RUN chmod +x /app/start.sh

CMD ["/app/start.sh"]