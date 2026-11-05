## 1. Title

# Bank Performance and Risk Early-Warning Scorecard

![Verified dashboard preview](visuals/dashboard-overview.png)

An Oracle SQL, PL/SQL, and Power BI portfolio case study using official FDIC institution-level quarterly financial data.

## 2. Executive Summary

This project converts 96,902 FDIC institution-quarter records from 2020 Q1 through 2024 Q4 into a validated performance and peer-benchmarking solution. The analysis tracks profitability, margin, funding, capitalization, lending, and credit quality across 20 quarters and four asset-size peer groups. In 2024, median ROA recovered from 0.882% in Q1 to 0.936% in Q4 and median NIM rose from 3.329% to 3.428%. At the same time, median loans-to-deposits reached 78.605% and median noncurrent loans rose to 0.335%, supporting continued funding and credit-quality monitoring. Oracle scripts define controlled staging, validation, dimensional storage, analytical views, and peer percentiles. PL/SQL prevents invalid batches from promotion. Power BI specifications and DAX support four stakeholder pages. The native Oracle and Power BI runtimes were unavailable locally, so their execution status is reported transparently.

## 3. Business Problem

Bank executives cannot evaluate performance from one earnings number. Profitability can improve while funding pressure, credit deterioration, or portfolio concentration rises. Comparisons are also misleading when a community bank is measured against a globally active institution.

The intended stakeholders are finance leadership, asset-liability committees, risk management, strategy teams, and regional executives. This case study addresses four questions:

1. How did industry profitability, margin, funding, lending, capital, and asset-quality indicators change from 2020 Q1 to 2024 Q4?
2. How do those indicators differ across documented asset-size peer groups?
3. Which institutions combine low peer-relative profitability with high peer-relative noncurrent loans and therefore warrant analyst review?
4. Which year-over-year changes are large enough to investigate through institution-level drill-through?

The scorecard is a descriptive screening tool. It does not predict bank failure, assign regulatory ratings, or establish why a metric changed.

## 4. Methodology

