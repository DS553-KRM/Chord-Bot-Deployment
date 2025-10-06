#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")"
source ./env
source ./utils.sh
need_root

apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install -y \
  git curl ca-certificates \
  python3 python3-pip python3-venv \
  build-essential

