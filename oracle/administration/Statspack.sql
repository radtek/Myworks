-- Create Tablespace using statspack
create tablespace statspack_data
datafile '/data/oracle/database/11gR2/oradata/scratch/statspack_data01.dbf' size 500M
autoextend on maxsize 2G
extent management local uniform size 1M
segment space management auto;

-- Create Statspack package
@?/rdbms/admin/spcreate.sql

-- Verify Statspack snap level description
select * from stats$level_description;
 
SNAP_LEVEL  DESCRIPTION
----------  --------------------------------------------------------------------
         0  This level captures general statistics, including rollback segment, 
            row cache, SGA, system events, background events, session events, 
            system statistics, wait statistics, lock statistics, and Latch 
            information
 
         5  This level includes capturing high resource usage SQL Statements, 
            along with all data captured by lower levels
 
         6  This level includes capturing SQL plan and SQL plan usage 
            information for high resource usage SQL Statements, along with all 
            data captured by lower levels
 
         7  This level captures segment level statistics, including logical and 
            physical reads, row lock, itl and buffer busy waits, along with all 
            data captured by lower levels
 
        10  This level includes capturing Child Latch statistics, along with 
            all data captured by lower levels
			
-- Set snap level
BEGIN
	statspack.modify_statspack_parameter(i_snap_level=>7, i_modify_parameter=>'TRUE');
END ;

-- Create schedule for statspack snap
BEGIN
    DBMS_SCHEDULER.CREATE_SCHEDULE(
     schedule_name => 'perfstat.statspack_per_30min',
     repeat_interval => 'FREQ=MINUTELY;BYMINUTE=00,30');

    DBMS_SCHEDULER.CREATE_JOB(
     job_name => 'perfstat.sp_snapshot',
     job_type => 'STORED_PROCEDURE',
     job_action => 'perfstat.statspack.snap',
     schedule_name => 'perfstat.statspack_per_30min',
     comments => 'Statspack snapshot per 30 minutes');

    DBMS_SCHEDULER.ENABLE('perfstat.sp_snapshot');
  END;
  

-- Create schedule for purge job (retention base)
BEGIN
    DBMS_SCHEDULER.CREATE_JOB (
            job_name => '"PERFSTAT"."SP_PURGE"',
            job_type => 'PLSQL_BLOCK',
            job_action => 'begin
                           statspack.purge(i_num_days=>14,i_extended_purge=>TRUE);
                           end;',
            number_of_arguments => 0,
            start_date => TO_TIMESTAMP_TZ('2018-10-19 00:00:00.000000000 ASIA/SEOUL','YYYY-MM-DD HH24:MI:SS.FF TZR'),
            repeat_interval => 'FREQ=DAILY;',
            end_date => NULL,
            enabled => FALSE,
            auto_drop => FALSE,
            comments => 'Statspack purge before 14d snapshots');
 
    DBMS_SCHEDULER.enable(
             name => '"PERFSTAT"."SP_PURGE"');
END;

-- Report between snapshots
@?/rdbms/admin/spreport.sql

-- Purge specific snapshot
@?/rdbms/admin/sppurge.sql

-- Truncate all snapshots
@?/rdbms/admin/sptrunc.sql

-- Drop All the Statspack package
@?/rdbms/admin/spdrop.sql


-- ### Managing Purge with Shell #######################################################################################################
Customized the sppurge.sql 

copy $ORACLE_HOME/rdbms/admin/sppurge.sql in your scripts directory (I also rename it to sppurge_customised.sql ) and Change it to include

column min_snap_id new_val LoSnapId
column max_snap_id new_val HiSnapId
select min(s.snap_id) min_snap_id, max(s.snap_id) max_snap_id
from stats$snapshot s
, stats$database_instance di
where s.dbid = :dbid
and di.dbid = :dbid
and s.instance_number = :inst_num
and di.instance_number = :inst_num
and di.startup_time = s.startup_time
and s.snap_time < sysdate - 90; -- purge anything older than 90 days


-- BEFORE the following code in the script

--
-- Post warning

prompt
prompt
prompt Warning
prompt ~~~~~~~
prompt sppurge.sql deletes all snapshots ranging between the lower and
prompt upper bound Snapshot Ids specified, for the database instance
prompt you are connected to.


-- Automate the collection and the purging

Set up a cron job to execute the following script every hour. Please note that the "sppurge_customised.sql" is executed only once in a day i.e. at midnight.

#!/bin/bash
if pgrep -f ora_
then
. /home/oracle/.bash_profile
SCRIPTPATH=/app/oracle/admin/scripts
LOGFILE=$SCRIPTPATH/LOGS
ORACLE_SID=mysid
export ORACLE_SID

cd $SCRIPTPATH
echo Starting Statsupdate at `date` >> $LOGFILE/statspack.log

# only purge older stats once a day at midnight
cuurent_hour=`date +%H`
if [ $cuurent_hour == "00" ]; then
sqlplus /nolog >> $LOGFILE/statspack.log << EOF
connect perfstat/perfstat
@sppurge_customised.sql
EOF
fi

sqlplus /nolog >> $LOGFILE/statspack.log << EOF
connect perfstat/perfstat
exec statspack.snap;
EOF

echo Finished at `date` >> $LOGFILE/statspack.log
fi