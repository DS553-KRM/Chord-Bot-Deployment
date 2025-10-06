#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")"
source ./env
source ./utils.sh
need_root

log "Updating apt and installing base packages..."
./install_system_packages.sh

log "Configuring optional SSH keys (array: SSH_PUBKEYS)..."
if declare -p SSH_PUBKEYS >/dev/null 2>&1 && [[ "${#SSH_PUBKEYS[@]}" -gt 0 ]]; then
  sudo -u "${RUN_AS_USER}" mkdir -p "/home/${RUN_AS_USER}/.ssh"
  sudo touch "/home/${RUN_AS_USER}/.ssh/authorized_keys"
  sudo chmod 700 "/home/${RUN_AS_USER}/.ssh"
  sudo chmod 600 "/home/${RUN_AS_USER}/.ssh/authorized_keys"
  for key in "${SSH_PUBKEYS[@]}"; do
    [[ -z "${key// }" ]] && continue
    if ! sudo grep -qxF -- "$key" "/home/${RUN_AS_USER}/.ssh/authorized_keys"; then
      echo "$key" | sudo tee -a "/home/${RUN_AS_USER}/.ssh/authorized_keys" >/dev/null
    fi
  done
  sudo chown "${RUN_AS_USER}:${RUN_AS_USER}" "/home/${RUN_AS_USER}/.ssh/authorized_keys"
fi
log "Creating log dirs..."
ensure_dir "${CHORD_BOT_LOG_DIR}"
ensure_dir "${CHORD_BOT_API_LOG_DIR}"

log "Cloning and building apps..."
./deploy_apps.sh

log "Setting up systemd services..."
./configure_systemd.sh

log "Enabling automated recovery (timer + service)..."
sudo cp -f ../services/chord-bot-recover.service /etc/systemd/system/
sudo cp -f ../services/chord-bot-recover.timer /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now chord-bot-recover.timer

log "Starting apps..."
sudo systemctl enable --now chord-bot.service
sudo systemctl enable --now chord-bot-api.service

log "Bootstrap complete."
#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")"
source ./env
source ./utils.sh
need_root

log "Updating apt and installing base packages..."
./install_system_packages.sh

log "Configuring optional SSH key (if provided)..."
if declare -p SSH_PUBKEYS >/dev/null 2>&1 && [[ "${#SSH_PUBKEYS[@]}" -gt 0 ]]; then
  sudo -u "${RUN_AS_USER}" mkdir -p "/home/${RUN_AS_USER}/.ssh"
  sudo touch "/home/${RUN_AS_USER}/.ssh/authorized_keys"
  sudo chmod 700 "/home/${RUN_AS_USER}/.ssh"
  sudo chmod 600 "/home/${RUN_AS_USER}/.ssh/authorized_keys"
  for key in "${SSH_PUBKEYS[@]}"; do
    [[ -z "${key// }" ]] && continue
    if ! sudo grep -qxF -- "$key" "/home/${RUN_AS_USER}/.ssh/authorized_keys"; then
      echo "$key" | sudo tee -a "/home/${RUN_AS_USER}/.ssh/authorized_keys" >/dev/null
    fi
  done
  sudo chown "${RUN_AS_USER}:${RUN_AS_USER}" "/home/${RUN_AS_USER}/.ssh/authorized_keys"
fi
log "Creating log dirs..."
ensure_dir "${CHORD_BOT_LOG_DIR}"
ensure_dir "${CHORD_BOT_API_LOG_DIR}"

log "Cloning and building apps..."
./deploy_apps.sh

log "Setting up systemd services..."
./configure_systemd.sh

log "Enabling automated recovery (timer + service)..."
sudo cp -f ../services/chord-bot-recover.service /etc/systemd/system/
sudo cp -f ../services/chord-bot-recover.timer /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now chord-bot-recover.timer

log "Starting apps..."
sudo systemctl enable --now chord-bot.service
sudo systemctl enable --now chord-bot-api.service

log "Bootstrap complete."
