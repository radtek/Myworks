NO	PARAMETER CATEGORY	PARAMETER NAME	PARAMETER DESCRIPTION	DEFAULT VALUE	RECOMMEND VALUE	"SET SCRIPT
(scope=spfile sid='*')"	"RESET SCRIPT
(파라미터 초기화)"
1	Critical Process	gcs_server_processes	"LMS process (Interconnect를 통한 버퍼 공유를 담당하며 RAC 성능에 매우 중요함) 개수를 지정하는 파라미터
 - 10g ~ 11.1g: CPU_COUNT/4
 - 11.2g ~ 12.1c: 2+(CPUs/32)
 - Upgrade/Mig 시: 기존 사용값 유지
 - 신규 설치 시: 성능테스트 이후 default 값 유지 또는 변경 결정"	2+(CPUs/32)	협의 필요 (5)	alter system set gcs_server_processes=협의 필요 (5) COMMENT='DEFAULT:2+(CPUs/32)' scope=spfile sid='*';	alter system reset gcs_server_processes scope=spfile sid='*';
2	Etc	_clusterwide_global_transactions	"접속한 instance가 아닌 다른 node에서도 transaction 수행 가능하도록 설정
 - XA (AP -> TM -> RM) 미사용시 FALSE
   - Transaction Manager와 Resource Manager 사이를 XA 인터페이스라 함
   - XA는 Global Transaction 설정이 가능하지만 TPS가 25% 정도 절감됨
 - Instance Hang (Note 1350157.1) 발생할 수 있음
 - ORA-600 (Note 1279926.1) 발생할 수 있음"	TRUE	FALSE	alter system set "_clusterwide_global_transactions"=FALSE COMMENT='DEFAULT:TRUE' scope=spfile sid='*';	alter system reset "_clusterwide_global_transactions" scope=spfile sid='*';
3	Diag & Dump	_gc_dump_remote_lock	"다량의 block dump 시 associated locks이 remote node에 생성할 지를 지정함. TRUE 시 대량의 LMS (Interconnect를 통한 버퍼 공유를 담당하며 RAC 성능에 매우 중요함) Trace로 급격한 성능저하 발생 가능성 있음
 - Note 15841749.8"	TRUE	FALSE	alter system set "_gc_dump_remote_lock"=FALSE COMMENT='DEFAULT:TRUE' scope=spfile sid='*';	alter system reset "_gc_dump_remote_lock" scope=spfile sid='*';
4	RAC	_gc_policy_time	"RAC에서 특정 블록을 자주 access하는 node가 자동으로 Master Node가 됨
 - _gc_affinity_time (10g)를 대체함
 - Default 10분 단위로 Remastering 자격 조사함
 - DRM (Dynamic Resource Mastering)을 disable 하기 위해 0으로 설정
 - 참고: Note 390483.1"	10	0	alter system set "_gc_policy_time"=0 COMMENT='DEFAULT:10' scope=spfile sid='*';	alter system reset "_gc_policy_time" scope=spfile sid='*';
5	Etc	_gc_read_mostly_locking	"11g New Feature의 Read mostly locking 기능 사용 여부
 - DRM 또는 Read mostly locking에 의해 ORA-600 발생할 수 있음 (ORA-600 [kjbrasr:pkey])
 - Rolling 불가하며 Rolling 시 startup 안됨
 - 회피책: DRM disable 또는
            ""_gc_read_mostly_locking""=FALSE"	TRUE	FALSE	alter system set "_gc_read_mostly_locking"=FALSE COMMENT='DEFAULT:TRUE' scope=spfile sid='*';	alter system reset "_gc_read_mostly_locking" scope=spfile sid='*';
6	RAC	_gc_undo_affinity	"RAC에서 Undo Segments를 활성화 한 node가 자동으로 Master Node가 됨
 - DRM (Dynamic Resource Mastering) disable 권고함
 - 참고: Note 390483.1"	TRUE	FALSE	alter system set "_gc_undo_affinity"=FALSE COMMENT='DEFAULT:TRUE' scope=spfile sid='*';	alter system reset "_gc_undo_affinity" scope=spfile sid='*';
7	DB Memory	memory_target	"SGA와 PGA를 관리하는 메모리. memory_max_target을 설정하면 memory_target은 동일한 값으로 설정됨
 - 값 지정 시 auto로 관리가 되고
 - 0 설정 시 수동관리를 의미함

memory_max_target을 설정하지 않고 memory_target을 설정하면 자동으로 memory_max_target을 memory_target값으로 설정함. 반대로 memory_max_target을 설정하고 memory_target을 설정하지 않으면 memory_target은 0으로 설정되고 DB가 기동된 이후에 유동적으로 memory_target 값을 변경할 수 있으며 그 값은 memory_max_target 값을 넘을 수 없다."	0	협의 필요	alter system set memory_target=협의 필요 COMMENT='DEFAULT:0' scope=spfile sid='*';	alter system reset memory_target scope=spfile sid='*';
8	DB Memory	memory_max_target	"memory_target 값을 설정할 수 있는 최대 값. Fixed memory 사용을 위하여 disable한다. memory_target을 0으로 설정하는 경우, 자동으로 설정됨

memory_max_target을 설정하지 않고 memory_target을 설정하면 자동으로 memory_max_target을 memory_target값으로 설정함. 반대로 memory_max_target을 설정하고 memory_target을 설정하지 않으면 memory_target은 0으로 설정되고 DB가 기동된 이후에 유동적으로 memory_target 값을 변경할 수 있으며 그 값은 memory_max_target 값을 넘을 수 없다."	0	협의 필요	alter system set memory_max_target=협의 필요 COMMENT='DEFAULT:0' scope=spfile sid='*';	alter system reset memory_max_target scope=spfile sid='*';
9	Etc	filesystemio_options	"파일 시스템에서 I/O 오페레이션을 정의하는 파라미터
 - ASYNCH - Enabled asynchronous I/O where possible.
 - DIRECTIO- Enabled direct I/O where possible.
 - SETALL- Enabled both direct I/O and asynchronous I/O where possible.
 - NONE - Disabled both direct I/O and asynchronous I/O."	asynch	setall	alter system set filesystemio_options=setall COMMENT='DEFAULT:asynch' scope=spfile sid='*';	alter system reset filesystemio_options scope=spfile sid='*';
10	Security	_sys_logon_delay	"Invalid Login으로 인한 library cache locks, row cache lock 설정 여부
 - Disable: 0
 - Enable (보안 중요한 경우 설정): 1
 - Bug 18044182"	1	0	alter system set "_sys_logon_delay"=0 COMMENT='DEFAULT:1' scope=spfile sid='*';	alter system reset "_sys_logon_delay" scope=spfile sid='*';
11	Etc	event	"LGWR등의 Background process의 redo dump을 막을뿐 아니라 Foreground process 역시 불필요한 redo dump를 막음
 - Event 10055
 - Parameter Set Value로 설정을 권고함
 - 참고: 9385758.8"	NONE	'10555 trace name context forever, level 1'	alter system set event='10555 trace name context forever, level 1' COMMENT='DEFAULT:NONE' scope=spfile sid='*';	alter system reset event scope=spfile sid='*';
12	Etc	events	"LOB 컬럼 가공으로 인한 TEMP 영역 사용 후 미반환 이슈
 - Event 60025
 - 근본적인 해결책은 소스 코드에서 lob을 free하는 코드를 추가하는 것임
 - 참고: 802897.1"	NONE	'60025 trace name context forever'	alter system set events='60025 trace name context forever' COMMENT='DEFAULT:NONE' scope=spfile sid='*';	alter system reset events scope=spfile sid='*';
