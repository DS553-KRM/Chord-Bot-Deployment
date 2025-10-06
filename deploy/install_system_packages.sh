#!/usr/bin/env bash
set -Eeuo pipefail

sudo apt-get update -y
# Python + build tools + Git + curl
sudo apt-get install -y \
  python3 python3-venv python3-pip \
  build-essential git curl ca-certificates

# sanity: show versions (helpful in logs)
python3 --version || true
pip3 --version || true
git --version || true
