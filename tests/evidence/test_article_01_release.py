import hashlib
import json
from pathlib import Path
import re
import struct
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
EVIDENCE_DIR = ROOT / "docs" / "results" / "scenario-01" / "evidence" / "2026-11-19-baseline"
ARTICLE_PATH = ROOT / "docs" / "articles" / "01-kubernetes-found-the-service.md"
ASSETS_DIR = ROOT / "docs" / "articles" / "assets" / "01"
EXPECTED_FIGURES = [
    "01-application-map",
    "02-network-path",
    "03-latency-results",
    "04-timeout-timeline",
    "05-architecture-decision",
]


class Article01ReleaseTests(unittest.TestCase):
    def test_evidence_manifest_and_sha256_checksums(self):
        manifest_path = EVIDENCE_DIR / "manifest.json"
        self.assertTrue(manifest_path.is_file(), f"missing {manifest_path}")
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        self.assertEqual(manifest["kind"], "scenario-01-evidence-snapshot")
        self.assertEqual(manifest["campaign_id"], "2026-11-19-baseline")
        self.assertFalse(manifest["working_tree_dirty"])
        self.assertEqual(len(manifest["files"]), 7)

        provenance = manifest["source_provenance"]
        for entry in manifest["files"]:
            report_path = EVIDENCE_DIR / entry["name"]
            self.assertTrue(report_path.is_file(), f"missing {report_path}")
            actual_sha = hashlib.sha256(report_path.read_bytes()).hexdigest()
            self.assertEqual(actual_sha, entry["sha256"], f"checksum mismatch for {entry['name']}")
            report = json.loads(report_path.read_text(encoding="utf-8"))
            self.assertEqual(report["metadata"]["campaign_id"], manifest["campaign_id"])
            for key in ("git_commit", "cluster_context", "namespace", "node_image_reference"):
                self.assertEqual(report["metadata"][key], provenance[key])

    def test_evidence_metrics_match_article_claims(self):
        reports = [
            json.loads((EVIDENCE_DIR / entry["name"]).read_text(encoding="utf-8"))
            for entry in json.loads((EVIDENCE_DIR / "manifest.json").read_text(encoding="utf-8"))["files"]
        ]
        by_key = {}
        for report in reports:
            exp = report.get("experiment", "network")
            if exp == "latency":
                by_key[f"latency-{report['request_controls']['payment_delay_ms']}"] = report
            else:
                by_key[exp] = report

        self.assertEqual(by_key["healthy"]["client_observed_latency_ms"]["p50"], 15.804)
        self.assertEqual(by_key["healthy"]["http_status_distribution"], {"201": 20})
        self.assertEqual(by_key["latency-300"]["client_observed_latency_ms"]["p50"], 308.562)
        self.assertEqual(by_key["latency-300"]["http_status_distribution"], {"201": 20})
        self.assertEqual(by_key["latency-1500"]["client_observed_latency_ms"]["p50"], 1508.864)
        self.assertEqual(by_key["latency-1500"]["http_status_distribution"], {"201": 20})
        self.assertEqual(by_key["latency-2500"]["client_observed_latency_ms"]["p50"], 2005.149)
        self.assertEqual(by_key["latency-2500"]["http_status_distribution"], {"502": 20})
        self.assertEqual(by_key["failure"]["http_status_distribution"], {"502": 20})
        self.assertEqual(by_key["failure"]["expected_http_status"], 502)
        self.assertEqual(by_key["failure"]["error_rate"], 0.0)
        self.assertEqual(by_key["recovery"]["http_status_distribution"], {"201": 20})
        self.assertEqual(by_key["network"]["cluster_ip"], "10.96.55.245")
        self.assertEqual(by_key["network"]["endpoint_ips"], ["10.244.0.15"])
        self.assertEqual(by_key["network"]["pod_ips"], ["10.244.0.15"])

        article = ARTICLE_PATH.read_text(encoding="utf-8")
        for token in ("15.8 ms", "308.6 ms", "1,508.9 ms", "2,005.1 ms", "10.96.55.245", "10.244.0.15", "2026-11-19-baseline"):
            self.assertIn(token, article)

    def test_svg_and_png_assets_are_valid_and_paired(self):
        for stem in EXPECTED_FIGURES:
            svg_path = ASSETS_DIR / f"{stem}.svg"
            png_path = ASSETS_DIR / f"{stem}.png"
            self.assertTrue(svg_path.is_file(), f"missing {svg_path}")
            self.assertTrue(png_path.is_file(), f"missing {png_path}")

            root = ET.fromstring(svg_path.read_text(encoding="utf-8"))
            self.assertEqual(root.attrib.get("viewBox"), "0 0 1400 800", f"unexpected viewBox in {svg_path}")

            header = png_path.read_bytes()[:24]
            self.assertEqual(header[:8], b"\x89PNG\r\n\x1a\n", f"invalid PNG signature in {png_path}")
            width, height = struct.unpack(">II", header[16:24])
            self.assertEqual((width, height), (1400, 800), f"unexpected PNG size in {png_path}")

    def test_article_markdown_links_and_fences(self):
        text = ARTICLE_PATH.read_text(encoding="utf-8")
        fence_count = sum(1 for line in text.splitlines() if line.strip().startswith("```"))
        self.assertEqual(fence_count % 2, 0, "unbalanced fenced code blocks in article")
        self.assertNotIn("[FIGURE", text, "unreplaced figure placeholder remains in article")

        referenced_pngs = set()
        for target in re.findall(r"!?\[[^\]]*\]\(([^)]+)\)", text):
            if target.startswith(("http://", "https://", "#")):
                continue
            resolved = (ARTICLE_PATH.parent / target).resolve()
            self.assertTrue(resolved.exists(), f"broken relative link in article: {target}")
            if resolved.suffix == ".png":
                referenced_pngs.add(resolved.stem)
        self.assertEqual(referenced_pngs, set(EXPECTED_FIGURES))


if __name__ == "__main__":
    unittest.main()
