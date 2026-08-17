FROM ghcr.io/danny-avila/librechat-dev:latest

USER root

# Install tailscale using the official static binary approach to avoid package manager discrepancies
RUN curl -fsSL https://tailscale.com/install.sh | sh

WORKDIR /app

COPY librechat.yaml /app/librechat.yaml
COPY start.sh /app/start.sh

RUN chmod +x /app/start.sh

CMD ["/app/start.sh"]