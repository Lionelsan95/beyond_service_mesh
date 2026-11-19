# Beyond the Mesh — Article 01 Release Readiness Report

**Date:** 2026-11-19  
**Target article:** [01-kubernetes-found-the-service.md](01-kubernetes-found-the-service.md)  
**Target repository:** `git@github.com:Lionelsan95/beyond_service_mesh.git` (`https://github.com/Lionelsan95/beyond_service_mesh`, verified HTTP 200 unauthenticated)  
**Verdict:** **READY FOR LOCAL REVIEW AND MANUAL GIT PUSH** — **NOT YET PUBLISHED** (awaiting user push, optional `article-01-v1.0.0` tag, Medium import, and LinkedIn/Canva assets).

---

## 1. Provenance & Experiment Method

- **Campaign ID:** `2026-11-19-baseline`
- **Evidence snapshot:** [docs/results/scenario-01/evidence/2026-11-19-baseline/manifest.json](../results/scenario-01/evidence/2026-11-19-baseline/manifest.json)
- **Source commit recorded in snapshot:** `8b4a4fd104569c8eb3a67c60c5b914549f9dbe9a` (`working_tree_dirty: false`)
- **Commit-separation transparency:** Campaign `2026-11-19-baseline` was captured directly against clean commit `8b4a4fd`. The follow-up commit(s) prepared here preserve the immutable evidence snapshot, integrate Article 01 and its figures, fix `make test` working directory (`-w /src/apps`), and add evidence/article verification tests. None of `apps/` or `platform/` changed after `8b4a4fd`.
- **Cluster & runtime context:** Single-node local kind cluster `kind-btm-lab`, namespace `btm-lab`, node image reference `kindest/node:v1.37.0` (local Docker ID recorded in `versions.lock.yaml`; remote registry manifest digest not yet captured). Observed networking: CoreDNS, `kindnet`, `kube-proxy` in `iptables` mode.
- **Experiment method:** 20 sequential HTTP `POST /orders` requests per condition from `curl` over `kubectl port-forward` to `order-service`; request-scoped `?payment_delay_ms` (0–5000 ms) and `?fail=payment` hooks; 2-second Go `http.Client` timeout in `order-service` with zero retries.

---

## 2. Files Added or Changed

### Added
- `docs/articles/01-kubernetes-found-the-service.md` — Publication-ready Article 01 integrated from `ARTICLE-01-MEDIUM-V2.md` with relative figure links and corrected `SCENARIO_01_CAMPAIGN_ID` command.
- `docs/articles/ARTICLE-01-RELEASE-READINESS.md` — This release readiness report.
- `docs/articles/assets/01/01-application-map.{svg,png}` — Figure 1 (SVG source + 1400×800 PNG export).
- `docs/articles/assets/01/02-network-path.{svg,png}` — Figure 2 (SVG source + 1400×800 PNG export).
- `docs/articles/assets/01/03-latency-results.{svg,png}` — Figure 3 (SVG source + 1400×800 PNG export).
- `docs/articles/assets/01/04-timeout-timeline.{svg,png}` — Figure 4 (SVG source + 1400×800 PNG export).
- `docs/articles/assets/01/05-architecture-decision.{svg,png}` — Figure 5 (SVG source + 1400×800 PNG export).
- `docs/results/scenario-01/evidence/2026-11-19-baseline/` — Authoritative snapshot (`manifest.json` + 7 JSON reports; previously untracked in workspace).
- `tests/evidence/test_article_01_release.py` — Automated verification of snapshot SHA-256 checksums, article-to-evidence numeric match, SVG/PNG integrity, relative links, and balanced code fences.

### Modified
- `Makefile` — Fixed `make test` container working directory from `-w /src` to `-w /src/apps` (where `go.mod` lives).
- `.gitignore` — Added `btm-*.tar.gz` so local export archives (including `btm-evidence-final.tar.gz`) are excluded while `docs/results/scenario-01/evidence/` stays tracked.
- `.github/workflows/ci.yaml` — Added `bash -n scripts/*.sh` and `scripts/validate-scenario-01-evidence.sh` to CI.
- `scripts/validate-scenario-01-evidence.sh` — Extended to run `test_article_01_release.py` and validate committed snapshot JSON files under `docs/results/scenario-01/evidence/*/`.
- `README.md` — Linked Article 01, documented `SCENARIO_01_CAMPAIGN_ID` for `make scenario-01-all`, and referenced `2026-11-19-baseline`.
- `docs/results/scenario-01/README.md` — Documented `SCENARIO_01_CAMPAIGN_ID`, snapshot workflow, and `error_rate` semantics on expected-failure runs.
- `docs/results/scenario-01/observations.md` — Recorded `2026-11-19-baseline` measurements while retaining Nov 17–18 history.
- `docs/results/scenario-01/validation-report.md` — Added the 2026-11-19 campaign matrix and updated publication readiness status.
- `docs/results/scenario-01/article-evidence.md` — Updated verified facts, caveats, commands, and figure references to match the validated snapshot.

