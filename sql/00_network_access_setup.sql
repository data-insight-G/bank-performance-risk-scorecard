-- Run as a DBA or another account authorized to manage network ACLs.
-- Replace the value with the schema that owns FDIC_API_INGESTION_PKG.
DEFINE application_schema = BANK_ANALYTICS;

BEGIN
    DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(
        host => 'api.fdic.gov',
        lower_port => 443,
        upper_port => 443,
        ace => xs$ace_type(
            privilege_list => xs$name_list('http'),
            principal_name => UPPER('&&application_schema'),
            principal_type => xs_acl.ptype_db,
            granted => TRUE
        )
    );
END;
/

COMMIT;

SELECT host, lower_port, upper_port, principal, privilege, grant_type
FROM dba_host_aces
WHERE host = 'api.fdic.gov'
  AND principal = UPPER('&&application_schema')
ORDER BY principal, privilege;
