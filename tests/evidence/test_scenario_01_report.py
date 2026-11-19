import json
import locale
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
REPORTER = ROOT / "scripts" / "scenario-01-report.py"


class Scenario01ReportTests(unittest.TestCase):
    def run_report(self, locale_name="C", experiment="healthy", delay=None, statuses="201=20", errors="0", service="1\n2\n"):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory); client = root / "client"; downstream = root / "downstream"; output = root / "report.json"
            client.write_text("7.865\n29.038\n44.860\n"); downstream.write_text(service)
            env = os.environ | {"LC_ALL": locale_name}
            command = ["python3", str(REPORTER), "experiment", "--experiment", experiment, "--samples", "20", "--expected-status", "201", "--statuses", statuses, "--error-count", errors, "--client-timings", str(client), "--service-timings", str(downstream), "--output", str(output), "--campaign-id", "test-campaign", "--git-commit", "test-commit"]
            if delay is not None:
                command += ["--delay-ms", str(delay)]
            if experiment == "failure":
                command += ["--failure-injection"]
            subprocess.run(command, check=True, env=env)
            return json.loads(output.read_text())

    def test_c_locale_json_and_numeric_types(self):
        report = self.run_report()
        self.assertIsInstance(report["error_rate"], float)
        self.assertIsInstance(report["client_observed_latency_ms"]["p50"], float)
        self.assertEqual(report["client_observed_latency_ms"]["p50"], 29.038)

    def test_comma_locale_json_when_available(self):
        choices = [value for value in locale.locale_alias.values() if "." in value and value.lower().startswith(("fr_", "de_", "it_"))]
        available = next((value for value in choices if self._available(value)), None)
        if not available:
            self.skipTest("No comma-decimal locale is installed; run with e.g. LC_ALL=fr_FR.UTF-8 when available.")
        report = self.run_report(available)
        self.assertEqual(report["client_observed_latency_ms"]["p95"], 44.86)

    def _available(self, candidate):
        try:
            previous = locale.setlocale(locale.LC_ALL)
            locale.setlocale(locale.LC_ALL, candidate)
            locale.setlocale(locale.LC_ALL, previous)
            return True
        except locale.Error:
            return False

    def test_experiment_structures(self):
        for name, delay, statuses, errors in (("healthy", None, "201=20", "0"), ("latency", 300, "201=20", "0"), ("failure", None, "502=20", "0"), ("recovery", None, "201=20", "0")):
            report = self.run_report(experiment=name, delay=delay, statuses=statuses, errors=errors)
            self.assertEqual(report["experiment"], name)
            self.assertIsInstance(report["http_status_distribution"], dict)

    def test_missing_service_measurements_are_null(self):
        report = self.run_report(service="")
        self.assertIsNone(report["payment_service_observed_latency_ms"]["p50"])

    def test_historical_normalization_preserves_numbers(self):
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / "raw"; source.mkdir(); source.joinpath("healthy.json").write_text('{"error_rate":0,000000,"p50_ms":2004,995000}')
            destination = Path(directory) / "derivative"
            subprocess.run(["python3", str(REPORTER), "normalize", "--source", str(source), "--destination", str(destination)], check=True)
            report = json.loads((destination / "normalized" / "healthy.json").read_text())
            self.assertEqual(report["error_rate"], 0.0); self.assertEqual(report["p50_ms"], 2004.995)

    def test_network_structure(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory); endpoints = root / "endpoints"; pods = root / "pods"; output = root / "network.json"
            endpoints.write_text("10.244.0.11\n"); pods.write_text("10.244.0.11\n")
            subprocess.run(["python3", str(REPORTER), "network", "--service", "payment-service", "--cluster-ip", "10.96.55.245", "--endpoint-file", str(endpoints), "--pod-file", str(pods), "--output", str(output)], check=True)
            report = json.loads(output.read_text())
            self.assertEqual(report["endpoint_ips"], ["10.244.0.11"])


if __name__ == "__main__":
    unittest.main()
