# Beyond the Mesh — baseline lab

An educational, fictitious Kubernetes application used to establish what plain Services and DNS provide before any service mesh is introduced. It is not production software and never contacts a real payment provider.

## Baseline request path

`traffic generator → order-service → inventory-service, payment-service, notification-service`.

All four services are synchronous HTTP processes in namespace `btm-lab`. The order service propagates `X-Correlation-ID`, records dependency status and duration in its response/logs, and returns a non-2xx result if a dependency fails. There is no Istio, sidecar, proxy, Gateway API, telemetry stack, external identity, or AI model.

## Prerequisites

Supported target: Linux with Docker Engine/compatible daemon, kind, kubectl, GNU Make, Bash, curl, and Git. macOS is documented but untested. Windows and WSL are untested. First use needs network access only to pull the explicitly versioned base images.

Estimates (not measurements): 2 CPU cores, 6 GiB available RAM, and 10 GiB free disk. The lab uses a project-only cluster named `btm-lab`; commands target `kind-btm-lab` explicitly and do not switch your current kubectl context.

On Linux, ensure your user can reach the Docker socket. On macOS, Docker Desktop must be running and allocated the estimated resources; filesystem-backed image builds may take longer. Neither platform claim has been validated by this bootstrap report. Windows/WSL are explicitly untested.

## Quickstart

```sh
make doctor
make lab-up
make smoke
make versions
make lab-down
```

`lab-up` is idempotent if the project cluster already exists. `lab-down` only deletes `btm-lab` and is safe to repeat. To cleanly replay, run `make lab-down` then `make lab-up`.

The smoke test sends a deterministic successful request with correlation ID `smoke-baseline-001`, then requests `?fail=payment`. The latter is an in-request test hook: it causes only the mock payment dependency to return HTTP 503; it never changes a deployment, Service, namespace, or another cluster.

## Commands and troubleshooting

`make help` lists all targets. `make validate` does client-side manifest validation. `make test` runs Go tests through the pinned builder image, so no host Go installation is needed. `make diagrams` needs Docker and writes derived files under `docs/diagrams/rendered/`; Mermaid sources remain canonical.

If Docker is unavailable, start the daemon and re-run `make doctor`. If kind image pulls fail, check network/proxy policy and use the exact images in `versions.lock.yaml`; do not substitute `latest`. If readiness times out, inspect only the lab with `kubectl --context kind-btm-lab -n btm-lab get pods` and `... logs deployment/order-service`.

The workloads run without mounted credentials, a Kubernetes API token, or privileged containers. Their mock payment endpoint is not a payment integration and must never be connected to one.

## Scenario status

| Lab | Status | Article |
|---|---|---|
| 01-baseline | Implemented foundation; host validation recorded separately | 01 |
| 02-traffic-and-proxies through 07-ai-workloads | Not implemented | 02–07 |
| Synthesis | Not a lab; not implemented | 08 |

Read [the implementation plan](docs/architecture/implementation-plan.md), [ADRs](docs/adr), and [validation record](docs/results/bootstrap-validation.md) before treating any behavior as verified.

For the Article 01 technical evidence workflow, use [the Scenario 01 evidence package](docs/results/scenario-01/README.md). It provides healthy, latency, failure, recovery, and networking capture targets without installing or enabling a mesh.
