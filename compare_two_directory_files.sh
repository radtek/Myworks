#!/bin/bash
DIR1=$1
DIR2=$2
WAS1=($( ls $1))
UWAS1=($( ls $2))
WAS_CNT=${#WAS1[@]}
UWAS_CNT=${#UWAS1[@]}
for ((CNUM=0 ; $CNUM<${WAS_CNT}; CNUM++)) ; do
  eval "WASFILE=\${WAS1[${CNUM}]}"
  #echo "AS: $WASFILE"
                echo "#########################################################################"
                echo "$DIR1 : $WASFILE"
                echo "#########################################################################"

                FILE_SIZE1=($(cat $DIR1/$WASFILE | awk '{print $1}'))
                FILE_NAME1=($(cat $DIR1/$WASFILE | awk '{print $2}'))
                DE_CNT=0
                FN_CNT=${#FILE_NAME1[@]}
       for ((UNUM=0 ; $UNUM<${UWAS_CNT}; UNUM++)) ; do
          eval "UWASFILE=\${UWAS1[${UNUM}]}"
            #echo "U2L: $UWASFILE"

            if [ $WASFILE == $UWASFILE ]; then
                  DE_CNT=1
                  for ((ICNUM=0 ; $ICNUM<${FN_CNT}; ICNUM++)) ; do
                    
                  eval "FN1=\${FILE_NAME1[${ICNUM}]}"
                  eval "FS1=\${FILE_SIZE1[${ICNUM}]}"

                  if [ -n "$FN1" ]; then
                    U_EXT=`grep $FN1 $DIR2/$UWASFILE`
                    #echo $?
                    #echo $U_EXT
                    if [ -n "$U_EXT" ]; then
                        UFN1=($(echo $U_EXT | awk '{print $2}'))
                        UFS1=($(echo $U_EXT | awk '{print $1}'))

                        if [ $FS1 == $UFS1 ]; then
                           echo $FN1  $FS1  $UFN1  $UFS1  true  true
                        else
                           echo $FN1  $FS1  $UFN1  $UFS1  true  false 
                        fi

                    else
                        echo $FN1  $FS1  NONE  NONE  false  false
                    fi
                  fi

                  done
             fi
        done

                  if [ $DE_CNT == 0 ]; then
                  #echo "Not matched files"
                  for ((DNUM=0 ; $DNUM<${FN_CNT}; DNUM++)) ; do
                    eval "DFN1=\${FILE_NAME1[${DNUM}]}"
                    eval "DFS1=\${FILE_SIZE1[${DNUM}]}"

                    if [ -n "$DFN1" ]; then

                    echo $DFN1  $DFS1  NONE  NONE  false  false

                    fi
                    DE_CNT=1
                  done
                  fi
 
  done