13	Critical Process	_use_adaptive_log_file_sync	"11g new feature로 log file sync 수행 시 “post-wait” 방식과 “polling”방식을 선택할 수 있도록 지정
 - TRUE: post-wait 과 polling 중 자동변환
 - FALSE:기존방식인 post-wait
 - polling_only: polling 방식 
 - 권고 : FALSE (post-wait 과 polling간의 자동변환 중 성능지연 발생함으로 변환되지 않도록 설정)
 - 참고: 1462942.1, 1541136.1"	TRUE	FALSE	alter system set "_use_adaptive_log_file_sync"=FALSE COMMENT='DEFAULT:TRUE' scope=spfile sid='*';	alter system reset "_use_adaptive_log_file_sync" scope=spfile sid='*';
14	Critical Process	_use_single_log_writer	"Scalable LGWR기능을 제어함. LGWR과 slave간에 동일한 structure를 access하며 memory barrier를 코드에 추가하지 않기 때문에, 기능 활성화 시 오동작할 가능성 내포함
 - TRUE: Scalable LGWR기능을 사용하지 않음
 - 기능 사용함으로 Instance crash, ORA-600, Hang 발생
 - 참고: 1968563.1, 1957710.1"	ADAPTIVE	TRUE	alter system set "_use_single_log_writer"=TRUE COMMENT='DEFAULT:ADAPTIVE' scope=spfile sid='*';	alter system reset "_use_single_log_writer" scope=spfile sid='*';
15	DBMS, Table & Partition	_add_col_optim_enabled	"Column add 시 dictionary만 update 하고 이후 insert시 object에 컬럼이 생성됨
 - 권고: Wrong result, scale 로 인해 FALSE 권고함 (ORA-7445)
 - 참고: Note 19183343.8"	TRUE	FALSE	alter system set "_add_col_optim_enabled"=FALSE COMMENT='DEFAULT:TRUE' scope=spfile sid='*';	alter system reset "_add_col_optim_enabled" scope=spfile sid='*';
16	Etc	_cursor_reload_failure_threshold	"Cursor reload failure 발생 시 retry 횟수 제어함 (CPU_COUNT값에 dependent 함)
 - 권고: Retry 횟수를 적합하게 설정하여 DDL 작업 완료 후 과도한 ""library cache:mutex X와 library cache lock wait""으로 인한 성능 저하 예방을 권고함 (CPU가 많은 경우 필수)
 - 참고: 11g에서는 event 12633340 level 5 설정 =>  12c부터는 해당 파라미터로 제어"	0	5	alter system set "_cursor_reload_failure_threshold"=5 COMMENT='DEFAULT:0' scope=spfile sid='*';	alter system reset "_cursor_reload_failure_threshold" scope=spfile sid='*';
17	DBMS, Table & Partition	deferred_segment_creation	"Create table 수행 시 즉시 table을 생성할 지를 결정
 - TRUE : create 명령수행 직후 table은 dictionary에만 등록되고 segment로는 만들어 지지 않음 insert시에 segment생성 됨
 - 권고 : true(default)로 설정시 library cache: mutex X‘, exp/imp에 포함되지 않는 문제, ORA-600으로 인해 FALSE 권고함
 - 주의 : FALSE 설정 이전에 만든 table은 parameter변경에도 영향을 받지 않음으로 SQL> alter table ""테이블"" move 또는 SQL> alter table ""테이블"" allocate extent; 를 수행해야 함 (Note 1178343.1)
 - 참조: _add_col_optim_enabled (column추가)
 - 참고: Note 1352678.1 , 1590806.1, 1352678.1"	TRUE	FALSE	alter system set deferred_segment_creation=FALSE COMMENT='DEFAULT:TRUE' scope=spfile sid='*';	alter system reset deferred_segment_creation scope=spfile sid='*';
18	Optimizer	optimizer_mode	"Optimizer가 어떠한 기준으로 최적화된 Access 경로 검색 결정법에 대해 제시함
 - CHOOSE
 - RULE
 - ALL_ROWS: 배치/OLAP/DW/MART
 - FIRST_ROWS(_number): OLTP"	ALL_ROWS	ALL_ROWS	alter system set optimizer_mode=ALL_ROWS COMMENT='DEFAULT:ALL_ROWS' scope=spfile sid='*';	alter system reset optimizer_mode scope=spfile sid='*';
19	Optimizer	optimizer_index_caching	"IN-list iterator 방식으로 Index Access 할 때 읽게 되는 인덱스 블록과 NL조인시 inner테이블에 속한 인덱스 블록에 대한 cost를 조정하고자 할 때 사용함. 단일 테이블을 액세스하기 위한 일반적인 Index Unique Scan 이나 Index Range Scan 비용을 계산할 때는 영향을 미치지 않음
 - 주의: 기존 운영DB와 동일하게 설정하지 않으면 실행계획이 변경될 수 있음
 - 참조: optimizer_index_cost_adj 과 같이 사용
 - 사용 예) 
   - OPTIMIZER_INDEX_CACHING = 0
      OPTIMIZER_INDEX_COST_ADJ = 100 (배치/DW/MART)
   - OPTIMIZER_INDEX_CACHING = 90
      OPTIMIZER_INDEX_COST_ADJ = 25 (OLTP)"	0	0	alter system set optimizer_index_caching=0 COMMENT='DEFAULT:0' scope=spfile sid='*';	alter system reset optimizer_index_caching scope=spfile sid='*';
20	Optimizer	optimizer_index_cost_adj	"1~10000사이의 값을 설정할 수 있으며 Index access와 Full Table Scan에서 사용되는 Physical I/O 의 Cost의 상대적인 비율을 의미함
 - 주의: 기존 운영DB와 동일하게 설정하지 않으면 실행계획이 변경될 수 있음
 - 100: Index Access, FTS를 동일한 비율로 Cost 계산
 - 50: Index Access를 기존 cost의 1/2로 계산, Index Access 방식으로 execution plan이 수립되어질 확률이 높아지게 됨
 - OLTP 시스템에서는 100 보다 적은 수치를 권장함
 - 참조: optimizer_index_caching 과 같이 사용
 - 사용 예) 
   - OPTIMIZER_INDEX_CACHING = 0
      OPTIMIZER_INDEX_COST_ADJ = 100 (배치/DW/MART)
   - OPTIMIZER_INDEX_CACHING = 90
      OPTIMIZER_INDEX_COST_ADJ = 25 (OLTP)"	100	100	alter system set optimizer_index_cost_adj=100 COMMENT='DEFAULT:100' scope=spfile sid='*';	alter system reset optimizer_index_cost_adj scope=spfile sid='*';
21	DB Memory	result_cache_max_size	"11g 신기능으로 이를 설정 후 /*+ result_cache */ 힌트를 사용하면 SQL결과가 Result cache area에 저장되어 response time이 보다 빨라짐
 - Disable: 0
 - 권고: 사용시 ORA-7445 [qesrcPin_Get] 발생함으로 필요시에만 설정
 - Note  1365365.1"	TRUE	0	alter system set result_cache_max_size=0 COMMENT='DEFAULT:TRUE' scope=spfile sid='*';	alter system reset result_cache_max_size scope=spfile sid='*';
