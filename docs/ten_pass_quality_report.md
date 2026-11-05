# Ten-pass quality report

Reviewed on 5 November 2026.

| # | Check | Result |
|---:|---|---|
| 1 | Technology scope | Oracle SQL, PL/SQL, and Power BI only |
| 2 | Source provenance | FDIC endpoint, 29 fields, row count, API index, and hashes recorded |
| 3 | API ingestion | Pagination, wallet, JSON parsing, fingerprinting, and rollback reviewed |
| 4 | Database schema | Seven tables created successfully on Oracle 21c XE |
| 5 | Data validation | Required values, numeric fields, dates, duplicates, and counts checked |
| 6 | PL/SQL controls | Both packages compiled with zero errors |
| 7 | Analytical SQL | Three views compiled; trend and percentile logic reviewed |
| 8 | Power BI | Nineteen DAX measures and three relationships checked |
| 9 | Business results | README figures reconciled to committed outputs |
| 10 | Repository | Public links, file scope, and Git synchronization verified |

Pending runtime work: execute the wallet-dependent API refresh and build the native Power BI report.
