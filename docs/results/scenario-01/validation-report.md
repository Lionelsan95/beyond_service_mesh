# Scenario 01 validation report

Captured on 2026-11-17. This report distinguishes commands that completed from commands that were attempted but could not produce workload evidence.

## 2026-11-18 continuation

The validation was retried in a fresh project cluster. The initial pinned Go test exposed and confirmed a source compilation defect in the first implementation of payment-delay propagation (`undefined: r` in `internal/service/service.go`). The helper now receives the delay explicitly; a re-run of the pinned Go test container passed all packages.

The current automation transport still terminates foreground Docker builds before their `go build` layer completes, and it terminates attempted background build descendants as well. No new image was produced and no manifest was applied in this continuation. This is an automation-execution limitation, not a successful workload test.

The named `btm-lab` control plane was again created only for the retry. It was not used to modify any unrelated cluster.

## Environment and cluster identity

- Host: Ubuntu 26.04.1 LTS, Linux kernel `7.0.0-43-generic`, x86_64; Docker Engine `29.4.1`; 16 CPUs; 27.81 GiB total memory.
- Tooling: kind `v0.33.0` (Go `1.26.7`), kubectl client/server `v1.37.0`, Kustomize `v5.8.1`, Git `2.53.0`.
- Project context: `kind-btm-lab`; cluster: `btm-lab`; node: `btm-lab-control-plane`, Ready, Kubernetes `v1.37.0`, containerd `2.3.4`.
- Other visible contexts/clusters (`kind-kind`, `kind-kube-lab`, `minikube`, and kind cluster `kube-lab`) were not modified.
- Node image reference: `kindest/node:v1.37.0`. Its local Docker image ID was captured previously in `versions.lock.yaml`; a registry manifest digest was not established and is not substituted with that local ID.

## Observed local networking configuration

- CoreDNS had two Ready Pods (`10.244.0.2` and `10.244.0.3`).
- The `kindnet` DaemonSet was Ready and used `docker.io/kindest/kindnetd:v20260820-69b56db7`.
- The `kube-proxy` DaemonSet was Ready and used `registry.k8s.io/kube-proxy:v1.37.0`.
- The observed kube-proxy ConfigMap configured `mode: iptables` and `clusterCIDR: 10.244.0.0/16`.

These are observed configuration facts. They show the local cluster has kindnet and kube-proxy in iptables mode; they do not prove every packet path or performance characteristic.

## Experiment matrix

| Check | Command / parameters | Status | Result or reason |
|---|---|---|---|
| Doctor | `make doctor` | FAIL | The unprivileged automation subprocess could not access `/var/run/docker.sock`. Docker was reachable only through separately approved access. |
| Project cluster identity | `kind get clusters`, `kubectl --context kind-btm-lab get nodes` | PASS | Only `btm-lab` was created for this run; its node became Ready. |
| Workload readiness | `make lab-up` | NOT EXECUTED | The command was attempted after cluster creation but Docker build output stopped at Go compilation before images/manifests completed. No compiler error was emitted and no resources were created in `btm-lab`. |
| Go unit tests | pinned Go container command | PASS | After the payment-delay helper fix, `go test ./...` passed: `internal/service` passed and the four command packages reported no test files. |
| Healthy, 20 requests | `make scenario-01-healthy` | NOT EXECUTED | Requires ready order-service; no Scenario 01 workloads were deployed in this validation run. |
| Payment latency, 300 ms | `PAYMENT_DELAY_MS=300 make scenario-01-latency` | NOT EXECUTED | Same prerequisite blocker. |
| Payment latency, 1500 ms | `PAYMENT_DELAY_MS=1500 make scenario-01-latency` | NOT EXECUTED | Same prerequisite blocker. |
| Payment latency, 2500 ms | `PAYMENT_DELAY_MS=2500 make scenario-01-latency` | NOT EXECUTED | Same prerequisite blocker. This is expected to exercise the 2-second order-service timeout once deployed; no result is claimed. |
| Payment failure | `make scenario-01-failure` | NOT EXECUTED | Same prerequisite blocker. |
| Recovery | `make scenario-01-recovery` | NOT EXECUTED | Same prerequisite blocker. |
| Service/endpoint snapshot | `make scenario-01-network` | NOT EXECUTED | Requires payment-service resources; namespace was empty. |
| Mermaid render | `make diagrams` | FAIL | GHCR denied pull of `ghcr.io/mermaid-js/mermaid-cli:11.12.0`; no derived asset was created. |
| Cleanup (2026-11-17) | `make lab-down && make lab-down` | PASS | Deleted only the empty `btm-lab` cluster created for that run; the second command made no change. |
| Cleanup (2026-11-18) | `make lab-down && make lab-down` | PASS with timing anomaly | The first check found no cluster, then a delayed project-cluster creation became visible and the second command deleted `btm-lab`. No unrelated cluster was touched. This reinforces that automation timing must be resolved before using it for evidence capture. |

## Architecture review

In the previously verified baseline, Kubernetes Services provided stable DNS names and virtual addressing for the four local services. In this fresh cluster, CoreDNS, kindnet, and kube-proxy were observed before application deployment, but Service ClusterIPs, EndpointSlices, and Pod IPs for the lab were not available because no workload was applied.

Application behavior remains the source of the two-second downstream HTTP timeout, absent retries, correlation IDs, structured request logging, failure propagation, and the request-scoped delay/failure controls. Kubernetes Service does not provide those HTTP semantics.

No new timeout result was measured at 2500 ms. The source code configures a two-second order-service client timeout, so that workload is designed to test timeout propagation, not to prove it without execution. The lab remains a one-node local kind experiment with sequential client requests and a port-forwarded client path; it cannot establish production latency, availability, CNI performance, or service-mesh benefits.

## Publication readiness

Article 01 may use the already verified baseline facts and the explicitly observed local cluster networking configuration. It must not cite latency percentiles, status distributions, recovery behavior, Service endpoint addresses, or timeout outcomes until the listed experiment commands complete and their generated JSON reports are retained.
