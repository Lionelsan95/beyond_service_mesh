# Scenario 01 audit and minimal-change plan

## Reused components

- Go standard-library HTTP service shared by all four fictitious services.
- Direct Service DNS request path, correlation header, structured logs, probes, requests/limits, and non-root hardened containers.
- Explicit `kind-btm-lab` context and `btm-lab` namespace convention.
- Local build/load/deploy and deterministic smoke/cleanup scripts.

## Additions

Add request-scoped payment delay, response-status logging, a sequential evidence runner, and documentation/report structure. No application topology, Kubernetes routing model, Service selector, workload count, or later scenario is changed.

## Why the application change is necessary

The existing failure header was enough for a single negative smoke check but could not model bounded latency or provide reusable latency evidence. The new delay is parsed only by payment-service, bounded to 0–5000 ms, disabled by default, and carried only by the request. This keeps the experiment deterministic and ensures cleanup cannot leave an injected state behind.
