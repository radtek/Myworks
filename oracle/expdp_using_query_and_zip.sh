#!/bin/bash
export ORACLE_BASE=/oracle
export ORACLE_HOME=${ORACLE_BASE}/product/12.2.0/dbhome_1
export ORACLE_SID=$1
export EXP_DIR=BACKUP_ADM
export EXP_PATH=/oradmp/backup_dmp
export LOG_PATH=${EXP_PATH}/logs

ORACLE_USER=SYSTEM
ORACLE_PASSWORD='oracle!23'
RETENTION_DAYS=7
QUERY_CMD="SELECT USERNAME FROM DBA_USERS WHERE REGEXP_LIKE(USERNAME, 'PROD$|BI$')"
CHECKPROC=`ps -ef | grep ora_pmon_$ORACLE_SID | grep -v grep | wc -l`

#----------------------------------------------------------------------
# Start Script
#----------------------------------------------------------------------
RETENTION=$[(${RETENTION_DAYS}-1)]
DATE=$(date +"%Y%m%d")
LOG_DF=${LOG_PATH}/exp.${DATE}

if [ ${CHECKPROC} == 1 ]; then
  echo "`date +%Y-%m-%d\ %H:%M:%S` : check pmon process = [PASS] start export" >> ${LOG_DF}

  CHECKLOG=`ls -ld ${LOG_PATH} | wc -l`
  if [ $CHECKLOG == 1 ]; then
    echo "`date +%Y-%m-%d\ %H:%M:%S` : log directory checked = [PASS] " >> ${LOG_DF}
  else
    echo "`date +%Y-%m-%d\ %H:%M:%S` : log directory checked = [FAILED] creating log directory automatically. " >> ${LOG_DF}
    `mkdir -p ${LOG_PATH}`
  fi

ORACLE_SCHEMAS=($(
${ORACLE_HOME}/bin/sqlplus -s <<EOF
${ORACLE_USER}/${ORACLE_PASSWORD}
set serveroutput off
set heading off
set feedback off
set verify off
set define off
${QUERY_CMD};
EOF
))

SCHEMA_CNT=${#ORACLE_SCHEMAS[@]}

#echo "`date +%Y-%m-%d\ %H:%M:%S` : Starting backup script.." > ${LOG_DF}

for ((CNUM=0 ; $CNUM<${SCHEMA_CNT}; CNUM++)) ; do
  eval "ORACLE_SCHEMA=\${ORACLE_SCHEMAS[${CNUM}]}"

  ${ORACLE_HOME}/bin/expdp ${ORACLE_USER}/${ORACLE_PASSWORD} directory=${EXP_DIR} schemas=${ORACLE_SCHEMA} dumpfile=${DATE}-${ORACLE_SID}_${ORACLE_SCHEMA}.dmp logfile=${DATE}-${ORACLE_SID}_${ORACLE_SCHEMA}.log
  EXP_STAT=$?

  if [ ${EXP_STAT} -eq 0 ]; then
    echo "`date +%Y-%m-%d\ %H:%M:%S` : [SUCCESS] ${ORACLE_SCHEMA} Export Succeded," >> ${LOG_DF}
    find ${EXP_PATH}/*-${ORACLE_SID}_* -daystart -mtime +${RETENTION} -delete
  elif [ ${EXP_STAT} -eq 5 ]; then
    echo "`date +%Y-%m-%d\ %H:%M:%S` : [ERROR] ${ORACLE_SCHEMA} Export Succeded with some errors," >> ${LOG_DF}
  else
    echo "`date +%Y-%m-%d\ %H:%M:%S` : [FAILED] ${ORACLE_SCHEMA} Export failed with errors," >> ${LOG_DF}
  fi

done

mv ${EXP_PATH}/*.log ${LOG_PATH}/
tar -czf ${EXP_PATH}/${DATE}-${ORACLE_SID}.tar.gz ${EXP_PATH}/${DATE}-*.dmp --remove-files >> ${LOG_DF}
  if [ $? -eq 0 ]; then
    echo "`date +%Y-%m-%d\ %H:%M:%S` TAR : [SUCCESS] Export archived successfully, delete over retention files," >> ${LOG_DF}
    find ${LOG_PATH}/* -daystart -mtime +${RETENTION} -delete
    find ${EXP_PATH}/*.tar.gz -daystart -mtime +${RETENTION} -delete
  else
    echo "`date +%Y-%m-%d\ %H:%M:%S` TAR : [ERROR] something wrong with tar archive. please check logs" >> ${LOG_DF}
  fi

echo "`date +%Y-%m-%d\ %H:%M:%S` : [DONE] Backup process done." >> ${LOG_DF}

else
  echo "`date +%Y-%m-%d\ %H:%M:%S` :  check pmon process = [FAILED] export aborted." >> ${LOG_DF}
fi
