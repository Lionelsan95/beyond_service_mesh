#!/usr/bin/env bash
# Runs only request-scoped Scenario 01 experiments; it never edits a workload.
set -euo pipefail
export LC_ALL=C
mode=${1:?usage: scenario-01-experiment.sh healthy|latency|failure|recovery|network}
context=kind-btm-lab; ns=btm-lab; samples=${SAMPLES:-20}; delay_ms=${PAYMENT_DELAY_MS:-300}
root=$(cd "$(dirname "$0")/.." && pwd); results="$root/docs/results/scenario-01/generated"
mkdir -p "$results"
[ "$samples" -ge 1 ] 2>/dev/null || { echo "SAMPLES must be a positive integer" >&2; exit 2; }
for command in kubectl curl sort awk sed python3 git; do command -v "$command" >/dev/null || { echo "missing $command" >&2; exit 1; }; done
kubectl --context "$context" -n "$ns" get deployment/order-service >/dev/null
git_commit=$(git -C "$root" rev-parse HEAD 2>/dev/null || echo unknown)
campaign_id=${SCENARIO_01_CAMPAIGN_ID:-unassigned}

if [ "$mode" = network ]; then
  report="$results/network-$(date -u +%Y%m%dT%H%M%SZ).json"
  service=$(kubectl --context "$context" -n "$ns" get service payment-service -o jsonpath='{.spec.clusterIP}')
  endpoints=$(mktemp); pods=$(mktemp); trap 'rm -f "$endpoints" "$pods"' EXIT
  kubectl --context "$context" -n "$ns" get endpointslice -l kubernetes.io/service-name=payment-service -o jsonpath='{range .items[*].endpoints[*]}{.addresses[0]}{"\n"}{end}' > "$endpoints"
  kubectl --context "$context" -n "$ns" get pod -l app.kubernetes.io/name=payment-service -o jsonpath='{range .items[*]}{.status.podIP}{"\n"}{end}' > "$pods"
  python3 "$root/scripts/scenario-01-report.py" network --service payment-service --cluster-ip "$service" --endpoint-file "$endpoints" --pod-file "$pods" --output "$report" --campaign-id "$campaign_id" --git-commit "$git_commit"
  echo "Wrote $report"; exit 0
fi

log=$(mktemp); body=$(mktemp); timings=$(mktemp); service_timings=$(mktemp)
cleanup() { [ -n "${forward_pid:-}" ] && kill "$forward_pid" 2>/dev/null || true; rm -f "$log" "$body" "$timings" "$service_timings"; }
trap cleanup EXIT
kubectl --context "$context" -n "$ns" port-forward service/order-service :8080 >"$log" 2>&1 & forward_pid=$!
for _ in $(seq 1 40); do grep -q 'Forwarding from' "$log" && break; sleep 0.25; done
port=$(sed -n 's/.*127.0.0.1:\([0-9][0-9]*\).*/\1/p' "$log" | head -1)
[ -n "$port" ] || { cat "$log" >&2; exit 1; }
base="http://127.0.0.1:$port/orders"; query=""; expected=201
case "$mode" in
  healthy|recovery) ;;
  latency) query="?payment_delay_ms=$delay_ms" ;;
  failure) query="?fail=payment"; expected=502 ;;
  *) echo "unknown mode: $mode" >&2; exit 2 ;;
esac
declare -A status_counts
for n in $(seq 1 "$samples"); do
  cid="scenario-01-${mode}-${n}"
  status=$(curl --silent --show-error -o "$body" -w '%{http_code} %{time_total}' -X POST -H "X-Correlation-ID: $cid" "$base$query")
  http_status=${status%% *}; client_seconds=${status#* }
  status_counts[$http_status]=$((${status_counts[$http_status]:-0}+1))
  awk -v seconds="$client_seconds" 'BEGIN {printf "%.3f\n", seconds*1000}' >> "$timings"
  payment_ms=$(sed -n 's/.*"name":"payment","status":[0-9]*,"duration_ms":\([0-9]*\).*/\1/p' "$body" | head -1)
  [ -n "$payment_ms" ] && printf '%s\n' "$payment_ms" >> "$service_timings"
done
percentile() { sort -n "$1" | awk -v p="$2" '{a[NR]=$1} END { if(NR==0){print "null";exit}; i=int((p/100)*NR+0.999); if(i<1)i=1; if(i>NR)i=NR; print a[i] }'; }
report="$results/${mode}-$(date -u +%Y%m%dT%H%M%SZ).json"
errors=$((samples-${status_counts[$expected]:-0}))
statuses=""; for code in "${!status_counts[@]}"; do statuses="${statuses}${statuses:+,}${code}=${status_counts[$code]}"; done
args=(experiment --experiment "$mode" --samples "$samples" --expected-status "$expected" --statuses "$statuses" --error-count "$errors" --client-timings "$timings" --service-timings "$service_timings" --output "$report" --campaign-id "$campaign_id" --git-commit "$git_commit")
[ "$mode" = latency ] && args+=(--delay-ms "$delay_ms")
[ "$mode" = failure ] && args+=(--failure-injection)
python3 "$root/scripts/scenario-01-report.py" "${args[@]}"
echo "Wrote $report"
