# Article 01 evidence: Kubernetes baseline

## Verified facts

- The lab uses four fictitious HTTP services in namespace `btm-lab`: order, inventory, payment, and notification.
- Order-service resolves downstream services through Kubernetes Service FQDNs such as `payment-service.btm-lab.svc.cluster.local`.
- Campaign `2026-11-19-baseline` ([manifest](evidence/2026-11-19-baseline/manifest.json), captured from clean commit `8b4a4fd104569c8eb3a67c60c5b914549f9dbe9a`) validated all seven reports with matching SHA-256 checksums:
  - Healthy: 20× HTTP 201, client p50 `15.804 ms`.
  - 300 ms payment delay: 20× HTTP 201, client p50 `308.562 ms`.
  - 1,500 ms payment delay: 20× HTTP 201, client p50 `1508.864 ms`.
  - 2,500 ms payment delay: 20× HTTP 502, client p50 `2005.149 ms` (against Order's 2-second HTTP client timeout with no retry loop).
  - Failure injection (`?fail=payment`): 20× HTTP 502 (`error_rate: 0.0` vs `expected_http_status: 502`).
  - Recovery (uninjected requests): 20× HTTP 201, client p50 `7.112 ms`.
  - Networking snapshot (`payment-service`): ClusterIP `10.96.55.245`, EndpointSlice IP `10.244.0.15`, Pod IP `10.244.0.15`.
- The workloads run without a service mesh, sidecar proxy, Gateway API, monitoring stack, real payments, credentials, or hosted AI service.

## Networking model and evidence to reproduce

Run `make scenario-01-network` after `make lab-up`. The report records three distinct address sets:

1. **Service ClusterIP:** the stable virtual address assigned to `payment-service`.
2. **EndpointSlice addresses:** current eligible backend endpoint addresses selected by Kubernetes.
3. **Pod IPs:** addresses assigned to the payment Pods by the cluster network.

They must not be treated as interchangeable. The application calls the Service DNS name; Kubernetes Service resolution and kube-proxy or its configured equivalent direct Service traffic to an eligible endpoint. The CNI provides Pod-to-Pod networking and Pod IP connectivity. Exact kube-proxy/CNI implementation details are node/runtime-specific and must be inspected on the tested kind host before making a stronger claim.

## What Kubernetes Services solve

- Stable service naming and virtual addressing despite Pod replacement.
- Backend endpoint selection based on the Service selector and ready endpoints.
- A discovery target that application code can use instead of Pod IPs.

## What they do not solve

- Application-level retries, retry budgets, HTTP circuit breaking, or request hedging.
- Per-request authorization, mTLS identity, or application business authorization.
- End-to-end tracing, semantic metrics, or a production SLO.
- A guarantee that an individual request will succeed when a selected backend is slow or unavailable.

## Article-safe conclusion

Kubernetes already provides valuable local service discovery and routing primitives. The baseline makes the remaining application responsibilities visible: timeout selection, failure propagation, request semantics, logging, and correlation. Whether a mesh is warranted is not answered by this baseline alone.

## Uncertainties and limitations

- Capture the exact `kindest/node:v1.37.0` registry manifest digest separately; the recorded Docker image ID in `versions.lock.yaml` is a local image ID, not a registry manifest digest.
- Mermaid CLI container rendering (`make diagrams`) remains unverified because GHCR denied pull of `ghcr.io/mermaid-js/mermaid-cli:11.12.0`. Article 01 uses the editorial SVG/PNG figure set under `docs/articles/assets/01/`.
- Do not publish local latency percentiles as production performance data; 20 sequential requests over `kubectl port-forward` on a single-node kind cluster illustrate timeout behavior, not throughput or tail latency.
- Measurements establish caller-side behavior; server-side processing after Order's client timeout cancellation was not measured.
- See [validation-report.md](validation-report.md) for the complete 2026-11-19 validation table and historical 2026-11-17/18 records.

## Commands and diagrams

```sh
make doctor
make lab-up
SCENARIO_01_CAMPAIGN_ID=local-baseline make scenario-01-all
make validate-evidence
make versions
make lab-down
```

Editorial figures: [docs/articles/assets/01/](../../articles/assets/01/) (SVG sources + matching PNG exports). Canonical Mermaid sources: [component view](../../diagrams/baseline-overview.mmd) and [request sequence](../../diagrams/request-sequence.mmd).
