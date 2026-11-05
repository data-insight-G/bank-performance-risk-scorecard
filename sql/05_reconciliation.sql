-- Expected values come from data/source_manifest.json and docs/data_quality_report.json.
SELECT CASE WHEN COUNT(*) = 96902 THEN 'PASS' ELSE 'FAIL' END AS record_count_check,
       COUNT(*) AS actual_record_count
FROM fact_bank_financial_quarter;

SELECT CASE WHEN COUNT(*) = 20 THEN 'PASS' ELSE 'FAIL' END AS quarter_count_check,
       COUNT(*) AS actual_quarter_count
FROM (SELECT DISTINCT report_date FROM fact_bank_financial_quarter);

SELECT CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS duplicate_key_check,
       COUNT(*) AS duplicate_key_count
FROM (
    SELECT cert, report_date
    FROM fact_bank_financial_quarter
    GROUP BY cert, report_date
    HAVING COUNT(*) > 1
);

SELECT report_date,
       COUNT(*) AS institution_count,
       ROUND(MEDIAN(roa_pct), 4) AS median_roa_pct,
       ROUND(MEDIAN(net_interest_margin_pct), 4) AS median_nim_pct,
       ROUND(MEDIAN(loans_to_deposits_pct), 4) AS median_loans_to_deposits_pct,
       ROUND(MEDIAN(noncurrent_loans_pct), 4) AS median_noncurrent_loans_pct
FROM vw_bank_quarter_metrics
WHERE report_date = DATE '2024-12-31'
GROUP BY report_date;
