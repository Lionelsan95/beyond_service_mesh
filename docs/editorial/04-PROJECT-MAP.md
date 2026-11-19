# Beyond the Mesh — Project Roadmap v1.0

## Foundation to publication
- Phase 0 (now): freeze editorial charter, architecture concept and Codex bootstrap instructions. **The application has not been implemented.**
- Phase 1: Codex builds baseline; review code, diagrams, constraints, exact version lock, smoke tests and validation report.
- Phase 2: use validated baseline to write Article 01; create 2–3 precise diagrams and Git tag; produce LinkedIn post and Canva carousel using user-provided base template.
- Phase 3: introduce traffic proxies for Article 02; test sidecar / ambient claims against installed exact Istio patch.
- Phase 4: resilience injection for Article 03; perform repeated test runs and publish raw evidence.
- Editorial checkpoint after Article 03: revise backlog based on reader feedback, maintainability and empirical findings.
- Subsequent phases: security, progressive migration, cross-cluster, AI and architectural synthesis.

## Content bundle convention for each article
```
content/article-01/
  outline.md
  article.md
  linkedin-post.md
  carousel-script.md
  evidence-index.md
  images/  # derived from diagrams, not their source
```
This is a proposed content workspace: do not require its creation during technical bootstrap unless useful. Actual Canva designs remain in Canva and PDF exports are linked after creation.

## Publication definition of done
1. Lab scenario runs on documented host with clean replay and a version tag.
2. Evidence index lists tests, conditions, raw outputs and result caveats.
3. Architecture alternatives + a negative recommendation are written.
4. Diagram sources/exports are aligned with real implementation.
5. Medium article is reviewed for English, length and accuracy.
6. LinkedIn post and Canva PDF convey same decision, without unsupported claims.
