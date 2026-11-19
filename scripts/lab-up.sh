#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd); cluster=btm-lab; context=kind-btm-lab; ns=btm-lab
for cmd in docker kind kubectl; do command -v "$cmd" >/dev/null || { echo "missing $cmd" >&2; exit 1; }; done
docker info >/dev/null || { echo "Docker daemon is not reachable" >&2; exit 1; }
if ! kind get clusters | grep -Fxq "$cluster"; then kind create cluster --name "$cluster" --config "$root/platform/kind/kind-config.yaml"; fi
for service in order-service inventory-service payment-service notification-service; do docker build --build-arg SERVICE="$service" -t "btm/$service:0.1.0" "$root/apps"; kind load docker-image --name "$cluster" "btm/$service:0.1.0"; done
kubectl --context "$context" apply -k "$root/platform/base"
for deployment in order-service inventory-service payment-service notification-service; do
  # Local images retain a fixed educational tag. Restart so an existing Pod
  # cannot keep an older locally loaded image after a source change.
  kubectl --context "$context" -n "$ns" rollout restart "deployment/$deployment"
done
for deployment in order-service inventory-service payment-service notification-service; do
  if ! kubectl --context "$context" -n "$ns" rollout status "deployment/$deployment" --timeout=120s; then
    echo "Readiness failed for $deployment. Lab-only diagnostics follow:" >&2
    kubectl --context "$context" -n "$ns" get pods -o wide >&2 || true
    kubectl --context "$context" -n "$ns" describe pods >&2 || true
    kubectl --context "$context" -n "$ns" describe "deployment/$deployment" >&2 || true
    kubectl --context "$context" -n "$ns" logs -l "app.kubernetes.io/name=$deployment" --all-containers --prefix --tail=100 >&2 || true
    exit 1
  fi
done
echo "Baseline ready in context $context, namespace $ns"
