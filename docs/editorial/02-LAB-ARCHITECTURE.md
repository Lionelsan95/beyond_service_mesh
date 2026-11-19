# Beyond the Mesh — Lab Architecture v1.0
Date: 2026-11-17 | State: Design specification, **not yet implemented or validated**

## Objectives and exclusions
The reader clones a repo and reproduces clearly documented examples on Linux/macOS with Docker, kind, kubectl, make and Git. Optional Helm/istioctl needed only for later scenarios. Every experiment has setup, run, inspect, cleanup, expected observations, failure checks and version capture. The first baseline has **no service mesh**.

Out of scope for initial bootstrap: cloud accounts, production SLA, full payment/business implementation, real payment credentials, full OTel fleet, 2-cluster topology, AI model inference, traffic governance, comparative benchmarking, publicly publishing a repository or claiming production readiness.

## Architecture and request path
`traffic-generator → order-service → inventory-service / payment-service / notification-service`.
Suggested service contracts (to be designed in implementation, not assumed as complete):
- `order-service`: `GET /healthz`, `GET /readyz`, `POST /orders` (or `GET /process` for idempotent synthetic traffic), correlation ID, composite response, stable structured logs, failure propagation.
- `inventory-service`: deterministic mock stock check, fixed delay and failure toggles reserved for upcoming scenarios.
- `payment-service`: deterministic **mock** payment authorization, no real external network or sensitive data; future delay, errors and optional non-idempotent operations to teach retry risks.
- `notification-service`: simple synchronous mock in v1; async messaging is not required for baseline.
- `traffic-generator`: CLI or scripted container; no need for a persistent fifth workload at bootstrap.

Architecture documentation must distinguish synchronous and asynchronous flows and should not misrepresent notifications or payment semantics. Use one runtime for all initial services for simplicity (recommend Go for small images/fast startup or Python stdlib if maintainer velocity wins), explain decision with ADR. Avoid heavyweight frameworks and needless abstractions.

## Reproducibility contract
- `make doctor` checks prerequisite executable versions, Docker daemon, disk/memory, host ports and machine capacity, and reports actionable failures without changing the host.
- `make lab-up` creates a project-specific named kind cluster (never blindly overwrite another cluster), applies baseline manifests, waits for workload readiness and prints context.
- `make smoke` executes deterministic HTTP happy-path and basic request-correlation checks, exits nonzero on failures.
- `make lab-down` removes **only** project-owned cluster/resources, and is safe to repeat.
- `make diagrams` builds derived assets from committed Mermaid sources using a pinned renderer, preferably container-based and not modifying global npm installations.
- `make versions` writes the current runtime/tool/image versions to a JSON or Markdown evidence file, including exact Kubernetes node image digest and container image IDs.
- `make help` lists commands and required resources.
- All Makefile tasks must be noninteractive and clearly documented; startup and cleanup failures must be actionable.
- Never require privileged host changes, cloud credentials, real payments or external proprietary services for baseline. Image pulls / dependency downloads on first run do require network.
- Avoid globally changing current kubectl context: use explicit project context or explicit `--context` in all scripts; do not depend on current context.
- Image builds, loading into kind and Kubernetes deployment should be reproducible. Choose deterministic local tags; capture image digests; avoid `:latest` and floating downloads.
- Versions in `versions.lock.yaml`: kind, Kubernetes node image with digest, kubectl supported range, runtime, build tooling, later Istio and Gateway API after verified installation.

## Stack strategy (validation required on target host)
- kind: **v0.33.0** candidate; Kubernetes node **v1.37.0** candidate; these reflect known local toolchain, not blanket compatibility guarantees.
- Istio: **1.32.x** family when mesh enters, select a specific tested patch, feature stage and compatibility. The initial bootstrap **does not install Istio**.
- Docker Engine, kubectl, GNU make, bash, Git; app build via pinned runtime/container images. Keep host dependency surface small.
- Mermaid CLI container image pinned by digest after verification. Alternative executable only if documented.
- CI: basic lint / manifest validation / app unit tests in early stage; e2e kind test only if runner resource costs are reasonable.
- Monitoring: simple JSON logs, metrics or lightweight load script in baseline; add Prometheus/Grafana/trace tooling only when scenarios need them.

