# Scenario 01 observations

## Verified bootstrap observations

- On the documented local Linux host, `make lab-up` completed after the numeric non-root image identity correction.
- `make smoke` observed both a happy response and the controlled payment failure path.
- `make lab-down` deleted only `btm-lab`; a second run did nothing.
- The renderer image pull from GHCR was denied, so no Mermaid export is verified.

## 2026-11-19 validated campaign (`2026-11-19-baseline`)

A complete seven-report campaign was executed from clean Git commit `8b4a4fd104569c8eb3a67c60c5b914549f9dbe9a` (`working_tree_dirty: false`) in `kind-btm-lab` / namespace `btm-lab` (`kindest/node:v1.37.0`) and preserved with SHA-256 checksums under [evidence/2026-11-19-baseline/manifest.json](evidence/2026-11-19-baseline/manifest.json):

- **Healthy (no delay):** 20/20 HTTP 201; client p50 `15.804 ms` (p95 `30.999 ms`, p99 `155.058 ms`); downstream payment p50 `2.0 ms`.
- **Payment delay 300 ms:** 20/20 HTTP 201; client p50 `308.562 ms` (p95 `309.607 ms`, p99 `309.803 ms`); downstream payment p50 `302.0 ms`.
- **Payment delay 1,500 ms:** 20/20 HTTP 201; client p50 `1508.864 ms` (p95 `1606.877 ms`, p99 `1630.445 ms`); downstream payment p50 `1502.0 ms`.
- **Payment delay 2,500 ms:** 20/20 HTTP 502 (`error_rate: 1.0` vs expected HTTP 201); client p50 `2005.149 ms` (p95 `2079.577 ms`, p99 `2106.14 ms`); downstream payment p50 `2000.0 ms`.
- **Payment failure injection (`?fail=payment`):** 20/20 HTTP 502 (`expected_http_status: 502`, `error_rate: 0.0` meaning zero deviations from expectation); client p50 `5.632 ms`.
- **Recovery (subsequent requests without injection):** 20/20 HTTP 201; client p50 `7.112 ms`. Confirms clean request-scoped behavior rather than automatic self-healing.
- **Networking snapshot (`payment-service`):** Service ClusterIP `10.96.55.245`; EndpointSlice IP `10.244.0.15`; Pod IP `10.244.0.15`.

## Historical record (2026-11-17 to 2026-11-18)

Prior to the 2026-11-19 campaign, earlier automated validation attempts were blocked before workload deployment:

## 2026-11-17 validation attempt

An isolated `btm-lab` control plane was created and became Ready. It exposed CoreDNS, kindnet, and kube-proxy; the exact observed configuration is retained in [validation-report.md](validation-report.md). No application resource was applied in that fresh cluster: the Docker build stage was attempted but automation output ended during Go compilation without a compiler error or completed image. Consequently, none of the new evidence targets was executed and no metric was generated.

`make diagrams` was also attempted and failed as before because GHCR denied the pinned renderer image pull. Mermaid sources remain the canonical diagrams.

## 2026-11-18 continuation

The first pinned Go test identified an implementation defect in the newly added delay propagation. It was corrected by passing the query value into the downstream-call helper; the corrected pinned test suite passed. Workload experiments remain unexecuted: the automation environment terminated Docker builds before the compile layer could complete, so the current source image was never deployed. This does not invalidate the earlier bootstrap smoke evidence, but it prevents new latency or network claims for the current source revision.

## Expected mechanics to test, not results

The healthy and recovery workloads send no injection setting. The latency workload adds `payment_delay_ms` to each order request. The failure workload adds `fail=payment`; order-service forwards this as an HTTP header only to its mock payment call. On each new request, absence of these query parameters disables the effect.

The downstream HTTP client in order-service has a fixed 2-second timeout and no retry loop. A requested delay outside 0–5000 ms is ignored by the payment handler's bounded-delay parser, rather than creating an indefinite injection.

## Interpretation boundary

This lab demonstrates one local kind topology. It is useful evidence for request propagation, dependency failure visibility, and Kubernetes Service routing mechanics, but not for production capacity, tail latency, CNI performance, availability, or a recommendation to adopt a service mesh.