### Left Untouched (Untracked / Ignored)
- `btm-evidence-final.tar.gz` — Preserved on disk and now ignored by `.gitignore` (`btm-*.tar.gz`); do not commit.
- `03-CODEX-BOOTSTRAP-PROMPT.md`, `docs/results/versions.json`, `docs/results/scenario-01/generated/*.json` — Remain ignored by `.gitignore`.

---

## 3. Evidence Validation Results

All 7 JSON files in `docs/results/scenario-01/evidence/2026-11-19-baseline/` parsed cleanly with strict JSON (`allow_nan=False`), matched their `manifest.json` SHA-256 checksums (7/7 **PASS**), and shared identical provenance (`campaign_id=2026-11-19-baseline`, `git_commit=8b4a4fd104569c8eb3a67c60c5b914549f9dbe9a`, `cluster_context=kind-btm-lab`, `namespace=btm-lab`, `node_image_reference=kindest/node:v1.37.0`, `working_tree_dirty=false`).

| Report file | Condition | Snapshot statuses | Snapshot client p50 | Article value | `error_rate` (vs expected) | SHA-256 | Consistency |
|---|---|---|---:|---:|---:|---|---|
| `healthy-20261119T145101Z.json` | No delay | `201: 20` | `15.804 ms` | `15.8 ms` | `0.0` (exp. `201`) | MATCH | PASS |
| `latency-20261119T145108Z.json` | 300 ms delay | `201: 20` | `308.562 ms` | `308.6 ms` | `0.0` (exp. `201`) | MATCH | PASS |
| `latency-20261119T145139Z.json` | 1,500 ms delay | `201: 20` | `1508.864 ms` | `1,508.9 ms` | `0.0` (exp. `201`) | MATCH | PASS |
| `latency-20261119T145220Z.json` | 2,500 ms delay | `502: 20` | `2005.149 ms` | `2,005.1 ms` | `1.0` (exp. `201`) | MATCH | PASS |
| `failure-20261119T145221Z.json` | `?fail=payment` | `502: 20` | `5.632 ms` | 20/20 HTTP 502 | `0.0` (exp. `502`) | MATCH | PASS |
| `recovery-20261119T145222Z.json` | Post-failure normal | `201: 20` | `7.112 ms` | 20/20 HTTP 201 | `0.0` (exp. `201`) | MATCH | PASS |
| `network-20261119T145222Z.json` | `payment-service` | ClusterIP `10.96.55.245`, Endpoint/Pod `10.244.0.15` | n/a | `10.96.55.245` / `10.244.0.15` | n/a | MATCH | PASS |

**Important metric clarification:** In `failure-20261119T145221Z.json`, `error_rate` is `0.0` because `expected_http_status` is `502` and all 20 responses returned HTTP 502. `error_rate` measures deviation from test expectation, not the HTTP 5xx rate.

---

## 4. Figure Index & Visual/Technical QA

All five figures reside in `docs/articles/assets/01/` as paired valid SVG (`viewBox="0 0 1400 800"`) and PNG (`1400 × 800`, 8-bit RGBA) files, preserving the Architecture Notebook visual identity (warm cream `#F7F3EC`, burgundy `#6A2431`, sage `#72957D`, terracotta `#B45F49`, peach `#F8E6DD`/`#FBE6D9`, mauve `#D99DA5`).

Updated SVGs (`01`, `02`, `04`, `05`) were re-exported to matching `1400 × 800` PNGs using headless Chrome:

```bash
google-chrome --headless=new --disable-gpu --no-sandbox \
  --window-size=1400,800 --force-device-scale-factor=1 \
  --default-background-color=00000000 --hide-scrollbars \
  --screenshot="<png>" "file://<svg>"
```

