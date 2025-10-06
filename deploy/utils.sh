cd /opt/deployment/Chord-Bot-Deployment/deploy

cat > utils.sh <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail

log() { echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] $*"; }

need_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "Run as root (use sudo)"; exit 1
  fi
}

ensure_dir() {
  # ensure dir exists and is owned by RUN_AS_USER
  local d="$1"
  sudo mkdir -p "$d"
  sudo chown -R "${RUN_AS_USER}:${RUN_AS_USER}" "$d"
}

clone_or_pull() {
  local url="$1" dest="$2" branch="${3:-main}"
  if [[ -d "$dest/.git" ]]; then
    log "Pulling $dest"
    sudo -u "${RUN_AS_USER}" git -C "$dest" fetch --all
    sudo -u "${RUN_AS_USER}" git -C "$dest" checkout "$branch"
    sudo -u "${RUN_AS_USER}" git -C "$dest" pull --ff-only
  else
    log "Cloning $url to $dest (branch: $branch)"
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
EOF

chmod +x utils.sh
