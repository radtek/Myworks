-- RMAN 설정

CONFIGURE BACKUP OPTIMIZATION ON;
CONFIGURE SNAPSHOT CONTROLFILE NAME TO '/dmsdevdmp/snapcf_DMSDEVDB.f'; 
CONFIGURE CONTROLFILE AUTOBACKUP ON;
CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO '/dmsdevdmp/%F';
CONFIGURE RETENTION POLICY TO REDUNDANCY 2;

RMAN> show all;

RMAN configuration parameters for database with db_unique_name DMSDEVDB are:
CONFIGURE RETENTION POLICY TO REDUNDANCY 2;
CONFIGURE BACKUP OPTIMIZATION ON;
CONFIGURE DEFAULT DEVICE TYPE TO DISK; # default
CONFIGURE CONTROLFILE AUTOBACKUP ON;
CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO '/dmsdevdmp/%F';
CONFIGURE DEVICE TYPE DISK PARALLELISM 1 BACKUP TYPE TO BACKUPSET; # default
CONFIGURE DATAFILE BACKUP COPIES FOR DEVICE TYPE DISK TO 1; # default
CONFIGURE ARCHIVELOG BACKUP COPIES FOR DEVICE TYPE DISK TO 1; # default
CONFIGURE MAXSETSIZE TO UNLIMITED; # default
CONFIGURE ENCRYPTION FOR DATABASE OFF; # default
CONFIGURE ENCRYPTION ALGORITHM 'AES128'; # default
CONFIGURE COMPRESSION ALGORITHM 'BASIC' AS OF RELEASE 'DEFAULT' OPTIMIZE FOR LOAD TRUE ; # default
CONFIGURE RMAN OUTPUT TO KEEP FOR 7 DAYS; # default
CONFIGURE ARCHIVELOG DELETION POLICY TO NONE; # default
CONFIGURE SNAPSHOT CONTROLFILE NAME TO '/dmsdevdmp/snapcf_DMSDEVDB.f'; 

-- /dmsdevdmp/rman_dmsdev.sh
#!/bin/bash
export ORACLE_BASE=/dmsdevora
export ORACLE_HOME=${ORACLE_BASE}/product/12.1.0/dbhome_1
export ORACLE_SID=$1
export RMAN_CMD=/dmsdevdmp/rman_dmsdev.cmd

$ORACLE_HOME/bin/rman cmdfile=$RMAN_CMD > /dmsdevdmp/`date +%Y%m%d`_RMANBAK.log
find /dmsdevdmp/*_RMANBAK.log -mtime +2 -delete

*/
-- CRONTAB
0 0 * * * /dmsdevdmp/rman_dmsdev.sh dmsdevdb 2>&1

-- /dmsdevdmp/rman_dmsdev.cmd
connect target /
run {
allocate channel t1 type DISK;
crosscheck archivelog all;
sql "alter system archive log current";
sql "alter system checkpoint";
backup as backupset 
filesperset 8
format '/ddmdata01/backup_rman/RMANBAK_%d_%U'
TAG='BAK_INIT'
current controlfile
spfile
database 
plus archivelog 
delete all input;
DELETE noprompt expired copy;
DELETE noprompt obsolete;
release channel t1;
}