22	Optimizer	_bloom_filter_enabled	"조인에 불필요한 데이터를 서버에서 제거하는 기능. 조인에 의해 연산건수가 많이 줄어드는 경우 효율적이지만 11g 버전에서 wrong result 발생하는 Bug 존재함. paralle query 성능 개선함.
 - 회피책: alter session set ""_bloom_filter_enabled"" = false;
 - 11.1.0.7 버전에서 Bug 존재함 (Bug 8308305 ORA-600 [qerpxSObjGdefVecInit] using bloom filters in Parallel Query)
 - 11.2.0.1 버전에서 Bug 존재함 (Bug 9488004 Intermittent Wrong Results with Bloom Filter in RAC)
 - 권고: 지속적으로 발생하는 Bug로 간주되므로 FALSE 설정 권고함"	TRUE	FALSE	alter system set "_bloom_filter_enabled"=FALSE COMMENT='DEFAULT:TRUE' scope=spfile sid='*';	alter system reset "_bloom_filter_enabled" scope=spfile sid='*';
23	Optimizer	_optimizer_aggr_groupby_elim	"Group by and Aggregation Elimination 기능 활성화 여부
 - 권고: Wrong result로 인해 FALSE 권고함
 - 참고: Note 19567916.8, 1924440.1"	TRUE	FALSE	alter system set "_optimizer_aggr_groupby_elim"=FALSE COMMENT='DEFAULT:TRUE' scope=spfile sid='*';	alter system reset "_optimizer_aggr_groupby_elim" scope=spfile sid='*';
24	Optimizer	_optimizer_null_aware_antijoin	"Anti-join 시 null 조건을 허용함
 - 권고: Wrong result 등의 이슈로 인해 FALSE 권고함
 - 참고: Note 9171379.8
                        18162779.8 (12.2.0.1 fix) (Function based index , DML with a DESC index fails with ORA-1428 ""argument '000000000000000000' is out of range“)"	TRUE	FALSE	alter system set "_optimizer_null_aware_antijoin"=FALSE COMMENT='DEFAULT:TRUE' scope=spfile sid='*';	alter system reset "_optimizer_null_aware_antijoin" scope=spfile sid='*';
25	Optimizer	_optimizer_reduce_groupby_key	"Query Transformation 수행 시 group by 절의 column이 상수로 지정된 경우 이를 생략하는 기능
 - 권고: Wrong result로 인해 FALSE 권고함
 - 참고: Note 20634449.8"	TRUE	FALSE	alter system set "_optimizer_reduce_groupby_key"=FALSE COMMENT='DEFAULT:TRUE' scope=spfile sid='*';	alter system reset "_optimizer_reduce_groupby_key" scope=spfile sid='*';
26	Optimizer	optimizer_adaptive_features	"Adaptive Optimizer feature의 기능을 제어함
(12cR1 이후, optimizer_adaptive_plans, optimizer_adaptive_statistics로 분기됨)
 - Adaptive Optimizer feature 기능
   - 1) Adaptive plan (adaptive join methods and bitmap plans)
   - 2) Automatic re-optimization
   - 3) SQL plan directives
   - 4) Adaptive distribution methods
 - 권고: 일반적인 경우 제거를 권고하나 해당 기능으로 plan변경을 막을 경우엔 FALSE 설정 및 application test필수 (dynamic설정 가능)
 - 참고: 해당 기능 중 01:adaptive plan을 disable할 경우엔 optimizer_adaptive_reporting_only 만 수정 할 것
 - 참고: Note 1409636.1 , 1964223.1"	TRUE	FALSE	alter system set optimizer_adaptive_features=FALSE COMMENT='DEFAULT:TRUE' scope=spfile sid='*';	alter system reset optimizer_adaptive_features scope=spfile sid='*';
27	Optimizer	optimizer_adaptive_reporting_only	"Adaptive Optimizer feature의 기능을 제어함
 - Adaptive Optimizer feature 기능
   - 1) Adaptive plan (adaptive join methods and bitmap plans)
   - 2) Automatic re-optimization
   - 3) SQL plan directives
   - 4) Adaptive distribution methods
 - 권고: 일반적인 경우 제거를 권고하나 해당 기능으로 plan변경을 막을 경우엔 FALSE 설정 및 application test필수 (dynamic설정 가능)
 - 참고: 해당 기능 중 01:adaptive plan을 disable할 경우엔 optimizer_adaptive_reporting_only 만 수정 할 것
 - 참고: Note 1409636.1 , 1964223.1"	FALSE	TRUE	alter system set optimizer_adaptive_reporting_only=TRUE COMMENT='DEFAULT:FALSE' scope=spfile sid='*';	alter system reset optimizer_adaptive_reporting_only scope=spfile sid='*';
28	Optimizer	_optim_peek_user_binds	"Bind variable peeking 활성화 여부 제어함 (바인드 변수에 따른 실행 계획 변경 여부 제어)
 - 권고: Plan의 안정화를 위해서 FALSE 권고함
 - 주의: 기존 운영DB와 동일하게 설정하지 않으면 실행계획이 변경될 수 있음"	TRUE	FALSE	alter system set "_optim_peek_user_binds"=FALSE COMMENT='DEFAULT:TRUE' scope=spfile sid='*';	alter system reset "_optim_peek_user_binds" scope=spfile sid='*';
29	Optimizer	_optimizer_adaptive_plans	실행되는 동안 초기단계에서 수집된 정보에 의해 Re-optimization (JOIN 방법, Parallel DOP 분배방법 등)을 수행하여 새로운 Plan을 생성함	TRUE	FALSE	alter system set "_optimizer_adaptive_plans"=FALSE COMMENT='DEFAULT:TRUE' scope=spfile sid='*';	alter system reset "_optimizer_adaptive_plans" scope=spfile sid='*';
30	Optimizer	_optimizer_dsdir_usage_control	"Optimizer가 사용하는 Dynamic Sampling Directives를 제어함
 - Disable: 0
 - Default: 126"	TRUE	0	alter system set "_optimizer_dsdir_usage_control"=0 COMMENT='DEFAULT:TRUE' scope=spfile sid='*';	alter system reset "_optimizer_dsdir_usage_control" scope=spfile sid='*';
31	Optimizer	_optimizer_gather_feedback	Optimizer가 정확한 cardinality를 계산하기 위해 feedback 받는 기능	TRUE	FALSE	alter system set "_optimizer_gather_feedback"=FALSE COMMENT='DEFAULT:TRUE' scope=spfile sid='*';	alter system reset "_optimizer_gather_feedback" scope=spfile sid='*';
32	Optimizer	_optimizer_nlj_hj_adaptive_join	실행되는 동안 초기단계에서 수집된 Nested Loops Join을 Hash Join으로 Plan 변경함	TRUE	FALSE	alter system set "_optimizer_nlj_hj_adaptive_join"=FALSE COMMENT='DEFAULT:TRUE' scope=spfile sid='*';	alter system reset "_optimizer_nlj_hj_adaptive_join" scope=spfile sid='*';
33	Optimizer	_optimizer_use_feedback	"Optimizer가 정확한 cardinality를 계산하지 않을 경우 새로운 실행계획을 수립하는 기능
 - 권고: 갑작스런 plan 변경 및 잘못된 계획수립으로 인해 FALSE 권고함
 - Note: 232243.1, 1344937.1, 1555541.1, 1123304.1"	TRUE	FALSE	alter system set "_optimizer_use_feedback"=FALSE COMMENT='DEFAULT:TRUE' scope=spfile sid='*';	alter system reset "_optimizer_use_feedback" scope=spfile sid='*';
