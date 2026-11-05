-- Question 1: How have industry medians and balance-sheet totals changed by quarter?
SELECT report_date,
       COUNT(*) AS institution_count,
       ROUND(SUM(total_assets_thousands) / 1000, 1) AS total_assets_usd_millions,
       ROUND(SUM(total_deposits_thousands) / 1000, 1) AS total_deposits_usd_millions,
       ROUND(SUM(net_loans_thousands) / 1000, 1) AS total_net_loans_usd_millions,
       ROUND(SUM(quarter_net_income_thousands) / 1000, 1) AS quarter_net_income_usd_millions,
       ROUND(MEDIAN(roa_pct), 4) AS median_roa_pct,
       ROUND(MEDIAN(net_interest_margin_pct), 4) AS median_nim_pct,
       ROUND(MEDIAN(loans_to_deposits_pct), 4) AS median_loans_to_deposits_pct,
       ROUND(MEDIAN(noncurrent_loans_pct), 4) AS median_noncurrent_loans_pct
FROM vw_bank_quarter_metrics
GROUP BY report_date
ORDER BY report_date;

-- Question 2: How do latest-quarter risk and return measures vary by asset-size peer group?
SELECT asset_size_band_name,
       COUNT(*) AS institution_count,
       ROUND(MEDIAN(roa_pct), 4) AS median_roa_pct,
       ROUND(MEDIAN(net_interest_margin_pct), 4) AS median_nim_pct,
       ROUND(MEDIAN(equity_to_assets_pct), 4) AS median_equity_to_assets_pct,
       ROUND(MEDIAN(loans_to_deposits_pct), 4) AS median_loans_to_deposits_pct,
       ROUND(MEDIAN(noncurrent_loans_pct), 4) AS median_noncurrent_loans_pct,
       ROUND(MEDIAN(net_charge_offs_pct), 4) AS median_net_charge_offs_pct
FROM vw_bank_quarter_metrics
WHERE report_date = DATE '2024-12-31'
GROUP BY asset_size_band_key, asset_size_band_name
ORDER BY asset_size_band_key;

-- Question 3: Which latest-quarter peer outliers warrant analyst review?
SELECT cert,
       report_date,
       asset_size_band_name,
       ROUND(roa_pct, 3) AS roa_pct,
       ROUND(roa_peer_percentile, 3) AS roa_peer_percentile,
       ROUND(noncurrent_loans_pct, 3) AS noncurrent_loans_pct,
       ROUND(noncurrent_loans_peer_percentile, 3) AS noncurrent_peer_percentile
FROM vw_peer_quarter_benchmark
WHERE report_date = DATE '2024-12-31'
  AND roa_peer_percentile <= 0.10
  AND noncurrent_loans_peer_percentile >= 0.90
ORDER BY asset_size_band_key, roa_peer_percentile, noncurrent_loans_peer_percentile DESC;

-- Question 4: Which institutions experienced the largest year-over-year movement in ROA?
WITH comparative_metrics AS (
    SELECT cert,
           report_date,
           asset_size_band_name,
           roa_pct,
           LAG(roa_pct, 4) OVER (PARTITION BY cert ORDER BY report_date) AS prior_year_roa_pct
    FROM vw_bank_quarter_metrics
)
SELECT cert,
       asset_size_band_name,
       ROUND(roa_pct, 3) AS roa_pct,
       ROUND(prior_year_roa_pct, 3) AS prior_year_roa_pct,
       ROUND(roa_pct - prior_year_roa_pct, 3) AS roa_change_percentage_points
FROM comparative_metrics
WHERE report_date = DATE '2024-12-31'
  AND prior_year_roa_pct IS NOT NULL
ORDER BY ABS(roa_pct - prior_year_roa_pct) DESC
FETCH FIRST 25 ROWS ONLY;
