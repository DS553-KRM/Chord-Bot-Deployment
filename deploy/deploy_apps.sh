#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")"
source ./env
source ./utils.sh
need_root

ensure_dir "${APP_ROOT}"

# Chord-Bot
clone_or_pull "${CHORD_BOT_REPO_URL}" "${CHORD_BOT_DIR}" "${CHORD_BOT_BRANCH}"
create_venv_and_install "${CHORD_BOT_DIR}" "${CHORD_BOT_VENV}"

# Chord-Bot-Api
clone_or_pull "${CHORD_BOT_API_REPO_URL}" "${CHORD_BOT_API_DIR}" "${CHORD_BOT_API_BRANCH}"
create_venv_and_install "${CHORD_BOT_API_DIR}" "${CHORD_BOT_API_VENV}"
