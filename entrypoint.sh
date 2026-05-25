#!/bin/sh
set -e

# Write configuration for the GooseRelay client
cat > /cfg.json <<EOF
{
  "socks_host": "127.0.0.1",
  "socks_port": 1080,
  "google_host": "${GOOGLE_HOST:-216.239.38.120}",
  "script_keys": ${DEPLOY_IDS:-[]},
  "tunnel_key": "${AUTH_KEY}"
}
EOF

# Start the backend (GooseRelay)
echo "Starting backend service..."
/usr/local/bin/app2 -config /cfg.json &
APP2_PID=$!

# Wait for SOCKS5 port to be ready
sleep 2

# Start the frontend (GOST) – Shadowsocks inbound → SOCKS5 outbound
echo "Starting frontend service..."
/usr/local/bin/app1 -L ss://chacha20-ietf-poly1305:${SS_PASS:-Ronaldo7}@:5000 -F socks5://127.0.0.1:1080 &
APP1_PID=$!

shutdown() {
    echo "Shutting down..."
    kill -TERM $APP2_PID 2>/dev/null
    kill -TERM $APP1_PID 2>/dev/null
    wait $APP2_PID $APP1_PID
    exit 0
}

trap shutdown TERM INT

wait -n $APP2_PID $APP1_PID
exit 1