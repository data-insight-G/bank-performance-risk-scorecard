-- Prerequisite: a DBA-created FDIC_DATA_DIR Oracle directory must point to the server folder
-- containing fdic_financials_2020q1_2024q4.csv.
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK;

CREATE TABLE ext_fdic_financials (
    cert_raw VARCHAR2(50),
    report_date_raw VARCHAR2(50),
    institution_name_raw VARCHAR2(500),
    state_code_raw VARCHAR2(50),
    specialization_group_raw VARCHAR2(500),
    community_bank_flag_raw VARCHAR2(50),
    total_assets_raw VARCHAR2(100),
    total_deposits_raw VARCHAR2(100),
    domestic_deposits_raw VARCHAR2(100),
    core_deposits_raw VARCHAR2(100),
    net_loans_raw VARCHAR2(100),
    net_income_ytd_raw VARCHAR2(100),
    roa_raw VARCHAR2(100),
    roe_raw VARCHAR2(100),
    net_interest_margin_raw VARCHAR2(100),
    equity_capital_raw VARCHAR2(100),
    equity_to_assets_raw VARCHAR2(100),
    loans_to_deposits_raw VARCHAR2(100),
    noncurrent_loans_ratio_raw VARCHAR2(100),
    net_charge_off_ratio_raw VARCHAR2(100),
    allowance_to_loans_ratio_raw VARCHAR2(100),
    domestic_offices_raw VARCHAR2(100),
    residential_loans_raw VARCHAR2(100),
    commercial_industrial_loans_raw VARCHAR2(100),
    credit_card_loans_raw VARCHAR2(100),
    auto_loans_raw VARCHAR2(100),
    consumer_loans_raw VARCHAR2(100),
    home_equity_loans_raw VARCHAR2(100),
    other_loans_raw VARCHAR2(100)
)
ORGANIZATION EXTERNAL (
    TYPE ORACLE_LOADER
    DEFAULT DIRECTORY fdic_data_dir
    ACCESS PARAMETERS (
        RECORDS DELIMITED BY NEWLINE
        SKIP 1
        BADFILE fdic_data_dir:'fdic_financials.bad'
        LOGFILE fdic_data_dir:'fdic_financials.log'
        FIELDS CSV WITH EMBEDDED
        MISSING FIELD VALUES ARE NULL
    )
    LOCATION ('fdic_financials_2020q1_2024q4.csv')
)
REJECT LIMIT UNLIMITED;

VARIABLE fdic_batch_id NUMBER;

BEGIN
    INSERT INTO fdic_load_batch (
        source_url,
        source_filter,
        extraction_timestamp_utc,
        source_sha256,
        expected_row_count
    ) VALUES (
        'https://api.fdic.gov/banks/financials',
        'REPDTE:[20200331 TO 20241231]',
        TO_TIMESTAMP_TZ('2026-11-05T15:45:28.122973+00:00', 'YYYY-MM-DD"T"HH24:MI:SS.FFTZH:TZM'),
        'a2955fdd52818cfebc029772d95b7dadaa5d555e2561b8fcc0461677c5069fd4',
        96902
    ) RETURNING batch_id INTO :fdic_batch_id;
END;
/

INSERT INTO fdic_financial_stage (
    batch_id, source_row_number, cert_raw, report_date_raw, institution_name_raw,
    state_code_raw, specialization_group_raw, community_bank_flag_raw,
    total_assets_raw, total_deposits_raw, domestic_deposits_raw, core_deposits_raw,
    net_loans_raw, net_income_ytd_raw, roa_raw, roe_raw, net_interest_margin_raw,
    equity_capital_raw, equity_to_assets_raw, loans_to_deposits_raw,
    noncurrent_loans_ratio_raw, net_charge_off_ratio_raw, allowance_to_loans_ratio_raw,
    domestic_offices_raw, residential_loans_raw, commercial_industrial_loans_raw,
    credit_card_loans_raw, auto_loans_raw, consumer_loans_raw, home_equity_loans_raw,
    other_loans_raw
)
SELECT :fdic_batch_id,
       ROWNUM,
       cert_raw, report_date_raw, institution_name_raw, state_code_raw,
       specialization_group_raw, community_bank_flag_raw, total_assets_raw,
       total_deposits_raw, domestic_deposits_raw, core_deposits_raw, net_loans_raw,
       net_income_ytd_raw, roa_raw, roe_raw, net_interest_margin_raw,
       equity_capital_raw, equity_to_assets_raw, loans_to_deposits_raw,
       noncurrent_loans_ratio_raw, net_charge_off_ratio_raw, allowance_to_loans_ratio_raw,
       domestic_offices_raw, residential_loans_raw, commercial_industrial_loans_raw,
       credit_card_loans_raw, auto_loans_raw, consumer_loans_raw, home_equity_loans_raw,
       other_loans_raw
FROM ext_fdic_financials;

BEGIN
    fdic_load_control_pkg.validate_batch(:fdic_batch_id);
    fdic_load_control_pkg.promote_batch(:fdic_batch_id);
END;
/

COMMIT;