34	Optimizer	_sql_plan_directive_mgmt_control	"Optimizer가 더 나은 Plan을 생성하기 위해 사용하는 SQL Plan Directive를 제어함
 - Disable: 0
 - Default: 3"	TRUE	0	alter system set "_sql_plan_directive_mgmt_control"=0 COMMENT='DEFAULT:TRUE' scope=spfile sid='*';	alter system reset "_sql_plan_directive_mgmt_control" scope=spfile sid='*';
35	Optimizer	optimizer_dynamic_sampling	"사용가능한 통계정보가 부족할 경우 통계를 강화하기 위해 동적으로 통계를 재수집함
 - Disable: 0
 - Default (최소 1개의 테이블의 통계정보가 없는 경우 작동함): 2"	2	0	alter system set optimizer_dynamic_sampling=0 COMMENT='DEFAULT:2' scope=spfile sid='*';	alter system reset optimizer_dynamic_sampling scope=spfile sid='*';
36	RAC	parallel_force_local	"Parallel server process를 모든 node에서 기동할 지 local에서 기동할 지 결정
 - TRUE: local node에서만 기동
 - FALSE: 모든 node에서 기동, instance_groups, parallel_instance_group 설정해야 함"	FALSE	TRUE	alter system set parallel_force_local=TRUE COMMENT='DEFAULT:FALSE' scope=spfile sid='*';	alter system reset parallel_force_local scope=spfile sid='*';
37	RAC	_px_adaptive_dist_method	실행되는 동안 초기단계에서 수집된 PX 분배방식을 변경하여 새로운 Plan을 생성함	TRUE	OFF	alter system set "_px_adaptive_dist_method"=OFF COMMENT='DEFAULT:TRUE' scope=spfile sid='*';	alter system reset "_px_adaptive_dist_method" scope=spfile sid='*';
38	DB Memory	_PX_use_large_pool	"Parallel Query 수행 시 large_pool 사용하도록 설정
 - TRUE 설정으로 ORA-4031 발생 확률 줄임"	FALSE	TRUE	alter system set "_PX_use_large_pool"=TRUE COMMENT='DEFAULT:FALSE' scope=spfile sid='*';	alter system reset "_PX_use_large_pool" scope=spfile sid='*';
39	DBMS, Table & Partition	_partition_large_extents	"Partitioned objects생성시 initial extent size를 지정함
 - TRUE: 8MB 크기부터 생성 시작
 - FALSE: 64KB 크기부터 생성 시작
 - 권고: space 낭비 줄이기 위해 FALSE 권고함
 - 참고: Note 1295484.1"	TRUE	FALSE	alter system set "_partition_large_extents"=FALSE COMMENT='DEFAULT:TRUE' scope=spfile sid='*';	alter system reset "_partition_large_extents" scope=spfile sid='*';
40	DB Memory	pga_aggregate_target	"하나의 인스턴스에서 구동되는 모든 서버 프로세스가 사용하는 PGA 메모리의 합계 크기에 대한 목표치 설정 파라미터
 - Hash, Sort 작업의 성능을 결정하는 값 (optimal, onepass, multipass로 확인)

아래의 히든파라미터가 실질적으로 메모리 사이즈를 제어함
 - _smm_max_size: 하나의 서버 프로세스가 사용 가능한 최대 workarea 크기
 - _smm_px_max_size: 하나의 병렬 실행에 속한 병렬 슬레이브들이 사용 가능한 최대 workarea 크기
 - _pga_max_size: 하나의 서버 프로세스가 사용가능한 최대 PGA 크기"	10MB 또는 SGA 20% 중 큰 값	협의 필요	alter system set pga_aggregate_target=협의 필요 COMMENT='DEFAULT:10MB 또는 SGA 20% 중 큰 값' scope=spfile sid='*';	alter system reset pga_aggregate_target scope=spfile sid='*';
41	DB Memory	pga_aggregate_limit	"Default로 2G 또는 PGA_AGGREGATE_TARGET의 200% 또는 PROCESS * 3MB 이상 설정됨
 - Default 보다 적게 설정하는 것을 권장하지 않음
 - PGA_AGGREGATE_LIMIT 값이 (Physical Memory - SGA)의 90% 보다 크다면 PGA_AGGREGATE_TARGET의 100% 이상 200% 이하로 설정 가능함
 - 0 설정은 no limit을 의미함
 - 참고: Note 1520324.1 216205.1, 396009.1"	2G 또는 PGA_AGGREGATE_TARGET의 200% 또는 PROCESS * 3MB 이상	협의 필요	alter system set pga_aggregate_limit=협의 필요 COMMENT='DEFAULT:2G 또는 PGA_AGGREGATE_TARGET의 200% 또는 PROCESS * 3MB 이상' scope=spfile sid='*';	alter system reset pga_aggregate_limit scope=spfile sid='*';
42	Critical Process	_highest_priority_processes	"Real time scheduler로 수행할 process를 지정함
 - 권고: 기존 VKTM에 LGWR를 추가함 (LGWR이 time sharing 에서 real time scheduler로 변경되어 log file sync등의 성능향상 가능)
 - 참고: _high_priority_processes 에 LGWR를 추가하면 gcr 프로세스가 별도로 GCR*|DIAG|CKPT|DBRM|RMS0 가 추가함으로 인해 추가된 다른 process들의 priority가 변경됨
 - 주의: 19c에서 VKTM 관련 에러 발생하고 있음 (Note 2718971.1)"	VKTM	'VKTM|LMS*|LG*'	alter system set "_highest_priority_processes"='VKTM|LMS*|LG*' COMMENT='DEFAULT:VKTM' scope=spfile sid='*';	alter system reset "_highest_priority_processes" scope=spfile sid='*';
43	Critical Process	resource_manager_plan	"Maintenance window 수행 시 자동으로 설정되는 Resource Manager 기능에 의해 'resmgr:cpu quantum' 대기 이벤트 발생하며 CPU 사용율이 높아짐
 - 권장: FORCE: (Disable)"	DEFAULT_PLAN	'FORCE:'	alter system set resource_manager_plan='FORCE:' COMMENT='DEFAULT:DEFAULT_PLAN' scope=spfile sid='*';	alter system reset resource_manager_plan scope=spfile sid='*';
44	Critical Process	_cleanup_rollback_entries	"Serial transaction rollback시 1회에 수행하는 entry 개수
 - 권고: 보다 빠른 process정리를 위해 큰 값으로 권고함"	100	2000	alter system set "_cleanup_rollback_entries"=2000 COMMENT='DEFAULT:100' scope=spfile sid='*';	alter system reset "_cleanup_rollback_entries" scope=spfile sid='*';
45	DB Memory	sga_target	"ASMM (Automatic Shared Memory Management) 설정을 제어함
 - ASMM Disable: 0
 - ASMM Enable: 0 아닌 값
   - SGA_TARGET 한도내에서 아래의 parameter resize가 빈번하게 발생하므로 0으로 설정 권장, 아래 parameter 경우, 값이 존재하면 min값으로 작동을하고 0이면 min값 없이 자동 관리됨
   - DB_CACHE_SIZE
   - SHARED_POOL_SIZE
   - LARGE_POOL_SIZE
   - JAVA_POOL_SIZE
   - STREAMS_POOL_SIZE
 - 참조: _memory_imm_mode_without_autosga
 - 참고: Note 1269139.1 (SGA Re-Sizes Occurring Despite AMM/ASMM Being Disabled (MEMORY_TARGET/SGA_TARGET=0))"	0	협의 필요	alter system set sga_target=협의 필요 COMMENT='DEFAULT:0' scope=spfile sid='*';	alter system reset sga_target scope=spfile sid='*';
