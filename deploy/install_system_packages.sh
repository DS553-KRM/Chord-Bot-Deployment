#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")"
source ./env
source ./utils.sh
need_root

apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install -y \
  git curl ca-certificates \
  ${PYTHON_BIN} ${PIP_BIN} python3-venv \
  build-essential

# For uvicorn/fastapi you don’t need extra system deps; add if your app needs more (e.g., ffmpeg).
