#!/usr/bin/env bash
set -Eeuo pipefail
URL="${1:-http://localhost:8000}"

# deps
command -v jq >/dev/null || { echo "Please install jq: sudo apt-get install -y jq"; exit 1; }

echo "[1] HEAD $URL"
curl -sSI "$URL" | head -n 1 || { echo "API not reachable"; exit 2; }

echo "[2] Fetch /config"
cfg="$(curl -sSf "$URL/config")" || { echo "Failed to fetch $URL/config"; exit 3; }

echo "Available endpoints:"
echo "$cfg" | jq -r '.dependencies[] | [.api_name, .fn_index] | @tsv' | nl

# Try to find a predict-like endpoint (handles "predict" or "/predict")
fn="$(echo "$cfg" | jq -r '
  (.dependencies[] | select(.api_name=="predict" or .api_name=="/predict") | .fn_index) // empty
')"

# If still empty, pick the first dependency that has an api_name at all
if [[ -z "$fn" ]]; then
  fn="$(echo "$cfg" | jq -r '
    (.dependencies[] | select(.api_name != null) | .fn_index) // empty
  ')"
fi

# If still empty, last resort: the very first dependency
if [[ -z "$fn" ]]; then
  fn="$(echo "$cfg" | jq -r '.dependencies[0].fn_index // empty')"
fi

if [[ -z "$fn" ]]; then
  echo "Could not determine fn_index from config."; exit 4
fi
echo "[3] Using fn_index=$fn"

# Try several common input formats the app might accept
for s in "C E" "C,E" "C, E" "C,E,G"; do
  printf "=> %-8s : " "$s"
  curl -sS -X POST "$URL/api/predict/" \
    -H 'Content-Type: application/json' \
    -d "{\"data\":[\"$s\"],\"fn_index\":$fn}" \
    | jq -r '.data[0] // .detail // .error // .' || true
done
