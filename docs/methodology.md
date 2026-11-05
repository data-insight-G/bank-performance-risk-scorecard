# Methodology

## Analytical grain

One row represents one FDIC certificate at one quarter end. Institutions remain in the analysis even when they do not report all 20 quarters.

## Validation

The ingestion package requires the approved API row count and a new source fingerprint. Oracle then validates reporting dates, `CERT`/`REPDTE` uniqueness, required fields, and numeric measures before promotion. Missing `NETINC` and `ROE` values remain null and are excluded from affected calculations.

## Peer groups

Institutions are grouped by assets: under $1B, $1B–$10B, $10B–$250B, and $250B+. These analytical groups are not regulatory classifications.

## Review flag

The outlier query identifies institutions below the 10th ROA percentile and above the 90th noncurrent-loan percentile within the same quarter and asset group. A flag prioritizes analyst review; it is not a failure prediction.

## Reporting controls

- Show the source quarter and extraction timestamp.
- Retain the last validated view when a refresh fails.
- Distinguish stale, incomplete, rejected, and unavailable states.
- Use labels and icons so color is not the only signal.
- Reconcile dashboard values to the committed summaries.

The source manifest records the API parameters, extraction time, row count, index, reference hash, and Oracle metadata fingerprint.
