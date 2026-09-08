#!/usr/bin/env python3
"""Check an sf project deploy start/report --json result against repository Apex."""
import json
from pathlib import Path
import re
import sys


def check(report_path):
    root = Path(__file__).resolve().parents[2]
    source = root / "force-app/main/default"
    expected = set()
    for path in [*source.rglob("*.cls"), *source.rglob("*.trigger")]:
        body = re.sub(r"/\*.*?\*/|//[^\n]*", "", path.read_text(), flags=re.S)
        if not re.search(r"@istest\b", body, flags=re.I):
            expected.add(path.stem)
    report = json.loads(Path(report_path).read_text())
    result = report.get("result", {})
    tests = result.get("details", {}).get("runTestResult", {})
    errors = []
    if report.get("status") != 0 or result.get("success") is not True:
        errors.append("Deployment/validation did not succeed.")
    if int(tests.get("numTestsRun", 0)) == 0 or int(tests.get("numFailures", -1)) != 0:
        errors.append("Tests must run with zero failures.")
    coverage = tests.get("codeCoverage", [])
    if isinstance(coverage, dict):
        coverage = [coverage]
    by_name = {item["name"]: item for item in coverage if not item.get("namespace")}
    if not expected:
        errors.append("No production Apex source found.")
    for name in sorted(expected):
        item = by_name.get(name)
        if item is None:
            errors.append(f"{name}: coverage missing.")
            continue
        total = int(item["numLocations"])
        covered = total - int(item["numLocationsNotCovered"])
        if total == 0:
            print(f"{name}: no executable locations")
            continue
        print(f"{name}: {covered}/{total} ({100 * covered / total:.2f}%)")
        if covered * 100 < total * 90:
            errors.append(f"{name}: below 90%.")
    for error in errors:
        print(f"FAIL: {error}", file=sys.stderr)
    if not errors:
        print(f"PASS: {tests['numTestsRun']} tests; every repository production Apex class/trigger meets 90%.")
    return bool(errors)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit("Usage: python3 scripts/validation/check_apex_coverage.py DEPLOY_RESULT.json")
    sys.exit(check(sys.argv[1]))
