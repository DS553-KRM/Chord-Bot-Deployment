#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")"
source ./env

echo "== Systemd status =="
systemctl --no-pager status chord-bot.service || true
systemctl --no-pager status chord-bot-api.service || true

echo "== Listening ports (expect API on ${API_PORT}) =="
ss -tulpn | grep -E ":${API_PORT}\b" || echo "API not detected on port ${API_PORT}"

echo "== Logs (last 50 lines) =="
journalctl -u chord-bot.service -n 50 --no-pager || true
journalctl -u chord-bot-api.service -n 50 --no-pager || true
