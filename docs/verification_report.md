# Verification report

| Component | Status | Verification evidence |
|---|---|---|
| Dataset | Pass | Live FDIC API extraction; 96,902 rows; 20 quarter ends; SHA-256 in `data/source_manifest.json` |
| Local analytical calculations | Pass | Strict CSV validation, processed outputs, and three passing unit tests |
| Oracle SQL | Not tested | Scripts reviewed statically; no Oracle runtime or Docker was available |
| Oracle PL/SQL | Not tested | Package reviewed statically; compilation and execution require Oracle |
| Power BI | Not tested | Model, DAX, page design, and reconciliation plan supplied; Power BI Desktop unavailable |
| README | Pass | Seven required sections in the required order; numeric claims reconcile to committed CSVs |
| GitHub repository | Pending | To be updated after remote creation and push |
| GitHub profile | Not changed | Existing private repositories preserved; no profile README existed |
| Public links | Pending | To be tested after repository publication |

“Not tested” is deliberate: files are not marked passed when the required runtime was unavailable.
