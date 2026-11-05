# Verification report

| Component | Status | Verification evidence |
|---|---|---|
| Dataset | Pass | Live FDIC API extraction; 96,902 rows; 20 quarter ends; SHA-256 in `data/source_manifest.json` |
| Excel Power Query | Not tested | Paginated M query and fail-fast validation supplied; Microsoft Excel runtime unavailable |
| Reference outputs | Pass | Committed 20-quarter and four-peer CSVs reconcile to the README values and Oracle reconciliation targets |
| Oracle SQL | Not tested | Scripts reviewed statically; no Oracle runtime or Docker was available |
| Oracle PL/SQL | Not tested | Package reviewed statically; compilation and execution require Oracle |
| Power BI | Not tested | Model, DAX, page design, and reconciliation plan supplied; Power BI Desktop unavailable |
| README | Pass | Seven required sections in the required order; headline numeric claims reconcile to committed CSVs |
| GitHub repository | Pass | Public repository at `https://github.com/data-insight-G/bank-performance-risk-scorecard`; local and remote `main` were synchronized after publication |
| GitHub profile | Not changed | Existing private repositories preserved; no profile README existed |
| Public links | Pass | Repository, raw README, dashboard image, and FDIC documentation opened without an authenticated GitHub session |

“Not tested” is deliberate: files are not marked passed when Excel, Oracle Database, or Power BI Desktop was unavailable.