46	DB Memory	sga_max_size	"Instance의 SGA Max size를 지정함
 - MEMORY_TARGET 미사용 시 설정을 권장함
 - MEMORY_TARGET 사용 시 제거를 권장함
   - Note 1431575.1
 - SELECT * FROM V$SGAINFO ORDER BY BYTES DESC ;"	internally adjusted	협의 필요	alter system set sga_max_size=협의 필요 COMMENT='DEFAULT:internally adjusted' scope=spfile sid='*';	alter system reset sga_max_size scope=spfile sid='*';
47	DB Memory	java_pool_size	Java 메소드, 클래스 정의에 사용되는 메모리 크기	0	협의 필요	alter system set java_pool_size=협의 필요 COMMENT='DEFAULT:0' scope=spfile sid='*';	alter system reset java_pool_size scope=spfile sid='*';
48	DB Memory	large_pool_size	"Shared server systems for session memory by PX and by backup (RMAN)
 - PX session 개수에 따라 적절히 설정
 - Bug 13096841"	SGA_TARGET, DBWR_IO_SLAVES, PARALLEL_MAX_SERVERS, PARALLEL_THREADS_PER_CPU, CLUSTER_DATABASE_INSTANCES, DISPATCHES 를 고려한 값	협의 필요	alter system set large_pool_size=협의 필요 COMMENT='DEFAULT:SGA_TARGET, DBWR_IO_SLAVES, PARALLEL_MAX_SERVERS, PARALLEL_THREADS_PER_CPU, CLUSTER_DATABASE_INSTANCES, DISPATCHES 를 고려한 값' scope=spfile sid='*';	alter system reset large_pool_size scope=spfile sid='*';
49	DB Memory	shared_pool_reserved_size	Shared pool의 일정 부분을 large object를 위해 할당하도록 지정하는 파라미터임. 기본적으로 shared pool의 5% 정도를 권장함	SHARED_POOL_SIZE의 5%	협의 필요	alter system set shared_pool_reserved_size=협의 필요 COMMENT='DEFAULT:SHARED_POOL_SIZE의 5%' scope=spfile sid='*';	alter system reset shared_pool_reserved_size scope=spfile sid='*';
50	DB Memory	shared_pool_size	"Shared cursors, stored procedures, 그리고 각종 sql문이 저장됨. Parallel_automatic_tuning 파라미터가 false로 되어 있으면 parallel 수행 시 shared pool을 사용함.
 - dictionary cache, library cache 영역으로 나누어짐
 - Data dictionary cache hit ratio >= 90% 권장
 - 확인쿼리: select round((1-(sum(getmisses)/sum(gets)))*100,2) ""Hit Ratio"" from v$rowcache ;"	0	협의 필요	alter system set shared_pool_size=협의 필요 COMMENT='DEFAULT:0' scope=spfile sid='*';	alter system reset shared_pool_size scope=spfile sid='*';
51	DB Memory	streams_pool_size	"Buffered queue msg.를 저장하고 capture process & apply process 를 위해 memory를 제공
 - SGA_TARGET <> 0 and STREAMS_POOL_SIZE <> 0 이면 ASSM 이 enable 되면서 STREAMS_POOS_SIZE 가 MIN 으로 사용
 - SGA_TARGET = 0   and STREAMS_POOL_SIZE <> 0 이면 ASSM 이 disable 되면서 STREAMS_POOS_SIZE 값 사용
 - SGA_TARGET = 0   and STREAMS_POOL_SIZE = 0 이면 ASSM 이 disable 되면서 10% of SHARED_POOL_SIZE 값 사용"	0	협의 필요	alter system set streams_pool_size=협의 필요 COMMENT='DEFAULT:0' scope=spfile sid='*';	alter system reset streams_pool_size scope=spfile sid='*';
52	DB Memory	log_buffer	"ASMM은 SGA를 동적으로 관리해주지만 Redo Buffer (LOG_BUFFER), Keep Cache, Recycle Cache는 ASMM에 속하지 않으며 수동으로 관리를 해줘야 함.
 - 65536 (bytes) 또는 그 이상의 값 설정 필요
 - LOG_BUFFER = _ksmg_granule_size - SGA's Fixed Size (show sga)"	"512KB 또는
128KB * CPU_COUNT"	협의 필요	"alter system set log_buffer=협의 필요 COMMENT='DEFAULT:512KB 또는
128KB * CPU_COUNT' scope=spfile sid='*';"	alter system reset log_buffer scope=spfile sid='*';
53	DB Memory	db_cache_size	표준 블록의 캐시 크기. SGA를 구성하는 메모리이며 sga_target 값이 0으로 세팅되어 있고 db_cache_size가 0으로 세팅되어 있으면 자동관리가 되므로 sga_target = 0 설정 후 db_cache_size 값 입력 (최소값)으로 수동 관리가 필요함. 서버 메모리의 20% ~ 25% 정도를 권장함	0	협의 필요	alter system set db_cache_size=협의 필요 COMMENT='DEFAULT:0' scope=spfile sid='*';	alter system reset db_cache_size scope=spfile sid='*';
54	DB Memory	_enable_shared_pool_durations	"AMM/ASMM 기능 사용시 shared pool내의 각 subpool이 4개의 duration pool로 분리되어 관리
 - FALSE: ORA-4031 발생 가능성이 높을 시 권장 (subpool x 4(duration pool)로 shared pool이 분리되어 shared pool 부족할 수 있음) 
 - TRUE: AMM/ASMM 기능이 disable 되어 있는 경우는 duration pool이 분리되지 않음으로 TRUE 설정"	TRUE	FALSE	alter system set "_enable_shared_pool_durations"=FALSE COMMENT='DEFAULT:TRUE' scope=spfile sid='*';	alter system reset "_enable_shared_pool_durations" scope=spfile sid='*';
55	DB Memory	_memory_imm_mode_without_autosga	"자동 Memory resize 기능에 대한 설정
 - TRUE: ORA-4031가 문제가 되는 경우 권고함
 - FALSE: memory관련 parameter를 충분히 크게 설정하여 자동조정으로 인한 성능저하 문제시 권고함
 - SGA_TARGET=0, MEMORY_TARGET=0 해도 resize 됨
   - 참고: Note 1269139.1
   - 해결책: ""_memory_imm_mode_without_autosga""=FALSE 설정"	TRUE	FALSE 또는 협의 필요	alter system set "_memory_imm_mode_without_autosga"=FALSE 또는 협의 필요 COMMENT='DEFAULT:TRUE' scope=spfile sid='*';	alter system reset "_memory_imm_mode_without_autosga" scope=spfile sid='*';
56	Etc	_report_capture_cycle_time	"SQL Monitoring Report 수행주기, 초단위 [s]
 - Default: 60s
 - SQL Monitoring Report 수행 실패 시 core dump 발생하므로 0으로 설정하여 disable 시킴
 - 참고: SR 3-11511432101"	60	0	alter system set "_report_capture_cycle_time"=0 COMMENT='DEFAULT:60' scope=spfile sid='*';	alter system reset "_report_capture_cycle_time" scope=spfile sid='*';
57	Undo	temp_undo_enabled	"TRUE 설정 시 Temporary object (Global Temporary Tables or Temporary Table Transformation) 들이 Temporary undo를 사용하도록 지정함
 - Global Temporary Tables 사용하면서 undo 양을 줄이려면 TRUE 설정 그 외는 FALSE
 - TRUE 설정 시 Temp Undo 사용하면서 Permanent undo에 반영되지 않으므로 undo 생성량 감소됨
 - 참고: 1570287.1, 216205.1, 396009.1"	FALSE	FALSE	alter system set temp_undo_enabled=FALSE COMMENT='DEFAULT:FALSE' scope=spfile sid='*';	alter system reset temp_undo_enabled scope=spfile sid='*';
