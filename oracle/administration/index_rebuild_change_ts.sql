SELECT OWNER, INDEX_NAME, TABLE_NAME, TABLESPACE_NAME, INDEX_TYPE, 
       'ALTER INDEX '||OWNER||'."'||INDEX_NAME||'" REBUILD TABLESPACE '
       ||SUBSTR(TABLESPACE_NAME,1,INSTR(TABLESPACE_NAME,'_',-1))||
         CASE WHEN 
              SUBSTR(TABLESPACE_NAME,
                     INSTR(TABLESPACE_NAME,'_',-1)+1,
                          LENGTH(TABLESPACE_NAME)) = 'DATA'
              THEN 'INDEX'
              WHEN SUBSTR(TABLESPACE_NAME,
                          INSTR(TABLESPACE_NAME,'_',-1)+1,
                                LENGTH(TABLESPACE_NAME)) = 'D'
              THEN 'X'
         END 
         ||' ;' AS REBUILD_COMMAND
FROM DBA_INDEXES
WHERE REGEXP_LIKE(TABLESPACE_NAME,'_DATA$|_D$')
      AND INDEX_TYPE <> 'LOB';
