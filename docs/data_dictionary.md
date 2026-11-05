# Analytical data dictionary

The full FDIC field definitions remain authoritative. Monetary fields from the Financials API are stored in **thousands of U.S. dollars** unless stated otherwise.

| Source field | Analytical name | Meaning used in this project | Treatment |
|---|---|---|---|
| `CERT` | cert | FDIC certificate identifier | Institution key |
| `REPDTE` | report_date | Quarter-end reporting date | Parsed from `YYYYMMDD` |
| `NAME` | institution_name | Published institution name | Latest name retained in dimension |
| `STALP` | state_code | Headquarters state abbreviation | Nullable |
| `SPECGRPDESC` | specialization_group | FDIC specialization description | Descriptive peer context |
| `CB` | community_bank_flag | FDIC community-bank indicator | 0/1; nullable |
| `ASSET` | total_assets_thousands | Total assets | Required numeric |
| `DEP` | total_deposits_thousands | Total deposits | Required numeric |
| `DEPDOM` | domestic_deposits_thousands | Domestic deposits | Nullable numeric |
| `COREDEP` | core_deposits_thousands | Core deposits | Nullable numeric |
| `LNLSNET` | net_loans_thousands | Net loans and leases | Required numeric |
| `NETINC` | net_income_ytd_thousands | Year-to-date net income | Nullable; differenced within year for quarterly value |
| `ROA` | roa_pct | Return on assets | FDIC-reported percentage |
| `ROE` | roe_pct | Return on equity | Nullable percentage |
| `NIMY` | net_interest_margin_pct | Year-to-date net interest margin | FDIC-reported percentage |
| `EQ` | equity_capital_thousands | Equity capital | Nullable numeric |
| `EQV` | equity_to_assets_pct | Equity capital as share of assets | FDIC-reported percentage |
| `LNLSDEPR` | loans_to_deposits_pct | Net loans and leases to deposits | FDIC-reported percentage |
| `NCLNLSR` | noncurrent_loans_pct | Noncurrent loans and leases as share of loans | FDIC-reported percentage |
| `NTLNLSR` | net_charge_offs_pct | Net charge-offs as share of loans | FDIC-reported percentage |
| `LNATRESR` | allowance_to_loans_pct | Allowance relative to loans | Nullable percentage |
| `OFFDOM` | domestic_office_count | Domestic office count | Nullable whole number |

Portfolio-balance fields beginning with `SZLN` are retained for future concentration analysis but have substantial structural missingness in this extract. They are not used in the headline findings.

## Derived fields

- **Quarter net income:** Q1 uses reported year-to-date net income; Q2–Q4 subtract the immediately preceding quarter within the same calendar year. Missing current or prior values produce null, never zero.
- **Asset-size band:** under $1B; $1B–$10B; $10B–$250B; and $250B+, using `ASSET` in thousands.
- **Peer percentile:** `PERCENT_RANK` within report date and asset-size band.
- **Industry summary medians:** institution-level median for the quarter; percentages are not summed.
