# Scenario 01 evidence package

This directory is the technical evidence package for the Kubernetes-only baseline. It is intentionally separate from publication writing.

## Audit and minimal additions

The existing baseline already provided four local images, one kind cluster, one namespace, direct Kubernetes Services, FQDN-based downstream URLs, a 2-second order-service HTTP-client timeout, correlation IDs, structured JSON logs, probes, a deterministic failure hook, and safe cluster cleanup. It had no repeatable latency/recovery workload, percentile report, service/endpoints capture, or article evidence index.

The additions are request-scoped only: `payment_delay_ms` causes the mock payment handler to sleep for 0–5000 ms on that request, and `fail=payment` causes that same request to receive a mock HTTP 503. Neither changes a Deployment, ConfigMap, Service, environment variable, or future request. `scenario-01-reset` removes only generated reports.

## Preconditions

Run `make doctor` and `make lab-up`. The current evidence workload uses 20 sequential requests by default. Override only when documenting the change, for example `SAMPLES=50 make scenario-01-healthy`. The latency experiment defaults to `PAYMENT_DELAY_MS=300`.

## Experiments

| Experiment | Command | Expected condition, not an asserted result |
|---|---|---|
| Healthy | `make scenario-01-healthy` | HTTP 201 responses if all mock dependencies respond. |
| Injected payment latency | `make scenario-01-latency` | Payment delay is request-scoped; observed client and downstream-call times may increase. |
| Injected payment unavailability | `make scenario-01-failure` | Order should expose a non-success composite result instead of accepting the order. |
| Recovery | `make scenario-01-recovery` | A new request has no failure/latency setting, so it exercises normal behavior. |
| Networking snapshot | `make scenario-01-network` | Captures the Service ClusterIP, EndpointSlice addresses, and Pod IPs. |

Each workload writes timestamped machine-readable JSON to `generated/`, which is intentionally ignored by Git. [samples](samples) contains illustrative schema examples only, not measured results.

To execute the full seven-report campaign (healthy, 300/1500/2500 ms latency, failure, recovery, and networking), set `SCENARIO_01_CAMPAIGN_ID` explicitly:

```sh
SCENARIO_01_CAMPAIGN_ID=local-baseline make scenario-01-all
```

`make scenario-01-all` exits nonzero if `SCENARIO_01_CAMPAIGN_ID` is unset so reports always record explicit provenance. To preserve a completed campaign under `evidence/<campaign-id>/` with a SHA-256 `manifest.json`, run `CAMPAIGN_ID=<campaign-id> make scenario-01-snapshot` and verify with `make validate-evidence`. The authoritative Article 01 snapshot is tracked under [evidence/2026-11-19-baseline/](evidence/2026-11-19-baseline/manifest.json).

The latest execution status is in [validation-report.md](validation-report.md). The report may mark an experiment `NOT EXECUTED` when its prerequisite cluster workload was unavailable; this is not a successful zero-result experiment.

## Metric definitions and limitations

- **Request count** is the number of sequential requests issued by the experiment script.
- **HTTP status distribution** and **error rate** are calculated from those client responses; an error is any status other than the experiment's expected status (`expected_http_status`). Consequently, for `failure` (`expected_http_status: 502`), observing 20× HTTP 502 yields `error_count: 0` and `error_rate: 0.0`—representing zero deviations from the test expectation, not a 0% HTTP 5xx rate.
- **Client-observed latency** is curl `time_total` over `kubectl port-forward`; it includes the local port-forward path and must not be generalized to in-cluster or production latency.
- **Payment service observed latency** is the duration measured by order-service around its HTTP call to payment-service and returned in the composite response. It includes downstream network and handler time, not only payment-handler CPU time.
- p50/p95/p99 are nearest-rank percentile values. With fewer than 100 samples, p95/p99 are sparse estimates, not statistically robust tail-latency claims.
- Order-service has a 2-second client timeout and no application retry. Kubernetes Services do not add HTTP retries, circuit breaking, application timeouts, or end-to-end tracing.

## Safe cleanup

`make scenario-01-reset` removes only generated JSON reports. `make lab-down` removes only the named project kind cluster. Run `make lab-down` twice to demonstrate repeatable cleanup.
