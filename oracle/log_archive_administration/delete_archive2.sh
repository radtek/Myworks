#!/bin/bash
USAGE=$(df | grep /oraarch | awk '{gsub("%","");print $5}')
#echo $USAGE
if [ $USAGE -gt 70 ] ; then
    # Delete archivelog over 70% own filesystem.
    `/bin/ls -t /oraarch/*.arc | tail -n +2 | xargs rm -- `
   #echo ARCHIVE LOG FILES DELETED
   exit 0;
fi
