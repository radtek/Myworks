Nested Loop, Sort-Merge, Hash Join 조인연산
http://needjarvis.tistory.com/162

Nested Loop Join

가. Nested Loop의 개념
- 2개 이상의 테이블에서 하나의 집합을 기준으로 순차적으로 상대방 Row를 결합하여 원하는 결과를 조합하는 방식
- 먼저 선행 테이블의 처리 범위를 하나씩 액세스하면서 추출된 값으로 연결할 테이블을 조인한다

쉽게 생각해서는 아래와 같은 C, JAVA 코드의 원리와 동일하다.
< C, JAVA >
 for(i=0; i<100; i++) { -- outer loop 
   for(j=0; j<100; j++) { -- inner loop 
   // Do Anything ... 
   } 
}

나. Nested Loop의 특징
- 좁은 범위에 유리한 성능을 보여줌
- 순차적으로 처리하며, Random Access 위주
- 후행 테이블(Driven)에는 조인을 위한 인덱스 생성 필요
- 실행속도 = 선행 테이블 사이즈 * 후행 테이블 접근횟수


다. 사용법 예제 및 PLAN
SQL> explain plan for
  2  SELECT /*+ ordered use_nl(e)*/*
  3  FROM   dept d, emp e
  4  WHERE  d.deptno = e.deptno;

해석되었습니다.

SQL> SELECT * FROM table(dbms_xplan.display);

PLAN_TABLE_OUTPUT
--------------------------------------------------------------------------------
Plan hash value: 4192419542

---------------------------------------------------------------------------
| Id  | Operation          | Name | Rows  | Bytes | Cost (%CPU)| Time     |
---------------------------------------------------------------------------
|   0 | SELECT STATEMENT   |      |    14 |   798 |     9   (0)| 00:00:01 |
|   1 |  NESTED LOOPS      |      |    14 |   798 |     9   (0)| 00:00:01 |
|   2 |   TABLE ACCESS FULL| DEPT |     4 |    80 |     3   (0)| 00:00:01 | => Outer/Driving
|*  3 |   TABLE ACCESS FULL| EMP  |     4 |   148 |     2   (0)| 00:00:01 | => Inner/Driven
---------------------------------------------------------------------------

라. Nested Loop 사용 시 주의사항

•데이터를 랜덤으로 액세스하기 때문에 결과 집합이 많으면 느려짐
•Join index가 없거나, 조인 집합을 구성하는 검색조건이 조인 범위를 줄여주지 못할 경우 비효율적
•테이블 중 Row수가 적은 쪽을 Driven 테이블로 설정
   




Sort Merge Join

가. Sort Merge Join의 개념
- 조인의 대상범위가 넓을 경우 발생하는 Random Access를 줄이기 위한 경우나 연결고리에 마땅한 인덱스가 존재하지 않을 경우 해결하기 위한 조인 방안
- 양쪽 테이블의 처리범위를 각자 Access하여 정렬한 결과를 차례로 Scan하면서 연결고리의 조건으로 Merge하는 방식


나. Sort Merge Join의 특징
- 연결을 위해 랜덤 액세스를 하지 않고 스캔을 하면서 수행
- Nested Loop Join처럼 선행집합 개념이 없음
- 정렬을 위한 영역(Sort Area Size)에 따라 효율에 큰 차이 발생
- 조인 연산자가 '='이 아닌 경우 nested loop 조인보다 유리한 경우가 많음


다. 사용법 예제 및 PLAN
SQL> explain plan for
  2  SELECT /*+ ordered full(d) use_merge(e)*/ *
  3  FROM   dept d, emp e
  4  WHERE  d.deptno = e.deptno;

해석되었습니다.

SQL> SELECT * FROM table(dbms_xplan.display);

PLAN_TABLE_OUTPUT
--------------------------------------------------------------------------------
Plan hash value: 1407029907

----------------------------------------------------------------------------
| Id  | Operation           | Name | Rows  | Bytes | Cost (%CPU)| Time     |
----------------------------------------------------------------------------
|   0 | SELECT STATEMENT    |      |    14 |   798 |     8  (25)| 00:00:01 |
|   1 |  MERGE JOIN         |      |    14 |   798 |     8  (25)| 00:00:01 |
|   2 |   SORT JOIN         |      |     4 |    80 |     4  (25)| 00:00:01 |
|   3 |    TABLE ACCESS FULL| DEPT |     4 |    80 |     3   (0)| 00:00:01 | => Outer/First
|*  4 |   SORT JOIN         |      |    14 |   518 |     4  (25)| 00:00:01 |
|   5 |    TABLE ACCESS FULL| EMP  |    14 |   518 |     3   (0)| 00:00:01 | => Inner/Second


라. Sort Merge 사용 시 주의사항
•두 결과집합의 크기가 차이가 많이 나는 경우에는 비효율적
•Sorting 메모리에 위치하는 대상은 join key뿐만 아니라 Select list도 포함되므로 불필요한 select 항목 제거




Hash Join

가. Hash Join의 개념
- 해싱 함수(Hashing Function) 기법을 활용하여 조인을 수행하는 방식(해싱 함수는 직접적인 연결을 담당하는 것이 아니라 연결될 대상을 특정 지역(partition)에 모아두는 역할만을 담당
- 해시값을 이용하여 테이블을 조인하는 방식
- Sort-Merge 조인은 소트의 부하가 많이 발생하여, 이를 보완하기 위한 방법으로 Sort 대신 해쉬값을 이용하는 조인


나. Hash Join의 특징
- 대용량 처리의 선결조건인 랜덤 액세스와 정렬에 대한 부담을 해결할 수 있는 대안
- parallel processing을 이용한 hash 조인은 대용량 데이터를 처리하기 위한 최적의 솔루션
- 2개의 조인 테이블 중 small rowset을 가지고 hash_area_size에 지정된 메모리 내에서 hash table 생성
- CBO에서만 가능하며, CPU 성능에 의존적
- Hash table 생성 후 Nested Loop처럼 순차적인 처리 형태로 수행



다. 사용법 예제 및 PLAN
SQL> explain plan for
  2  SELECT /*+ ordered use_hash(e)*/*
  3  FROM   dept d, emp e
  4  WHERE  d.deptno = e.deptno;

해석되었습니다.

SQL> SELECT * FROM table(dbms_xplan.display);

PLAN_TABLE_OUTPUT
--------------------------------------------------------------------------------
Plan hash value: 615168685

---------------------------------------------------------------------------
| Id  | Operation          | Name | Rows  | Bytes | Cost (%CPU)| Time     |
---------------------------------------------------------------------------
|   0 | SELECT STATEMENT   |      |    14 |   798 |     7  (15)| 00:00:01 |
|*  1 |  HASH JOIN         |      |    14 |   798 |     7  (15)| 00:00:01 |
|   2 |   TABLE ACCESS FULL| DEPT |     4 |    80 |     3   (0)| 00:00:01 | => Outer/Build Input
|   3 |   TABLE ACCESS FULL| EMP  |    14 |   518 |     3   (0)| 00:00:01 | => Inner/Probe Input
---------------------------------------------------------------------------

라. Hash Join 사용 시 주의사항
•대용량 데이터 처리에서는 상당히 큰 hash area를 필요로 함으로, 메모리의 지나친 사용으로 오버헤드 발생 가능성
•연결조건 연산자가 ‘=’인 동치조인인 경우에만 가능




참고자료

http://wiki.gurubee.net/pages/viewpage.action?pageId=26743004
DBGuide.net - SQL 가이드

출처: http://needjarvis.tistory.com/162 [자비스가 필요해]