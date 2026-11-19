# Bootstrap validation record

Captured: 2026-11-17 (Europe/Paris host context)

## Observed environment

- kind `v0.33.0` was installed.
- kubectl client `v1.37.0` was installed.
- GNU Make `4.4.1` and Git `2.53.0` were installed.
- No host Go runtime was found; this is expected because build/test use a container.
- Docker executable was found, but its daemon did not answer the version query during bootstrap inspection.
- Available disk was about 83 GiB; available memory was about 8.6 GiB when inspected.

## Commands actually executed

- Contract and repository inspection commands: completed.
- `bash -n scripts/*.sh`: completed successfully.
- `kubectl kustomize platform/base`: completed successfully (render/syntax check only).
- `make help`: completed successfully.
- `make doctor`: completed and correctly failed because the Docker daemon was unreachable.
- `make versions`: completed and recorded installed client-side tooling.
- `make validate`: completed successfully; it renders the Kustomize package without requiring an API server.
- `make lab-down`: correctly made no deletion and failed safely because Docker could not be queried to establish cluster ownership.
- `make diagrams`: correctly created no derived assets and failed because Docker was unavailable.
- A later local `make lab-up` run built and locally loaded all four images successfully. Its final readiness check failed before execution because kubectl v1.37.0 rejected `rollout status --all`; the command has been replaced with explicit deployment checks. The pasted output does not establish readiness, so no readiness success is claimed.
- A subsequent `make lab-up` reached the explicit order-service readiness check but timed out with zero available replicas. The cause was not present in the supplied output. The setup script now restarts local-image workloads after loading and prints deployment, Pod, and container-log diagnostics on readiness failure.
- Pod diagnostics then showed `CreateContainerConfigError` for all four workloads. The shared image had declared a named non-root user while the Pod policy required a verifiable non-root identity. The Dockerfile now declares the distroless numeric UID/GID `65532:65532`; this remains to be revalidated by `make lab-up`.
- After rebuilding and loading the numeric-UID images, `make lab-up` completed successfully: order-service, inventory-service, payment-service, and notification-service each reported a successful rollout in context `kind-btm-lab`, namespace `btm-lab`. This evidence comes from the local command output supplied on 2026-11-17. Smoke, diagram rendering, version capture, and cleanup still require separate execution.
- `make smoke` completed successfully: it observed the happy path and the controlled payment failure.
- `make versions` completed successfully and captured installed tool versions. Its initial implementation did not include local image IDs despite the images being available; the script has been corrected for the next capture.
- The corrected `make versions` capture recorded local Docker IDs for all four workload images and for `kindest/node:v1.37.0`. These are local image IDs, not a registry manifest digest; the lock file preserves that distinction and does not fabricate a remote digest.
- `make diagrams` did not render assets: Docker received an access-denied response while pulling `ghcr.io/mermaid-js/mermaid-cli:11.12.0`. No rendered asset is claimed.
- `make lab-down` deleted only `btm-lab`; a second invocation confirmed the cluster did not exist and performed no action.
- `kubectl apply --dry-run=client --validate=true -f platform/base/`: did not complete validation because kubectl attempted to reach an unavailable local API server; it also treated `kustomization.yaml` as a resource when passed with the directory. This command is not used by `make validate`.
- At initial bootstrap, end-to-end creation, image build/loading, `make test`, Mermaid rendering, and smoke were unavailable because Docker access had not yet been established. Subsequent supplied evidence verified `make lab-up`, `make smoke`, `make versions`, and idempotent `make lab-down`; Mermaid rendering remains unverified because its GHCR image pull was denied. `make test` has not yet been run.

## Remaining risks and next validation

The actual kind node registry manifest digest remains absent: the recorded identifier is a local Docker image ID, not a manifest digest. For the Scenario 01 evidence package, run the healthy, latency, failure, recovery, and networking targets and retain their generated reports before tagging or publishing.