## Seven scenario definitions
| Lab | Goal | Controlled variable | Evidence | Caveat |
|---|---|---|---|---|
| 01-baseline | Kubernetes direct communication, DNS/Service, failure assumptions | No mesh | baseline request traces/latency/error observations | Do not infer production performance |
| 02-traffic-and-proxies | Compare native, sidecar and ambient request paths (subject to feature status) | Proxy/data-plane mode | proxy config, workload identity and traffic inspection | Ambient L4 vs L7 requires accurate modeling |
| 03-resilience | Introduce delayed/failing payment dependency; compare timeout/retry policies | Delay/error and timeout rules | p50/p95/p99, error rate, request counts, resource cost | Retries may amplify failures and duplicate non-idempotent writes |
| 04-zero-trust | Enforce inter-workload auth, policy and encryption | mTLS / authn / authz | allowed vs denied flows, TLS metadata, policy tests | Distinguish network policy and end-user auth |
| 05-progressive-migration | v1/v2 canary with rollback | weights/headers/routes | actual traffic distribution, rollback behavior | Stateful migration cannot be solved by routing alone |
| 06-cross-cluster | Coexistence between two kind clusters | cross-cluster connectivity and discovery | reachability, failure modes, rollback plan | Check CNI, multicluster mode, resource and host network constraints first |
| 07-ai-workloads | Mock model server and tool access; compare control locations | mesh/AI gateway/tool authorization | traceability, policy coverage, simulated cost | Do not imply mesh understands prompts or replaces business authorization |

Article 08 is a synthesis/ADR, **not an eighth lab**. The seven labs may be staged in order; no need to have the full lab implemented before post 1.

## Repository layout (target)
```
service-mesh-architecture-lab/
├── README.md
├── Makefile
├── versions.lock.yaml
├── .gitignore
├── LICENSE
├── apps/
│   ├── order-service/
│   ├── inventory-service/
│   ├── payment-service/
│   └── notification-service/
├── platform/
│   ├── kind/
│   ├── base/
│   ├── istio/          # deferred
│   └── observability/  # incremental
├── scenarios/
│   ├── 01-baseline/
│   ├── 02-traffic-and-proxies/
│   ├── 03-resilience/
│   ├── 04-zero-trust/
│   ├── 05-progressive-migration/
│   ├── 06-cross-cluster/
│   └── 07-ai-workloads/
├── docs/
│   ├── architecture/
│   ├── adr/
│   ├── diagrams/
│   ├── editorial/
│   └── results/
├── scripts/
├── tests/
└── .github/workflows/
```

## Git strategy
Main = one working shared source of truth; scenario-specific folder per lab; short-lived feature branches merged via review; immutable release tag e.g. `article-01-v1.0.0` used by Medium links. A tag's README tells the reader which commands apply. Avoid long-lived branches by article. Do not use real customer data, internal configs or names.

## Explicit ADRs for foundation
- ADR-001: kind vs managed Kubernetes: choose kind for local reproducibility; not representative of production network/performance.
- ADR-002: no mesh at bootstrap: retain baseline as a valid alternative.
- ADR-003: one fictitious application domain across posts, avoiding irrelevant complexity.
- ADR-004: scenario folders + immutable tags rather than long-lived branches.
- ADR-005: Mermaid as editable diagram source; PNG/SVG rendered outputs.
- ADR-006 (to decide during coding): runtime choice backed by image build, team ergonomics and startup/resource costs.

## Quality gates for Bootstrap v0.1
- Clean clone on supported Linux host with installed prerequisites, `make doctor`, `make lab-up`, `make smoke`, `make lab-down` succeeds twice (idempotency of cleanup).
- No installed mesh; workload images local, no need to publish any image to a registry; no `latest` dependencies.
- App, load and smoke tests are deterministic; negative path tested.
- Diagram source syntax can be rendered; architectural claims reflect traffic in baseline.
- Docs clearly label unimplemented labs as roadmap.
- README includes resource limits, platform notes, security warnings and troubleshooting.

## Failure and risk register
1. Kind 1.37 with actual Istio 1.32 patch mismatch: validate actual compatibility and feature stage before installing.
2. Docker networking and kind CNI differ across Linux/macOS/Windows: test compatibility and document issues, avoid promises of universal support.
3. Hidden dependencies or tags: pin images/tools, capture versions, eliminate `curl | bash` in scripts.
4. Benchmarks in containers are noisy: control load, repeat runs, publish conditions and raw output.
5. Retry/idempotency, trace context and JWT/user identities: build explicit tests to prevent overselling mesh controls.
6. Machine budget: later multicluster and observability may exceed laptops; provide optional lightweight profiles or skip guidance.

## References checked 2026-11-17
- https://istio.io/latest/docs/releases/supported-releases/
- https://istio.io/latest/news/releases/1.32.x/announcing-1.32/
- https://kind.sigs.k8s.io/docs/user/quick-start/
- https://gateway-api.sigs.k8s.io/docs/mesh/mesh-overview/
- https://github.com/mermaid-js/mermaid-cli