58	Undo	undo_retention	_undo_retention=true인 경우 low value를 의미하며 지정된 값 이상으로 자동 조정됨	900	협의 필요	alter system set undo_retention=협의 필요 COMMENT='DEFAULT:900' scope=spfile sid='*';	alter system reset undo_retention scope=spfile sid='*';
59	Undo	_highthreshold_undoretention	"_undo_autotune=true 지정 시 자동으로 조정되는 Undo Retention의 최대 값을 지정
 - 권고: SQL의 최대 수행시간 고려하여 설정
 - v$undostat.tuned_undoretention 값 참고 (The view contains each 10 mins interval for the last 4 days)"	4294967294	협의 필요	alter system set "_highthreshold_undoretention"=협의 필요 COMMENT='DEFAULT:4294967294' scope=spfile sid='*';	alter system reset "_highthreshold_undoretention" scope=spfile sid='*';
60	Undo	_rollback_segment_count	"지정한 수 만큼 undo를 미리 online 시킴
 - enq: US contention과 적절한 성능을 위해 노드당 1000개 권고함
 - 해당 값 크게 설정 시 배치성능 개선되나 SMON의 Dead TX Recovery 시간이 늘고 Order by, Group by, Latch: row cache object등의 성능저하 발생할 수 있음"	0	1000	alter system set "_rollback_segment_count"=1000 COMMENT='DEFAULT:0' scope=spfile sid='*';	alter system reset "_rollback_segment_count" scope=spfile sid='*';
61	Undo	_smu_debug_mode	"Undo 세그먼트 관리하는 방식을 설정
 - Default: 0
 - 권고: Oracle SR 진행 후 value 설정
 - 참고: SR 3-13349551481"	0	33554432	alter system set "_smu_debug_mode"=33554432 COMMENT='DEFAULT:0' scope=spfile sid='*';	alter system reset "_smu_debug_mode" scope=spfile sid='*';
62	Undo	_undo_autotune	"undo_retention의 자동 조정기능 설정
 - 권고: 아래의 note의 issue들로 인해 FALSE 권고함
 - TRUE 설정 시 ""_highthreshold_undoretention"" 설정 고려해야 함
 - 참고: ORA-1555 (Note 1131474.1)
              unexpired undo remain (Note 1112431.1 등)
 - 참조: _smu_debug_mode undo 파라미터"	TRUE	FALSE 또는 협의 필요	alter system set "_undo_autotune"=FALSE 또는 협의 필요 COMMENT='DEFAULT:TRUE' scope=spfile sid='*';	alter system reset "_undo_autotune" scope=spfile sid='*';
63	DB Memory	use_large_pages	"DB가 Large pages 사용하는 것을 관리함 (for SGA memory)
 - ONLY: Large pages를 사용하지 못한다면 instance가 fail 됨. Huge Pages 사용하는 경우에만 적용
 - OS에서 vm.nr_hegepages 변경 -> DB restart (리스너 포함) -> 파라미터 변경"	TRUE	"ONLY
(Large Page 설정 시)"	"alter system set use_large_pages=ONLY
(Large Page 설정 시) COMMENT='DEFAULT:TRUE' scope=spfile sid='*';"	alter system reset use_large_pages scope=spfile sid='*';
64	DB Memory	lock_sga	"SGA의 Swap out 여부를 결정.
 - True 설정 시 Large Page Size로 할당된 크기만큼 SGA는 Lock 한 것과 같이 사용 가능
 - AIX OS에서 사용하는 파라미터임
 - Linux에서는 use_large_pages 파라미터 사용
 - 설정 명령어: vmo -p -o lgpg_regions=num_of_large_pages -o lgpg_size=16777216
 - 참고: ORA-00847: MEMORY_TARGET/MEMORY_MAX_TARGET and LOCK_SGA cannot be set together
 - 참고: Action: Do not set MEMORY_TARGET or MEMORY_MAX_TARGET if LOCK_SGA is set to TRUE"	FALSE	협의 필요	alter system set lock_sga=협의 필요 COMMENT='DEFAULT:FALSE' scope=spfile sid='*';	alter system reset lock_sga scope=spfile sid='*';
65	Critical Process	processes	DB에 동시 접속할 수 있는 최대 프로세스 수를 의미하며 이는 Foreground, Background, Parallel Execution 프로세스 등 모두 포함하는 수치임	CPU 영향 받음	3000	alter system set processes=3000 COMMENT='DEFAULT:CPU 영향 받음' scope=spfile sid='*';	alter system reset processes scope=spfile sid='*';
66	Undo	_in_memory_undo	"Undo 데이터를 Undo 세그먼트가 아닌 Shared Pool 내(內) 미리 할당된 공간을 사용함
 - 짧은 트랜잭션에 대한 성능향상을 위해 10g 이후 적용된 방법
 - 미리 할당된 private 공간이 다 채워지면 Undo 세그먼트에 일괄 저장함
 - in memory undo latch에 의해 보호됨
 - ""Private strand flush not complete"", ""Checkpoint not complete"" 메세지 발생
   -> 기존 Undo 세그먼트 이용한 방식 권장함"	TRUE	FALSE	alter system set "_in_memory_undo"=FALSE COMMENT='DEFAULT:TRUE' scope=spfile sid='*';	alter system reset "_in_memory_undo" scope=spfile sid='*';
67	DBMS, Table & Partition	db_files	DB에서 생성할 수 있는 파일의 수를 명시함	200	2048	alter system set db_files=2048 COMMENT='DEFAULT:200' scope=spfile sid='*';	alter system reset db_files scope=spfile sid='*';
68	DB Memory	allow_group_access_to_sga	"솔루션 업체의 기능 활성화를 위해 파라미터 변경이 필요함
 - Maxgauge, Sherpa 등 Direct Memory Access (DMA) 솔루션 사용이 없으면 변경을 권장하지 않음"	FALSE	TRUE	alter system set allow_group_access_to_sga=TRUE COMMENT='DEFAULT:FALSE' scope=spfile sid='*';	alter system reset allow_group_access_to_sga scope=spfile sid='*';
69	Etc	_disable_file_resize_logging	_disable_file_resize_logging=FALSE 이며 datafile Autoextensible인 경우 Alert.log에 datafile resize에 대한 로그가 기록됨. 둘 중 하나를 OFF 시키면 비활성화됨. 기능에 대한 오류는 아님.	FALSE	협의 필요	alter system set "_disable_file_resize_logging"=협의 필요 COMMENT='DEFAULT:FALSE' scope=spfile sid='*';	alter system reset "_disable_file_resize_logging" scope=spfile sid='*';
70	Optimizer	optimizer_adaptive_plans	"12cR1 의 optimizer_adaptive_features 파라미터에서 분기한 두 기능 중 하나임.
Adaptive plan에 대한 기능 제어 역할을 하는 것으로 아래 보는 기능들에 대한 제어
   - 1) Adaptive joins (currently controlled by _optimizer_nlj_hj_adaptive_join)
   - 2) Adaptive distribution method (currently controlled by _px_adaptive_dist_method)
   - 3) Adaptive bitmap plans (currently controlled by _optimizer_strans_adaptive_pruning)
 - 권고: 일반적인 경우 제거를 권고하나 해당 기능으로 plan 변경을 막을 경우에는 FALSE 권고함
 - 참고: 해당 기능 중 01:adaptive plan을 disable할 경우엔 optimizer_adaptive_reporting_only 만 수정 할 것
              Note 1409636.1, 1964223.1, Optimizer with Oracle Database 18c (White Paper)"	TRUE	FALSE	alter system set optimizer_adaptive_plans=FALSE COMMENT='DEFAULT:TRUE' scope=spfile sid='*';	alter system reset optimizer_adaptive_plans scope=spfile sid='*';
