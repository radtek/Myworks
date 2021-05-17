SET serveroutput ON;
DECLARE
   l_status NUMBER(10);
BEGIN
	select count(status)
	INTO l_status
    from v$backup  
    where status = 'ACTIVE';
         DBMS_OUTPUT.put_line ('');

   IF (l_status = '0')
    THEN
      BEGIN
         DBMS_OUTPUT.put_line ('Lets GET BEGIN BACKUP!!!');
         --EXECUTE IMMEDIATE 'ALTER DATABASE BEGIN BACKUP';
    EXCEPTION
      WHEN OTHERS
       THEN   DBMS_OUTPUT.put_line ('ERROR: Some tablespaces are already in Backup Mode Before BEGIN BACKUP!!!');
   	   END;
   END IF;

END;


select decode(count(*),0,'None','SomeInBackupMode') as BackupInProgress 
from v$backup 
where status = 'ACTIVE';

select distinct df.tablespace_name, bk.file#, bk.status 
from dba_data_files df, v$backup bk
where df.file_id = bk.file#
and bk.status != 'ACTIVE'
ORDER BY 2;

SELECT DISTINCT df.tablespace_name, df.file_name , bk.file#
FROM dba_data_files df, v$backup bk
WHERE df.file_id = bk.file#
AND bk.status != 'ACTIVE'
ORDER BY 3;


select count(*)
    from v$backup  
    where status = 'ACTIVE';
    


