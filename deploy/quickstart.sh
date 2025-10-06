#!/usr/bin/env bash
set -Eeuo pipefail
ts(){ date +"[%F %T]"; }

REPO_URL="https://github.com/DS553-KRM/Chord-Bot-Deployment.git"
REPO_DIR="/opt/deployment/Chord-Bot-Deployment"
BRANCH="main"

echo "$(ts) [QS] start"
sudo mkdir -p /opt/deployment
sudo chown -R "$USER:$USER" /opt/deployment

if [ -d "$REPO_DIR/.git" ]; then
  echo "$(ts) [QS] repo exists: fast-sync"
  git -C "$REPO_DIR" remote set-url origin "$REPO_URL" || true
  git -C "$REPO_DIR" fetch --depth=1 origin "$BRANCH"
  git -C "$REPO_DIR" reset --hard "origin/$BRANCH"
  git -C "$REPO_DIR" clean -fdx
else
  echo "$(ts) [QS] repo missing or non-git: reclone via tmp+rsync"
  tmpdir="$(mktemp -d)"
  git clone --depth=1 --branch "$BRANCH" "$REPO_URL" "$tmpdir"
  rsync -a --delete "$tmpdir"/ "$REPO_DIR"/
  rm -rf "$tmpdir"
fi

echo "$(ts) [QS] run bootstrap"
chmod +x "$REPO_DIR"/deploy/*.sh
sudo "$REPO_DIR"/deploy/bootstrap.sh
echo "$(ts) [QS] done"
