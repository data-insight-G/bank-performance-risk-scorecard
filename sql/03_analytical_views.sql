CREATE OR REPLACE VIEW vw_bank_quarter_metrics AS
WITH sequenced_financials AS (
    SELECT fact.*,
           LAG(net_income_ytd_thousands) OVER (
               PARTITION BY cert, EXTRACT(YEAR FROM report_date)
               ORDER BY report_date
           ) AS prior_net_income_ytd_thousands
    FROM fact_bank_financial_quarter fact
), quarter_metrics AS (
    SELECT sequenced_financials.*,
           CASE
               WHEN net_income_ytd_thousands IS NULL THEN NULL
               WHEN TO_CHAR(report_date, 'MMDD') = '0331' THEN net_income_ytd_thousands
               WHEN prior_net_income_ytd_thousands IS NULL THEN NULL
               ELSE net_income_ytd_thousands - prior_net_income_ytd_thousands
           END AS quarter_net_income_thousands
    FROM sequenced_financials
)
SELECT quarter_metrics.*,
       band.asset_size_band_key,
       band.asset_size_band_name
FROM quarter_metrics
JOIN dim_asset_size_band band
  ON quarter_metrics.total_assets_thousands >= band.lower_asset_thousands
 AND (
     band.upper_asset_thousands IS NULL
     OR quarter_metrics.total_assets_thousands < band.upper_asset_thousands
 );

CREATE OR REPLACE VIEW vw_peer_quarter_benchmark AS
SELECT metrics.*,
       PERCENT_RANK() OVER (
           PARTITION BY report_date, asset_size_band_key ORDER BY roa_pct
       ) AS roa_peer_percentile,
       PERCENT_RANK() OVER (
           PARTITION BY report_date, asset_size_band_key ORDER BY net_interest_margin_pct
       ) AS nim_peer_percentile,
       PERCENT_RANK() OVER (
           PARTITION BY report_date, asset_size_band_key ORDER BY noncurrent_loans_pct
       ) AS noncurrent_loans_peer_percentile,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY roa_pct) OVER (
           PARTITION BY report_date, asset_size_band_key
       ) AS median_peer_roa_pct,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY net_interest_margin_pct) OVER (
           PARTITION BY report_date, asset_size_band_key
       ) AS median_peer_nim_pct,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY noncurrent_loans_pct) OVER (
           PARTITION BY report_date, asset_size_band_key
       ) AS median_peer_noncurrent_loans_pct
FROM vw_bank_quarter_metrics metrics;
