# Ten-pass project quality report

Audit date: 5 November 2026

## Overall conclusion

The reproducible data and analytical pipeline works: the FDIC source replayed exactly, validation passed, calculated outputs rebuilt byte-for-byte, tests passed, README claims reconciled, and the public repository is accessible. Oracle SQL/PLSQL and Power BI are complete implementation specifications but remain **runtime-unverified** because Oracle Database and Power BI Desktop were not available in the execution environment.

| Pass | Area | Status | Evidence |
|---:|---|---|---|
| 1 | Repository baseline | Pass | Local `main` tracked the public remote before the audit; no unrelated files or existing GitHub content were changed. |
| 2 | Live FDIC reproduction | Pass | A new API extraction returned exactly 96,902 rows for 2020 Q1–2024 Q4. |
| 3 | Source integrity | Pass | The new raw extract SHA-256 was exactly `a2955fdd52818cfebc029772d95b7dadaa5d555e2561b8fcc0461677c5069fd4`, matching the committed manifest. Ordered and sorted row comparisons were both identical. |
| 4 | Structural data quality | Pass | 96,902 unique `CERT`/report-date keys, all 20 expected quarter ends, valid required numeric fields, and documented nullable `NETINC`/`ROE` treatment. |
| 5 | Deterministic analytical outputs | Pass | Rebuilt industry and peer CSVs were byte-for-byte identical to the committed files; their SHA-256 hashes were `9c48ed...e59d` and `971590...a6f`. |
| 6 | Calculation tests | Pass | Three unit tests passed for asset-band boundaries, year-to-date net-income differencing, and year-boundary handling. Python compilation and repository invariant checks passed. |
| 7 | README structure and claims | Pass | Exactly seven numbered sections appear in the required order. Automated checks reconcile 96,902 rows, 2024 Q1/Q4 ROA, 2024 Q4 loans-to-deposits, the 32.2% noncurrent-loan change, and the 14-bank largest peer. |
| 8 | Oracle SQL compatibility review | Static pass; runtime not tested | Seven tables have primary keys; five foreign-key relationships are defined; analytical views use documented Oracle `LAG`, `PERCENT_RANK`, and analytic `PERCENTILE_CONT`; external CSV syntax was checked against Oracle 19c documentation. |
| 9 | PL/SQL and Power BI contract review | Static pass; native runtimes not tested | PL/SQL package/body, explicit errors, batch-state checks, savepoint rollback, 19 DAX measures, three single-direction relationships, page design, mobile behavior, and reconciliation rules were inspected. |
| 10 | Public presentation | Pass | Public repository, rendered README, raw README, dashboard image, and FDIC source documentation opened without an authenticated GitHub session. |

## Remaining runtime checks

1. Compile and execute the Oracle scripts and package on Oracle Database 19c or newer.
2. Build the `.pbix` in Power BI Desktop, validate relationships and DAX, and test slicers, drill-through, mobile layout, and KPI reconciliation.
3. Replace the static preview with verified Power BI screenshots only after those checks pass.

No untested component is marked as fully passed.
