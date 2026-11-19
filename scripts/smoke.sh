#!/usr/bin/env bash
set -euo pipefail
context=kind-btm-lab; ns=btm-lab; cid=smoke-baseline-001
kubectl --context "$context" -n "$ns" get deployment/order-service >/dev/null
log=$(mktemp); body=$(mktemp)
cleanup() { [ -n "${forward_pid:-}" ] && kill "$forward_pid" 2>/dev/null || true; rm -f "$log" "$body"; }
trap cleanup EXIT
kubectl --context "$context" -n "$ns" port-forward service/order-service :8080 >"$log" 2>&1 & forward_pid=$!
for _ in $(seq 1 20); do grep -q 'Forwarding from' "$log" && break; sleep 0.25; done
port=$(sed -n 's/.*127.0.0.1:\([0-9][0-9]*\).*/\1/p' "$log" | head -1)
[ -n "$port" ] || { cat "$log" >&2; echo "port-forward did not become ready" >&2; exit 1; }
base="http://127.0.0.1:$port"
happy=$(curl --fail --silent --show-error -X POST -H "X-Correlation-ID: $cid" "$base/orders")
printf '%s' "$happy" | grep -q '"status":"accepted"' && printf '%s' "$happy" | grep -q "$cid" || { echo "happy path response invalid: $happy" >&2; exit 1; }
set +e
status=$(curl --silent --show-error -o "$body" -w '%{http_code}' -X POST -H "X-Correlation-ID: $cid" "$base/orders?fail=payment")
set -e
[ "$status" = 502 ] && grep -q '"failed_dependency":"payment"' "$body" || { echo "controlled failure was not observed (status $status): $(cat "$body")" >&2; exit 1; }
echo "PASS happy path and controlled payment failure"
