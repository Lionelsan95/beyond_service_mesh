#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd); out="$root/docs/diagrams/rendered"; mkdir -p "$out"
docker info >/dev/null || { echo "Docker daemon is required to render diagrams; no derived assets were created." >&2; exit 1; }
for file in "$root"/docs/diagrams/*.mmd; do base=$(basename "$file" .mmd); docker run --rm -u "$(id -u):$(id -g)" -v "$root/docs/diagrams:/data:rw" ghcr.io/mermaid-js/mermaid-cli:11.12.0 -i "/data/$base.mmd" -o "/data/rendered/$base.svg" -b transparent; docker run --rm -u "$(id -u):$(id -g)" -v "$root/docs/diagrams:/data:rw" ghcr.io/mermaid-js/mermaid-cli:11.12.0 -i "/data/$base.mmd" -o "/data/rendered/$base.png" -b transparent -w 2400; done
