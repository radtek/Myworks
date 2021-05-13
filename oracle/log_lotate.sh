#!/bin/bash
# lsnrctl need export ORACLE_HOME
export ORACLE_HOME=/oracle/product/12.1.0/dbhome_1/
LISTENER_NAME=LISTENER
LOG_DEST=/oraclelog/diag/tnslsnr/pfcsidb1/listener/alert/
LOG_FILE=listener.log
ALERT_LOG=/oraclelog/diag/rdbms/mdmdb/MDMDB/trace/alert_MDMDB.log
RETENTION_DAYS=180

#----------------------------------------------------------------------
# Start Script
#----------------------------------------------------------------------
RETENTION=$[${RETENTION_DAYS}+2]
CURRENT_DATE=`date +%Y%m%d`
EXIST_NUM=`ls -l ${LOG_DEST}/${LOG_FILE} | wc -l`
LOG_NUM=`ls -t ${LOG_DEST} | tail -n +${RETENTION} | wc -l`

#echo ${LOG_NUM}
if [ $EXIST_NUM != 0 ]; then
${ORACLE_HOME}/bin/lsnrctl << EOF
set current_listener ${LISTENER_NAME}
set log_status off
EOF

#mv ${LOG_DEST}/${LOG_FILE}  ${LOG_DEST}/${LOG_FILE}.${CURRENT_DATE}
cp ${LOG_DEST}/${LOG_FILE}  ${LOG_DEST}/${LOG_FILE}.${CURRENT_DATE}
umask 127
#touch ${LOG_DEST}/${LOG_FILE}
cat "Log Rotate Complete ---------------" > ${LOG_DEST}/${LOG_FILE}
umask 022

${ORACLE_HOME}/bin/lsnrctl << EOF
set current_listener ${LISTENER_NAME}
set log_status on
EOF
#echo ${RETENTION}
#echo ${LOG_NUM}
    if [ $LOG_NUM != 0 ]; then
        `ls -t ${LOG_DEST} | tail -n +${RETENTION} | xargs rm --`
    fi

else
echo "Listener log Rotation ERROR: Log file not Exist\n Listener logfile automatically will be set to ${LOG_DEST}." >> ${ALERT_LOG}

umask 127
touch ${LOG_DEST}/${LOG_FILE}
umask 022

${ORACLE_HOME}/bin/lsnrctl << EOF
set current_listener ${LISTENER_NAME}
set log_status off
set log_status on
EOF

fi
