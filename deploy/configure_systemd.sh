#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")"
source ./env
source ./utils.sh
need_root

# Render unit files from templates by replacing placeholders (simple sed)
render() {
  local src="$1" dst="$2"
  sed -e "s|{{RUN_AS_USER}}|${RUN_AS_USER}|g" \
      -e "s|{{CHORD_BOT_DIR}}|${CHORD_BOT_DIR}|g" \
      -e "s|{{CHORD_BOT_VENV}}|${CHORD_BOT_VENV}|g" \
      -e "s|{{CHORD_BOT_START_CMD}}|${CHORD_BOT_START_CMD}|g" \
      -e "s|{{CHORD_BOT_LOG_DIR}}|${CHORD_BOT_LOG_DIR}|g" \
      -e "s|{{CHORD_BOT_API_DIR}}|${CHORD_BOT_API_DIR}|g" \
      -e "s|{{CHORD_BOT_API_VENV}}|${CHORD_BOT_API_VENV}|g" \
      -e "s|{{CHORD_BOT_API_START_CMD}}|${CHORD_BOT_API_START_CMD}|g" \
      -e "s|{{CHORD_BOT_API_LOG_DIR}}|${CHORD_BOT_API_LOG_DIR}|g" \
      < "$src" > "$dst"
}

render ../services/chord-bot.service /etc/systemd/system/chord-bot.service
render ../services/chord-bot-api.service /etc/systemd/system/chord-bot-api.service

sudo systemctl daemon-reload
