#!/usr/bin/env bash
set -Eeuo pipefail

log() { echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] $*"; }

need_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "Run as root (use: sudo $0)"; exit 1
  fi
}

ensure_dir() {
  local d="$1"
  sudo mkdir -p "$d"
  sudo chown -R "${RUN_AS_USER}:${RUN_AS_USER}" "$d"
}

clone_or_pull() {
  local url="$1" dest="$2" branch="${3:-main}"
  if [[ -d "$dest/.git" ]]; then
    log "Pulling $dest (branch: $branch)"
    sudo -u "${RUN_AS_USER}" git -C "$dest" remote set-url origin "$url" || true
    sudo -u "${RUN_AS_USER}" git -C "$dest" fetch --all --prune || true
    sudo -u "${RUN_AS_USER}" git -C "$dest" checkout "$branch" 2>/dev/null || \
      sudo -u "${RUN_AS_USER}" git -C "$dest" checkout -B "$branch" || true
    if ! sudo -u "${RUN_AS_USER}" git -C "$dest" pull --ff-only; then
      log "Non-ff in $dest → resetting to origin/${branch} (discarding local changes)"
      sudo -u "${RUN_AS_USER}" git -C "$dest" fetch origin "$branch" --prune || true
      sudo -u "${RUN_AS_USER}" git -C "$dest" reset --hard "origin/${branch}"
      sudo -u "${RUN_AS_USER}" git -C "$dest" clean -fd
    fi
  else
    log "Cloning $url → $dest (branch: $branch)"
    sudo -u "${RUN_AS_USER}" git clone --branch "$branch" --depth 1 "$url" "$dest"
  fi
}

create_venv_and_install() {
  local app_dir="$1" venv_dir="$2"
  sudo -u "${RUN_AS_USER}" "${PYTHON_BIN}" -m venv "$venv_dir"
  sudo -u "${RUN_AS_USER}" bash -lc "source '${venv_dir}/bin/activate' && pip install --upgrade pip"
  if [[ -f "${app_dir}/requirements.txt" ]]; then
    log "Installing requirements for ${app_dir}"
    sudo -u "${RUN_AS_USER}" bash -lc "source '${venv_dir}/bin/activate' && pip install -r '${app_dir}/requirements.txt'"
  fi
  if [[ -f "${app_dir}/pyproject.toml" || -f "${app_dir}/setup.py" ]]; then
    sudo -u "${RUN_AS_USER}" bash -lc "source '${venv_dir}/bin/activate' && pip install -e '${app_dir}'"
  fi
}
