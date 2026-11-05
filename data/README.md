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
- `raw/`: excluded from Git. Recreate the 25 MB CSV with the extraction script.

## Reproduce the raw extract

From the repository root:

```powershell
uv run python scripts/fetch_fdic_financials.py `
  --output data/raw/fdic_financials_2020q1_2024q4.csv `
  --manifest data/source_manifest.json
```

Then validate and rebuild the processed outputs:

```powershell
uv run python scripts/build_verified_outputs.py `
  --source data/raw/fdic_financials_2020q1_2024q4.csv `
  --output-directory data/processed `
  --quality-report docs/data_quality_report.json
```

Because the API can be revised, a later extraction may have a different row count or hash. Do not overwrite the documented historical manifest without reviewing and explaining the change.
