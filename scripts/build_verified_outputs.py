from __future__ import annotations

import argparse
import csv
import json
import statistics
from collections import defaultdict
from dataclasses import dataclass
from decimal import Decimal, InvalidOperation
from pathlib import Path
from typing import Iterable


EXPECTED_REPORT_DATES = (
    "20200331", "20200630", "20200930", "20201231",
    "20210331", "20210630", "20210930", "20211231",
    "20220331", "20220630", "20220930", "20221231",
    "20230331", "20230630", "20230930", "20231231",
    "20240331", "20240630", "20240930", "20241231",
)
REQUIRED_FIELDS = (
    "cert", "repdte", "name", "asset", "dep", "lnlsnet", "netinc",
    "roa", "roe", "nimy", "eqv", "lnlsdepr", "nclnlsr", "ntlnlsr",
)
ASSET_BANDS = (
    (Decimal("0"), Decimal("1000000"), "Under $1B"),
    (Decimal("1000000"), Decimal("10000000"), "$1B–$10B"),
    (Decimal("10000000"), Decimal("250000000"), "$10B–$250B"),
    (Decimal("250000000"), None, "$250B+"),
)


class AnalyticsValidationError(RuntimeError):
    """Raised when source data violate an analytical invariant."""


@dataclass(frozen=True)
class FinancialRecord:
    cert: int
    report_date: str
    name: str
    state: str
    asset: Decimal
    deposits: Decimal
    net_loans: Decimal
    year_to_date_net_income: Decimal | None
    roa: Decimal
    roe: Decimal | None
    net_interest_margin: Decimal
    equity_to_assets: Decimal
    loans_to_deposits: Decimal
    noncurrent_loans_ratio: Decimal
    net_charge_off_ratio: Decimal


def parse_decimal(raw_value: str, field_name: str, row_number: int) -> Decimal:
    if raw_value == "":
        raise AnalyticsValidationError(f"Row {row_number} has no value for required field {field_name}")
    try:
        return Decimal(raw_value)
    except InvalidOperation as error:
        raise AnalyticsValidationError(
            f"Row {row_number} has invalid numeric value {raw_value!r} for {field_name}"
        ) from error


def parse_optional_decimal(raw_value: str, field_name: str, row_number: int) -> Decimal | None:
    if raw_value == "":
        return None
    return parse_decimal(raw_value, field_name, row_number)


def read_records(source_csv: Path) -> list[FinancialRecord]:
    with source_csv.open("r", encoding="utf-8", newline="") as source_file:
        reader = csv.DictReader(source_file)
        if reader.fieldnames is None:
            raise AnalyticsValidationError("Source CSV has no header")
        missing_fields = sorted(set(REQUIRED_FIELDS) - set(reader.fieldnames))
        if missing_fields:
            raise AnalyticsValidationError(f"Source CSV is missing required fields: {missing_fields}")

        records: list[FinancialRecord] = []
        observed_keys: set[tuple[int, str]] = set()
        for row_number, row in enumerate(reader, start=2):
            cert_raw = row["cert"]
            if not cert_raw.isdigit():
                raise AnalyticsValidationError(f"Row {row_number} has invalid CERT {cert_raw!r}")
            cert = int(cert_raw)
            report_date = row["repdte"]
            if report_date not in EXPECTED_REPORT_DATES:
                raise AnalyticsValidationError(f"Row {row_number} has out-of-scope report date {report_date!r}")
            record_key = (cert, report_date)
            if record_key in observed_keys:
                raise AnalyticsValidationError(f"Duplicate CERT/report-date key: {record_key}")
            observed_keys.add(record_key)
            records.append(
                FinancialRecord(
                    cert=cert,
                    report_date=report_date,
                    name=row["name"],
                    state=row.get("stalp", ""),
                    asset=parse_decimal(row["asset"], "asset", row_number),
                    deposits=parse_decimal(row["dep"], "dep", row_number),
                    net_loans=parse_decimal(row["lnlsnet"], "lnlsnet", row_number),
                    year_to_date_net_income=parse_optional_decimal(row["netinc"], "netinc", row_number),
                    roa=parse_decimal(row["roa"], "roa", row_number),
                    roe=parse_optional_decimal(row["roe"], "roe", row_number),
                    net_interest_margin=parse_decimal(row["nimy"], "nimy", row_number),
                    equity_to_assets=parse_decimal(row["eqv"], "eqv", row_number),
                    loans_to_deposits=parse_decimal(row["lnlsdepr"], "lnlsdepr", row_number),
                    noncurrent_loans_ratio=parse_decimal(row["nclnlsr"], "nclnlsr", row_number),
                    net_charge_off_ratio=parse_decimal(row["ntlnlsr"], "ntlnlsr", row_number),
                )
            )

    observed_report_dates = {record.report_date for record in records}
    if observed_report_dates != set(EXPECTED_REPORT_DATES):
        missing_dates = sorted(set(EXPECTED_REPORT_DATES) - observed_report_dates)
        raise AnalyticsValidationError(f"Source CSV is missing expected report dates: {missing_dates}")
    return records


