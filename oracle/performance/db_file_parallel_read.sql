Index Prefetch? db file parallel read? db file scattered read?
오라클 2009.08.26 18:42

(이 글은 다소 생소한 내용을 담고 있으니 관심있으신 분들만 읽어 보세요) 
Index Prefetch는 약간은 혼란스러운 기능입니다. 아래 정보들을 읽어 보면 제 말이 이해가 가실 겁니다. 
•PIO is more than LIO althought PIO is ''db file scattered read 
•db file scatter read 
•(RE): Calculating LIOs 
일반적인 견해는 다음과 같습니다. 1.Index Prefetch가 발생하면 Index Range Scan과 Table Lookup By ROWID에 대해 Non-Contignous Multiblock Read를 수행한다. 즉, 인접하지 않은 Block들을 Parallel하게 한꺼번에 읽어들인다. 물론 이것은 OS가 지원해야 가능한 기능이다. 
2.이 때 db file parallel read라는 대기 이벤트가 발생한다. 
3.한 꺼번에 읽을 수 있는 최대 블록 수는 _db_file_noncontig_mblock_read_count(기본값 11)에 의해 결정된다. 
4.Index Prefetch는 Oracle(CBO)가 전적으로 결정하며, 실행 계획이 동일하더라도 Index Prefetch가 선택될 수도 있고 안될 수도 있다. 
하지만 간혹 Index Range Scan과 Table Look by ROWID에 대해 db file scattered read 이벤트를 대기하는 경우가 종종 보고되고 있습니다. 저도 몇 년전 이 현상을 처음 보고 상당히 놀랐던 기억이 납니다. 왜 db file parallel read도 아니고 db file scattered read인가? 이것은 Index Prefetch인가, 아니면 전혀 다른 Prefetch 방법인가? 
이 문제에 대해서는 아직 명확한 설명이 존재하지 않는 것 같습니다. 

그래서 Test Database에서 Index Prefetch를 직접 재현해 보았습니다. 

우선 다음과 같이 Clustering Factor가 불량한 Index를 만듭니다. Clutering Factor가 불량하면 Single Block I/O의 성능이 느려지기 때문에 Oracle이 Multi Block I/O를 선택할 확률이 높아지기 때문입니다. 
UKJA@ukja1106> select * from v$version;

BANNER
--------------------------------------------------------------------------------
Oracle Database 11g Enterprise Edition Release 11.1.0.6.0 - Production
PL/SQL Release 11.1.0.6.0 - Production
CORE    11.1.0.6.0  Production
TNS for 32-bit Windows: Version 11.1.0.6.0 - Production
NLSRTL Version 11.1.0.6.0 - Production

Elapsed: 00:00:00.00

UKJA@ukja1106> create table t1(c1 int, c2 int);

Table created.

Elapsed: 00:00:00.14
UKJA@ukja1106> insert into t1
  2  select level, 1 from dual connect by level <= 100000
  3  order by dbms_random.random;

100000 rows created.

Elapsed: 00:00:01.82
UKJA@ukja1106> create index t1_n1 on t1(c1);

Index created.

Elapsed: 00:00:00.28
UKJA@ukja1106> 
UKJA@ukja1106> @gather t1
UKJA@ukja1106> exec dbms_stats.gather_table_stats(user, '&1', no_invalidate=>false);

PL/SQL procedure successfully completed.

Elapsed: 00:00:01.20

Index Prefetch가 선택될 확률을 극단적으로 높입니다. UKJA@ukja1106> alter session set "_index_prefetch_factor" = 1;

Session altered.

Elapsed: 00:00:00.00
UKJA@ukja1106> alter session set db_file_multiblock_read_count = 128;

Session altered.

Elapsed: 00:00:00.00

Buffer Cache를 Flush하고 Index Range Scan + Table Lookup By ROWID를 선택하게끔 Hint를 부여해서 Query를 수행합니다.  
UKJA@ukja1106> alter system flush buffer_cache;

System altered.

Elapsed: 00:00:00.37
UKJA@ukja1106> select /*+ index(t1) */ count(*)
  2  from t1 where c1 between 1 and 1000 and c2 = 1;

  COUNT(*)
----------
      1000

Elapsed: 00:00:00.03

SQL*Trace의 결과는 db file parallel read이벤트를 분명하게 보고합니다. select /*+ index(t1) */ count(*)
from t1 where c1 between 1 and 1000 and c2 = 1

call     count       cpu    elapsed       disk      query    current        rows
------- ------  -------- ---------- ---------- ---------- ----------  ----------
Parse        1      0.01       0.02          0          0          0           0
Execute      1      0.00       0.00          0          0          0           0
Fetch        2      0.03       0.11        182        998          0           1
------- ------  -------- ---------- ---------- ---------- ----------  ----------
total        4      0.04       0.13        182        998          0           1