71	Optimizer	optimizer_adaptive_statistics	"12cR1 의 optimizer_adaptive_features 파라미터에서 분기한 두 기능 중 하나이며 아래 4가지 기능에 대한 제어임
   - 1) Usage of SQL plan directives (currently controlled by _optimizer_dsdir_usage_control)
   - 2) Cardinality feedback for joins (currently controlled by _optimizer_use_feedback_for_join)
   - 3) Performance feedback (currently controlled by _optimizer_performance_feedback)
   - 4) ADS for Parallel Query (currently controlled by _optimizer_ads_for_pq)
 - 참고: Optimizer with Oracle Database 18c (White Paper)"	FALSE	FALSE	alter system set optimizer_adaptive_statistics=FALSE COMMENT='DEFAULT:FALSE' scope=spfile sid='*';	alter system reset optimizer_adaptive_statistics scope=spfile sid='*';
72	Optimizer	_optimizer_adaptive_cursor_sharing	Bind 변수에 따라 cardinality의 변동이 대량으로 발생하는 경우 cursor sharing 사용 여부를 제어함	TRUE	FALSE	alter system set "_optimizer_adaptive_cursor_sharing"=FALSE COMMENT='DEFAULT:TRUE' scope=spfile sid='*';	alter system reset "_optimizer_adaptive_cursor_sharing" scope=spfile sid='*';
73	Optimizer	_optimizer_connect_by_cost_based	"Connect by절 사용에 의한 Query transform 적용 여부를 제어함
 - 권고: Wrong result, ORA-3002에러 발생으로 인해 FALSE 권고함
 - 주의: 설정 시 성능에 큰 영향 발생함으로 협의 필요"	TRUE	FALSE	alter system set "_optimizer_connect_by_cost_based"=FALSE COMMENT='DEFAULT:TRUE' scope=spfile sid='*';	alter system reset "_optimizer_connect_by_cost_based" scope=spfile sid='*';
74	Optimizer	_optimizer_extended_cursor_sharing	"Extended Cursor Sharing 기능 중 user defined bind operator 레벨에서의 cursor sharing 사용을 제어함
 - 권고: 대부분 이슈는 fixed이나 협의 필요함. 기능을 사용하지 않으려면 NONE 권고함
 - 참고: 19392364.8 (12.2.0.1 fix), 1949350.1"	UDO	NONE	alter system set "_optimizer_extended_cursor_sharing"=NONE COMMENT='DEFAULT:UDO' scope=spfile sid='*';	alter system reset "_optimizer_extended_cursor_sharing" scope=spfile sid='*';
75	Optimizer	_optimizer_extended_cursor_sharing_rel	"Extended Cursor Sharing 기능 중 relational operator 레벨에서의 cursor sharing 사용 여부를 결정함
 - relational operator 예시: = < > <= >= != , LIKE
 - 권고: 대부분 이슈는 fixed이나 협의 필요함. 기능을 사용하지 않으려면 NONE 권고함"	SIMPLE	NONE	alter system set "_optimizer_extended_cursor_sharing_rel"=NONE COMMENT='DEFAULT:SIMPLE' scope=spfile sid='*';	alter system reset "_optimizer_extended_cursor_sharing_rel" scope=spfile sid='*';
76	Optimizer	optimizer_secure_view_merging	"Optimizer secure view merging ,, Predicate pushdown/movearound 를 제어함
 - Query Transform 관련 security check를  수행하면서 object owner가 아닌 경우, 실행 계획이 다르게 생성 될 수 있음"	TRUE	FALSE	alter system set optimizer_secure_view_merging=FALSE COMMENT='DEFAULT:TRUE' scope=spfile sid='*';	alter system reset optimizer_secure_view_merging scope=spfile sid='*';
77	Diag & Dump	_disable_system_state	"사용자가 명시적으로 호출한 system state dump 또는 Oracle Code에서 자동으로 발행되는 system state dump level을 낮춤. Default 설정인 system state dump의 level 267로 인한 latch: gc element 경합, gc wait 대량 발생을 예방하고 Disk I/O 지연에 따른 성능 장애를 예방하기 위함
 - 권고: level 11 이상으로 dump 요청 시 설정된 level 10 이하로 낮추어 dump 수행하도록 권고함"	Number	10	alter system set "_disable_system_state"=10 COMMENT='DEFAULT:Number' scope=spfile sid='*';	alter system reset "_disable_system_state" scope=spfile sid='*';
78	Diag & Dump	_kks_obsolete_dump_threshold	"Parent cursor obsolete시 diag dump 생성을 제어하는 파라미터
 - 권고 : 0으로 설정하여 dump 기능 disable 권고함
 - 참고 : 1) Default 1: 매번 parent cursor obsoletion이 발생할 때마다 dumping
               2) 이외의 값 n으로 설정하면 n번 obsoletion발생하면 dumping"	1	0	alter system set "_kks_obsolete_dump_threshold"=0 COMMENT='DEFAULT:1' scope=spfile sid='*';	alter system reset "_kks_obsolete_dump_threshold" scope=spfile sid='*';
79	Diag & Dump	_nonfatalprocess_redo_dump_time_limit	"Non fatal process, 즉 user process들에 의한 diagnostic redo dump 수행에 대한 시간 제어함
 - 권고: Default : 1 (hour)은 1시간 이상 redo dump가 수행되면 해당 수행을 정지하도록 동작하며, 해당 동작 정지를 위해 0 권고함
 - 참고: allowable numeric range (0..12hrs)
              12cR2이전까지의 10555 event의 두 가지 역할 중 하나로, Non fatal process의 redo dump 기능 제어함"	1	0	alter system set "_nonfatalprocess_redo_dump_time_limit"=0 COMMENT='DEFAULT:1' scope=spfile sid='*';	alter system reset "_nonfatalprocess_redo_dump_time_limit" scope=spfile sid='*';
80	RAC	_gc_bypass_readers	"11g 신기능인 Bypass reader 기능 사용 여부 제어함
 - Read/Write concurrency가 많은 application의 성능 개선을 위한 새로운 cache fusion mechanism
 - 다른 instance에서 읽고 있는 블록에 대한 쓰기 액세스 요청 시 발생하는 wait 제거 
 - 해당 Block에 대해 다른 Session들이 갖고 있는 S(shared) Lock을 Null로 Convert 하기 위한 wait 제거
 - 권고: Parallel DML 수행 시 deadlock이 발생하며 checkpoint 불가 및 instance hang 유발 그리고 ORA-600 등의 bug 이슈로 disable 권고"	TRUE	FALSE	alter system set "_gc_bypass_readers"=FALSE COMMENT='DEFAULT:TRUE' scope=spfile sid='*';	alter system reset "_gc_bypass_readers" scope=spfile sid='*';
