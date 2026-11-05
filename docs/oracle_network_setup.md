# Oracle HTTPS network setup

The primary ingestion path runs entirely inside Oracle Database. It requires a DBA to grant the application schema outbound HTTPS access to `api.fdic.gov:443` and to provide an Oracle wallet that trusts the server certificate chain.

Official references:

- [Oracle 19c UTL_HTTP](https://docs.oracle.com/en/database/oracle/oracle-database/19/arpls/UTL_HTTP.html)
- [Configuring external network access](https://docs.oracle.com/en/database/oracle/oracle-database/19/dbseg/configuring-access-control-external-network-services.html)
- [Configuring Oracle wallet access](https://docs.oracle.com/en/database/oracle/oracle-database/19/dbseg/configuring-access-control-oracle-wallet.html)
- [Oracle PL/SQL JSON types](https://docs.oracle.com/en/database/oracle/oracle-database/19/arpls/json-types.html)

## 1. Configure the host ACL

Run `sql/00_network_access_setup.sql` as a DBA after replacing `BANK_ANALYTICS` with the application schema. The grant is restricted to the FDIC API host and HTTPS port.

## 2. Prepare the wallet

Create or use a DBA-managed wallet containing the trusted certificate authorities required for `api.fdic.gov`. The path supplied to `UTL_HTTP.SET_WALLET` must begin with `file:`. Prefer an auto-login wallet where organizational security policy permits it; otherwise provide the password only at runtime.

Never commit wallet files, private keys, or wallet passwords to this repository.

## 3. Compile in dependency order

1. `sql/00_schema.sql`
2. `sql/01_reference_data.sql`
3. `sql/02_data_quality.sql`
4. `plsql/fdic_load_control_pkg.sql`
5. `plsql/fdic_api_ingestion_pkg.sql`
6. `sql/03_analytical_views.sql`

## 4. Run the refresh

Execute `sql/11_run_api_refresh.sql` in SQL*Plus or SQLcl. The script prompts for the wallet path and hides the wallet password. The package then:

1. Requests API pages in 10,000-row blocks.
2. Parses JSON with `JSON_VALUE` and `JSON_TABLE`.
3. Verifies the fixed 96,902-row snapshot.
4. Rejects a duplicate API fingerprint.
5. Inserts rows into the staging table.
6. Runs batch validation.
7. Promotes the validated batch atomically.

If outbound database access is prohibited, use the Oracle external-table fallback in `sql/10_external_load.sql`; analytical logic remains in Oracle.
