#!/usr/bin/env bash
set -Eeuo pipefail

# Expect env file beside this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/env"

# Helpers
ts(){ date +"[%F %T]"; }
log(){ echo "$(ts) $*"; }

ensure_dir() {
  sudo mkdir -p "$1"
  sudo chown -R "${RUN_AS_USER}:${RUN_AS_USER}" "$1"
}

sync_repo() {
  local repo_url="$1" dest="$2" branch="$3"
  ensure_dir "$(dirname "$dest")"

  if [[ -d "$dest/.git" ]]; then
    log "[GIT] Updating $dest from $branch"
    sudo -u "${RUN_AS_USER}" git -C "$dest" remote set-url origin "$repo_url" || true
    sudo -u "${RUN_AS_USER}" git -C "$dest" fetch --depth=1 origin "$branch"
    sudo -u "${RUN_AS_USER}" git -C "$dest" reset --hard "origin/$branch"
    sudo -u "${RUN_AS_USER}" git -C "$dest" clean -fdx
  else
    log "[GIT] Fresh clone $repo_url -> $dest"
    # unique tmp dir per call; always clean afterward
    local tmpdir
    tmpdir="$(mktemp -d -t repo.clone.XXXXXXXX)"  # e.g., /tmp/repo.clone.ABC12345
    trap 'rm -rf "$tmpdir"' RETURN

    # in case mktemp returned an existing non-empty dir (paranoid)
    rm -rf "$tmpdir" && mkdir -p "$tmpdir"

    sudo -u "${RUN_AS_USER}" git clone --depth=1 --branch "$branch" "$repo_url" "$tmpdir/repo"
    rsync -a --delete "$tmpdir/repo"/ "$dest"/
    sudo chown -R "${RUN_AS_USER}:${RUN_AS_USER}" "$dest"
  fi
}


ensure_venv_and_requirements() {
  local app_dir="$1" venv_dir="$2"

  log "[PY] Ensure venv at $venv_dir"
  ensure_dir "$app_dir"
  # Create venv if missing
  if [[ ! -x "$venv_dir/bin/python" ]]; then
    sudo -u "${RUN_AS_USER}" python3 -m venv "$venv_dir"
  fi

  # Upgrade pip tooling (inside venv)
  sudo -u "${RUN_AS_USER}" bash -lc "
    source '$venv_dir/bin/activate'
    python -V
    pip install --upgrade pip setuptools wheel
  "

  # Install requirements.txt if present
  if [[ -f "$app_dir/requirements.txt" ]]; then
    log "[PY] Installing requirements for $app_dir"
    sudo -u "${RUN_AS_USER}" bash -lc "
      source '$venv_dir/bin/activate'
      pip install -r '$app_dir/requirements.txt'
    "
  else
    log "[PY] No requirements.txt in $app_dir (skipping)"
  fi
}

# --------------------
# Chord-Bot (local UI)
# --------------------
log "[APP] Sync Chord-Bot"
sync_repo "$CHORD_BOT_REPO_URL" "$CHORD_BOT_DIR" "$CHORD_BOT_BRANCH"
ensure_dir "$CHORD_BOT_LOG_DIR"
ensure_venv_and_requirements "$CHORD_BOT_DIR" "$CHORD_BOT_VENV"

# --------------------
# Chord-Bot-API (Gradio/FastAPI)
# --------------------
log "[APP] Sync Chord-Bot-API"
sync_repo "$CHORD_BOT_API_REPO_URL" "$CHORD_BOT_API_DIR" "$CHORD_BOT_API_BRANCH"
ensure_dir "$CHORD_BOT_API_LOG_DIR"
ensure_venv_and_requirements "$CHORD_BOT_API_DIR" "$CHORD_BOT_API_VENV"

log "[DONE] Apps deployed with isolated virtualenvs."
