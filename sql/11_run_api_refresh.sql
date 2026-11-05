-- Run after schema, reference data, validation view, and both PL/SQL packages compile.
-- Wallet path must include the file: prefix. An auto-login wallet can use a blank password.
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK;

ACCEPT wallet_path CHAR PROMPT 'Oracle wallet path (file:/...): '
ACCEPT wallet_password CHAR PROMPT 'Oracle wallet password (blank for auto-login): ' HIDE

VARIABLE fdic_batch_id NUMBER;

BEGIN
    fdic_api_ingestion_pkg.refresh_snapshot(
        p_wallet_path => '&wallet_path',
        p_wallet_password => NULLIF('&wallet_password', ''),
        p_batch_id => :fdic_batch_id
    );
END;
/

PRINT fdic_batch_id;

COMMIT;

SELECT batch_id,
       source_transport,
       source_api_index,
       expected_row_count,
       actual_row_count,
       load_status
FROM fdic_load_batch
WHERE batch_id = :fdic_batch_id;
