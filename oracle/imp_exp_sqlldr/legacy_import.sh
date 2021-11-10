#!/bin/bash
export ORACLE_HOME=/oracle/product/11.2.0/dbhome_1
export ORACLE_SID=SID
PASSWORD=oracle!23
DATE=`date +%y%m%d_%H%M%S`
DUMPFILE=$1

imp SYSTEM/${PASSWORD} FROMUSER=LIAMGR,RYOMGR,RWMMGR,SALMGR,CYMMGR,TMAX2,BIDMGR,MCC_CONTENTS,JDKIM,SMSMGR,EDIMGR,SHPMGR,KTNMGR,WEBMGR,WAGMGR,CMINFO,ITNC,CFSMGR,SIAMGR,SAMMGR,ICPMGR,SOMMGR,TMAX1,EAIMGR,GPANS,EWSMGR,CONV,GGS,EQUMGR FILE=${DUMPFILE} LOG=SCHEMA_IMPORTS_${DATE}.log IGNORE=Y

imp SYSTEM/${PASSWORD} FROMUSER=DAMO TOUSER=DAMO_CON FILE=${DUMPFILE} LOG=DAMO_CON_IMPORT_${DATE}.log IGNORE=Y
