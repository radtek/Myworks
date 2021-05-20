-- DB Cache size and Hit Ratio
SELECT parm.value AS "Cache Size", 
      (cur.value+con.value) AS "Total Read",
       phy.value AS "Non Hit", 
       ROUND((1-(phy.value / (cur.value + con.value)))*100,2) "Cache Hit Ratio"
FROM v$sysstat cur, 
     v$sysstat con,
     v$sysstat phy,
     v$parameter parm
WHERE cur.name = 'db block gets'
AND con.name = 'consistent gets'
AND phy.name = 'physical reads'
AND parm.name = 'db_cache_size'

-- Cache Hit Ratio
SELECT 'Buffer Cache' AS name, 
       ROUND((1-(phy.value / (cur.value + con.value)))*100,2) AS Percent
FROM v$sysstat cur, 
        v$sysstat con,
        v$sysstat phy
WHERE cur.name = 'db block gets'
AND con.name = 'consistent gets'
AND phy.name = 'physical reads'
UNION
SELECT 'Library Cache' AS name,
       ROUND((1-(SUM(RELOADS)/SUM(PINS)))*100,2) AS Percent
FROM V$LIBRARYCACHE  
UNION
SELECT 'Dictionary Cache' AS name,
       ROUND((1-sum(getmisses)/(sum(gets)+sum(getmisses)))*100,2) AS Percent
FROM v$rowcache
WHERE gets+getmisses <> 0

-- SGA Pool Size
SELECT name,value
FROM   v$parameter
WHERE  name like '%_pool%'
	AND value IS NOT NULL
	AND value NOT IN ('FALSE','0')
ORDER BY name;

-- Actual Memory Size (When Using Automatic Parm)
select component , CURRENT_SIZE/1024/1024 AS CURRNET_MB , USER_SPECIFIED_SIZE
from V$MEMORY_DYNAMIC_COMPONENTS
where CURRENT_SIZE > 0;


-- Logical Reads Ratio -- Latch Misses Ratio -- Long Table Scan Ratio
/*
SELECT 'Logical Reads' AS name, (lr.value/(lr.value+pr.value))*100 AS Value
FROM 
  gv$sysstat lr,
  gv$sysstat pr
WHERE
  lr.name='session logical reads'
  AND pr.name='physical reads'
UNION
*/
SELECT
       'Latch Misses Ratio' AS name, 
       sum(l.misses) / sum(l.gets)*100 AS Value
FROM   v$latch l
UNION
SELECT 'Full table scan Ratio' AS name,
		ROUND(((SELECT SUM(value) 
 				FROM 
  				   gv$sysstat 
 				WHERE
  				   name IN ('table scans (long tables)')
				)
				/
				(SELECT SUM(value) 
 				FROM 
  				   gv$sysstat 
 				WHERE
     				name IN ('table fetch by rowid',
           				     'table scans (long tables)',
           					 'table scans (short tables)')
				))*100, 2) AS value
FROM dual
UNION
SELECT 'Chain count Ratio' AS name,
       NVL((SUM(chain_cnt)/SUM(num_rows)),0) AS value
FROM dba_tables
WHERE
owner NOT IN ('SYS','SYSTEM')
AND table_name NOT IN
 (SELECT table_name FROM dba_tab_columns
   WHERE
 data_type IN ('RAW','LONG RAW','CLOB','BLOB','NCLOB')
 )
AND chain_cnt > 0

-- Parse Ratio
select 'Soft Parses ' "Ratio",
       round(((select sum(value) from v$sysstat where name = 'parse count (total)')
             - (select sum(value) from v$sysstat where name = 'parse count (hard)'))
             /(select sum(value) from v$sysstat where name = 'execute count')
             *100,2)||'%' "percentage"
from dual
union
select 'Hard Parses ' "Ratio",
       round((select sum(value) from v$sysstat where name = 'parse count (hard)')
            /(select sum(value) from v$sysstat where name = 'execute count')
            *100,2)||'%' "percentage"
from dual
union
select 'Parse Failure ' "Ratio",
       round((select sum(value) from v$sysstat where name = 'parse count (failures)')
            /(select sum(value) from v$sysstat where name = 'parse count (total)')
            *100,2)||'%' "percentage"
from dual

-- Sort In memory ratio (PGA)
SELECT 'Sort ratio' AS name,
	   (a.value-b.value)/(a.value)*100 AS value 
FROM v$sysstat a, v$sysstat b 
WHERE a.name = 'sorts (memory)' 
AND b.name ='sorts (disk)'


-- TABLESPACE Usage
SELECT ddf.tablespace_name,
       SUM( distinct ddf.ddfbytes )/1048576 Total_mbyte,
       SUM( NVL( ds.bytes , 0 ) / 1048576 ) Used_mbyte
FROM 
   ( SELECT tablespace_name, SUM( bytes ) ddfbytes
     FROM dba_data_files
     GROUP BY tablespace_name ) ddf
   LEFT OUTER JOIN dba_segments ds
   ON ddf.tablespace_name = ds.tablespace_name
