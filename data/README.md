# Data provenance and reproduction

## Source

- Publisher: Federal Deposit Insurance Corporation (FDIC)
- Dataset: BankFind Suite Financials API
- Documentation: https://api.fdic.gov/banks/docs
- Endpoint: https://api.fdic.gov/banks/financials
- Filter: `REPDTE:[20200331 TO 20241231]`
- Extracted: 5 November 2026 at 15:45:28 UTC
- Records: 96,902 institution-quarter rows
- Source SHA-256: `a2955fdd52818cfebc029772d95b7dadaa5d555e2561b8fcc0461677c5069fd4`

The FDIC describes BankFind as publicly available bank data. This repository attributes the source and does not apply the repository's MIT code licence to FDIC data. Review the FDIC website terms before redistributing a raw extract.

## Files

- `source_manifest.json`: immutable extraction metadata, fields, count, date boundaries, API index, and hash.
- `processed/industry_quarter_summary.csv`: 20 rows of verified quarterly totals and medians.
- `processed/latest_peer_summary.csv`: verified 2024 Q4 medians for four asset-size bands.
- `raw/`: excluded from Git. The primary workflow loads the API directly into Oracle and does not require a CSV.

## Load the approved snapshot

1. Configure the Oracle network ACL and HTTPS wallet as described in `docs/oracle_network_setup.md`.
2. Run `sql/00_schema.sql`, `sql/01_reference_data.sql`, and `sql/02_data_quality.sql`.
3. Compile `plsql/fdic_load_control_pkg.sql`, followed by `plsql/fdic_api_ingestion_pkg.sql`.
4. Run `sql/11_run_api_refresh.sql` and provide the wallet path and password when prompted.
5. Run the analytical views, analysis queries, and reconciliation script.

The package fails if the API metadata no longer reports 96,902 rows, if the same source fingerprint was already loaded, or if Oracle validation finds data-quality issues. `sql/10_external_load.sql` remains an optional Oracle external-table fallback for environments where outbound database network access is prohibited.

Because the API can be revised, a later extraction may have a different row count or hash. Do not overwrite the documented historical manifest without reviewing and explaining the change.
