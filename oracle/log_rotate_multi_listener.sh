#!/bin/bash
# lsnrctl need export ORACLE_HOME
export ORACLE_HOME=/polapora/product/12.1.0/dbhome_1/
LISTENER_NAME_1=li_pfcoldb
LISTENER_NAME_2=li_pfcoldb_map
LISTENER_NAME_3=li_pfcoldb_mgps
LISTENER_NAME_4=li_pfcoldb_vctl
LOG_DIR=/polaporalog/diag/tnslsnr/pFcolapdb1/
ALERT_LOG=/polaporalog/diag/rdbms/pfcoldb/PFCOLDB/trace/alert_PFCOLDB.log
RETENTION_DAYS=180

#----------------------------------------------------------------------
# Start Script
#----------------------------------------------------------------------

RETENTION=$[${RETENTION_DAYS}+2]
CURRENT_DATE=`date +%Y%m%d`

#CNUM=1
for CNUM in {1..4} ; do
eval "LISTENER_NAME=\${LISTENER_NAME_${CNUM}}"
LOG_DEST=${LOG_DIR}/${LISTENER_NAME}/alert
LOG_FILE=${LISTENER_NAME}.log
EXIST_NUM=`ls -l $LOG_DEST/$LOG_FILE | wc -l`
LOG_NUM=`ls -t $LOG_DEST | tail -n +${RETENTION} | wc -l`

#echo $LISTENER_NAME
#echo $RETENTION
#echo $CURRENT_DATE
#echo $LOG_DEST
#echo $LOG_FILE
#echo $EXIST_NUM
#echo $LOG_NUM
#CNUM=$CNUM+1

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

done
