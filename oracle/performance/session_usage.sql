--1. Session I/O By User
select nvl(ses.USERNAME,'ORACLE PROC') username,
 OSUSER os_user,
 PROCESS pid,
 ses.SID sid,
 SERIAL#,
 PHYSICAL_READS,
 BLOCK_GETS,
 CONSISTENT_GETS,
 BLOCK_CHANGES,
 CONSISTENT_CHANGES
from v$session ses, 
 v$sess_io sio
where  ses.SID = sio.SID
order  by PHYSICAL_READS, ses.USERNAME;

--2. CPU Usage By Session
select  nvl(ss.USERNAME,ss.PROGRAM) username,
 se.SID,
 VALUE cpu_usage
from  v$session ss, 
 v$sesstat se, 
 v$statname sn
where   se.STATISTIC# = sn.STATISTIC#
and   NAME like '%CPU used by this session%'
and   se.SID = ss.SID
order   by VALUE DESC;

--3. Resource Usage By User
select  ses.SID,
 nvl(ses.USERNAME,ses.PROGRAM) username,
 sn.NAME statistic,
 sest.VALUE,
 ses.status
from  v$session ses, 
 v$statname sn, 
 v$sesstat sest
where  ses.SID = sest.SID
and  sn.STATISTIC# = sest.STATISTIC#
and  sest.VALUE is not null
and  sest.VALUE != 0
AND ses.status = 'ACTIVE'
order  by ses.USERNAME, ses.SID, sn.NAME;

--4. Session Stats By Session
select  nvl(ss.USERNAME,'ORACLE PROC') username,
 se.SID,
 sn.NAME stastic,
 VALUE usage
from  v$session ss, 
 v$sesstat se, 
 v$statname sn
where   se.STATISTIC# = sn.STATISTIC#
and   se.SID = ss.SID
and se.VALUE > 0
order   by sn.NAME, se.SID, se.VALUE desc;
