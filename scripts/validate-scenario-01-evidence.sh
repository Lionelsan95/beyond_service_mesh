#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
python3 -m unittest tests/evidence/test_scenario_01_report.py
shopt -s nullglob
normalized=("$root"/docs/results/scenario-01/evidence/*/normalized/*.json)
if [ "${#normalized[@]}" -gt 0 ]; then
  python3 "$root/scripts/scenario-01-report.py" validate "${normalized[@]}"
else
  echo "SKIPPED normalized historical evidence: no normalized derivative exists"
fi
