from __future__ import annotations

import argparse
import csv
import hashlib
import json
import time
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


API_ENDPOINT = "https://api.fdic.gov/banks/financials"
PERIOD_START = "20200331"
PERIOD_END = "20241231"
PAGE_SIZE = 10_000
SOURCE_FIELDS = (
    "CERT",
    "REPDTE",
    "NAME",
    "STALP",
    "SPECGRPDESC",
    "CB",
    "ASSET",
    "DEP",
    "DEPDOM",
    "COREDEP",
    "LNLSNET",
    "NETINC",
    "ROA",
    "ROE",
    "NIMY",
    "EQ",
    "EQV",
    "LNLSDEPR",
    "NCLNLSR",
    "NTLNLSR",
    "LNATRESR",
    "OFFDOM",
    "SZLNRES",
    "SZLNCI",
    "SZLNCRCD",
    "SZLNAUTO",
    "SZLNCON",
    "SZLNHEL",
    "SZLNOTH",
)


class FdicExtractionError(RuntimeError):
    """Raised when the FDIC response violates the extraction contract."""


def _request_page(offset: int) -> dict[str, Any]:
    query_parameters = {
        "filters": f"REPDTE:[{PERIOD_START} TO {PERIOD_END}]",
        "fields": ",".join(SOURCE_FIELDS),
        "sort_by": "REPDTE",
        "sort_order": "ASC",
        "limit": str(PAGE_SIZE),
        "offset": str(offset),
    }
    request_url = f"{API_ENDPOINT}?{urllib.parse.urlencode(query_parameters)}"
    request = urllib.request.Request(
        request_url,
        headers={"Accept": "application/json", "User-Agent": "bank-performance-portfolio/1.0"},
    )
    try:
        with urllib.request.urlopen(request, timeout=90) as response:
            payload = json.load(response)
    except Exception as error:
        raise FdicExtractionError(f"FDIC request failed at offset {offset}: {error}") from error

    if not isinstance(payload, dict) or "meta" not in payload or "data" not in payload:
        raise FdicExtractionError(f"FDIC response at offset {offset} is missing meta or data")
    return payload


def _normalize_record(api_record: dict[str, Any]) -> dict[str, str]:
    record_body = api_record.get("data")
    if not isinstance(record_body, dict):
        raise FdicExtractionError("FDIC record is missing its data object")

    normalized_record: dict[str, str] = {}
    for source_field in SOURCE_FIELDS:
        source_value = record_body.get(source_field)
        normalized_record[source_field.lower()] = "" if source_value is None else str(source_value)
    return normalized_record


def extract_records() -> tuple[list[dict[str, str]], dict[str, Any]]:
    first_page = _request_page(0)
    total_records = first_page["meta"].get("total")
    if not isinstance(total_records, int) or total_records <= 0:
        raise FdicExtractionError("FDIC metadata did not provide a positive total record count")

    all_records: list[dict[str, str]] = []
    page_payload = first_page
    offset = 0
    while offset < total_records:
        if offset > 0:
            time.sleep(0.15)
            page_payload = _request_page(offset)
        page_records = page_payload.get("data")
        if not isinstance(page_records, list) or not page_records:
            raise FdicExtractionError(f"FDIC returned an empty page before completion at offset {offset}")
        for api_record in page_records:
            if not isinstance(api_record, dict):
                raise FdicExtractionError(f"FDIC returned a non-object record at offset {offset}")
            all_records.append(_normalize_record(api_record))
        offset += len(page_records)

    if len(all_records) != total_records:
        raise FdicExtractionError(
            f"Extracted {len(all_records)} records but FDIC metadata reported {total_records}"
        )
    return all_records, first_page["meta"]


def write_extract(output_csv: Path, manifest_path: Path) -> None:
    records, source_metadata = extract_records()
    output_csv.parent.mkdir(parents=True, exist_ok=True)
    fieldnames = [source_field.lower() for source_field in SOURCE_FIELDS]
    with output_csv.open("w", encoding="utf-8", newline="") as output_file:
        writer = csv.DictWriter(output_file, fieldnames=fieldnames, lineterminator="\n")
        writer.writeheader()
        writer.writerows(records)

    file_hash = hashlib.sha256(output_csv.read_bytes()).hexdigest()
    report_dates = [record["repdte"] for record in records]
    manifest = {
        "system_version": "1.0.0",
        "publisher": "Federal Deposit Insurance Corporation",
        "dataset": "BankFind Suite Financials API",
        "source_endpoint": API_ENDPOINT,
        "source_filter": f"REPDTE:[{PERIOD_START} TO {PERIOD_END}]",
        "source_fields": list(SOURCE_FIELDS),
        "extracted_at_utc": datetime.now(timezone.utc).isoformat(),
        "record_count": len(records),
        "minimum_report_date": min(report_dates),
        "maximum_report_date": max(report_dates),
        "sha256": file_hash,
        "api_index": source_metadata.get("index"),
        "redistribution": "Raw extract is not committed; reproduce it with this script.",
    }
    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Download the fixed FDIC portfolio analysis window.")
    parser.add_argument("--output", required=True, type=Path, help="Destination CSV path")
    parser.add_argument("--manifest", required=True, type=Path, help="Destination manifest JSON path")
    return parser.parse_args()


def main() -> None:
    arguments = parse_arguments()
    write_extract(arguments.output.resolve(), arguments.manifest.resolve())


if __name__ == "__main__":
    main()
