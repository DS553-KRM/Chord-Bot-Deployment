#!/usr/bin/env bash
set -Eeuo pipefail
URL="${1:-http://localhost:8000}"

command -v jq >/dev/null || { echo "Please install jq: sudo apt-get install -y jq"; exit 1; }

echo "[1] HEAD $URL"
curl -sSI "$URL" | head -n 1 || { echo "API not reachable"; exit 2; }

echo "[2] Fetch /config"
cfg="$(curl -sSf "$URL/config")" || { echo "Failed to fetch $URL/config"; exit 3; }

echo "Available endpoints (api_name):"
echo "$cfg" | jq -r '.dependencies[]?.api_name // empty' | nl

# prefer 'predict' (with/without leading slash)
api="$(echo "$cfg" | jq -r '
  (.dependencies[]?.api_name // empty)
  | select(.=="predict" or .=="/predict")
  ' | head -n1)"

# if not found, pick the first non-empty api_name
if [[ -z "$api" ]]; then
  api="$(echo "$cfg" | jq -r '(.dependencies[]?.api_name // empty)' | head -n1)"
fi

if [[ -z "$api" ]]; then
  echo "Could not find any named endpoint in config."; exit 4
fi

# normalize leading slash away (Gradio accepts either, but we'll be explicit)
api="${api#/}"

echo "[3] Using named endpoint: /api/predict/${api}"

for s in "C E" "C,E" "C, E" "C,E,G"; do
  printf "=> %-10s : " "$s"
  # Named-endpoint POST (no fn_index needed)
  curl -sS -X POST "$URL/api/predict/${api}" \
    -H 'Content-Type: application/json' \
    -d "{\"data\":[\"$s\"]}" \
    | jq -r '.data[0] // .detail // .error // .'
done
