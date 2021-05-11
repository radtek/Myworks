DECLARE 
    TYPE userlist
    IS TABLE OF varchar2(100)
    INDEX BY pls_integer;

    TYPE commandlist
    IS TABLE OF varchar2(4000)
    INDEX BY pls_integer;

    NUSER userlist;
    COMM  commandlist;
    name  varchar2(100);
BEGIN
    DBMS_OUTPUT.PUT_LINE('User migration command line extract.');
    
    SELECT USERNAME
    BULK COLLECT INTO NUSER 
    FROM DBA_USERS 
    WHERE USER_ID BETWEEN 75 AND 2147483616;

    FOR idx IN 1 .. NUSER.COUNT 
    LOOP
        name := NUSER(idx);
        
        SELECT *
        BULK COLLECT INTO COMM
        FROM
            (SELECT dbms_metadata.get_ddl('USER', name)
              FROM dual
            UNION ALL
            SELECT dbms_metadata.get_granted_ddl('ROLE_GRANT', grantee)
              FROM dba_role_privs
             WHERE grantee = name
               AND ROWNUM = 1
            UNION ALL
            SELECT dbms_metadata.get_granted_ddl('DEFAULT_ROLE', grantee)
              FROM dba_role_privs
             WHERE grantee = name
               AND ROWNUM = 1
            UNION ALL
            SELECT dbms_metadata.get_granted_ddl('SYSTEM_GRANT', grantee)
              FROM dba_sys_privs          sp,
                   system_privilege_map   spm
             WHERE sp.grantee = name
               AND sp.privilege = spm.name
               AND spm.property <> 1
               AND ROWNUM = 1
            UNION ALL
            SELECT dbms_metadata.get_granted_ddl('OBJECT_GRANT', grantee)
              FROM dba_tab_privs
             WHERE grantee = name
               AND ROWNUM = 1
            UNION ALL
            SELECT dbms_metadata.get_granted_ddl('TABLESPACE_QUOTA', username)
              FROM dba_ts_quotas
             WHERE username = name
               AND ROWNUM = 1);
           
           FOR comidx IN 1 .. COMM.COUNT
            LOOP
                dbms_output.put_line(COMM(COMIDX));
            END LOOP;
    END LOOP ;       
END;
   