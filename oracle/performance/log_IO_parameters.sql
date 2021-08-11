SELECT TO_CHAR(NEXT_TIME, 'YYYY-MM-DD') AS "DATE", 
       TO_CHAR(NEXT_TIME, 'HH24') AS "HOUR", 
       COUNT(RECID) AS SWITCHED 
FROM V$ARCHIVED_LOG
GROUP BY TO_CHAR(NEXT_TIME, 'YYYY-MM-DD'), TO_CHAR(NEXT_TIME, 'HH24')
ORDER BY 1 DESC, 2 DESC ;

SELECT RECID, NAME, RESETLOGS_TIME, FIRST_TIME, NEXT_TIME, COMPLETION_TIME ,BLOCKS ,STATUS
FROM V$ARCHIVED_LOG
ORDER BY FIRST_TIME DESC;


SELECT NAME, DISPLAY_VALUE, 
       CASE WHEN ISINSTANCE_MODIFIABLE='TRUE' THEN 'DYNAMIC'
       ELSE 'STATIC' END AS MODIFIABLE
FROM V$PARAMETER
WHERE NAME IN ('filesystemio_options','db_writer_processes',
'dbwr_io_slaves','disk_asynch_io','log_archive_max_processes',
'fast_start_mttr_target','fast_start_io_target','log_checkpoint_timeout',
'log_checkpoint_interval')