GROUP BY ddf.tablespace_name;


-- Datafiles Ordered Tablespace
SELECT
   ts.tablespace_name, vts.ts#, ts.file_name, ts.mbytes
FROM
   v$tablespace vts,
   (
   SELECT 
      tablespace_name, file_id, file_name, ( bytes / 1048576 ) mbytes
   FROM
      sys.dba_data_files
   UNION
   SELECT 
      tablespace_name, file_id, file_name, ( bytes / 1048576 ) mbytes
   FROM
      sys.dba_temp_files
   ) ts
WHERE
   vts.name = ts.tablespace_name
ORDER BY
   ts.tablespace_name, ts.file_id

-- Datafile per used size   
SET PAGESIZE 60
SET LINESIZE 300
COLUMN "Tablespace Name" FORMAT A20
COLUMN "File Name" FORMAT A80
 
SELECT  SUBSTR(DF.TABLESPACE_NAME,1,20) "TABLESPACE NAME",
        SUBSTR(DF.FILE_NAME,1,80) "FILE NAME",
        ROUND(DF.BYTES/1024/1024,0) "SIZE (M)",
        DECODE(EF.USED_BYTES,NULL,0,ROUND(EF.USED_BYTES/1024/1024,0)) "USED (M)",
        DECODE(EF.FREE_BYTES,NULL,0,ROUND(EF.FREE_BYTES/1024/1024,0)) "FREE (M)",
        DECODE(EF.USED_BYTES,NULL,0,ROUND((EF.USED_BYTES/DF.BYTES)*100,0)) "% USED"
FROM    DBA_DATA_FILES DF LEFT OUTER JOIN  
       (SELECT E.FILE_ID, SUM(E.BYTES) USED_BYTES, SUM(F.BYTES) FREE_BYTES
        FROM DBA_EXTENTS E, DBA_FREE_SPACE F
        WHERE E.FILE_ID = F.FILE_ID
        GROUP BY E.FILE_ID) EF
ON DF.FILE_ID = EF.FILE_ID
ORDER BY DF.TABLESPACE_NAME,
         DF.FILE_NAME;
   
-- invalid object 
select 
    owner, object_type, object_name, status
 from 
    dba_objects 
 where 
    status != 'VALID'
 order by owner, object_type; 


/*
-----------------------------
@?/rdbms/admin/utlrp.sql
or
-----------------------------
set heading off; 
set feedback off; 
set echo off; 
Set lines 999; 

Spool run_invalid.sql 

select 
'ALTER ' || OBJECT_TYPE || ' ' || 
OWNER || '.' || OBJECT_NAME || ' COMPILE;' 
from 
dba_objects 
where 
 status = 'INVALID' 
and 
object_type in ('PACKAGE','FUNCTION','PROCEDURE') 
; 
spool off; 
set heading on; 
set feedback on; 
set echo on; 

@run_invalid.sql 
*/

-- Wait time and event TOP 5   
SELECT NVL(s.username, '(oracle)') AS username,
s.sid,
s.serial#,
sw.event,
sw.wait_class,
sw.wait_time,
sw.seconds_in_wait,
sw.state
FROM   v$session_wait sw,
v$session s
WHERE  s.sid = sw.sid
AND sw.wait_class != 'Idle'
AND rownum < 6
ORDER BY sw.seconds_in_wait DESC


-- Redo log Switch Per Day / Hour
SELECT to_char(first_time, 'yyyy - mm - dd') aday,
--           to_char(first_time, 'hh24') hour,
           count(*) total
FROM   v$log_history
--WHERE  thread#=&EnterThreadId
GROUP BY to_char(first_time, 'yyyy - mm - dd')--,
--              to_char(first_time, 'hh24')
ORDER BY to_char(first_time, 'yyyy - mm - dd')--,
--              to_char(first_time, 'hh24') asc


-- Archivelog Generation Per day
SELECT TRUNC(completion_time)  "Generation Date" ,
   round(SUM(blocks*block_size)/1048576,0) "Total for the Day in MB"
FROM gv$archived_log
GROUP BY TRUNC(completion_time)
ORDER BY TRUNC(completion_time)

                

-- I/O Perfomance per File 
SELECT Substr(d.name,1,50) "File Name",
       f.phyblkrd "Blocks Read",
       f.phyblkwrt "Blocks Writen",
       f.phyblkrd + f.phyblkwrt "Total I/O"
FROM   v$filestat f,
       v$datafile d
WHERE  d.file# = f.file#
ORDER BY f.phyblkrd + f.phyblkwrt DESC


