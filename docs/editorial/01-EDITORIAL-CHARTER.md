# Beyond the Mesh — Editorial Charter v1.0
Date: 2026-11-17 | Status: Approved direction; subject to findings from actual labs

## Mission
Teach DevOps engineers, platform engineers, software engineers and technical/cloud architects how to reason about distributed service communication and when a service mesh does—and does not—solve their problems. **Problem → context → alternatives → technical experiment → evidence → architecture decision.**

## Audience & promise
- Primary: DevOps / Platform Engineers and Technical / Cloud Architects. Secondary: experienced developers curious about infrastructure behaviors.
- Accessible to readers familiar with basic containers, HTTP and Kubernetes Services; explain specialized concepts before using them heavily.
- Show realistic operational and migration situations; separate product features from experimentally verified behavior.
- English-only published assets. Project planning may be in French.

## Voice and editorial constraints
- Clear, technically accurate, direct, curious and vendor-neutral. No exaggerated claims, empty buzzwords, tool worship or unearned certainty.
- Each Medium post targets 1,200–1,800 words (flex if evidence needs more space), approximately 6–10 minutes; keep code excerpts small (typically <=25 lines), with complete manifests in GitHub.
- One central question and one architectural decision per article. Explain jargon on first encounter; never replace the real technical term with a misleading metaphor.
- Prefer diagrams, contrasts, tables and actual observations to prose walls. Add alternative text, caption and a clear legend to diagrams.
- Explicitly mark **assumption**, **hypothesis**, **observation**, **interpretation**, and **decision**. No invented measurements or production success stories.
- Disclose lab restrictions and do not generalize local kind benchmark results into production SLO or capacity claims.
- Use original diagrams, original code, public documentation and fictitious sanitized migration narratives; do not use confidential workplace architecture.

## Standard article architecture
1. Hook / real-world incident (100–150 words): what broke, who noticed, why it matters.
2. Why basic mechanisms do or don't solve it: Kubernetes Services, app libraries, API gateway, CNI, network policy as relevant.
3. Option assessment: 2–3 approaches with trade-offs and applicable contexts.
4. Under the hood: diagrams and concrete request/identity/route behavior.
5. Reproduce: short command/YAML excerpt, lab tag, expected vs observed evidence, limitations.
6. Architecture decision: when to use it; when *not* to use it; trade-offs and questions left open.
7. GitHub link and next episode teaser.

## Publication catalogue: Season 1
| # | Working title | Corresponding lab | Core decision |
|---|---|---|---|
| 01 | Service Mesh: When Kubernetes Isn't Enough—and When It Is | 01-baseline | Is a mesh warranted? |
| 02 | Who Really Controls Microservice Traffic? | 02-traffic-and-proxies | What does the data plane add? |
| 03 | One Slow Service, One Failing System: Can a Mesh Help? | 03-resilience | Which timeouts/retries belong where? |
| 04 | Zero Trust Between Services: What Does mTLS Really Protect? | 04-zero-trust | Workload identity vs app authorization vs network isolation |
| 05 | Migrating Without a Big Bang: Canary and Coexistence | 05-progressive-migration | How to shift traffic safely? |
| 06 | Two Clusters, One Application: Migration Pitfalls | 06-cross-cluster | Is mesh interconnection the best option? |
| 07 | Mesh Meets AI: LLMs, Agents and MCP | 07-ai-workloads | Where does mesh end and an AI gateway begin? |
| 08 | Should You Really Run a Service Mesh in Production? | synthesis across all labs | Decision framework and operational burden |

## Visual standard
- Mermaid `.mmd` is canonical source, exported to SVG and high-resolution PNG by pinned tooling. SVG/PNG is a derived asset, not the source.
- Every episode: at least one context / problem diagram and one architecture or flow diagram. The same logical app and naming appear through the series.
- One conceptual diagram + one faithful technical diagram where simplification could cause misunderstandings.
- Reuse consistent semantic colors: neutral infrastructure, teal for selected communication control, amber for trade-off, red for failure; don't rely solely on color.
- Use meaningful captions and versioned filenames; export at readable sizes for mobile readers.

## LinkedIn package for every article
- 1 concise English announcement post, hook → insight → trade-off → clear invitation to read / reproduce; no generic hype.
- 1 Canva-based PDF carousel based on user-supplied template: suggested 6–8 pages (problem, stakes, before, mechanism, observation, decision, read more).
- Link to article / tag; visual and claim review before publication. Do not imply Canva connection/template exists until supplied.
- Keep stable master design, layout grid, font hierarchy, section markers, captions, logo and footer. Use original diagrams adapted to page dimensions.

## Pre-publication checklist
- [ ] Does the opening state a relatable problem and its consequences?
- [ ] Are alternatives and at least one 'do not use a mesh if' condition presented?
- [ ] Are all product/version claims checked against official docs and date noted?
- [ ] Is all quantitative evidence reproducible, linked and qualified?
- [ ] Do diagrams reflect actual mechanics, with simplifications labeled?
- [ ] Does the referenced Git tag exist and pass from a clean environment?
- [ ] Is no employer/client-confidential information included?
- [ ] Is LinkedIn copy accurate and aligned with article + Canva template?

## Editorial governance
- Never publish technical numbers prior to execution. Unexpected or null results are legitimate outcomes.
- First three posts form a pilot. Review technical effort, reader questions and editorial response before locking Episodes 4–8.
- Keep a changelog and record corrections transparently after publication.
