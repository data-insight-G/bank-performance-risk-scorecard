-- Prevent SQL*Plus/SQLcl from treating URL query-string ampersands as variables.
SET DEFINE OFF;

CREATE OR REPLACE PACKAGE fdic_api_ingestion_pkg AS
    PROCEDURE refresh_snapshot(
        p_wallet_path IN VARCHAR2,
        p_wallet_password IN VARCHAR2 DEFAULT NULL,
        p_batch_id OUT NUMBER
    );
END fdic_api_ingestion_pkg;
/

CREATE OR REPLACE PACKAGE BODY fdic_api_ingestion_pkg AS
    c_api_endpoint CONSTANT VARCHAR2(1000) := 'https://api.fdic.gov/banks/financials';
    c_source_filter CONSTANT VARCHAR2(500) := 'REPDTE:[20200331 TO 20241231]';
    c_source_fields CONSTANT VARCHAR2(4000) :=
        'CERT,REPDTE,NAME,STALP,SPECGRPDESC,CB,ASSET,DEP,DEPDOM,COREDEP,' ||
        'LNLSNET,NETINC,ROA,ROE,NIMY,EQ,EQV,LNLSDEPR,NCLNLSR,NTLNLSR,' ||
        'LNATRESR,OFFDOM,SZLNRES,SZLNCI,SZLNCRCD,SZLNAUTO,SZLNCON,SZLNHEL,SZLNOTH';
    c_page_size CONSTANT PLS_INTEGER := 10000;
    c_expected_row_count CONSTANT PLS_INTEGER := 96902;
    c_user_agent CONSTANT VARCHAR2(100) := 'bank-performance-risk-scorecard/1.0';

    FUNCTION build_request_url(p_offset IN PLS_INTEGER) RETURN VARCHAR2 IS
    BEGIN
        RETURN c_api_endpoint ||
               '?filters=' || UTL_URL.ESCAPE(c_source_filter, TRUE, 'UTF-8') ||
               '&fields=' || UTL_URL.ESCAPE(c_source_fields, TRUE, 'UTF-8') ||
               '&sort_by=REPDTE' ||
               '&sort_order=ASC' ||
               '&limit=' || TO_CHAR(c_page_size) ||
               '&offset=' || TO_CHAR(p_offset);
    END build_request_url;

    FUNCTION fetch_page(p_offset IN PLS_INTEGER) RETURN CLOB IS
        v_request UTL_HTTP.REQ;
        v_response UTL_HTTP.RESP;
        v_response_open BOOLEAN := FALSE;
        v_response_body CLOB;
        v_text_buffer VARCHAR2(32767);
        v_status_code PLS_INTEGER;
    BEGIN
        v_request := UTL_HTTP.BEGIN_REQUEST(
            url => build_request_url(p_offset),
            method => 'GET',
            http_version => 'HTTP/1.1'
        );
        UTL_HTTP.SET_HEADER(v_request, 'Accept', 'application/json');
        UTL_HTTP.SET_HEADER(v_request, 'User-Agent', c_user_agent);
        v_response := UTL_HTTP.GET_RESPONSE(v_request);
        v_response_open := TRUE;
        v_status_code := v_response.status_code;

        IF v_status_code <> 200 THEN
            UTL_HTTP.END_RESPONSE(v_response);
            v_response_open := FALSE;
            RAISE_APPLICATION_ERROR(
                -20101,
                'FDIC API returned HTTP ' || v_status_code ||
                ' at offset ' || p_offset
            );
        END IF;

        DBMS_LOB.CREATETEMPORARY(v_response_body, TRUE, DBMS_LOB.CALL);
        BEGIN
            LOOP
                UTL_HTTP.READ_TEXT(v_response, v_text_buffer, 32767);
                DBMS_LOB.WRITEAPPEND(
                    v_response_body,
                    LENGTH(v_text_buffer),
                    v_text_buffer
                );
            END LOOP;
        EXCEPTION
            WHEN UTL_HTTP.END_OF_BODY THEN
                NULL;
        END;

        UTL_HTTP.END_RESPONSE(v_response);
        v_response_open := FALSE;
        RETURN v_response_body;
    EXCEPTION
        WHEN OTHERS THEN
            IF v_response_open THEN
                UTL_HTTP.END_RESPONSE(v_response);
            END IF;
            IF v_response_body IS NOT NULL
               AND DBMS_LOB.ISTEMPORARY(v_response_body) = 1 THEN
                DBMS_LOB.FREETEMPORARY(v_response_body);
            END IF;
            RAISE;
    END fetch_page;

    PROCEDURE insert_page_rows(
        p_batch_id IN NUMBER,
        p_starting_row_number IN NUMBER,
        p_response_body IN CLOB,
        p_inserted_row_count OUT NUMBER
    ) IS
    BEGIN
        INSERT INTO fdic_financial_stage (
            batch_id, source_row_number, cert_raw, report_date_raw, institution_name_raw,
            state_code_raw, specialization_group_raw, community_bank_flag_raw,
            total_assets_raw, total_deposits_raw, domestic_deposits_raw, core_deposits_raw,
            net_loans_raw, net_income_ytd_raw, roa_raw, roe_raw, net_interest_margin_raw,
            equity_capital_raw, equity_to_assets_raw, loans_to_deposits_raw,
            noncurrent_loans_ratio_raw, net_charge_off_ratio_raw, allowance_to_loans_ratio_raw,
            domestic_offices_raw, residential_loans_raw, commercial_industrial_loans_raw,
            credit_card_loans_raw, auto_loans_raw, consumer_loans_raw,
            home_equity_loans_raw, other_loans_raw
        )
        SELECT p_batch_id,
               p_starting_row_number + page_row_number,
               cert_raw, report_date_raw, institution_name_raw, state_code_raw,
               specialization_group_raw, community_bank_flag_raw, total_assets_raw,
               total_deposits_raw, domestic_deposits_raw, core_deposits_raw,
               net_loans_raw, net_income_ytd_raw, roa_raw, roe_raw,
               net_interest_margin_raw, equity_capital_raw, equity_to_assets_raw,
               loans_to_deposits_raw, noncurrent_loans_ratio_raw, net_charge_off_ratio_raw,
               allowance_to_loans_ratio_raw, domestic_offices_raw, residential_loans_raw,
               commercial_industrial_loans_raw, credit_card_loans_raw, auto_loans_raw,
               consumer_loans_raw, home_equity_loans_raw, other_loans_raw
        FROM JSON_TABLE(
            p_response_body,
            '$.data[*].data'
            COLUMNS (
                page_row_number FOR ORDINALITY,
                cert_raw VARCHAR2(50) PATH '$.CERT',
                report_date_raw VARCHAR2(50) PATH '$.REPDTE',
                institution_name_raw VARCHAR2(500) PATH '$.NAME',
                state_code_raw VARCHAR2(50) PATH '$.STALP',
                specialization_group_raw VARCHAR2(500) PATH '$.SPECGRPDESC',
                community_bank_flag_raw VARCHAR2(50) PATH '$.CB',
                total_assets_raw VARCHAR2(100) PATH '$.ASSET',
                total_deposits_raw VARCHAR2(100) PATH '$.DEP',
                domestic_deposits_raw VARCHAR2(100) PATH '$.DEPDOM',
                core_deposits_raw VARCHAR2(100) PATH '$.COREDEP',
                net_loans_raw VARCHAR2(100) PATH '$.LNLSNET',
                net_income_ytd_raw VARCHAR2(100) PATH '$.NETINC',
                roa_raw VARCHAR2(100) PATH '$.ROA',
                roe_raw VARCHAR2(100) PATH '$.ROE',
                net_interest_margin_raw VARCHAR2(100) PATH '$.NIMY',
                equity_capital_raw VARCHAR2(100) PATH '$.EQ',
                equity_to_assets_raw VARCHAR2(100) PATH '$.EQV',
                loans_to_deposits_raw VARCHAR2(100) PATH '$.LNLSDEPR',
                noncurrent_loans_ratio_raw VARCHAR2(100) PATH '$.NCLNLSR',
                net_charge_off_ratio_raw VARCHAR2(100) PATH '$.NTLNLSR',
                allowance_to_loans_ratio_raw VARCHAR2(100) PATH '$.LNATRESR',
                domestic_offices_raw VARCHAR2(100) PATH '$.OFFDOM',
                residential_loans_raw VARCHAR2(100) PATH '$.SZLNRES',
                commercial_industrial_loans_raw VARCHAR2(100) PATH '$.SZLNCI',
                credit_card_loans_raw VARCHAR2(100) PATH '$.SZLNCRCD',
                auto_loans_raw VARCHAR2(100) PATH '$.SZLNAUTO',
                consumer_loans_raw VARCHAR2(100) PATH '$.SZLNCON',
                home_equity_loans_raw VARCHAR2(100) PATH '$.SZLNHEL',
                other_loans_raw VARCHAR2(100) PATH '$.SZLNOTH'
            )
        );

        p_inserted_row_count := SQL%ROWCOUNT;
        IF p_inserted_row_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20102, 'FDIC API returned an empty page before completion');
        END IF;
    END insert_page_rows;

    PROCEDURE refresh_snapshot(
        p_wallet_path IN VARCHAR2,
        p_wallet_password IN VARCHAR2 DEFAULT NULL,
        p_batch_id OUT NUMBER
    ) IS
        v_response_body CLOB;
        v_api_total NUMBER;
        v_api_index VARCHAR2(200);
        v_fingerprint_input VARCHAR2(4000);
        v_fingerprint_sha256 VARCHAR2(64);
        v_existing_batch_id NUMBER;
        v_offset PLS_INTEGER := 0;
        v_staged_row_count NUMBER := 0;
        v_page_row_count NUMBER;
        v_batch_status fdic_load_batch.load_status%TYPE;
    BEGIN
        IF p_wallet_path IS NULL OR NOT p_wallet_path LIKE 'file:%' THEN
            RAISE_APPLICATION_ERROR(-20103, 'Wallet path must be an explicit file: path');
        END IF;

        SAVEPOINT before_fdic_api_refresh;
        UTL_HTTP.SET_DETAILED_EXCP_SUPPORT(TRUE);
        UTL_HTTP.SET_TRANSFER_TIMEOUT(180);
        UTL_HTTP.SET_WALLET(p_wallet_path, p_wallet_password);

        v_response_body := fetch_page(0);
        SELECT JSON_VALUE(
                   v_response_body,
                   '$.meta.total' RETURNING NUMBER ERROR ON ERROR
               ),
               JSON_VALUE(
                   v_response_body,
                   '$.meta.index.name' RETURNING VARCHAR2(200) ERROR ON ERROR
               )
        INTO v_api_total, v_api_index
        FROM dual;

        IF v_api_total <> c_expected_row_count THEN
            RAISE_APPLICATION_ERROR(
                -20104,
                'FDIC API returned ' || v_api_total ||
                ' rows; expected approved snapshot count ' || c_expected_row_count
            );
        END IF;

        v_fingerprint_input := c_api_endpoint || '|' || c_source_filter || '|' ||
                               v_api_index || '|' || TO_CHAR(v_api_total);
        SELECT RAWTOHEX(STANDARD_HASH(v_fingerprint_input, 'SHA256'))
        INTO v_fingerprint_sha256
        FROM dual;

        BEGIN
            SELECT batch_id
            INTO v_existing_batch_id
            FROM fdic_load_batch
            WHERE source_fingerprint_sha256 = v_fingerprint_sha256;

            RAISE_APPLICATION_ERROR(
                -20105,
                'This FDIC API snapshot already exists as batch ' || v_existing_batch_id
            );
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
        END;

        INSERT INTO fdic_load_batch (
            source_url, source_filter, source_transport, source_api_index,
            extraction_timestamp_utc, source_fingerprint_sha256, expected_row_count
        ) VALUES (
            c_api_endpoint, c_source_filter, 'ORACLE_UTL_HTTP', v_api_index,
            SYSTIMESTAMP AT TIME ZONE 'UTC', v_fingerprint_sha256, v_api_total
        ) RETURNING batch_id INTO p_batch_id;

        WHILE v_offset < v_api_total LOOP
            IF v_offset > 0 THEN
                v_response_body := fetch_page(v_offset);
            END IF;

            insert_page_rows(
                p_batch_id => p_batch_id,
                p_starting_row_number => v_staged_row_count,
                p_response_body => v_response_body,
                p_inserted_row_count => v_page_row_count
            );
            v_staged_row_count := v_staged_row_count + v_page_row_count;

            IF v_response_body IS NOT NULL
               AND DBMS_LOB.ISTEMPORARY(v_response_body) = 1 THEN
                DBMS_LOB.FREETEMPORARY(v_response_body);
            END IF;
            v_offset := v_offset + c_page_size;
        END LOOP;

        IF v_staged_row_count <> v_api_total THEN
            RAISE_APPLICATION_ERROR(
                -20106,
                'Staged ' || v_staged_row_count || ' rows but API reported ' || v_api_total
            );
        END IF;

        fdic_load_control_pkg.validate_batch(p_batch_id);
        SELECT load_status
        INTO v_batch_status
        FROM fdic_load_batch
        WHERE batch_id = p_batch_id;

        IF v_batch_status <> 'VALIDATED' THEN
            RAISE_APPLICATION_ERROR(
                -20107,
                'Batch ' || p_batch_id || ' failed validation with status ' || v_batch_status
            );
        END IF;

        fdic_load_control_pkg.promote_batch(p_batch_id);
    EXCEPTION
        WHEN OTHERS THEN
            IF v_response_body IS NOT NULL
               AND DBMS_LOB.ISTEMPORARY(v_response_body) = 1 THEN
                DBMS_LOB.FREETEMPORARY(v_response_body);
            END IF;
            ROLLBACK TO before_fdic_api_refresh;
            p_batch_id := NULL;
            RAISE;
    END refresh_snapshot;
END fdic_api_ingestion_pkg;
/

SET DEFINE ON;
