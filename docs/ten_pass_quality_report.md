# Ten-pass project quality report

Audit date: 5 November 2026

## Overall conclusion

The repository now uses only Excel Power Query, Oracle SQL, Oracle PL/SQL, and Power BI. The source provenance, expected outputs, business claims, repository structure, and public presentation are verified. Native execution in Excel, Oracle Database, and Power BI Desktop remains explicitly untested because those applications were unavailable in the execution environment.

| Pass | Area | Status | Evidence |
|---:|---|---|---|
| 1 | Technology scope | Pass | Repository source is limited to Excel Power Query, Oracle SQL, Oracle PL/SQL, Power BI specifications, documentation, and static assets. |
| 2 | Dataset provenance | Pass | The manifest records the official FDIC endpoint, 29 fields, 96,902 rows, 20 quarter ends, API index, extraction time, and source SHA-256. |
| 3 | Excel acquisition design | Static pass; Excel not tested | Power Query paginates in 10,000-row blocks, selects the documented fields, assigns types, and fails on count, duplicate-key, or quarter-set mismatches. |
| 4 | Oracle schema | Static pass; Oracle not tested | Seven typed tables define primary keys, constraints, load state, institution, quarter, peer-band, fact, and quality-issue responsibilities. |
| 5 | Oracle validation | Static pass; Oracle not tested | Boundary validation checks certificate, quarter, institution name, required numerics, duplicate keys, and expected batch count before promotion. |
| 6 | PL/SQL controls | Static pass; Oracle not tested | Package/body, explicit application errors, batch-state checks, quality logging, savepoint rollback, and promotion controls are present. |
| 7 | Analytical SQL | Static pass; Oracle not tested | Quarterly net income, asset-size bands, `LAG`, `PERCENT_RANK`, analytic `PERCENTILE_CONT`, stakeholder queries, and reconciliation SQL are supplied. |
| 8 | Power BI design | Static pass; Power BI not tested | Nineteen DAX measures reference modeled columns, three single-direction relationships are documented, and desktop/mobile/reconciliation requirements are defined. |
| 9 | README and business claims | Pass | Exactly seven numbered sections remain in order; headline values reconcile to the committed 20-quarter and four-peer expected outputs. |
| 10 | Public presentation | Pass | Public repository, README, dashboard image, and FDIC documentation are accessible without an authenticated GitHub session. |

## Remaining native runtime checks

1. Refresh the Power Query in Microsoft Excel and export the validated UTF-8 CSV.
2. Compile and execute the Oracle scripts and PL/SQL package on Oracle Database 19c or newer.
3. Run `sql/05_reconciliation.sql` and compare its results with the expected CSV outputs.
4. Build the `.pbix`, reconcile every DAX measure, and test slicers, drill-through, accessibility, and mobile layout.

No native component is marked as passed when its required application was unavailable.
