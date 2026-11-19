#!/usr/bin/env bash
set -u
failed=0
need() { if command -v "$1" >/dev/null 2>&1; then echo "PASS $1: $(command -v "$1")"; else echo "FAIL $1 is required. Install it, then retry."; failed=1; fi; }
for tool in docker kind kubectl make git curl; do need "$tool"; done
if command -v docker >/dev/null 2>&1; then docker info >/dev/null 2>&1 && echo "PASS Docker daemon reachable" || { echo "FAIL Docker daemon is not reachable. Start Docker before lab-up."; failed=1; }; fi
if command -v kind >/dev/null 2>&1; then kind version; fi
if command -v kubectl >/dev/null 2>&1; then kubectl version --client --short 2>/dev/null || kubectl version --client; fi
avail_kb=$(df -Pk . | awk 'NR==2 {print $4}'); if [ "$avail_kb" -ge 10485760 ]; then echo "PASS disk: at least 10 GiB free"; else echo "WARN disk: less than estimated 10 GiB free"; fi
mem_kb=$(awk '/MemAvailable:/ {print $2}' /proc/meminfo 2>/dev/null || echo 0); if [ "$mem_kb" -ge 6291456 ]; then echo "PASS memory: at least 6 GiB available"; else echo "WARN memory: less than estimated 6 GiB available"; fi
exit "$failed"
