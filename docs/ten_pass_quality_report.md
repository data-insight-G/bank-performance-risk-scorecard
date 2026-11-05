# Ten-pass project quality report

Audit date: 5 November 2026

## Overall conclusion

The repository now uses Oracle SQL and PL/SQL for ingestion, validation, and analysis, with Power BI for reporting. The source provenance, expected outputs, business claims, repository structure, and public presentation are verified. The Oracle objects compile successfully on Oracle Database 21c XE. The wallet-dependent HTTPS refresh and native Power BI rendering remain explicitly untested.

| Pass | Area | Status | Evidence |
|---:|---|---|---|
| 1 | Technology scope | Pass | Repository source is limited to Oracle SQL, Oracle PL/SQL, Power BI specifications, documentation, data outputs, and static assets. |
| 2 | Dataset provenance | Pass | The manifest records the official FDIC endpoint, 29 fields, 96,902 rows, 20 quarter ends, API index, reference CSV hash, and Oracle metadata fingerprint. |
| 3 | Oracle API ingestion | Compile pass; live API not tested | Package specification/body compile on Oracle 21c XE; `UTL_HTTP` pagination, wallet use, metadata validation, SHA-256 fingerprinting, JSON parsing, staging, and empty-page detection are implemented. |
| 4 | Oracle schema | Pass | Seven typed tables created on Oracle 21c XE with primary keys, constraints, load state, institution, quarter, peer-band, fact, and quality-issue responsibilities. |
| 5 | Oracle validation | Pass (compile) | Validation view compiled; it checks certificate, quarter, institution name, required numerics, duplicate keys, and expected batch count before promotion. |
| 6 | PL/SQL controls | Pass (compile) | Both package specifications and bodies compiled with zero errors; explicit errors, batch-state checks, quality logging, savepoint rollback, and promotion controls are present. |
| 7 | Analytical SQL | Pass (compile) | Two analytical views compiled with quarterly net income, asset-size bands, `LAG`, `PERCENT_RANK`, and analytic `PERCENTILE_CONT`; stakeholder and reconciliation queries are supplied. |
| 8 | Power BI design | Static pass; Power BI not tested | Nineteen DAX measures reference modeled columns, three single-direction relationships are documented, and desktop/mobile/reconciliation requirements are defined. |
| 9 | README and business claims | Pass | Exactly seven numbered sections remain in order; headline values reconcile to the committed 20-quarter and four-peer expected outputs. |
| 10 | Public presentation | Pass | Public repository, README, dashboard image, and FDIC documentation are accessible without an authenticated GitHub session. |

## Remaining native runtime checks

1. Configure the Oracle network ACL and HTTPS wallet for `api.fdic.gov`.
2. Execute the wallet-dependent API refresh in the target Oracle environment.
3. Run `sql/05_reconciliation.sql` and compare its results with the expected CSV outputs.
4. Build the `.pbix`, reconcile every DAX measure, and test slicers, drill-through, accessibility, and mobile layout.

Oracle compilation and environment-dependent runtime execution are reported separately so no unexecuted component is presented as tested.
