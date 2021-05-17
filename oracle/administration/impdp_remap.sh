[DOLAPDB]SYS> create directory dpump_dir as '/dolapdmp' ;

Directory created.

[DOLAPDB]SYS> select directory_name, directory_path from dba_directories;

DIRECTORY_NAME    DIRECTORY_PATH
----------------- -----------------------------------------------------------------------------
DPUMP_DIR         /dolapdmp



expdp system/'dolapdb1!' directory=DPUMP_DIR schemas=VCTADM dumpfile=VCTADM_20180228.dmp logfile=export_VCTADM_20180228.log 

[root@dFcalldb dolapdmp]# cp VCTADM_20180228.dmp /dtmdmp/
[root@dFcalldb dtmdmp]# chown dtmora:oinstall VCTADM_20180228.dmp 


[DTMDB]SYS> select directory_name, directory_path from dba_directories;

DIRECTORY_NAME   DIRECTORY_PATH
---------------- ------------------------------------------------------------------------------------
DPUMP_DIR        /dtmdmp


[DTMDB]SYS> grant all on directory dpump_dir to vctadm; -- user로 import 진행할때만

impdp system/'dtmdb1!' directory=DPUMP_DIR schemas=vctadm dumpfile=VCTADM_20180228.dmp \
logfile=import_VCTADM_20180228.log  exclude=index remap_tablespace=USERS:TS_TMS_VCTL_D



--remap schema and tablespace------------------------------------------------------------------------------------------------------

impdp system/'dtmdb1!' directory=DPUMP_DIR remap_schema=vctadm:jdafo dumpfile=20180319-DTMDB_VCTADM.dmp \
logfile=import_VCTADM_20180319.log  exclude=index remap_tablespace=TS_TMS_VCTL_D:jdafo_data


impdp system/'dtmdb1!' directory=DPUMP_DIR remap_schema=vctadm:jdafo dumpfile=20180319-DTMDB_VCTADM.dmp \
logfile=import_VCTADM_20180319-1.log  include=index remap_tablespace=TS_TMS_VCTL_X:jdafo_index

-- remap schema, tablespace and TABLE
INCLUDE TABLES : 'TB_IF_USR',   'TB_IF_CUST ',   'TB_IF_SLCJ',   'TB_IF_SL3PL',   'TB_IF_ITEMCJ',   'TB_IF_ITEM3PL'
REMAP TABLES :'FO_TB_IF_USR','FO_TB_IF_CUST ','FO_TB_IF_SLCJ','FO_TB_IF_SL3PL','FO_TB_IF_ITEMCJ','FO_TB_IF_ITEM3PL'

impdp system remap_schema=jdafo:dtsadm remap_tablespace=JDAFO_DATA:TS_OLAP_DTS_D,JDAFO_INDEX:TS_OLAP_DTS_X \
directory=backup_adm table_exists_action=skip \
remap_table=JDAFO.TB_IF_USR:FO_TB_IF_USR,JDAFO.TB_IF_CUST:FO_TB_IF_CUST,JDAFO.TB_IF_SLCJ:FO_TB_IF_SLCJ,JDAFO.TB_IF_SL3PL:FO_TB_IF_SL3PL,JDAFO.TB_IF_ITEMCJ:FO_TB_IF_ITEMCJ,JDAFO.TB_IF_ITEM3PL:FO_TB_IF_ITEM3PL \
include=table:\"IN\(\'TB_IF_USR\',\'TB_IF_CUST\',\'TB_IF_SLCJ\',\'TB_IF_SL3PL\',\'TB_IF_ITEMCJ\',\'TB_IF_ITEM3PL\'\)