| # | Stem | Technical check | Visual QA findings & fixes applied | Status |
|---|---|---|---|---|
| 01 | `01-application-map` | Accurate 4-service logical HTTP topology; no mesh. | Changed `NOTIFICATION` sublabel from `"Events"` to `"Sync HTTP mock"` so baseline synchronous HTTP behavior is not confused with async messaging. Re-exported PNG and visually verified. | PASS |
| 02 | `02-network-path` | Exact ClusterIP `10.96.55.245` and Endpoint `10.244.0.15`; EndpointSlice shown as dashed metadata, NOT a network hop. | Widened `PAYMENT SERVICE` card (`270 → 320 px`) so title no longer crowds the border; increased `ENDPOINTSLICE` card height (`74 → 86 px`) for comfortable bottom padding. Re-exported PNG and visually verified. | PASS |
| 03 | `03-latency-results` | Exact measured local p50 values (`15.8`, `308.6`, `1,508.9`, `2,005.1 ms`), 2,000 ms timeout line, and `20 × 201` / `20 × 502` counts. | Clean layout, clear hierarchy, high contrast, no cropping. Kept original SVG and PNG untouched. | PASS |
| 04 | `04-timeout-timeline` | Caller-side timeout only; explicitly states server-side cancellation was not measured. | **Fixed critical cropping bug:** title at `51 px` previously overflowed into the right burgundy frame; reduced to `45 px` so it fits cleanly inside the cream canvas. Replaced right-to-left arrowhead (which could imply Payment sent a timeout) with a caller-side marker dot on Order's lifeline. Re-exported PNG and visually verified. | PASS |
| 05 | `05-architecture-decision` | Nuanced responsibility boundaries + baseline mesh-free decision. | Widened and aligned all three cards symmetrically to the `x=90..1308` grid (`382 px` each) so `"Consistent traffic policy"` has clean right padding; added subtle overlap note (`"Starting points, not mutually exclusive boxes — libraries, gateways, and CNIs overlap in practice."`). Re-exported PNG and visually verified. | PASS |

**Editorial ordering note:** In `ARTICLE-01-MEDIUM-V2.md`, **Figure 3** (`03-latency-results.png`) appears in Section 1 directly beneath the latency table, before **Figure 2** (`02-network-path.png`) in Section 2. The integrated Markdown preserves the supplied narrative order and ensures every Markdown caption matches its diagram's stamped figure number (`Figure 1`, `Figure 3`, `Figure 2`, `Figure 4`, `Figure 5`). Decide before Medium import whether to keep this order or swap the Figure 2 / Figure 3 numbering.

---

## 5. Article Review Results

- **Location:** [docs/articles/01-kubernetes-found-the-service.md](01-kubernetes-found-the-service.md) (~1,381 words — inside the 1,200–1,800 word Editorial Charter target).
- **Technical accuracy:** All latency, status, IP, kube-proxy/kindnet, and timeout claims match `2026-11-19-baseline`. Clearly separates assumptions, measured results, and interpretations. Avoids false claims ("Kubernetes returned 502", "Payment continued processing", "automatic self-healing", or unmeasured mesh benefits).
- **Reproducibility fix:** Section 6 originally listed bare `make scenario-01-all`, which exits with code 2 because `Makefile` requires `SCENARIO_01_CAMPAIGN_ID`. Updated to `SCENARIO_01_CAMPAIGN_ID=local-baseline make scenario-01-all` + `make validate-evidence`.
- **Links & formatting:** All 5 figure placeholders replaced with valid relative PNG links, accessible alt text, and italic captions; all relative Markdown links verified; fenced code blocks balanced.
- **Repository visibility:** `https://github.com/Lionelsan95/beyond_service_mesh` returned HTTP `200` unauthenticated on 2026-11-19. Note that Article 01 and `2026-11-19-baseline` will appear there only after the manual push.

---

## 6. Verification & Test Matrix

| Check | Command | Outcome | Evidence / Notes |
|---|---|---|---|
| Shell script syntax | `bash -n scripts/*.sh` | **PASS** | All 8 Bash scripts parsed cleanly. |
| Host preflight | `make doctor` | **PASS** | Docker daemon reachable; kind `v0.33.0`, kubectl `v1.37.0`, Kustomize `v5.8.1`, make, git, curl, disk ≥ 10 GiB, RAM ≥ 6 GiB. |
| Manifest render | `make validate` | **PASS** | `PASS Kustomize rendered platform/base`. |
| Go unit tests | `make test` | **PASS** | Initially **FAIL** (`-w /src` missed `apps/go.mod`); fixed to `-w /src/apps`, then `internal/service` passed in `0.004s` via pinned `golang:1.26.0-alpine3.22`. |
| Evidence & Article 01 suite | `make validate-evidence` | **PASS** (1 skipped) | 10 Python tests run: 9 passed, 1 skipped (`test_comma_locale_json_when_available`: no `fr_`/`de_`/`it_` locale installed in container/host); all 7 snapshot JSON files validated; all 7 SHA-256 checksums, metrics, 5 SVGs, 5 PNGs, and Markdown links verified. |
| Full live cluster replay | `make lab-up && SCENARIO_01_CAMPAIGN_ID=... make scenario-01-all && make lab-down` | **NOT EXECUTED** | Deliberately not re-run in this release-integration step to avoid long Docker builds and preserve the already-validated `2026-11-19-baseline` evidence captured from clean commit `8b4a4fd`. |
| Mermaid CLI render | `make diagrams` | **NOT EXECUTED** | Previously **FAIL** due to GHCR pull access denial on `ghcr.io/mermaid-js/mermaid-cli:11.12.0` (documented in `bootstrap-validation.md`). Article 01 uses the verified SVG/PNG assets under `docs/articles/assets/01/`. |

