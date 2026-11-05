# Bank Performance and Risk Early-Warning Scorecard

![Dashboard preview](visuals/dashboard-overview.png)

**Oracle SQL | PL/SQL | Power BI | FDIC Banking Data**

## Executive Summary

This project analyzes **96,902 FDIC institution-quarter records** from 2020 Q1 through 2024 Q4. It helps finance and risk teams monitor profitability, funding, capital, and credit quality while comparing banks with similar-sized peers.

PL/SQL retrieves paginated FDIC API data directly into Oracle. Oracle SQL validates and models the data, calculates banking KPIs and peer percentiles, and supplies a Power BI reporting model.

Key findings:

- Median ROA increased from **0.882% to 0.936%** during 2024.
- Median loans-to-deposits reached **78.605%** in 2024 Q4.
- Median noncurrent loans increased **32.2% year over year**.
- The number of reporting institutions declined **12.0%** from 2020 Q1.

## Business Problem

Profit growth alone does not show whether a bank is becoming stronger or taking more risk. Executives need to evaluate earnings alongside funding pressure, capital, credit quality, and peer performance.

This project answers four questions:

1. How have industry performance and risk indicators changed over time?
2. How do results differ by asset-size peer group?
3. Which institutions combine weak profitability with high noncurrent loans?
4. Which year-over-year changes require further review?

The scorecard supports investigation; it does not predict bank failure or replace regulatory analysis.

## Methodology

1. **Extract:** PL/SQL uses `UTL_HTTP` to retrieve 29 fields from the [FDIC BankFind Financials API](https://api.fdic.gov/banks/docs).
2. **Validate:** Oracle checks row counts, required fields, numeric values, reporting dates, duplicate institution-quarter keys, and duplicate source fingerprints.
3. **Model:** A controlled staging-to-fact process creates institution, reporting-quarter, asset-band, and financial fact tables.
4. **Analyze:** SQL calculates quarterly net income, trends, peer medians, percentiles, and review flags.
5. **Report:** Nineteen DAX measures support executive, peer, risk, and institution-level Power BI pages.
6. **Reconcile:** SQL and Power BI outputs are compared with committed quarterly and peer summary files.

### Project structure

| Folder | Purpose |
|---|---|
| [`sql/`](sql/) | Schema, validation, analytical views, business questions, and reconciliation |
| [`plsql/`](plsql/) | FDIC API ingestion and controlled batch promotion |
| [`powerbi/`](powerbi/) | Semantic model, DAX measures, page design, and QA checklist |
| [`data/`](data/) | Source manifest and verified summary outputs |
| [`docs/`](docs/) | Data dictionary, methodology, Oracle setup, and verification |

The Oracle schema, three views, and both PL/SQL packages compile successfully on **Oracle Database 21c XE** with zero compiler errors and zero invalid objects.

## Skills

- **Oracle SQL:** data modeling, constraints, CTEs, joins, validation, `LAG`, `PERCENT_RANK`, `PERCENTILE_CONT`, KPI calculation, and reconciliation
- **PL/SQL:** packages, `UTL_HTTP`, JSON parsing, API pagination, HTTPS wallet integration, exception handling, savepoints, and atomic promotion
- **Power BI:** star schema, DAX, KPI design, peer benchmarking, drill-through, mobile layout, and accessibility
- **Banking analytics:** ROA, ROE, NIM, loans-to-deposits, capital, credit quality, asset-size peers, and trend analysis
- **Data quality:** source fingerprinting, null handling, duplicate controls, batch validation, and audit-ready outputs

## Results & Business Recommendation

### Results

- Reporting institutions declined from **5,182 to 4,560**, while total assets increased from **$20.44T to $24.36T**.
- Median ROA improved from **0.882% in 2024 Q1 to 0.936% in Q4**; median NIM increased from **3.329% to 3.428%**.
- Median loans-to-deposits rose to **78.605%**, indicating a need to monitor lending growth with funding conditions.
- Median noncurrent loans increased from **0.253% to 0.335% year over year**.
- In 2024 Q4, median noncurrent loans ranged from **0.282%** for banks under $1B to **0.908%** for banks above $250B.

### Recommendations

1. Review banks that remain below the 10th ROA percentile and above the 90th noncurrent-loan percentile within their peer group for two consecutive quarters.
2. Evaluate rising loans-to-deposits together with credit deterioration, deposit mix, loan concentration, and allowance coverage.
3. Report institutions above $250B separately because their balance sheets differ from community and regional banks.
4. Track flagged institutions, completed analyst reviews, explanations, and whether risk signals persist.

## Next Steps

1. Run the wallet-dependent FDIC refresh in the target Oracle environment.
2. Execute [`sql/05_reconciliation.sql`](sql/05_reconciliation.sql) against the loaded data.
3. Build and validate the native Power BI report from the supplied model and DAX.
4. Add institution-history events to explain mergers, closures, and reporting-population changes.
5. Test peer groups based on specialization and community-bank status.

> The repository includes a verified dashboard preview and Power BI specification, not a `.pbix` file.
