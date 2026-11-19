SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

.PHONY: help doctor lab-up smoke versions lab-down diagrams test validate validate-evidence scenario-01-healthy scenario-01-latency scenario-01-failure scenario-01-recovery scenario-01-network scenario-01-reset scenario-01-all scenario-01-normalize-historical scenario-01-snapshot
help: ## List supported commands.
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z0-9_-]+:.*##/ {printf "%-24s %s\n", $$1, $$2}' $(MAKEFILE_LIST)
doctor: ## Run non-mutating host prerequisite checks.
	@scripts/doctor.sh
lab-up: ## Create only kind-btm-lab, build/load images, and deploy baseline.
	@scripts/lab-up.sh
smoke: ## Run deterministic successful and controlled-failure requests.
	@scripts/smoke.sh
versions: ## Capture non-sensitive local tool and image evidence.
	@scripts/versions.sh
lab-down: ## Delete only the project kind cluster; safe to repeat.
	@scripts/lab-down.sh
diagrams: ## Render Mermaid source through the pinned container renderer.
	@scripts/diagrams.sh
test: ## Run Go unit tests in the pinned builder container.
	@docker run --rm -v "$(CURDIR):/src:ro" -w /src golang:1.26.0-alpine3.22 go test ./...
validate: ## Render the Kustomize manifests for syntax/structure checks.
	@kubectl kustomize platform/base >/dev/null && echo "PASS Kustomize rendered platform/base"
validate-evidence: ## Run locale-safe JSON/report regression tests and validate normalized evidence.
	@scripts/validate-scenario-01-evidence.sh
scenario-01-healthy: ## Record healthy baseline request evidence.
	@scripts/scenario-01-experiment.sh healthy
scenario-01-latency: ## Record request-scoped payment latency evidence (PAYMENT_DELAY_MS=300 by default).
	@scripts/scenario-01-experiment.sh latency
scenario-01-failure: ## Record request-scoped payment failure evidence.
	@scripts/scenario-01-experiment.sh failure
scenario-01-recovery: ## Confirm normal behavior after a failure experiment.
	@scripts/scenario-01-experiment.sh recovery
scenario-01-network: ## Record Service ClusterIP, endpoint, and Pod IP evidence.
	@scripts/scenario-01-experiment.sh network
scenario-01-reset: ## Remove only Scenario 01 generated reports; does not change the cluster.
	@rm -f docs/results/scenario-01/generated/*.json && echo "Removed Scenario 01 generated reports"
scenario-01-all: ## Run a complete explicit campaign; requires SCENARIO_01_CAMPAIGN_ID.
	@test -n "$(SCENARIO_01_CAMPAIGN_ID)" || (echo "Set SCENARIO_01_CAMPAIGN_ID (for example 2026-11-19-baseline)" >&2; exit 2)
	@$(MAKE) scenario-01-healthy
	@PAYMENT_DELAY_MS=300 $(MAKE) scenario-01-latency
	@PAYMENT_DELAY_MS=1500 $(MAKE) scenario-01-latency
	@PAYMENT_DELAY_MS=2500 $(MAKE) scenario-01-latency
	@$(MAKE) scenario-01-failure
	@$(MAKE) scenario-01-recovery
	@$(MAKE) scenario-01-network
	@echo "Campaign $(SCENARIO_01_CAMPAIGN_ID) completed; inspect generated reports before snapshotting."
scenario-01-normalize-historical: ## Preserve raw November 19 reports and create a normalized derivative once.
	@python3 scripts/scenario-01-report.py normalize --source docs/results/scenario-01/generated --destination docs/results/scenario-01/evidence/2026-11-19-historical-normalized
scenario-01-snapshot: ## Snapshot a complete provenance-tagged campaign; requires CAMPAIGN_ID.
	@test -n "$(CAMPAIGN_ID)" || (echo "Set CAMPAIGN_ID" >&2; exit 2)
	@python3 scripts/scenario-01-report.py snapshot --campaign-id "$(CAMPAIGN_ID)" --destination docs/results/scenario-01/evidence --repository . docs/results/scenario-01/generated/*.json
