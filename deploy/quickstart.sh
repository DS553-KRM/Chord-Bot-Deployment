#!/usr/bin/env bash
set -Eeuo pipefail

# Idempotent self-restore using public HTTPS
USER="${USER:-$(id -un)}"

sudo mkdir -p /opt/deployment
sudo chown -R "$USER:$USER" /opt/deployment
cd /opt/deployment

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
