# ADR-006: Go standard library runtime

**Decision:** use Go's HTTP and JSON standard library for a small readable static binary and no application dependency graph. The host need not install Go because tests/builds run in a pinned container. The image version is an unverified lock until Docker validation captures digests.
