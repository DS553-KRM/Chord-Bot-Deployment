#!/usr/bin/env bash
set -Eeuo pipefail
URL="${1:-http://localhost:8000}"
cfg="$(curl -sSf "$URL/config")"
fn=$(echo "$cfg" | jq -r '.dependencies[] | select(.api_name=="/predict") | .fn_index')
echo "[fn_index=$fn]"
for s in "C E" "C,E" "C,E,G"; do
  printf "=> %-10s : " "$s"
  curl -sSf -X POST "$URL/api/predict/" -H 'Content-Type: application/json' \
    -d "{\"data\":[\"$s\"],\"fn_index\":$fn}" | jq -r '.data[0] // .'
done
