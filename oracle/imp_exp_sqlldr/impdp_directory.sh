#!/bin/bash
export ORACLE_HOME=/oracle/product/11.2.0/dbhome_1
export ORACLE_SID=SID
PASSWORD=oracle!23
EXP_DIR=BACKUP_ADM
SCHEMAS=($(ls -l /oradmp/backup_dmp/*.dmp | awk '{print $9}' | awk -F '.' '{print $1}'))
DATE=`date +%y%m%d_%H%M%S`

for SCH in "${SCHEMAS[@]}"
do
${ORACLE_HOME}/bin/impdp system/${PASSWORD} schemas=${SCH} directory=${EXP_DIR} dumpfile=${SCH}.dmp logfile=${DUMPFILES}_IMPORT_${DATE}.log
done
