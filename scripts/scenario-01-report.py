#!/usr/bin/env python3
"""Locale-independent JSON reporting and evidence utilities for Scenario 01."""
import argparse
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys


def utc_now():
    return dt.datetime.now(dt.timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def percentile(path, percentage):
    values = sorted(float(line.strip()) for line in Path(path).read_text().splitlines() if line.strip())
    if not values:
        return None
    index = max(0, min(len(values) - 1, int((percentage / 100) * len(values) + 0.999999) - 1))
    return values[index]


def parse_statuses(raw):
    result = {}
    if raw:
        for pair in raw.split(","):
            code, count = pair.split("=", 1)
            result[str(int(code))] = int(count)
    return result


def experiment(args):
    statuses = parse_statuses(args.statuses)
    data = {
        "captured_at_utc": args.captured_at,
        "experiment": args.experiment,
        "sample_count": args.samples,
        "expected_http_status": args.expected_status,
        "http_status_distribution": statuses,
        "error_count": args.error_count,
        "error_rate": args.error_count / args.samples,
        "client_observed_latency_ms": {p: percentile(args.client_timings, int(p[1:])) for p in ("p50", "p95", "p99")},
        "payment_service_observed_latency_ms": {p: percentile(args.service_timings, int(p[1:])) for p in ("p50", "p95", "p99")},
        "request_controls": {"payment_delay_ms": args.delay_ms, "failure_injection": args.failure_injection},
        "metadata": {
            "campaign_id": args.campaign_id,
            "git_commit": args.git_commit,
            "cluster_context": args.cluster_context,
            "namespace": args.namespace,
            "node_image_reference": args.node_image_reference,
        },
        "note": "Client latency is curl time_total through kubectl port-forward. Payment latency is measured by order-service around its downstream HTTP call; neither is a production benchmark.",
    }
    Path(args.output).write_text(json.dumps(data, indent=2, ensure_ascii=False, allow_nan=False) + "\n")


def network(args):
    data = {
        "captured_at_utc": args.captured_at,
        "service": args.service,
        "cluster_ip": args.cluster_ip,
        "endpoint_ips": [line for line in Path(args.endpoint_file).read_text().splitlines() if line],
        "pod_ips": [line for line in Path(args.pod_file).read_text().splitlines() if line],
        "metadata": {"campaign_id": args.campaign_id, "git_commit": args.git_commit,
                     "cluster_context": args.cluster_context, "namespace": args.namespace,
                     "node_image_reference": args.node_image_reference},
    }
    Path(args.output).write_text(json.dumps(data, indent=2, ensure_ascii=False, allow_nan=False) + "\n")


def validate(paths):
    failed = False
    for raw in paths:
        try:
            data = json.loads(Path(raw).read_text())
            if not isinstance(data, dict):
                raise ValueError("top-level value is not an object")
            print(f"PASS {raw}")
        except (OSError, ValueError, json.JSONDecodeError) as error:
            print(f"FAIL {raw}: {error}", file=sys.stderr)
            failed = True
    return 1 if failed else 0


def normalize(args):
    destination = Path(args.destination)
    destination.mkdir(parents=True, exist_ok=False)
    manifest = {"kind": "historical-normalized-derivative", "created_at_utc": utc_now(), "files": []}
    for source in sorted(Path(args.source).glob("*.json")):
        raw = source.read_text()
        # Historical defect: a comma occurred only between digits inside numeric literals.
        normalized = re.sub(r"(?<=\d),(?=\d)", ".", raw)
        data = json.loads(normalized)
        raw_copy = destination / "raw" / source.name
        raw_copy.parent.mkdir(exist_ok=True)
        shutil.copy2(source, raw_copy)
        target = destination / "normalized" / source.name
        target.parent.mkdir(exist_ok=True)
        target.write_text(json.dumps(data, indent=2, ensure_ascii=False, allow_nan=False) + "\n")
        manifest["files"].append({"name": source.name, "raw_sha256": sha256(source), "normalized_sha256": sha256(target)})
    (destination / "normalization-manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")


def sha256(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def snapshot(args):
    sources = [Path(item) for item in args.files]
    reports = [json.loads(path.read_text()) for path in sources]
    required = {"healthy", "failure", "recovery", "network"}
    types = {report.get("experiment", "network") for report in reports}
    latencies = {report.get("request_controls", {}).get("payment_delay_ms") for report in reports if report.get("experiment") == "latency"}
    if not required <= types or latencies != {300, 1500, 2500}:
        raise ValueError("campaign must contain healthy, failure, recovery, network, and 300/1500/2500 ms latency reports")
    metadata = [report.get("metadata") for report in reports]
    if any(not item or item.get("campaign_id") != args.campaign_id for item in metadata):
        raise ValueError("reports lack a matching explicit campaign_id; historical timestamp proximity is not provenance")
    keys = ("git_commit", "cluster_context", "namespace", "node_image_reference")
    baseline = {key: metadata[0].get(key) for key in keys}
    if any({key: item.get(key) for key in keys} != baseline for item in metadata):
        raise ValueError("reports have inconsistent source or cluster provenance")
    target = Path(args.destination) / args.campaign_id
    if target.exists():
        raise FileExistsError(f"snapshot already exists: {target}")
    target.mkdir(parents=True)
    for source in sources:
        shutil.copy2(source, target / source.name)
    dirty = subprocess.run(["git", "diff", "--quiet"], cwd=args.repository).returncode != 0
    manifest = {"kind": "scenario-01-evidence-snapshot", "created_at_utc": utc_now(), "campaign_id": args.campaign_id,
                "source_provenance": baseline, "working_tree_dirty": dirty,
                "files": [{"name": source.name, "sha256": sha256(source)} for source in sources]}
    (target / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")


def parser():
    root = argparse.ArgumentParser()
    commands = root.add_subparsers(required=True)
    common = argparse.ArgumentParser(add_help=False)
    common.add_argument("--captured-at", default=utc_now()); common.add_argument("--campaign-id", default=os.getenv("SCENARIO_01_CAMPAIGN_ID", "unassigned"))
    common.add_argument("--git-commit", default=os.getenv("SCENARIO_01_GIT_COMMIT", "unknown")); common.add_argument("--cluster-context", default="kind-btm-lab")
    common.add_argument("--namespace", default="btm-lab"); common.add_argument("--node-image-reference", default="kindest/node:v1.37.0")
    exp = commands.add_parser("experiment", parents=[common]); exp.add_argument("--experiment", required=True); exp.add_argument("--samples", type=int, required=True)
    exp.add_argument("--expected-status", type=int, required=True); exp.add_argument("--statuses", required=True); exp.add_argument("--error-count", type=int, required=True)
    exp.add_argument("--client-timings", required=True); exp.add_argument("--service-timings", required=True); exp.add_argument("--delay-ms", type=int)
    exp.add_argument("--failure-injection", action="store_true"); exp.add_argument("--output", required=True); exp.set_defaults(func=experiment)
    net = commands.add_parser("network", parents=[common]); net.add_argument("--service", required=True); net.add_argument("--cluster-ip", required=True)
    net.add_argument("--endpoint-file", required=True); net.add_argument("--pod-file", required=True); net.add_argument("--output", required=True); net.set_defaults(func=network)
    valid = commands.add_parser("validate"); valid.add_argument("files", nargs="+"); valid.set_defaults(func=lambda a: validate(a.files))
    norm = commands.add_parser("normalize"); norm.add_argument("--source", required=True); norm.add_argument("--destination", required=True); norm.set_defaults(func=normalize)
    snap = commands.add_parser("snapshot"); snap.add_argument("--campaign-id", required=True); snap.add_argument("--destination", required=True); snap.add_argument("--repository", required=True); snap.add_argument("files", nargs="+"); snap.set_defaults(func=snapshot)
    return root


if __name__ == "__main__":
    arguments = parser().parse_args()
    result = arguments.func(arguments)
    raise SystemExit(result if isinstance(result, int) else 0)
