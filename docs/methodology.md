# Methodology and interpretation controls

## Analytical grain

One row represents one FDIC certificate at one quarter end. The project keeps an unbalanced panel: institutions are not removed merely because they lack all 20 quarters.

## Validation contract

Excel Power Query first requires the API row count, the 20 expected quarter ends, and unique `CERT`/`REPDTE` keys. Oracle then validates required fields and numeric measures before batch promotion. Missing `NETINC` and `ROE` values are permitted because they occur in the official extract; affected calculations exclude those rows and disclose coverage.

## Peer design

Asset size is used as the first peer dimension because scale materially changes bank balance sheets. The four bands are transparent and stored as reference data rather than hidden report logic. They are analytical categories, not regulatory peer groups. A later version should test specialization and community-bank status.

## Screening logic

The Oracle outlier query identifies institutions below the 10th percentile for ROA and above the 90th percentile for noncurrent loans within the same quarter and size band. This combination prioritizes review; it is not a prediction, rating, or allegation. Persistence across two quarters is recommended before operational escalation.

## Dashboard design contract

- Analytical job: quarterly monitoring, peer comparison, and diagnostic drill-through.
- Artifact family: asynchronous executive dashboard with four coordinated pages.
- First scan: latest quarter, coverage, profitability, funding, and credit-quality state.
- On-demand detail: peer distribution, institution history, geography, and specialization.
- Static fallback: accessible SVG/PNG generated from committed verified summaries.
- Refresh behavior: full quarterly snapshot replacement with the last-known verified view retained if refresh fails.
- Failure states: stale, incomplete, validation-rejected, and unavailable must be visually distinct.
- Accessibility: direct labels, redundant alert icons/text, keyboard order, alt text, and no hover-only evidence.

## Reproducibility

The source manifest freezes API parameters, timestamp, row count, index version, and file hash. The Excel Power Query contains the complete paginated extraction and validation logic. The raw extract is not committed; two small expected outputs are committed so README findings and Oracle reconciliation targets can be reviewed without downloading 25 MB.
