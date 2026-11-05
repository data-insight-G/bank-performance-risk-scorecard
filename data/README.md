# Data

## Source

- Publisher: Federal Deposit Insurance Corporation (FDIC)
- Dataset: BankFind Suite Financials API
- Documentation: https://api.fdic.gov/banks/docs
- Endpoint: https://api.fdic.gov/banks/financials
- Filter: `REPDTE:[20200331 TO 20241231]`
- Extracted: 5 November 2026 at 15:45:28 UTC
- Records: 96,902 institution-quarter rows
- Reference CSV SHA-256: `a2955fdd52818cfebc029772d95b7dadaa5d555e2561b8fcc0461677c5069fd4`

The raw extract is not committed. Review FDIC terms before redistributing source data.

## Files

- `source_manifest.json`: source parameters, fields, row count, API index, and hashes
- `processed/industry_quarter_summary.csv`: verified quarterly totals and medians
- `processed/latest_peer_summary.csv`: verified 2024 Q4 peer-group medians

## Reproduce

1. Configure the network ACL and wallet using `docs/oracle_network_setup.md`.
2. Run `sql/00_schema.sql`, `sql/01_reference_data.sql`, and `sql/02_data_quality.sql`.
3. Compile `plsql/fdic_load_control_pkg.sql`, followed by `plsql/fdic_api_ingestion_pkg.sql`.
4. Run `sql/11_run_api_refresh.sql`.
5. Run the analytical and reconciliation scripts.

The load fails on an unexpected row count, duplicate fingerprint, or validation issue. Use `sql/10_external_load.sql` when outbound database access is unavailable.