def asset_band(asset_thousands: Decimal) -> str:
    for lower_bound, upper_bound, label in ASSET_BANDS:
        if asset_thousands < lower_bound:
            continue
        if upper_bound is None or asset_thousands < upper_bound:
            return label
    raise AnalyticsValidationError(f"No asset band configured for {asset_thousands}")


def median(values: Iterable[Decimal]) -> Decimal:
    materialized_values = list(values)
    if not materialized_values:
        raise AnalyticsValidationError("Median requires at least one value")
    return Decimal(str(statistics.median(materialized_values)))


def quarterly_net_income(records: list[FinancialRecord]) -> dict[tuple[int, str], Decimal | None]:
    records_by_institution: dict[int, list[FinancialRecord]] = defaultdict(list)
    for record in records:
        records_by_institution[record.cert].append(record)

    results: dict[tuple[int, str], Decimal | None] = {}
    for institution_records in records_by_institution.values():
        sorted_records = sorted(institution_records, key=lambda record: record.report_date)
        prior_record: FinancialRecord | None = None
        for record in sorted_records:
            month_day = record.report_date[4:]
            if record.year_to_date_net_income is None:
                results[(record.cert, record.report_date)] = None
            elif month_day == "0331":
                results[(record.cert, record.report_date)] = record.year_to_date_net_income
            elif (
                prior_record is not None
                and prior_record.report_date[:4] == record.report_date[:4]
                and prior_record.year_to_date_net_income is not None
            ):
                results[(record.cert, record.report_date)] = (
                    record.year_to_date_net_income - prior_record.year_to_date_net_income
                )
            else:
                results[(record.cert, record.report_date)] = None
            prior_record = record
    return results


def format_decimal(value: Decimal, places: int = 4) -> str:
    return f"{value:.{places}f}"


def build_industry_quarter_rows(records: list[FinancialRecord]) -> list[dict[str, str]]:
    records_by_quarter: dict[str, list[FinancialRecord]] = defaultdict(list)
    for record in records:
        records_by_quarter[record.report_date].append(record)
    net_income_by_key = quarterly_net_income(records)

    summary_rows: list[dict[str, str]] = []
    for report_date in EXPECTED_REPORT_DATES:
        quarter_records = records_by_quarter[report_date]
        quarter_net_income_values: list[Decimal] = []
        for record in quarter_records:
            net_income_value = net_income_by_key[(record.cert, report_date)]
            if net_income_value is not None:
                quarter_net_income_values.append(net_income_value)
        summary_rows.append(
            {
                "report_date": report_date,
                "institution_count": str(len(quarter_records)),
                "total_assets_usd_millions": format_decimal(sum(r.asset for r in quarter_records) / Decimal("1000"), 1),
                "total_deposits_usd_millions": format_decimal(sum(r.deposits for r in quarter_records) / Decimal("1000"), 1),
                "total_net_loans_usd_millions": format_decimal(sum(r.net_loans for r in quarter_records) / Decimal("1000"), 1),
                "quarter_net_income_usd_millions": format_decimal(sum(quarter_net_income_values) / Decimal("1000"), 1),
                "quarter_net_income_coverage": format_decimal(
                    Decimal(len(quarter_net_income_values)) / Decimal(len(quarter_records)), 4
                ),
                "median_roa_pct": format_decimal(median(r.roa for r in quarter_records)),
                "median_roe_pct": format_decimal(median(r.roe for r in quarter_records if r.roe is not None)),
                "median_nim_pct": format_decimal(median(r.net_interest_margin for r in quarter_records)),
                "median_equity_to_assets_pct": format_decimal(median(r.equity_to_assets for r in quarter_records)),
                "median_loans_to_deposits_pct": format_decimal(median(r.loans_to_deposits for r in quarter_records)),
                "median_noncurrent_loans_pct": format_decimal(median(r.noncurrent_loans_ratio for r in quarter_records)),
                "median_net_charge_offs_pct": format_decimal(median(r.net_charge_off_ratio for r in quarter_records)),
            }
        )
    return summary_rows


