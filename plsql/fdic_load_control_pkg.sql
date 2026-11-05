CREATE OR REPLACE PACKAGE fdic_load_control_pkg AS
    PROCEDURE validate_batch(p_batch_id IN NUMBER);
    PROCEDURE promote_batch(p_batch_id IN NUMBER);
END fdic_load_control_pkg;
/

CREATE OR REPLACE PACKAGE BODY fdic_load_control_pkg AS
    PROCEDURE assert_batch_status(
        p_batch_id IN NUMBER,
        p_expected_status IN VARCHAR2
    ) IS
        v_actual_status fdic_load_batch.load_status%TYPE;
    BEGIN
        SELECT load_status
        INTO v_actual_status
        FROM fdic_load_batch
        WHERE batch_id = p_batch_id
        FOR UPDATE;

        IF v_actual_status <> p_expected_status THEN
            RAISE_APPLICATION_ERROR(
                -20001,
                'Batch ' || p_batch_id || ' must be ' || p_expected_status ||
                ' but is ' || v_actual_status
            );
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20002, 'Batch ' || p_batch_id || ' does not exist');
    END assert_batch_status;

    PROCEDURE validate_batch(p_batch_id IN NUMBER) IS
        v_expected_row_count fdic_load_batch.expected_row_count%TYPE;
        v_actual_row_count NUMBER;
        v_issue_count NUMBER;
    BEGIN
        assert_batch_status(p_batch_id, 'STAGED');

        SELECT expected_row_count
        INTO v_expected_row_count
        FROM fdic_load_batch
        WHERE batch_id = p_batch_id;

        SELECT COUNT(*)
        INTO v_actual_row_count
        FROM fdic_financial_stage
        WHERE batch_id = p_batch_id;

        DELETE FROM fdic_data_quality_issue WHERE batch_id = p_batch_id;

        INSERT INTO fdic_data_quality_issue (
            batch_id, source_row_number, issue_code, issue_detail
        )
        SELECT batch_id, source_row_number, issue_code, issue_detail
        FROM vw_fdic_stage_validation_issue
        WHERE batch_id = p_batch_id;

        IF v_actual_row_count <> v_expected_row_count THEN
            INSERT INTO fdic_data_quality_issue (
                batch_id, source_row_number, issue_code, issue_detail
            ) VALUES (
                p_batch_id,
                NULL,
                'ROW_COUNT_MISMATCH',
                'Expected ' || v_expected_row_count || ' rows but staged ' || v_actual_row_count
            );
        END IF;

        SELECT COUNT(*)
        INTO v_issue_count
        FROM fdic_data_quality_issue
        WHERE batch_id = p_batch_id;

        UPDATE fdic_load_batch
        SET actual_row_count = v_actual_row_count,
            load_status = CASE WHEN v_issue_count = 0 THEN 'VALIDATED' ELSE 'REJECTED' END
        WHERE batch_id = p_batch_id;
    END validate_batch;

    PROCEDURE promote_batch(p_batch_id IN NUMBER) IS
        v_issue_count NUMBER;
    BEGIN
        SAVEPOINT before_fdic_promotion;
        assert_batch_status(p_batch_id, 'VALIDATED');

        SELECT COUNT(*)
        INTO v_issue_count
        FROM fdic_data_quality_issue
        WHERE batch_id = p_batch_id;

        IF v_issue_count <> 0 THEN
            RAISE_APPLICATION_ERROR(-20003, 'Validated batch contains data-quality issues');
        END IF;

        MERGE INTO dim_institution target
        USING (
            SELECT cert,
                   MAX(institution_name) KEEP (DENSE_RANK LAST ORDER BY report_date) AS institution_name,
                   MAX(state_code) KEEP (DENSE_RANK LAST ORDER BY report_date) AS state_code,
                   MAX(specialization_group) KEEP (DENSE_RANK LAST ORDER BY report_date) AS specialization_group,
                   MAX(community_bank_flag) KEEP (DENSE_RANK LAST ORDER BY report_date) AS community_bank_flag,
                   MIN(report_date) AS first_report_date,
                   MAX(report_date) AS latest_report_date
            FROM (
                SELECT TO_NUMBER(cert_raw) AS cert,
                       TO_DATE(report_date_raw, 'YYYYMMDD') AS report_date,
                       institution_name_raw AS institution_name,
                       state_code_raw AS state_code,
                       specialization_group_raw AS specialization_group,
                       CASE community_bank_flag_raw WHEN '1' THEN 1 WHEN '0' THEN 0 END AS community_bank_flag
                FROM fdic_financial_stage
                WHERE batch_id = p_batch_id
            )
            GROUP BY cert
        ) source
        ON (target.cert = source.cert)
        WHEN MATCHED THEN UPDATE SET
            target.institution_name = source.institution_name,
            target.state_code = source.state_code,
            target.specialization_group = source.specialization_group,
            target.community_bank_flag = source.community_bank_flag,
            target.first_report_date = LEAST(target.first_report_date, source.first_report_date),
            target.latest_report_date = GREATEST(target.latest_report_date, source.latest_report_date)
        WHEN NOT MATCHED THEN INSERT (
            cert, institution_name, state_code, specialization_group, community_bank_flag,
            first_report_date, latest_report_date
        ) VALUES (
            source.cert, source.institution_name, source.state_code, source.specialization_group,
            source.community_bank_flag, source.first_report_date, source.latest_report_date
        );

        INSERT INTO fact_bank_financial_quarter (
            batch_id, cert, report_date, total_assets_thousands, total_deposits_thousands,
            domestic_deposits_thousands, core_deposits_thousands, net_loans_thousands,
            net_income_ytd_thousands, roa_pct, roe_pct, net_interest_margin_pct,
            equity_capital_thousands, equity_to_assets_pct, loans_to_deposits_pct,
            noncurrent_loans_pct, net_charge_offs_pct, allowance_to_loans_pct,
            domestic_office_count, residential_loans_thousands,
            commercial_industrial_loans_thousands, credit_card_loans_thousands,
            auto_loans_thousands, consumer_loans_thousands, home_equity_loans_thousands,
            other_loans_thousands
        )
        SELECT p_batch_id,
               TO_NUMBER(cert_raw),
               TO_DATE(report_date_raw, 'YYYYMMDD'),
               TO_NUMBER(total_assets_raw),
               TO_NUMBER(total_deposits_raw),
               TO_NUMBER(NULLIF(domestic_deposits_raw, '')),
               TO_NUMBER(NULLIF(core_deposits_raw, '')),
               TO_NUMBER(net_loans_raw),
               TO_NUMBER(NULLIF(net_income_ytd_raw, '')),
               TO_NUMBER(roa_raw),
               TO_NUMBER(NULLIF(roe_raw, '')),
               TO_NUMBER(net_interest_margin_raw),
               TO_NUMBER(NULLIF(equity_capital_raw, '')),
               TO_NUMBER(equity_to_assets_raw),
               TO_NUMBER(loans_to_deposits_raw),
               TO_NUMBER(noncurrent_loans_ratio_raw),
               TO_NUMBER(net_charge_off_ratio_raw),
               TO_NUMBER(NULLIF(allowance_to_loans_ratio_raw, '')),
               TO_NUMBER(NULLIF(domestic_offices_raw, '')),
               TO_NUMBER(NULLIF(residential_loans_raw, '')),
               TO_NUMBER(NULLIF(commercial_industrial_loans_raw, '')),
               TO_NUMBER(NULLIF(credit_card_loans_raw, '')),
               TO_NUMBER(NULLIF(auto_loans_raw, '')),
               TO_NUMBER(NULLIF(consumer_loans_raw, '')),
               TO_NUMBER(NULLIF(home_equity_loans_raw, '')),
               TO_NUMBER(NULLIF(other_loans_raw, ''))
        FROM fdic_financial_stage
        WHERE batch_id = p_batch_id;

        UPDATE fdic_load_batch
        SET load_status = 'PROMOTED'
        WHERE batch_id = p_batch_id;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK TO before_fdic_promotion;
            UPDATE fdic_load_batch SET load_status = 'FAILED' WHERE batch_id = p_batch_id;
            RAISE;
    END promote_batch;
END fdic_load_control_pkg;
/
