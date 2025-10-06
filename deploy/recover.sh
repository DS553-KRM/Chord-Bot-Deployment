#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")"
source ./env
source ./utils.sh
need_root

log "Recovery check starting..."

# Recreate logs if missing
ensure_dir "${CHORD_BOT_LOG_DIR}"
ensure_dir "${CHORD_BOT_API_LOG_DIR}"

# If either app dir is missing, reclone & reinstall
missing=0
[[ -d "${CHORD_BOT_DIR}" ]] || missing=1
[[ -d "${CHORD_BOT_API_DIR}" ]] || missing=1

if [[ "$missing" -eq 1 ]]; then
  log "One or more app directories missing — redeploying..."
  ./deploy_apps.sh
fi

# Always try to pull latest & reinstall requirements (idempotent)
./deploy_apps.sh

# Restart services
log "Restarting services..."
systemctl restart chord-bot.service || true
systemctl restart chord-bot-api.service || true

log "Recovery complete."
