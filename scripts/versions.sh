#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd); mkdir -p "$root/docs/results"
escape() { printf '%s' "$1" | sed 's/"/\\"/g'; }
{
  echo '{'
  echo "  \"captured_at_utc\": \"$(date -u +%FT%TZ)\","
  for tool in kind kubectl docker git; do
    if command -v "$tool" >/dev/null; then v=$($tool version 2>/dev/null | head -1 || true); printf '  "%s": "%s",\n' "$tool" "$(escape "$v")"; fi
  done
  echo '  "local_images": {'
  images=(btm/order-service:0.1.0 btm/inventory-service:0.1.0 btm/payment-service:0.1.0 btm/notification-service:0.1.0 kindest/node:v1.37.0)
  for i in "${!images[@]}"; do
    image=${images[$i]}; id="unavailable"
    if docker info >/dev/null 2>&1; then id=$(docker image inspect --format '{{.Id}}' "$image" 2>/dev/null || echo unavailable); fi
    comma=','; [ "$i" -eq $((${#images[@]} - 1)) ] && comma=''
    printf '    "%s": "%s"%s\n' "$image" "$id" "$comma"
  done
  echo '  },'
  echo '  "note": "Image IDs are local Docker IDs; node image ID is available only while retained by Docker."'
  echo '}'
} > "$root/docs/results/versions.json"
cat "$root/docs/results/versions.json"
