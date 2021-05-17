SELECT b.tablespace,
       ROUND(((b.blocks*p.value)/1024/1024),2)||'M' AS temp_size,
       a.inst_id as Instance,
       a.sid||','||a.serial# AS sid_serial,
       NVL(a.username, '(oracle)') AS username,
       a.program,
       a.status,
       a.sql_id
FROM   gv$session a,
       gv$sort_usage b,
       gv$parameter p
WHERE  p.name  = 'db_block_size'
AND    a.saddr = b.session_addr
AND    a.inst_id=b.inst_id
AND    a.inst_id=p.inst_id
ORDER BY b.tablespace, b.blocks;

------------------------------------------------
SELECT se.username username,
se.SID sid, se.serial# serial#,
se.status status, se.sql_hash_value,
se.prev_hash_value,se.machine machine,
su.TABLESPACE tablespace,su.segtype,
su.CONTENTS CONTENTS
FROM v$session se,
v$sort_usage su
WHERE se.saddr=su.session_addr;
-------------------------------------------------
select * from V$TEMPSEG_USAGE;

alter tablespace TEMP1 shrink space keep 1024M;