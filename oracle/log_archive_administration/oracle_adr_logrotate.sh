#!/bin/bash
#---------------------------------------------------------------------------------------------
# ADR_LOG_ROTATOR Created by YS.Kim 2020.10
# lsnrctl need export ORACLE_HOME.
# RETENTION_MNS determine logfile retention N month period.
# For using This script, You should set adr base diagnostic dest and listener.
# alert log dest and Listener log dest MUST set adr default for autocheck, except ADR base.
#---------------------------------------------------------------------------------------------
export ORACLE_HOME=/oracle/product/11.2.0/dbhome_1/
RETENTION_MNS=6

#---------------------------------------------------------------------------------------------
# Script Area
#---------------------------------------------------------------------------------------------
CURRENT_DATE=`date +%Y%m%d`
ADR_BASE=`$ORACLE_HOME/bin/adrci exec="show base"|awk -F '"' '{print $2}'`
ADR_HOMEPATHS=($($ORACLE_HOME/bin/adrci exec="show homepath" | grep -v "ADR Homes:"))

# Check ADR base homepaths
if [ -z "$ADR_HOMEPATHS" ]; then
	echo "${CURRENT_DATE} ERROR : No Default ADR BASE homepaths." 
	exit 1
fi

CUR_YR=${CURRENT_DATE:0:4}
CUR_MN=${CURRENT_DATE:4:2}
CUR_DY=${CURRENT_DATE:6:2}

for HOMEPATH in "${ADR_HOMEPATHS[@]}"
 do
	IFS='/'
	read -ra DESCRIPTORS <<< "$HOMEPATH"
	DESCRT=${DESCRIPTORS[${#DESCRIPTORS[@]}-1]}
	
	if [[ $HOMEPATH =~ "tnslsnr" ]]; then
		# Set variable when listener home
		 LOG_DEST=$ADR_BASE/$HOMEPATH/alert
		 LOG_FILE=log.xml
	 elif [[ $HOMEPATH =~ "rdbms" ]]; then
		# Set variable when rdbms home
		 LOG_DEST=$ADR_BASE/$HOMEPATH/trace
		 LOG_FILE=alert_${DESCRT}.log
	 else
		# not compatible destination
		 echo "`date +%Y-%m-%d\ %H:%M:%S` homepaths not include rdbms or tnslsnr. please verify using default dest set." >> ${ADR_BASE}/${CURRENT_DATE:0:6}_logrotate.err
		 exit 1
	fi
	# Check and create directory when needed.
	IFS=''
	cd $LOG_DEST
	if [ -d $CUR_YR ]; then
	 # When year directory exist..
		cd $CUR_YR
		 if [ -d $CUR_MN ]; then
			# month directory exist..
			echo ""
		  else 
			# Make current month directory
			 mkdir $CUR_MN
			  if [ $? == 1 ]; then
				# mkdir failed
				 echo "`date +%Y-%m-%d\ %H:%M:%S` make directory failed - "${LOG_DEST} >> ${ADR_BASE}/${CURRENT_DATE:0:6}_logrotate.err
				 exit 1
			  fi
		 fi
	 else 
	 # Make current year/month directory
		mkdir -p $CUR_YR/$CUR_MN
		 if [ $? == 1 ]; then
			# mkdir failed
			 echo "`date +%Y-%m-%d\ %H:%M:%S` make directory failed - "${LOG_DEST} >> ${ADR_BASE}/${CURRENT_DATE:0:6}_logrotate.err
			 exit 1	
		 fi
	fi

	# copy and truncate logfile start from here.
	cp ${LOG_DEST}/${LOG_FILE}  ${LOG_DEST}/${CUR_YR}/${CUR_MN}/${LOG_FILE}.${CURRENT_DATE}
	if [ $? == 0 ]; then
	  	 echo "`date +%Y-%m-%d\ %H:%M:%S` : Log Rotate Complete -------------------------------------------------------" > ${LOG_DEST}/${LOG_FILE}
	 else
		# abort when cp failed.
		 echo "`date +%Y-%m-%d\ %H:%M:%S` cp logfile failed - "${LOG_FILE} >> ${ADR_BASE}/${CURRENT_DATE:0:6}_logrotate.err
		 exit 1	
	fi

	# directory deletion start
	if [ $CUR_DY == '01' ]; then
		 RYRS=$[$RETENTION_MNS/12]
		 RMNS=$[$RETENTION_MNS%12]
		 RETENTION=$[(${CUR_MN}-${RMNS})]
		 cd $LOG_DEST

		if [ $RETENTION -lt 1 ]; then
			 LAST_MN=$[ 11+$RETENTION ]
			 LAST_YR=$[ $CUR_YR-$RYRS-1 ]
			 		
		 elif [ $RETENTION -gt 1 ]; then
			 LAST_MN=$[ $RETENTION-1 ]
			 LAST_YR=$[ $CUR_YR-$RYRS ]
			 
		 elif [ $RETENTION -eq 1 ]; then
			 LAST_YR=$[ $CUR_YR-$RYRS-1 ]
			 find . -type d -regex "./$LAST_YR" | xargs -d"\n" rm -rf
			 if [ $? == 0 ]; then
				exit 0
			 else
				exit 1
			 fi
		fi
		
		if [ $LAST_MN -gt 9 ]; then
			MN_D1=${LAST_MN:1:1}
			find . -type d -regex "./$LAST_YR/\(0[0-9]\|1[0-$MN_D1]\)" | xargs -d"\n" rm -rf
			
		 elif [ $LAST_MN -lt 10 ]; then
			find . -type d -regex "./$LAST_YR/\(0[0-$LAST_MN]\)" | xargs -d"\n" rm -rf
		fi

	fi
done


# lsnrctl stat $LISTENER_NAME | grep -E 'TNS-12531|TNS-01101'
#LOG_DEST=`$ORACLE_HOME/bin/lsnrctl show log_directory | grep log_directory | awk '{print $6}'`

#${ORACLE_HOME}/bin/lsnrctl << EOF
#set current_listener ${LISTENER_NAME}
#set log_status off
#set log_status on
#EOF