1. **Acquire a fixed official dataset.** `scripts/fetch_fdic_financials.py` calls the public [FDIC BankFind Financials API](https://api.fdic.gov/banks/docs), requests 29 documented fields, and writes a source manifest containing the API index, extraction timestamp, row count, and SHA-256 hash.
2. **Validate before analysis.** `scripts/build_verified_outputs.py` rejects duplicate institution-quarter keys, invalid required numerics, and dates outside the 20-quarter scope. Documented null `NETINC` and `ROE` values remain null and are excluded only from affected measures.
3. **Stage safely in Oracle.** `sql/00_schema.sql` separates raw source text from typed dimensions and facts. `sql/02_data_quality.sql` centralizes validation rules rather than scattering them across reports.
4. **Control promotion with PL/SQL.** `plsql/fdic_load_control_pkg.sql` compares expected and actual counts, records row-level issues, and promotes a batch only after validation succeeds.
5. **Calculate banking KPIs consistently.** `sql/03_analytical_views.sql` converts year-to-date net income into quarterly values, assigns asset-size peers, and calculates peer percentiles and medians with Oracle analytical functions.
6. **Answer stakeholder questions.** `sql/04_analysis.sql` contains traceable queries for trends, peer differences, screening outliers, and year-over-year ROA movement.
7. **Design the BI layer.** `powerbi/model.md` defines a star schema, four report pages, interaction behavior, mobile layout, accessibility treatment, and reconciliation controls. `powerbi/dax_measures.dax` contains the report measures.
8. **Reconcile outputs.** The committed processed CSVs, data-quality report, unit tests, and `sql/05_reconciliation.sql` provide independent checkpoints. Raw data are reproducible but excluded from Git because the extract is 25 MB.

## 5. Skills

**Oracle SQL:** External-table loading, typed staging, constraints, joins, CTEs, `LAG`, `PERCENT_RANK`, `PERCENTILE_CONT`, conditional aggregation, peer segmentation, data-quality validation, and KPI reconciliation.

**Oracle PL/SQL:** Package specification/body, controlled batch state, procedures, explicit application errors, exception handling, savepoints, validation logging, and atomic promotion design.

**Power BI:** Star-schema design, Power Query responsibility boundaries, DAX time intelligence, KPI measures, peer benchmarking, drill-through, mobile layout, accessibility, and SQL-to-dashboard reconciliation.

**Business Analytics:** Bank profitability, net interest margin, funding intensity, credit quality, capital, regulatory data interpretation, peer comparison, trend analysis, and executive recommendations.

**Data Engineering & QA:** API pagination, immutable source manifest, SHA-256 verification, null handling, duplicate-key controls, reproducible extracts, unit tests, and transparent verification status.

## 6. Results & Business Recommendation

### Verified findings

- **Industry consolidation with balance-sheet growth:** reporting institutions declined from 5,182 in 2020 Q1 to 4,560 in 2024 Q4, a 12.0% reduction. Over the same endpoints, total assets rose from $20.44 trillion to $24.36 trillion and deposits rose from $15.88 trillion to $19.35 trillion. These are descriptive changes; the dataset does not by itself assign the decline to mergers, failures, or reporting changes.
- **Profitability recovered during 2024:** median ROA rose from 0.882% in Q1 to 0.936% in Q4, while median NIM increased from 3.329% to 3.428%. Median ROA nevertheless remained below its 2021 quarterly peak in this dataset.
- **Funding intensity remained elevated:** median loans-to-deposits was 78.605% in 2024 Q4, 0.945 percentage points above 2024 Q1. This does not prove a liquidity problem, but it supports joint monitoring of lending growth and funding structure.
- **Credit quality weakened from a low base:** median noncurrent loans increased from 0.253% in 2023 Q4 to 0.335% in 2024 Q4, a 0.082 percentage-point or 32.2% relative increase.
- **Peer context materially changes interpretation:** in 2024 Q4, median noncurrent loans ranged from 0.282% for institutions under $1 billion to 0.908% for the 14 institutions above $250 billion. The largest-bank group also had a lower median NIM (2.834%) and lower median loans-to-deposits (56.679%) than the under-$1-billion group. The $250-billion-plus result must be read cautiously because the peer contains only 14 institutions.
- **Quarterly net-income coverage is explicit:** the derived 2024 Q4 net-income total covers 99.52% of reporting institutions; rows with missing source `NETINC` are not treated as zero.

### Recommendations

1. **Use peer-relative screening, not universal thresholds.** Review institutions that remain below the 10th ROA percentile and above the 90th noncurrent-loan percentile within the same asset-size band for two consecutive quarters. This is a proposed investigation rule, not an FDIC standard or distress classification.
2. **Review funding and credit quality together.** Escalate a diagnostic review when rising loans-to-deposits coincides with worsening noncurrent loans, then inspect deposit mix, loan concentration, allowance coverage, and institution context before changing strategy.
3. **Keep large-bank findings separate.** The 14 institutions above $250 billion have structurally different balance sheets; management reporting should not blend them with community and regional banks.
4. **Measure success through review quality.** Track the number of persistent peer outliers, the share receiving documented analyst review, false-positive explanations, and whether flagged movements normalize or persist in later quarters.

### Important limitations

- FDIC data are regulatory financial records, not customer-level behavior or credit files.
- Accounting definitions, mergers, charter changes, and reporting populations can change over time.
- Peer percentile flags are descriptive and do not predict failure or establish causation.
- Monetary API fields are reported in thousands of dollars; the processed summaries convert totals to millions.
- Oracle compilation and native Power BI rendering remain untested because those runtimes were unavailable. The static dashboard is a generated preview, not a `.pbix` screenshot.

## 7. Next Steps

1. Execute and compile all Oracle scripts against Oracle Database 19c or newer, then attach the reconciliation output and PL/SQL test log.
2. Build the native Power BI report from the supplied model and DAX, reconcile every card to the committed CSVs, and test desktop/mobile interactions.
3. Add FDIC institution-history events so the decline in reporter count can be separated into mergers, closures, new reporters, and other structural changes.
4. Test alternative peer definitions using specialization group and community-bank designation, then document whether screening results are stable.
5. Extend the refresh process to later quarters only after the fixed historical build remains reproducible.
