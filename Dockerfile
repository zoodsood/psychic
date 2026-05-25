# syntax=docker/dockerfile:1
FROM alpine:3.20 AS builder
RUN apk add --no-cache curl tar gzip ca-certificates

ARG GOST_URL=https://github.com/ginuerzh/gost/releases/download/v2.12.0/gost_2.12.0_linux_amd64.tar.gz
RUN curl -fsSL --retry 5 --retry-delay 2 -o /tmp/gost.tar.gz "$GOST_URL" && \
    tar -xzf /tmp/gost.tar.gz -C /tmp && \
    mv /tmp/gost /tmp/app1 && \
    chmod +x /tmp/app1 && \
    rm /tmp/gost.tar.gz

ARG GOOSE_URL=https://github.com/Kianmhz/GooseRelayVPN/releases/download/v1.7.1/GooseRelayVPN-client-v1.7.1-linux-amd64.tar.gz
RUN curl -fsSL --retry 5 --retry-delay 2 -o /tmp/goose.tar.gz "$GOOSE_URL" && \
    tar -xzf /tmp/goose.tar.gz -C /tmp && \
    # The archive extracts to a folder like "GooseRelayVPN-client-v1.7.1-linux-amd64/"
    mv /tmp/GooseRelayVPN-client-v1.7.1-linux-amd64/goose-client /tmp/app2 && \
    chmod +x /tmp/app2 && \
    rm -rf /tmp/goose.tar.gz /tmp/GooseRelayVPN-client-v1.7.1-linux-amd64

# Final stage
FROM alpine:3.20
RUN apk add --no-cache ca-certificates tzdata

COPY --from=builder /tmp/app1 /usr/local/bin/app1
COPY --from=builder /tmp/app2 /usr/local/bin/app2

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD nc -z 127.0.0.1 1080 || exit 1

ENTRYPOINT ["/entrypoint.sh"]