81	Security	audit_trail	"권한, 문장 등에 대한 audit 설정을 나타냄 (11gR1부터 DBCA를 이용해서 DB를 생성하게 되면서 기본적으로 audit_trail=DB 설정)
 - 권고: System TBS의 aud$에 누적되어 공간 부족 발생으로 None 설정 권고"	DB	NONE	alter system set audit_trail=NONE COMMENT='DEFAULT:DB' scope=spfile sid='*';	alter system reset audit_trail scope=spfile sid='*';
82	ADO	_drop_stat_segment	"Heatmap 기능의 정책을 관리하는ADO ( Adaptive Data Optimization)을 비활성화 하여도 SYSAUX 테이블스페이스가 증가하는 현상을 제어함
 - 권고: ADO가 비활성화되어 동작하지 않아야 함(default)에도 기능 동작하여, SYSAUX TBS 사이즈 지속적인 증가 등 side effet 발생할수 있어 heat map drop 을 위한 값 1 설정을 권고함"	0	1	alter system set "_drop_stat_segment"=1 COMMENT='DEFAULT:0' scope=spfile sid='*';	alter system reset "_drop_stat_segment" scope=spfile sid='*';
83	Security	_trace_files_public	"Trace 파일들에 대한 other group의 user read 여부 설정함
 - 참고 : Oracle 외에 다른 user가 trace file access할 필요가 있는 경우 설정 권고함"	FALSE	TRUE	alter system set "_trace_files_public"=TRUE COMMENT='DEFAULT:FALSE' scope=spfile sid='*';	alter system reset "_trace_files_public" scope=spfile sid='*';
84	Critical Process	_cursor_obsolete_threshold	"Cursor reload failure 발생 시 retry 제어 횟수를 의미함
권고 : 과도한 재시도를 막기 위해 12cR1의 설정값을 권고함"	"12cR1: 1024
12cR2 이후: 8192"	1024	"alter system set ""_cursor_obsolete_threshold""=1024 COMMENT='DEFAULT:12cR1: 1024
12cR2 이후: 8192' scope=spfile sid='*';"	alter system reset "_cursor_obsolete_threshold" scope=spfile sid='*';
85	Critical Process	job_queue_processes	"Job 수행 (DBMS_JOB and Oracle Scheduler) 시  생성되는 최대 Process 개수
 - 권고 : 과도한 Job queue process 실행을 예방하기 위해 적정한 값에 대해 협의 후 설정을 권고함"	"12cR1: 1000
12cR2 이후: 4000"	협의 필요 (100)	"alter system set job_queue_processes=협의 필요 (100) COMMENT='DEFAULT:12cR1: 1000
12cR2 이후: 4000' scope=spfile sid='*';"	alter system reset job_queue_processes scope=spfile sid='*';
86	Performance	parallel_max_servers	"Instance에서 사용할 수 있는 maximum parallel query slave 수를 의미함. Maximum 개수가 이미 사용 중이라면 이후 새로 유입되는 parallel query는 serial로 처리됨
 - 계산식: CPU_COUNT * parallel_threads_per_cpu * _parallel_adaptive_max_users * 5         
 - 권고 : Parallel Query 자원에 대한 수동 관리 (제어)를 위해 협의 후 설정을 권고함"	CPU_COUNT * PARALLEL_THREADS_PER_CPU * _PARALLEL_ADAPTIVE_MAX_USERS * 5	협의 필요 (200)	alter system set parallel_max_servers=협의 필요 (200) COMMENT='DEFAULT:CPU_COUNT * PARALLEL_THREADS_PER_CPU * _PARALLEL_ADAPTIVE_MAX_USERS * 5' scope=spfile sid='*';	alter system reset parallel_max_servers scope=spfile sid='*';
87	Performance	parallel_min_servers	"Instance에서 사용할 수 있는 minimum parallel query slave 수를 의미함. 5분 동안 사용되지 않으면 process는 종료되고, parallel_min_servers 개수만큼만 살아있음
 - 계산식: CPU_COUNT * parallel_threads_per_cpu * 2
 - 권고 : Parallel Query 자원에 대한 수동 관리 (제어)를 위해 협의 후 설정을 권고함"	CPU_COUNT * PARALLEL_THREADS_PER_CPU * 2	협의 필요 (1)	alter system set parallel_min_servers=협의 필요 (1) COMMENT='DEFAULT:CPU_COUNT * PARALLEL_THREADS_PER_CPU * 2' scope=spfile sid='*';	alter system reset parallel_min_servers scope=spfile sid='*';
88	Performance	parallel_servers_target	PARALLEL_DEGREE_POLICY = AUTO 인 경우에만 적용됨. 설정값 이상의 경우 Parallel process가 Queue에 대기하게 됨	CPU_COUNT * PARALLEL_THREADS_PER_CPU * concurrent_parallel_users * 2	AUTO 경우, 협의 필요 (200)	alter system set parallel_servers_target=AUTO 경우, 협의 필요 (200) COMMENT='DEFAULT:CPU_COUNT * PARALLEL_THREADS_PER_CPU * concurrent_parallel_users * 2' scope=spfile sid='*';	alter system reset parallel_servers_target scope=spfile sid='*';
89	Critical Process	_dlm_stats_collect	"DLM (Distributed Lock Manager) 통계정보를 수집하여 DRM (Dynamic Resource Mastering) 수행 시 사용하는 기능을 제어함
 - 권고 : 이 Process가 CPU를 과도하게 사용하는 이슈 예방을 위해 설정을 권고함"	1	0	alter system set "_dlm_stats_collect"=0 COMMENT='DEFAULT:1' scope=spfile sid='*';	alter system reset "_dlm_stats_collect" scope=spfile sid='*';
90	Optimizer	_rowsets_enabled	"특정 SQL operation에 대해 row source를 batch로 처리하는 기능
 - 권고: Wrong result로 인해 FALSE 권고함
 - 참고: Note 2079913.1"	TRUE	FALSE	alter system set "_rowsets_enabled"=FALSE COMMENT='DEFAULT:TRUE' scope=spfile sid='*';	alter system reset "_rowsets_enabled" scope=spfile sid='*';
91	Etc	db_cache_advice	"V$DB_CACHE_ADVICE를 이용해서 CACHE SIZE의 현황 예측을 위해 statistic 수집 여부를 의미함
 - 권고 : 필요한 경우에만 사용하도록 권고"	ON	OFF	alter system set db_cache_advice=OFF COMMENT='DEFAULT:ON' scope=spfile sid='*';	alter system reset db_cache_advice scope=spfile sid='*';
92	Optimizer	_optimizer_band_join_aware	"12cR2 부터 Band join (sort merge join 기능개선) 기능이 추가
 - 권고: Wrong result로 인해 FALSE 권고함"	TRUE	FALSE	alter system set "_optimizer_band_join_aware"=FALSE COMMENT='DEFAULT:TRUE' scope=spfile sid='*';	alter system reset "_optimizer_band_join_aware" scope=spfile sid='*';
93	Optimizer	_optimizer_batch_table_access_by_rowid	"몇 개의 ROWID를 검색한 다음 블록 순서로 행에 엑세스하려고 시도하여 클러스터링을 향상시키고 데이터베이스가 블록에 엑세스해야하는 횟수를 줄임
 - 권고 : 행을 저장하는 블록의 상황에 따라 결과의 정렬이 인덱스 컬럼의 정렬을 따르지 않기 때문에 FALSE를 권고함"	TRUE	FALSE	alter system set "_optimizer_batch_table_access_by_rowid"=FALSE COMMENT='DEFAULT:TRUE' scope=spfile sid='*';	alter system reset "_optimizer_batch_table_access_by_rowid" scope=spfile sid='*';
