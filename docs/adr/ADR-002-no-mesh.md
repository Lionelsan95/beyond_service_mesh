# ADR-002: no mesh at bootstrap

**Decision:** retain a direct Kubernetes Service baseline with no proxy, Istio, Gateway API, or mesh policy. This is the comparison point for later experiments, not a claim that every system needs a mesh.
