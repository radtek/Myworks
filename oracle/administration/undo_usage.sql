SELECT r.NAME "Undo Segment Name", dba_seg.size_mb,
DECODE(TRUNC(SYSDATE - LOGON_TIME), 0, NULL, TRUNC(SYSDATE - LOGON_TIME) || ' Days' || ' + ') || 
TO_CHAR(TO_DATE(TRUNC(MOD(SYSDATE-LOGON_TIME,1) * 86400), 'SSSSS'), 'HH24:MI:SS') LOGON, 
v$session.SID, v$session.SERIAL#, p.SPID, v$session.process,
v$session.USERNAME, v$session.STATUS, v$session.OSUSER, v$session.MACHINE, v$session.PROGRAM, v$session.module, action 
FROM v$lock l, v$process p, v$rollname r, v$session, 
(SELECT segment_name, ROUND(bytes/(1024*1024),2) size_mb FROM dba_segments WHERE segment_type = 'TYPE2 UNDO' ORDER BY bytes DESC) dba_seg 
WHERE l.SID = p.pid(+) AND 
v$session.SID = l.SID AND 
TRUNC (l.id1(+)/65536)=r.usn AND 
l.TYPE(+) = 'TX' AND 
l.lmode(+) = 6 
AND r.NAME = dba_seg.segment_name
AND v$session.username = 'SORADM'
AND status = 'INACTIVE'
ORDER BY size_mb DESC;

select a.sid, a.serial#, a.username, b.used_urec used_undo_record, b.used_ublk used_undo_blocks
from v$session a, v$transaction b
where a.saddr=b.ses_addr ;
 