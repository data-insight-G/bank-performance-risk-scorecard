CREATE OR REPLACE VIEW vw_fdic_stage_validation_issue AS
SELECT batch_id, source_row_number, 'MISSING_CERT' AS issue_code,
       'CERT is required' AS issue_detail
FROM fdic_financial_stage
WHERE cert_raw IS NULL
UNION ALL
SELECT batch_id, source_row_number, 'INVALID_CERT',
       'CERT must be a whole number: ' || cert_raw
FROM fdic_financial_stage
WHERE cert_raw IS NOT NULL AND VALIDATE_CONVERSION(cert_raw AS NUMBER) = 0
UNION ALL
SELECT batch_id, source_row_number, 'INVALID_REPORT_DATE',
       'REPDTE must be one of the configured reporting quarters: ' || report_date_raw
FROM fdic_financial_stage
WHERE report_date_raw IS NULL
   OR NOT EXISTS (
       SELECT 1
       FROM dim_reporting_quarter quarter_dimension
       WHERE TO_CHAR(quarter_dimension.report_date, 'YYYYMMDD') = report_date_raw
   )
UNION ALL
SELECT batch_id, source_row_number, 'MISSING_INSTITUTION_NAME',
       'Institution name is required'
FROM fdic_financial_stage
WHERE institution_name_raw IS NULL
UNION ALL
SELECT batch_id, source_row_number, 'INVALID_REQUIRED_NUMERIC',
       'One or more required financial measures are not numeric'
FROM fdic_financial_stage
WHERE total_assets_raw IS NULL OR VALIDATE_CONVERSION(total_assets_raw AS NUMBER) = 0
   OR total_deposits_raw IS NULL OR VALIDATE_CONVERSION(total_deposits_raw AS NUMBER) = 0
   OR net_loans_raw IS NULL OR VALIDATE_CONVERSION(net_loans_raw AS NUMBER) = 0
   OR roa_raw IS NULL OR VALIDATE_CONVERSION(roa_raw AS NUMBER) = 0
   OR net_interest_margin_raw IS NULL OR VALIDATE_CONVERSION(net_interest_margin_raw AS NUMBER) = 0
   OR equity_to_assets_raw IS NULL OR VALIDATE_CONVERSION(equity_to_assets_raw AS NUMBER) = 0
   OR loans_to_deposits_raw IS NULL OR VALIDATE_CONVERSION(loans_to_deposits_raw AS NUMBER) = 0
   OR noncurrent_loans_ratio_raw IS NULL OR VALIDATE_CONVERSION(noncurrent_loans_ratio_raw AS NUMBER) = 0
   OR net_charge_off_ratio_raw IS NULL OR VALIDATE_CONVERSION(net_charge_off_ratio_raw AS NUMBER) = 0
UNION ALL
SELECT batch_id, MIN(source_row_number), 'DUPLICATE_INSTITUTION_QUARTER',
       'Duplicate CERT/report-date key: ' || cert_raw || '/' || report_date_raw
FROM fdic_financial_stage
GROUP BY batch_id, cert_raw, report_date_raw
HAVING COUNT(*) > 1;
