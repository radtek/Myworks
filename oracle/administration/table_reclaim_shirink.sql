-- 각 테이블 용량확인
select segment_name,sum(bytes)/1024/1024 MB
from dba_segments
where segment_type='TABLE'
and owner = 'BIZENIC_ADM'
group by SEGMENT_NAME
order by 2 DESC;

-- 데이터 삭제 후 해당 테이블 축소작업
ALTER TABLE BIZENIC_ADM.BZ_SEND_MERGE enable ROW movement;
ALTER TABLE BIZENIC_ADM.BZ_SEND_MERGE shrink SPACE compact;
ALTER TABLE BIZENIC_ADM.BZ_SEND_MERGE shrink SPACE cascade;
ALTER TABLE BIZENIC_ADM.BZ_SEND_MERGE disable ROW movement;

/*
-- 추가 공간 할당 필요시 아래 커맨드 사용 ?에 번호 기입 (*현재 3번까지 있음)
-- 여유공간 81GB 남아있습니다.
ALTER tablespace TS_BIZENIC_D 
ADD datafile '/oradata1/BIZENIC/df_bizenic_0?.dbf'
SIZE 30000M;
*/

-- shrink script
SELECT CASE 
       WHEN B.LV=1 THEN 'ALTER TABLE '||A.owner||'.'||A.table_name||' enable ROW movement;'
       WHEN B.LV =2 THEN 'ALTER TABLE '||A.owner||'.'||A.table_name||' shrink SPACE CASCADE;'
       WHEN B.LV =3 THEN 'ALTER TABLE '||A.owner||'.'||A.table_name||' disable ROW movement;'
       END
FROM dba_tables A,
(SELECT LEVEL AS LV FROM dual
CONNECT BY LEVEL < 4) B
WHERE A.OWNER = 'IFIMS'
ORDER BY A.TABLE_NAME, B.LV;

--Script for MAX-Shrink:-

--================================
set verify off
column file_name format a50 word_wrapped
column smallest format 999,990 heading “Smallest|Size|Poss.”
column currsize format 999,990 heading “Current|Size”
column savings format 999,990 heading “Poss.|Savings”
break on report
compute sum of savings on report
column value new_val blksize
select value from v$parameter where name = 'db_block_size';
/
select file_name,
ceil( (nvl(hwm,1)*&&blksize)/1024/1024 ) smallest,
ceil( blocks*&&blksize/1024/1024) currsize,
ceil( blocks*&&blksize/1024/1024) -
ceil( (nvl(hwm,1)*&&blksize)/1024/1024 ) savings
from dba_data_files a,
( select file_id, max(block_id+blocks-1) hwm
from dba_extents
group by file_id ) b
where a.file_id = b.file_id(+) order by savings desc
/
--================================

--In lower versions you can use below query to find out possible savings from each data files of Database.

--================================
set linesize 400
col tablespace_name format a15
col file_size format 99999
col file_name format a50
col hwm format 99999
col can_save format 99999
SELECT tablespace_name, file_name, file_size, hwm, file_size-hwm can_save
FROM (SELECT /*+ RULE */ ddf.tablespace_name, ddf.file_name file_name,
ddf.bytes/1048576 file_size,(ebf.maximum + de.blocks-1)*dbs.db_block_size/1048576 hwm
FROM dba_data_files ddf,(SELECT file_id, MAX(block_id) maximum FROM dba_extents GROUP BY file_id) ebf,dba_extents de,
(SELECT value db_block_size FROM v$parameter WHERE name='db_block_size') dbs
WHERE ddf.file_id = ebf.file_id
AND de.file_id = ebf.file_id
AND de.block_id = ebf.maximum
ORDER BY 1,2);
--================================