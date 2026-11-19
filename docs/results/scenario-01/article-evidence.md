# Article 01 evidence: Kubernetes baseline

## Verified facts

- The lab uses four fictitious HTTP services in namespace `btm-lab`: order, inventory, payment, and notification.
- Order-service resolves downstream services through Kubernetes Service FQDNs such as `payment-service.btm-lab.svc.cluster.local`.
- The successful smoke run proved that the baseline request path can complete through those direct Services on the validated local host.
- Order-service uses a 2-second HTTP-client timeout and has no application retry loop.
- A request-scoped mock payment failure produced a visible non-success outcome rather than a successful order response.
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

## Uncertainties and required evidence before publication

- Run and retain reports for healthy, latency, failure, recovery, and network evidence on the publication candidate revision.
- Capture the exact node image manifest digest separately; the recorded Docker image ID is not a registry manifest digest.
- Mermaid exports remain unavailable until an accessible pinned renderer is verified.
- Do not publish local latency percentiles as production performance data.
- The 2026-11-17 fresh-cluster validation captured kindnet and kube-proxy in iptables mode, but did not deploy the application after an interrupted Docker build. See [validation-report.md](validation-report.md); do not present its unexecuted experiment outcomes as evidence.
- On 2026-11-18, the current source passed the pinned Go unit suite after a delay-propagation compile fix. Its Docker image was not deployed because the automation environment interrupted the image build; no new workload experiment result is available.

## Commands and diagrams

```sh
make lab-up
make scenario-01-healthy
PAYMENT_DELAY_MS=300 make scenario-01-latency
make scenario-01-failure
make scenario-01-recovery
make scenario-01-network
make versions
make lab-down
```

Canonical diagrams: [component view](../../diagrams/baseline-overview.mmd) and [request sequence](../../diagrams/request-sequence.mmd).
