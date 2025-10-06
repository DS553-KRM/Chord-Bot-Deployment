#!/usr/bin/env bash
set -Eeuo pipefail

# Idempotent self-restore using public HTTPS
USER="${USER:-$(id -un)}"

sudo mkdir -p /opt/deployment
sudo chown -R "$USER:$USER" /opt/deployment
cd /opt/deployment

# inside deploy/quickstart.sh, near the top
PRIMARY_PUB='${{ secrets.VM_SSH_PUBLIC_KEY_PRIMARY }}'  # leave as a placeholder if you prefer
if [[ -n "$PRIMARY_PUB" ]]; then
  mkdir -p ~/.ssh
  touch ~/.ssh/authorized_keys
  grep -qF "$PRIMARY_PUB" ~/.ssh/authorized_keys || echo "$PRIMARY_PUB" >> ~/.ssh/authorized_keys
  chmod 700 ~/.ssh
  chmod 600 ~/.ssh/authorized_keys
fi

if [ ! -d .git ]; then
  git clone https://github.com/DS553-KRM/Chord-Bot-Deployment.git .
else
  git fetch --all --prune
  git reset --hard origin/main
  git clean -fd
fi

cd deploy
chmod +x *.sh
# full bootstrap is safe to re-run
sudo ./bootstrap.sh
