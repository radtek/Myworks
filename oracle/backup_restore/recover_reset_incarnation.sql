Example 2-111 Resetting RMAN to a Previous Incarnation in NOCATALOG Mode

In NOCATALOG mode, you must mount a control file that contains information about the incarnation that you want to recover. The following scenario resets the database to an abandoned incarnation of database trgt and performs incomplete recovery.

CONNECT TARGET / NOCATALOG

# step 1: start and mount a control file that knows about the incarnation to which
# you want to return. Refer to the RESTORE command for appropriate options.
STARTUP NOMOUNT;
RESTORE CONTROLFILE FROM AUTOBACKUP;
ALTER DATABASE MOUNT;

# step 2: obtain the primary key of old incarnation
LIST INCARNATION OF DATABASE trgt;

List of Database Incarnations
DB Key  Inc Key DB Name  DB ID            STATUS   Reset SCN  Reset Time
------- ------- -------- -------------    -------  ---------- ----------
1       2       TRGT     1334358386       PARENT   154381     OCT 30 2007 16:02:12
1       116     TRGT     1334358386       CURRENT  154877     OCT 30 2007 16:37:39

# step 3: in this example, reset database to incarnation key 2
RESET DATABASE TO INCARNATION 2;

# step 4: restore and recover the database to a point before the RESETLOGS
RESTORE DATABASE UNTIL SCN 154876;
RECOVER DATABASE UNTIL SCN 154876;

# step 5: make this incarnation the current incarnation and list incarnations:
ALTER DATABASE OPEN RESETLOGS;
LIST INCARNATION OF DATABASE trgt;

List of Database Incarnations
DB Key  Inc Key DB Name  DB ID            STATUS  Reset SCN  Reset Time
------- ------- -------- ---------------- ------- ---------- ----------
1       2       TRGT     1334358386       PARENT  154381     OCT 30 2007 16:02:12
1       116     TRGT     1334358386       PARENT  154877     OCT 30 2007 16:37:39
1       311     TRGT     1334358386       CURRENT 156234     AUG 13 2007 17:17:03



col name for a52
SELECT df.FILE#
     , df.name
     , df.CHECKPOINT_CHANGE# AS SCN
     , df.CHECKPOINT_TIME AS SCN_TIMESTAMP
FROM v$datafile df
ORDER BY 1 ;

RECOVER DATABASE UNTIL CANCEL USING BACKUP CONTROLFILE;
RECOVER DATABASE UNTIL TIME '2000-12-31:12:47:30' USING BACKUP CONTROLFILE;
RECOVER DATABASE UNTIL CHANGE 10034;