-- Disk File Operation               
select
    decode(p3,0 ,'Other',
              1 ,'Control File',
              2 ,'Data File',
              3 ,'Log File',
              4 ,'Archive Log',
              6 ,'Temp File',
              9 ,'Data File Backup',
              10,'Data File Incremental Backup',
              11,'Archive Log Backup',
              12,'Data File Copy',
              17,'Flashback Log',
              18,'Data Pump Dump File',
                  'unknown '||p3)  "File Type",
    decode(p1,1 ,'file creation',
              2 ,'file open',
              3 ,'file resize',
              4 ,'file deletion',
              5 ,'file close',
              6 ,'wait for all aio requests to finish',
              7 ,'write verification',
              8 ,'wait for miscellaneous io (ftp, block dump, passwd file)',
              9 ,'read from snapshot files',
                 'unknown '||p1) "File Operation",
    decode(p3,2,-1,p2) file#,
    count(*)
from dba_hist_active_sess_history
where event ='Disk file operations I/O'
group by p1,p3,
    decode(p3,2,-1,p2)

    
    


         

-- List Unusable Index in Schema         
SELECT owner,
       index_name
FROM   dba_indexes
WHERE  owner = DECODE(UPPER('&&Owner'), 'ALL', owner, UPPER('&&Owner'))
AND    status NOT IN ('VALID', 'N/A')
ORDER BY owner, index_name


-- Show all users in Database          
SELECT
   LPAD( DECODE( p.granted_role, 'DBA' , '*' ), 3 ) grole,
   u.username, u.default_tablespace, u.temporary_tablespace
FROM
   dba_users u, 
   (
   SELECT
      grantee, granted_role
   FROM
      dba_role_privs
   WHERE
      granted_role = 'DBA'
   ) p 
WHERE
   u.username = p.grantee (+)
ORDER BY 
   u.username

   
-- All Locked Objects   
SELECT b.session_id AS sid,
       NVL(b.oracle_username, '(oracle)') AS username,
       a.owner AS object_owner,
       a.object_name,
       Decode(b.locked_mode, 0, 'None',
                             1, 'Null (NULL)',
                             2, 'Row-S (SS)',
                             3, 'Row-X (SX)',
                             4, 'Share (S)',
                             5, 'S/Row-X (SSX)',
                             6, 'Exclusive (X)',
                             b.locked_mode) locked_mode,
       b.os_user_name
FROM   dba_objects a,
       gv$locked_object b
WHERE  a.object_id = b.object_id
ORDER BY 1, 2, 3, 4

-- Index Usage per Table
SELECT table_name,
       index_name,
       used,
       start_monitoring,
       end_monitoring
FROM   v$object_usage
WHERE  table_name = UPPER('&Table_Name')
AND    index_name = DECODE(UPPER('&&Index_Name'), 'ALL', index_name, UPPER('&&Index_Name'))


-- Tablespace Free Sizing
 select a.tablespace_name,sum(a.tots/1048576) Total_Size,
     sum(a.sumb/1048576) Total_Free,
     sum(a.sumb)*100/sum(a.tots) Percent_Free,
     sum(a.largest/1024) Max_Free,sum(a.chunks) Chunks_Free
     from
     (
     select tablespace_name,0 tots,sum(bytes) sumb,
     max(bytes) largest,count(*) chunks
     from dba_free_space a
     group by tablespace_name
     union
     select tablespace_name,sum(bytes) tots,0,0,0 from
      dba_data_files
     group by tablespace_name) a
     group by a.tablespace_name
order by percent_free;


-- Tablespace Fragmentaion (100%=No Frag)
select tablespace_name, count(*) free_chunks, 
       decode( round((max(bytes) / 1024000),2), null,0, round((max(bytes) / 1024000),2)) largest_chunk, 
       nvl(round(sqrt(max(blocks)/sum(blocks))*(100/sqrt(sqrt(count(blocks)) )),2), 0) fragmentation 
from sys.dba_free_space 
group by tablespace_name 
order by 2 desc, 1; 

-- Chained Rows
SELECT
   owner         AS     owner, 
   table_name    AS     table_name, 
   pct_free      AS     percent_free, 
   pct_used      AS     percent_used, 
   avg_row_len   AS     avg_row, 
   num_rows      AS     rownums, 
   chain_cnt     AS     chain_count,
   chain_cnt/num_rows AS percent
FROM dba_tables
WHERE
owner NOT IN ('SYS','SYSTEM')
AND table_name NOT IN
 (SELECT table_name FROM dba_tab_columns
   WHERE
 data_type IN ('RAW','LONG RAW','CLOB','BLOB','NCLOB')
 )
AND chain_cnt > 0
ORDER BY chain_cnt DESC
;


-- Dictionary Cache Detail
select 
   parameter,
   count,
   usage, 
   100*nvl(usage,0)/decode(count,null,1,0,1,count) pctused,
   gets,
   getmisses, 
   100*nvl(getmisses,0)/decode(gets,null,1,0,1,gets) pctmisses,
   decode( 
     greatest(100*nvl(usage,0)/decode(count,null,1,0,1,count),80), 
     80, ' Lower', 
     decode(least(100*nvl(getmisses,0)/decode(gets,null,1,0,1,gets),10), 
     10, '*Raise', ' Ok')   ) action 
 from
    v$rowcache 
 order by   1 
 ;  
 
