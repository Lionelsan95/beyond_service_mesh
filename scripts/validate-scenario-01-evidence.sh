#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
python3 -m unittest tests/evidence/test_scenario_01_report.py tests/evidence/test_article_01_release.py
shopt -s nullglob
snapshots=("$root"/docs/results/scenario-01/evidence/*/healthy-*.json "$root"/docs/results/scenario-01/evidence/*/latency-*.json "$root"/docs/results/scenario-01/evidence/*/failure-*.json "$root"/docs/results/scenario-01/evidence/*/recovery-*.json "$root"/docs/results/scenario-01/evidence/*/network-*.json)
if [ "${#snapshots[@]}" -gt 0 ]; then
  python3 "$root/scripts/scenario-01-report.py" validate "${snapshots[@]}"
fi
normalized=("$root"/docs/results/scenario-01/evidence/*/normalized/*.json)
if [ "${#normalized[@]}" -gt 0 ]; then
  python3 "$root/scripts/scenario-01-report.py" validate "${normalized[@]}"
else
  echo "SKIPPED normalized historical evidence: no normalized derivative exists"
fi