---

## 7. Known Limitations & Remaining Publication Blockers

### Technical / Repository Limitations (Non-blocking if disclosed — already disclosed in Article 01 & docs)
1. **Local kind scope:** Single-node kind cluster, 20 sequential requests over `kubectl port-forward`; p95/p99 are sparse estimates and not production benchmarks.
2. **Node image manifest digest:** `versions.lock.yaml` records the local Docker image ID for `kindest/node:v1.37.0`, not a remote registry manifest digest.
3. **Mermaid CLI renderer (`make diagrams`):** GHCR pull for `ghcr.io/mermaid-js/mermaid-cli:11.12.0` remains unverified (does not affect Article 01's 5 editorial SVG/PNG figures).
4. **Comma-locale regression test:** Skipped on hosts without an installed `fr_`/`de_`/`it_` locale (`test_comma_locale_json_when_available`).

### Remaining Manual Publication Blockers (Must complete before publishing Medium)
1. **Uncommitted / unpushed changes:** Article 01, the 5 figures, `2026-11-19-baseline` evidence, and `Makefile`/doc fixes exist only locally until you review, commit, and push to `origin/main`.
2. **Immutable release tag (`article-01-v1.0.0`):** Per `ADR-004` and the Editorial Charter pre-publication checklist, cut and push tag `article-01-v1.0.0` after pushing `main` so Medium links stay pinned to an immutable snapshot.
3. **Optional Figure 2 / Figure 3 ordering decision:** Confirm whether you are happy with Figure 3 appearing in Section 1 before Figure 2 in Section 2, or prefer swapping their numbers before uploading to Medium.
4. **LinkedIn post & Canva PDF carousel:** Not included in the V2 kit; still need to be authored/exported before full launch per `docs/editorial/01-EDITORIAL-CHARTER.md`.

---

## 8. Publication Checklist (GitHub, Medium & Canva)

### GitHub
- [x] Evidence snapshot `2026-11-19-baseline` verified (7 JSON reports + `manifest.json` SHA-256).
- [x] `make validate`, `make test`, `make validate-evidence`, and `bash -n scripts/*.sh` pass locally.
- [x] `.gitignore` excludes `btm-*.tar.gz` and keeps `docs/results/scenario-01/evidence/` tracked.
- [ ] Review `git status` and `git diff`, commit on `main`, and push to `origin/main`.
- [ ] Verify GitHub Actions `baseline-ci` workflow goes green on `main`.
- [ ] Create and push annotated tag `article-01-v1.0.0` (`git tag -a article-01-v1.0.0 -m "Beyond the Mesh — Article 01 baseline release" && git push origin article-01-v1.0.0`).

### Medium
- [ ] Import text from `docs/articles/01-kubernetes-found-the-service.md`.
- [ ] Upload the 5 `1400 × 800` PNG exports from `docs/articles/assets/01/` with alt text and captions.
- [ ] Verify GitHub link (`https://github.com/Lionelsan95/beyond_service_mesh` or tagged URL `.../tree/article-01-v1.0.0`) resolves cleanly in an incognito browser.
- [ ] Preview mobile rendering of all 5 figures and the latency table.

### LinkedIn & Canva
- [ ] Draft concise English LinkedIn announcement post (hook → insight → trade-off → link).
- [ ] Build 6–8 slide Canva PDF carousel using the Architecture Notebook palette and the verified figures/numbers from `2026-11-19-baseline`.
- [ ] Cross-check carousel claims against `docs/results/scenario-01/evidence/2026-11-19-baseline/`.

---

## 9. Recommended Git Commit Structure

Split into two clean, auditable commits on `main` (recommended) or one combined release commit:

1. **Commit 1 — Authoritative evidence & reproducibility fixes:**
   - `docs/results/scenario-01/evidence/2026-11-19-baseline/`
   - `docs/results/scenario-01/{README.md,article-evidence.md,observations.md,validation-report.md}`
   - `Makefile`, `.gitignore`, `.github/workflows/ci.yaml`, `scripts/validate-scenario-01-evidence.sh`, `tests/evidence/test_article_01_release.py`
   - Message: `feat(scenario-01): record 2026-11-19-baseline evidence and fix test/validation workflow`
2. **Commit 2 — Article 01 editorial package & figures:**
   - `docs/articles/01-kubernetes-found-the-service.md`
   - `docs/articles/ARTICLE-01-RELEASE-READINESS.md`
   - `docs/articles/assets/01/`
   - `README.md`
   - Message: `docs(article-01): integrate Article 01, figures, and release readiness report`
