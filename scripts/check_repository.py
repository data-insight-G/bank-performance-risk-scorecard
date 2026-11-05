from __future__ import annotations

import csv
import hashlib
import json
import re
import unittest
from pathlib import Path


EXPECTED_README_SECTIONS = [
    "## 1. Title",
    "## 2. Executive Summary",
    "## 3. Business Problem",
    "## 4. Methodology",
    "## 5. Skills",
    "## 6. Results & Business Recommendation",
    "## 7. Next Steps",
]


class RepositoryCheckError(RuntimeError):
    """Raised when a committed portfolio invariant fails."""


def check_readme(repository_root: Path) -> None:
    readme_text = (repository_root / "README.md").read_text(encoding="utf-8")
    observed_sections = re.findall(r"^## [1-7]\. .+$", readme_text, flags=re.MULTILINE)
    if observed_sections != EXPECTED_README_SECTIONS:
        raise RepositoryCheckError(
            f"README sections are not in the required order: {observed_sections}"
        )
    required_claims = (
        "96,902",
        "0.882%",
        "0.936%",
        "78.605%",
        "32.2%",
        "14 institutions above $250 billion",
    )
    missing_claims = [claim for claim in required_claims if claim not in readme_text]
    if missing_claims:
        raise RepositoryCheckError(f"README is missing verified claims: {missing_claims}")


def check_manifest(repository_root: Path) -> None:
    manifest_path = repository_root / "data" / "source_manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    if manifest["record_count"] != 96_902:
        raise RepositoryCheckError("Source manifest record count must remain 96,902")
    raw_path = repository_root / "data" / "raw" / "fdic_financials_2020q1_2024q4.csv"
    if raw_path.exists():
        observed_hash = hashlib.sha256(raw_path.read_bytes()).hexdigest()
        if observed_hash != manifest["sha256"]:
            raise RepositoryCheckError("Raw extract SHA-256 does not match the source manifest")


def check_processed_outputs(repository_root: Path) -> None:
    industry_path = repository_root / "data" / "processed" / "industry_quarter_summary.csv"
    with industry_path.open("r", encoding="utf-8", newline="") as source_file:
        industry_rows = list(csv.DictReader(source_file))
    if len(industry_rows) != 20:
        raise RepositoryCheckError("Industry summary must contain exactly 20 quarters")
    if industry_rows[-1]["report_date"] != "20241231":
        raise RepositoryCheckError("Industry summary must end at 2024 Q4")
    if industry_rows[-1]["institution_count"] != "4560":
        raise RepositoryCheckError("Latest institution count does not match verified output")
    rows_by_date = {row["report_date"]: row for row in industry_rows}
    if rows_by_date["20240331"]["median_roa_pct"] != "0.8821":
        raise RepositoryCheckError("2024 Q1 median ROA does not match the README baseline")
    if rows_by_date["20241231"]["median_roa_pct"] != "0.9361":
        raise RepositoryCheckError("2024 Q4 median ROA does not match the README result")
    if rows_by_date["20241231"]["median_loans_to_deposits_pct"] != "78.6050":
        raise RepositoryCheckError("2024 Q4 loans-to-deposits does not match the README result")
    prior_noncurrent = float(rows_by_date["20231231"]["median_noncurrent_loans_pct"])
    latest_noncurrent = float(rows_by_date["20241231"]["median_noncurrent_loans_pct"])
    relative_noncurrent_change = round((latest_noncurrent / prior_noncurrent - 1) * 100, 1)
    if relative_noncurrent_change != 32.2:
        raise RepositoryCheckError("Noncurrent-loan relative change does not match the README result")

    peer_path = repository_root / "data" / "processed" / "latest_peer_summary.csv"
    with peer_path.open("r", encoding="utf-8", newline="") as source_file:
        peer_rows = list(csv.DictReader(source_file))
    if len(peer_rows) != 4:
        raise RepositoryCheckError("Peer summary must contain exactly four asset-size bands")
    largest_peer = next(row for row in peer_rows if row["asset_size_band"] == "$250B+")
    if largest_peer["institution_count"] != "14":
        raise RepositoryCheckError("Largest-bank peer count does not match the README result")


def run_unit_tests(repository_root: Path) -> None:
    test_suite = unittest.defaultTestLoader.discover(str(repository_root / "tests"))
    test_result = unittest.TextTestRunner(verbosity=2).run(test_suite)
    if not test_result.wasSuccessful():
        raise RepositoryCheckError("Unit tests failed")


def main() -> None:
    repository_root = Path(__file__).resolve().parents[1]
    check_readme(repository_root)
    check_manifest(repository_root)
    check_processed_outputs(repository_root)
    run_unit_tests(repository_root)
    print("Repository checks passed.")


if __name__ == "__main__":
    main()
