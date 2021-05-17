#!/bin/bash
FILECOUNT=`/bin/ls -t /oraarch/*.arc | tail -n +2 | wc -l`
if [ $FILECOUNT == 0 ]; then
   echo "No needed deleted"
   exit 0;
else
   `/bin/ls -t /oraarch/*.arc | tail -n +2 | xargs rm -- `
   echo $FILECOUNT ARCHIVE LOG FILES DELETED
   exit 0;
fi