def build_latest_peer_rows(records: list[FinancialRecord]) -> list[dict[str, str]]:
    latest_records = [record for record in records if record.report_date == EXPECTED_REPORT_DATES[-1]]
    records_by_band: dict[str, list[FinancialRecord]] = defaultdict(list)
    for record in latest_records:
        records_by_band[asset_band(record.asset)].append(record)

    peer_rows: list[dict[str, str]] = []
    for _, _, label in ASSET_BANDS:
        band_records = records_by_band[label]
        peer_rows.append(
            {
                "asset_size_band": label,
                "institution_count": str(len(band_records)),
                "total_assets_usd_millions": format_decimal(sum(r.asset for r in band_records) / Decimal("1000"), 1),
                "median_roa_pct": format_decimal(median(r.roa for r in band_records)),
                "median_roe_pct": format_decimal(median(r.roe for r in band_records if r.roe is not None)),
                "median_nim_pct": format_decimal(median(r.net_interest_margin for r in band_records)),
                "median_equity_to_assets_pct": format_decimal(median(r.equity_to_assets for r in band_records)),
                "median_loans_to_deposits_pct": format_decimal(median(r.loans_to_deposits for r in band_records)),
                "median_noncurrent_loans_pct": format_decimal(median(r.noncurrent_loans_ratio for r in band_records)),
                "median_net_charge_offs_pct": format_decimal(median(r.net_charge_off_ratio for r in band_records)),
            }
        )
    return peer_rows


def write_csv(output_path: Path, rows: list[dict[str, str]]) -> None:
    if not rows:
        raise AnalyticsValidationError(f"No rows were produced for {output_path}")
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with output_path.open("w", encoding="utf-8", newline="") as output_file:
        writer = csv.DictWriter(output_file, fieldnames=list(rows[0].keys()), lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def build_outputs(source_csv: Path, output_directory: Path, quality_report_path: Path) -> None:
    records = read_records(source_csv)
    industry_rows = build_industry_quarter_rows(records)
    peer_rows = build_latest_peer_rows(records)
    write_csv(output_directory / "industry_quarter_summary.csv", industry_rows)
    write_csv(output_directory / "latest_peer_summary.csv", peer_rows)

    quality_report = {
        "system_version": "1.0.0",
        "status": "pass",
        "validated_record_count": len(records),
        "unique_institution_quarter_keys": len({(record.cert, record.report_date) for record in records}),
        "reporting_quarter_count": len({record.report_date for record in records}),
        "minimum_report_date": min(record.report_date for record in records),
        "maximum_report_date": max(record.report_date for record in records),
        "latest_institution_count": sum(
            1 for record in records if record.report_date == EXPECTED_REPORT_DATES[-1]
        ),
        "quarter_net_income_coverage_latest": industry_rows[-1]["quarter_net_income_coverage"],
        "checks": [
            "Required headers present",
            "CERT values are integers",
            "Required numeric fields parse without coercion",
            "Documented nullable NETINC and ROE values remain null and are excluded from affected measures",
            "CERT/report-date keys are unique",
            "Exactly 20 expected quarter-end dates are represented",
            "All latest-quarter institutions map to one configured asset-size band",
        ],
    }
    quality_report_path.parent.mkdir(parents=True, exist_ok=True)
    quality_report_path.write_text(json.dumps(quality_report, indent=2) + "\n", encoding="utf-8")


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Validate FDIC data and build verified portfolio outputs.")
    parser.add_argument("--source", required=True, type=Path)
    parser.add_argument("--output-directory", required=True, type=Path)
    parser.add_argument("--quality-report", required=True, type=Path)
    return parser.parse_args()


def main() -> None:
    arguments = parse_arguments()
    build_outputs(
        arguments.source.resolve(),
        arguments.output_directory.resolve(),
        arguments.quality_report.resolve(),
    )


if __name__ == "__main__":
    main()
