WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK;

CREATE TABLE fdic_load_batch (
    batch_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    system_version VARCHAR2(20) DEFAULT '1.0.0' NOT NULL,
    source_url VARCHAR2(1000) NOT NULL,
    source_filter VARCHAR2(500) NOT NULL,
    extraction_timestamp_utc TIMESTAMP WITH TIME ZONE NOT NULL,
    source_sha256 VARCHAR2(64) NOT NULL,
    expected_row_count NUMBER NOT NULL,
    actual_row_count NUMBER,
    load_status VARCHAR2(20) DEFAULT 'STAGED' NOT NULL,
    created_at_utc TIMESTAMP WITH TIME ZONE DEFAULT SYS_EXTRACT_UTC(SYSTIMESTAMP) NOT NULL,
    CONSTRAINT uq_fdic_load_batch_sha UNIQUE (source_sha256),
    CONSTRAINT ck_fdic_load_batch_status CHECK (
        load_status IN ('STAGED', 'VALIDATED', 'REJECTED', 'PROMOTED', 'FAILED')
    )
);

CREATE TABLE fdic_financial_stage (
    batch_id NUMBER NOT NULL,
    source_row_number NUMBER NOT NULL,
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
    other_loans_raw VARCHAR2(100),
    CONSTRAINT pk_fdic_financial_stage PRIMARY KEY (batch_id, source_row_number),
    CONSTRAINT fk_fdic_stage_batch FOREIGN KEY (batch_id) REFERENCES fdic_load_batch(batch_id)
);

CREATE TABLE fdic_data_quality_issue (
    issue_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    batch_id NUMBER NOT NULL,
    source_row_number NUMBER,
    issue_code VARCHAR2(100) NOT NULL,
    issue_detail VARCHAR2(1000) NOT NULL,
    created_at_utc TIMESTAMP WITH TIME ZONE DEFAULT SYS_EXTRACT_UTC(SYSTIMESTAMP) NOT NULL,
    CONSTRAINT fk_fdic_quality_batch FOREIGN KEY (batch_id) REFERENCES fdic_load_batch(batch_id)
);

CREATE TABLE dim_asset_size_band (
    asset_size_band_key NUMBER PRIMARY KEY,
    system_version VARCHAR2(20) DEFAULT '1.0.0' NOT NULL,
    asset_size_band_name VARCHAR2(50) NOT NULL,
    lower_asset_thousands NUMBER(20, 2) NOT NULL,
    upper_asset_thousands NUMBER(20, 2),
    display_order NUMBER NOT NULL,
    CONSTRAINT uq_asset_size_band_name UNIQUE (asset_size_band_name),
    CONSTRAINT ck_asset_size_band_range CHECK (
        upper_asset_thousands IS NULL OR upper_asset_thousands > lower_asset_thousands
    )
);

CREATE TABLE dim_reporting_quarter (
    report_date DATE PRIMARY KEY,
    system_version VARCHAR2(20) DEFAULT '1.0.0' NOT NULL,
    calendar_year NUMBER(4) NOT NULL,
    quarter_number NUMBER(1) NOT NULL,
    quarter_label VARCHAR2(10) NOT NULL,
    CONSTRAINT uq_reporting_quarter_label UNIQUE (quarter_label),
    CONSTRAINT ck_reporting_quarter_number CHECK (quarter_number BETWEEN 1 AND 4)
);

CREATE TABLE dim_institution (
    cert NUMBER PRIMARY KEY,
    system_version VARCHAR2(20) DEFAULT '1.0.0' NOT NULL,
    institution_name VARCHAR2(500) NOT NULL,
    state_code VARCHAR2(2),
    specialization_group VARCHAR2(500),
    community_bank_flag NUMBER(1),
    first_report_date DATE NOT NULL,
    latest_report_date DATE NOT NULL,
    CONSTRAINT ck_institution_cb_flag CHECK (community_bank_flag IN (0, 1) OR community_bank_flag IS NULL)
);

CREATE TABLE fact_bank_financial_quarter (
    batch_id NUMBER NOT NULL,
    cert NUMBER NOT NULL,
    report_date DATE NOT NULL,
    system_version VARCHAR2(20) DEFAULT '1.0.0' NOT NULL,
    total_assets_thousands NUMBER(20, 2) NOT NULL,
    total_deposits_thousands NUMBER(20, 2) NOT NULL,
    domestic_deposits_thousands NUMBER(20, 2),
    core_deposits_thousands NUMBER(20, 2),
    net_loans_thousands NUMBER(20, 2) NOT NULL,
    net_income_ytd_thousands NUMBER(20, 2),
    roa_pct NUMBER(12, 6) NOT NULL,
    roe_pct NUMBER(12, 6),
    net_interest_margin_pct NUMBER(12, 6) NOT NULL,
    equity_capital_thousands NUMBER(20, 2),
    equity_to_assets_pct NUMBER(12, 6) NOT NULL,
    loans_to_deposits_pct NUMBER(12, 6) NOT NULL,
    noncurrent_loans_pct NUMBER(12, 6) NOT NULL,
    net_charge_offs_pct NUMBER(12, 6) NOT NULL,
    allowance_to_loans_pct NUMBER(12, 6),
    domestic_office_count NUMBER,
    residential_loans_thousands NUMBER(20, 2),
    commercial_industrial_loans_thousands NUMBER(20, 2),
    credit_card_loans_thousands NUMBER(20, 2),
    auto_loans_thousands NUMBER(20, 2),
    consumer_loans_thousands NUMBER(20, 2),
    home_equity_loans_thousands NUMBER(20, 2),
    other_loans_thousands NUMBER(20, 2),
    CONSTRAINT pk_bank_financial_quarter PRIMARY KEY (cert, report_date),
    CONSTRAINT fk_financial_quarter_batch FOREIGN KEY (batch_id) REFERENCES fdic_load_batch(batch_id),
    CONSTRAINT fk_financial_quarter_institution FOREIGN KEY (cert) REFERENCES dim_institution(cert),
    CONSTRAINT fk_financial_quarter_date FOREIGN KEY (report_date) REFERENCES dim_reporting_quarter(report_date)
);

CREATE INDEX ix_financial_quarter_report_date ON fact_bank_financial_quarter(report_date);
CREATE INDEX ix_quality_issue_batch ON fdic_data_quality_issue(batch_id);
