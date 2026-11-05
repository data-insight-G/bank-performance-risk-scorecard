# Verification report

| Component | Status | Verification evidence |
|---|---|---|
| Dataset | Pass | Live FDIC API extraction; 96,902 rows; 20 quarter ends; SHA-256 in `data/source_manifest.json` |
| Reference outputs | Pass | Committed 20-quarter and four-peer CSVs reconcile to the README values and Oracle reconciliation targets |
| Oracle SQL | Pass (compile) | Seven tables, four asset bands, 20 reporting quarters, one validation view, and two analytical views created successfully on Oracle Database 21c XE with zero invalid objects |
| Oracle PL/SQL | Pass (compile) | Both package specifications and bodies compiled successfully on Oracle Database 21c XE with zero compiler errors; the live HTTPS refresh was not run because it requires an environment-specific wallet and network ACL |
| Power BI | Not tested | Model, DAX, page design, and reconciliation plan supplied; Power BI Desktop unavailable |
| README | Pass | Seven required sections in the required order; headline numeric claims reconcile to committed CSVs |
| GitHub repository | Pass | Public repository at `https://github.com/data-insight-G/bank-performance-risk-scorecard`; local and remote `main` were synchronized after publication |
| GitHub profile | Not changed | Existing private repositories preserved; no profile README existed |
| Public links | Pass | Repository, raw README, dashboard image, and FDIC documentation opened without an authenticated GitHub session |

Runtime status is explicit: Oracle compilation was tested, while the wallet-dependent API call and native Power BI report were not executed.
