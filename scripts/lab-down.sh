#!/usr/bin/env bash
set -euo pipefail
if ! command -v kind >/dev/null; then echo "kind is not installed; no action taken"; exit 0; fi
if ! docker info >/dev/null 2>&1; then echo "Docker daemon is not reachable; unable to determine whether btm-lab exists. No action taken." >&2; exit 1; fi
if kind get clusters | grep -Fxq btm-lab; then kind delete cluster --name btm-lab; else echo "Cluster btm-lab does not exist; no action taken"; fi
