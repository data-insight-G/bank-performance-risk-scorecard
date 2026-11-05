# Power BI semantic model

## Import tables

| Power BI table | Oracle source | Grain | Role |
|---|---|---|---|
| Bank Quarter Metrics | `VW_PEER_QUARTER_BENCHMARK` | Institution × quarter | Central fact/view |
| Institution | `DIM_INSTITUTION` | One row per FDIC certificate | Institution attributes |
| Asset Size Band | `DIM_ASSET_SIZE_BAND` | One row per band | Ordered peer categories |
| Reporting Date | `DIM_REPORTING_QUARTER` | One row per quarter end | Time intelligence |

## Relationships

- `Institution[cert]` 1 → * `Bank Quarter Metrics[cert]`, single direction.
- `Asset Size Band[asset_size_band_key]` 1 → * `Bank Quarter Metrics[asset_size_band_key]`, single direction.
- `Reporting Date[report_date]` 1 → * `Bank Quarter Metrics[report_date]`, single direction.

No bidirectional relationships are required. Hide technical keys and additive raw ratio columns from report authors. Use the documented measures rather than summing percentages.

## Power Query responsibilities

Power Query should only set types and rename presentation labels. Financial logic, date scope, peer definitions, quarterly net-income conversion, and data validation remain in Oracle so there is one source of truth.

## Page design

1. **Executive Overview:** stable KPI cards; ROA/NIM time series; loans-to-deposits and noncurrent-loans trends; last refresh and coverage.
2. **Peer Benchmarking:** asset-band selector; direct-labeled percentile chart; institution-vs-peer trend; comparison table with conditional icons plus numbers.
3. **Risk & Funding Diagnostics:** small multiples for lending/funding and credit-quality indicators; outlier table; visible statement that flags require analyst review.
4. **Institution Detail:** search and drill-through; quarterly financial history; peer percentiles; state and specialization context.

## Interaction contract

- The report opens on the latest quarter with all asset bands selected.
- Asset band, state, community-bank flag, and quarter filters persist across pages.
- Selecting a bank commits the selection and enables institution drill-through.
- Every page provides a visible reset bookmark.
- Essential values remain visible without hover; tooltips add definitions and source notes.
- Quarterly reporting is asynchronous, not real time. The report must show the latest source quarter and extraction timestamp; there is no false “live” indicator.

## Mobile layout

The mobile overview shows the report date, four KPI cards, ROA/NIM trend, then funding and credit-quality trends. Filters open in a pane after the evidence rather than pushing the dashboard below the fold. Dense peer tables are replaced by a ranked list with tap-through detail.

## Color-role ledger

- Neutral context: navy/slate and light gray.
- Primary focal metric: teal.
- Comparison/peer reference: gold.
- Review-required state: coral plus an icon and text label; color is never the only signal.

## QA checklist

- Reconcile the latest-quarter card values to `data/processed/industry_quarter_summary.csv`.
- Reconcile each asset-band median to `data/processed/latest_peer_summary.csv`.
- Test slicers, reset bookmarks, drill-through, keyboard order, alt text, and 200% zoom.
- Verify that ratio measures use medians and are not summed.
- Confirm the quarterly net-income coverage measure remains visible.