Misses in library cache during parse: 1
Optimizer mode: ALL_ROWS
Parsing user id: 88  

Rows     Row Source Operation
-------  ---------------------------------------------------
      1  SORT AGGREGATE (cr=998 pr=182 pw=182 time=0 us)
   1000   TABLE ACCESS BY INDEX ROWID T1 (cr=998 pr=182 pw=182 time=8601 us cost=999 size=7000 card=1000)
   1000    INDEX RANGE SCAN T1_N1 (cr=4 pr=4 pw=4 time=21 us cost=4 size=0 card=1000)(object id 72154)


Elapsed times include waiting on following events:
  Event waited on                             Times   Max. Wait  Total Waited
  ----------------------------------------   Waited  ----------  ------------
  SQL*Net message to client                       2        0.00          0.00
  db file sequential read                        12        0.01          0.02
  db file parallel read                          15        0.03          0.08
  SQL*Net message from client                     2        0.00          0.00
********************************************************************************

원본 Trace 파일의 Wait Event에 대해 좀 더 상세한 분석을 해보겠습니다. UKJA@ukja1106> @trace_file_short
TRACE_FILE_NAME
--------------------------------------------------------------------------------
ukja1106_ora_31724.trc

Elapsed: 00:00:00.01
ukja1106_ora_31724.trc
UKJA@ukja1106> @wait_analyze &trace_file % 'db file parallel read' nam,files,blocks
NAM                            FILES      BLOCKS       COUNT(*)
------------------------------ ---------- ---------- ----------
'db file parallel read'        1          15                  1
'db file parallel read'        1          2                   3
'db file parallel read'        1          37                  1
'db file parallel read'        1          3                   1
'db file parallel read'        1          4                   2
'db file parallel read'        1          27                  1
'db file parallel read'        1          11                  1
'db file parallel read'        1          7                   3
'db file parallel read'        1          30                  1
'db file parallel read'        1          12                  1

10 rows selected.

Elapsed: 00:00:00.25

Multi Block Read의 Block수가 11이 아니라 3 ~ 37 사이까지 광범위하게 분포된 것을 알 수 있습니다. 문서화된 것과는 다른 현상이죠. 
Multi Block I/O가 어느 오브젝트에서 발생했는지를 보면 Index가 아닌 Table에 대해서만 발생했다는 것을 알 수 있습니다. 
UKJA@ukja1106> col obj new_value obj_no
UKJA@ukja1106> @wait_analyze &trace_file % 'db file parallel read' nam,obj
NAM                            OBJ          COUNT(*)
------------------------------ ---------- ----------
'db file parallel read'        72153              15

Elapsed: 00:00:00.09
UKJA@ukja1106> @obj &obj_no
UKJA@ukja1106> exec print_table('select * from all_objects where object_id = &1');
OWNER                         : UKJA
OBJECT_NAME                   : T1
SUBOBJECT_NAME                :
OBJECT_ID                     : 72153
DATA_OBJECT_ID                : 72153
OBJECT_TYPE                   : TABLE
CREATED                       : 2009/08/26 18:02:30
LAST_DDL_TIME                 : 2009/08/26 18:02:32
TIMESTAMP                     : 2009-08-26:18:02:30
STATUS                        : VALID
TEMPORARY                     : N
GENERATED                     : N
SECONDARY                     : N
NAMESPACE                     : 1
EDITION_NAME                  :
-----------------

역시 문서화된 것과는 다른 현상입니다. 아마도 Oracle이 판단하기에 Index는 Single Block I/O로 읽는 것은 유리하지만, Table로 가능 과정은 무겁기 때문에(Clustering Factor가 안좋기 때문에) Multi Block I/O가 유리하다고 판단한 것 같습니다. 어디까지나 추측입니다. 물론 이런 Oracle의 판단이 항상 성능에 유리한 것은 아닙니다. 자칫 치명적인 성능 저하를 가져올 수 있습니다.  
역시 풀리지 않은 의문은 "그렇다면 Oracle은 언제 db file parallel read 이벤트가 아닌 db file scattered read 이벤트를 보고하는가? 즉 "언제 Non-Contiguous Multi Block I/O가 아닌 Contiguous Multi Block I/O를 하는가"입니다. 역시 모르겠습니다. ^^; 

Footnote:wait_analyze.sql 파일은 여기에 있습니다. 


출처: http://ukja.tistory.com/243 [오라클 성능 문제에 대한 통찰 - 조동욱]