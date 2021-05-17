SELECT SQL_ID,
FROM v$session
WHERE USERNAME = 'MCCADM'
AND status = 'ACTIVE'
/*
SELECT SQL_ID, 
       AVG(CPU_TIME/EXECUTIONS/1000000) AS CPU_USED_SEC, 
       AVG(ELAPSED_TIME/EXECUTIONS/1000000) AS ELAPSED_SEC, 
       AVG(BUFFER_GETS/EXECUTIONS) AS BUFFER_GETS, 
       AVG(DISK_READS/EXECUTIONS) AS DISK_READS, 
       AVG(SORTS/EXECUTIONS) AS SORTS, 
       SQL_TEXT
FROM V$SQL
WHERE PARSING_SCHEMA_NAME LIKE '%ADM'
AND EXECUTIONS <> 0
AND SQL_TEXT NOT LIKE '/* SQL Analyze(1)%'
GROUP BY SQL_ID, SQL_TEXT
ORDER BY 3 DESC;
*/

SELECT A.*
FROM  (SELECT
       SQL_ID, 
       MAX(LAST_ACTIVE_TIME) AS LAST_ACTION,
       SUM(EXECUTIONS) AS EXECUTION_MAX,
       MAX(CPU_TIME/EXECUTIONS/1000000) AS CPU_USED_SEC, 
       MAX(ELAPSED_TIME/EXECUTIONS/1000000) AS ELAPSED_SEC, 
       MAX(BUFFER_GETS/EXECUTIONS) AS BUFFER_GETS, 
       MAX(DISK_READS/EXECUTIONS) AS DISK_READS, -- disk_reads * block_size = physical_read_bytes
       MAX(SORTS/EXECUTIONS) AS SORTS, 
       MAX(ROWS_PROCESSED/EXECUTIONS) AS ROWS_PROCESSED,
       MAX(APPLICATION_WAIT_TIME/EXECUTIONS/1000000) AS APP_WAIT,
       MAX(USER_IO_WAIT_TIME/EXECUTIONS/1000000) AS USERIO_WAIT,
       MAX(CONCURRENCY_WAIT_TIME/EXECUTIONS/1000000) AS CONCUR_WAIT,
       SQL_TEXT
FROM V$SQL
WHERE PARSING_SCHEMA_NAME LIKE '%ADM'
AND SQL_TEXT NOT LIKE '/* SQL Analyze(1)%'
AND LAST_ACTIVE_TIME > TO_DATE(TRUNC(sysdate-1),'YYYY-MM-DD HH24:MI:SS')
AND EXECUTIONS > 0
GROUP BY SQL_ID, SQL_TEXT) A
WHERE A.EXECUTION_MAX > 100 -- 시스템에 따라
AND A.ELAPSED_SEC > 0.3     -- 다르게 설정해야 한다.
ORDER BY 5 DESC;


SELECT * FROM TABLE(DBMS_XPLAN.display_cursor('884mfbqf1k1xn'));


SELECT SQL_ID, LAST_LOAD_TIME, EXECUTIONS, CPU_TIME, ELAPSED_TIME, BUFFER_GETS, SORTS, SQL_FULLTEXT
FROM v$sqlarea
WHERE sql_id ='884mfbqf1k1xn';
