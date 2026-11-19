# Bootstrap implementation plan

Scope is restricted to `01-baseline`. The application uses a single tiny Go standard-library implementation compiled four times, then runs as four labelled Kubernetes Deployments and Services. The order service calls Service DNS names synchronously. A query parameter only forwards a controlled failure header to the selected mock dependency.

The cluster is named `btm-lab`; every mutation passes `--context kind-btm-lab` and the application namespace is `btm-lab`. No ports are exposed to the host. Docker image loading is local to kind. `02`–`07` have no runnable stubs: they are roadmap-only.

Validation stages: Bash syntax and Kubernetes client validation can run without Docker; Go tests and end-to-end deployment require the Docker daemon. Exact image digests are deferred until a successful pull. This is a conservative reproducibility decision, documented in the version lock and validation record.
