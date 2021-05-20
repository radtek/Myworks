6.3 인덱스 파티셔닝

6.3.1 인덱스 파티션 유형

- 파티션 여부에 따라 비파티션 인덱스와 파티션 인덱스로 나뉘고, 파티션 인덱스는 각 인덱스 파티션이 담당하는 

    테이블 파티션 범위에 따라 글로벌과 로컬로 나뉜다.
  - 비파티션 인덱스(Non-Partitioned Index)
  - 글로벌 파티션 인덱스(Global Partitioned Index)
  - 로컬 파티션 인덱스(Local Partitioned Index)
  - 로컬 파티션 인덱스는 각 테이블 파티션과 인덱스 파티션이 서로 1:1대응 관계가 되도록 


    오라클이 자동 관리하는 파티션 인덱스
  - 로컬이 아닌 파티션 인덱스는 모두 글로벌 파티션 인덱스에 속하며, 테이블 파티션과 독립적인 구성

    (파티션 키, 파티션 기준값)을 갖는다.


글로벌 인덱스 = 비파티션 인덱스 + 글로벌 파티션 인덱스
  
- 비파티션 테이블은 비파티션 인덱스와 글로벌 파티션 인덱스를 가질 수 있다.
- 파티션 테이블은 비파티션, 글로벌, 로컬 파티션 인덱스를 가질 수 있다.
※참고 : 비파티션 테이블에 대한 비트맵 인덱스는 파티셔닝이 허용되지 않고, 
       파티션  테이블에 대한 비트맵 인덱스는 로컬 파티셔닝만 허용된다.

6.3.2 로컬 파티션 인덱스
- 각 인덱스 파티션이 테이블 파티션과 1:1대응관계를 가지며, 테이블 파티션 속성을 그대로 상속 받는다.
- 파티션 키를 사용자가 따로 정의하지 않아도 오라클이 자동 관리
- 항상 테이블 파티션과 1:1관계를 형성하므로 만약 테이블이 결합 파티셔닝 되어 있다면 

  인덱스도 같은 단위로 파티셔닝된다.
- 관리적 편의성 : 테이블 파티션 구성에 변경(drop, exchange, split 등)이 생기더라도 인덱스를 재생성할 필요가 없어 관리비용이 아주 적다.


6.3.3 비파티션 인덱스
- 파시셔닝 하지않은 인덱스
- 1:M 관계 즉, 하나의 인덱스 세그먼트가 여러 테이블 파티션 세그먼트와 관계를 갖는다. 


6.3.4 글로벌 파티션 인덱스
- 테이블 파티션과 독립적인 구성을 갖도록 파티셔닝 하는것.(테이블은 파티셔닝 되어있지 않을 수도 있다.)
- 몇몇 제약 사항으로 오히려 효용성이 낮은편
- 기준 테이블의 파티션 구성에 변경이 생길 때마다 인데스가 unuasble 상태로 바뀌고 그때마다 인덱스를 재생성해야 한다.
  (비파티션 인덱스 일때도 동일)

- 9i부터 update global indexes 옵션을 주면 파티션 DDL작업에 의해 영향받는 인덱스 레코드를 자동으로 갱신해 주므로 
  인덱스가 unuasble 상태로 빠지지않는다.

alter table ... split partition ... update global indexes;


- 파티션 DDL로 인해 영향 받는 레코드가 전체의 5% 미만일 때만 유용  (항상은 아니고 평균적으로)
  5% 이상일 경우 재생성

6.3.4.1 테이블 파티션과의 관계
- 인덱스를 테이블 파티션과 같은 키 컬럼으로 글로벌 파티셔닝 한다면 파티션 기분 값에 따라 

  1:M, M:1, M:M 관계가 가능하다. 즉, 하나의 인덱스 파티션이 여러 테이블 파티션과 관계를 갖고, 
  반대로 하나의 테이블 파티션이 여러 인덱스 파티션 관계를 갖는다.
- 인덱스를 테이블 파티션과 다른 키 컬럼으로 글로벌 파티셔닝(ex> 테이블 - 주문일자 인덱스 - 배송일자) 할 수도 있는데 
  이때는 테이블 파티션과 인딕스 파티션간에는 항상 M:M 관계가 형성

6.3.4.2 글로벌 해시 파티션 인덱스
- 9i전까지는 글로벌 Range 파티션만 가능 10g부터 글로벌 해시 파티션도 가능해졌고 즉, 테이블과 독립적으로 
  인덱스만 해시 키 값에 따라 파티셔닝할 수있게 되었다.
  
※참고 : Right Growing 인덱스 : 일련번호 나 입력일시 처럼 순차적으로 증가하는 컬럼에 생성한 인덱스는 
        항상 맨 우측블록으로만 값이 이렵되는데 이러한 특직을 갖는 인덱스
- Right Growing 인덱스 처럼 Hot 블록이 발생하는 인덱스의 경합을 분산할 목적으로 주로 사용된다.
- 글로벌 결합(Composite) 인덱스 파티셔닝은 여전히 불가능


6.3.5 Prefixed vs. Nonprefixed
-  인덱스 파티션 키 컬럼이 인덱스 구성상 왼쪽 선두 컬럼에 위치하는지에 따른 구분

Prefixed    : 파티션 인덱스를 생성할 때 피타션 키 컬럼을 인덱스 키 컬럼 왼쪽 선두에 두는것.
Nonprefixed : 파티션 인덱스를 생성할 때 피타션 키 컬럼을 인덱스 키 컬럼 왼쪽 선두에 두지 않는것.
              파티션 키가 인덱스 컬럼에 아예 속하지 않을때도 여기에 속한다.
              
- 글로벌 파티션 인덱스는 Prefixed 파티션만 지원되므로 결과적으로 세개의 파티션 인덱스가 있고 비파티션 인덱스를 포함한다.


비파티션 인덱스
글로벌 Prefixed    파티션 인덱스
로컬   Prefixed    파티션 인덱스
로컬   Nonprefixed 파티션 인덱스


6.3.6 파티션 인덱스 구성 예시

6.3.6.1 인덱스 파티셔닝 예제


-- 테이블을 생성하면서 SEQ 컬럼 기준으로 RANGE 파티셔닝 했다.
CREATE TABLE T ( 
   GUBUN
   , SEQ, SEQ_NAME, SEQ_CLS
   , SEQ2, SEQ2_NAME, SEQ2_CLS
)
PARTITION BY RANGE(SEQ) (
  PARTITION P1 VALUES LESS THAN(100)
, PARTITION P2 VALUES LESS THAN(200)
, PARTITION P3 VALUES LESS THAN(300)
, PARTITION P4 VALUES LESS THAN(MAXVALUE)
)
AS
SELECT 1
     , ROWNUM, DBMS_RANDOM.STRING('U', 10), 'A'
     , ROWNUM, DBMS_RANDOM.STRING('L', 10), 'B'
FROM   DUAL
CONNECT BY LEVEL <= 400;


-- 테이블에 로컬 파티션 인덱스를 생성한다.(실패)
CREATE UNIQUE INDEX T_IDX1 ON T(GUBUN, SEQ2) LOCAL;
-- ORA-14039: partitioning columns must form a subset of key columns of a UNIQUE index
-- UNIQUE 파티션 인덱스를 만들 때는 파티션 키 컬럼이 인덱스 컬럼에 포함 되어있어야 하기 때문이다.
   테이블 파티션 키 컬럼을 상속받아 SEQ가 파티션 키 컬럼인데 이 컬럼이 인덱스 컬럼에 포함 되어 있지 않아 에러 발생

-- 테이블에 비파티션 인덱스를 생성한다.(성공)
CREATE UNIQUE INDEX T_IDX1 ON T(GUBUN, SEQ2);
-- 테이블 파티션 키 컬럼을 상속받아 파티션 키 컬럼을 포함해야 되는 제약이 없으므로 UNIQUE 인덱스가 생성된다.


-- 테이블에 로컬 파티션 인덱스를 생성한다.(성공)
CREATE UNIQUE INDEX T_IDX2 ON T(GUBUN, SEQ) LOCAL;
-- 파티션 키 컬럼을 인덱스 컬럼에 포함시 에러없이 성공

-- 로컬 Prefixed    파티션 인덱스 예시 : 파티션 키 컬럼이 선두(O)
CREATE INDEX T_IDX3 ON T(SEQ, GUBUN) LOCAL;

-- 로컬 Nonprefixed 파티션 인덱스 예시 : 파티션 키 컬럼이 선두(X) 앞서 만든 T_IDX2 와 동일
CREATE INDEX T_IDX4 ON T(SEQ_NAME, SEQ) LOCAL;

-- 로컬 파티션 인덱스 에선 Nonprefixed 가 허용되지만 글로벌 파티션 인덱스에는 허용되지 않는다.
CREATE INDEX T_IDX5 ON T(SEQ_CLS, SEQ) GLOBAL
PARTITION BY RANGE(SEQ) (
  PARTITION P1 VALUES LESS THAN(100)
, PARTITION P2 VALUES LESS THAN(200)
, PARTITION P3 VALUES LESS THAN(300)
, PARTITION P4 VALUES LESS THAN(MAXVALUE)
)
-- ORA-14038: GLOBAL partitioned index must be prefixed
-- 비파티션 인덱스에는 이런 제약이 없다.

-- 파티션 키 컬럼 선두에 놓고 글로벌 Prefixed 파티션 인덱스 생성
CREATE INDEX T_IDX5 ON T(SEQ, SEQ_CLS) GLOBAL
PARTITION BY RANGE(SEQ) (
  PARTITION P1 VALUES LESS THAN(100)
, PARTITION P2 VALUES LESS THAN(200)
, PARTITION P3 VALUES LESS THAN(300)
, PARTITION P4 VALUES LESS THAN(MAXVALUE)
) ;
-- 테이블 파티션과 100% 같게 정의 하더라도 이를 '로컬파티션 인덱스'라고 부르지 않는다.

-- 파티션 키 컬럼이 테이블 파티션과 같지만 키 값 구간 정의가 다르므로 당연히 글로벌 파티션 인덱스이다.
-- 키 값 정의에 따라 각 인덱스 파티션이 두개 테이블 파티션과 매핑된다.
/*
CREATE TABLE T ( 
   GUBUN
   , SEQ, SEQ_NAME, SEQ_CLS
   , SEQ2, SEQ2_NAME, SEQ2_CLS
)
PARTITION BY RANGE(SEQ) (
  PARTITION P1 VALUES LESS THAN(100)       -- A 테이블 파티션
, PARTITION P2 VALUES LESS THAN(200)       -- B 테이블 파티션
, PARTITION P3 VALUES LESS THAN(300)       -- C 테이블 파티션
, PARTITION P4 VALUES LESS THAN(MAXVALUE)  -- D 테이블 파티션
);
*/

CREATE INDEX T_IDX6 ON T(SEQ, SEQ_NAME) GLOBAL
PARTITION BY RANGE(SEQ) (
  PARTITION P1 VALUES LESS THAN(200)          -- A, B
, PARTITION P2 VALUES LESS THAN(MAXVALUE)     -- C, D
);

-- 또다른 글로벌 파티션 인덱스 생성 패턴
-- 키 값 정의에 따라 두개의 인덱스 파티션이 한개 테이블 파티션과 매핑된다.
CREATE INDEX T_IDX7 ON T(SEQ, SEQ_NAME, SEQ_CLS) GLOBAL
PARTITION BY RANGE(SEQ) (
  PARTITION P1 VALUES LESS THAN(50)            -- A
, PARTITION P2 VALUES LESS THAN(100)           -- A
, PARTITION P3 VALUES LESS THAN(150)           -- B
, PARTITION P4 VALUES LESS THAN(200)           -- B
, PARTITION P5 VALUES LESS THAN(250)           -- C
, PARTITION P6 VALUES LESS THAN(300)           -- C
, PARTITION P7 VALUES LESS THAN(350)           -- D
, PARTITION P8 VALUES LESS THAN(MAXVALUE)      -- D
);

- T_IDX6(1:M) 와 T_IDX7(M:1) 처럼 테이블파티션과의 관계에 따라 파티션키를 정의 할 수는 있지만 
  궁극적으로 M:M 관계로 이해해야한다.

- 테이블과 다른 컬럼으로 파티셔닝 할 때는 항상 M:M 관계 형성
CREATE INDEX T_IDX8 ON T(SEQ2) GLOBAL
PARTITION BY RANGE(SEQ2) (
  PARTITION P1 VALUES LESS THAN(100)
, PARTITION P2 VALUES LESS THAN(200)
, PARTITION P3 VALUES LESS THAN(300)
, PARTITION P4 VALUES LESS THAN(MAXVALUE)
);

-- 지금까지 테이블 T에 대한 8개의 파티션 인덱스에 대한 딕셔너리 정보

SELECT I.INDEX_NAME, I.UNIQUENESS, P.LOCALITY
       , P.ALIGNMENT, I.PARTITIONED, P.PARTITION_COUNT
FROM   USER_INDEXES I, USER_PART_INDEXES P
WHERE  I.TABLE_NAME = 'T'
AND    P.TABLE_NAME(+) = I.TABLE_NAME
AND    P.INDEX_NAME(+) = I.INDEX_NAME
ORDER BY 1;

INDEX_NAME    UNIQUENESS    LOCALITY    ALIGNMENT    PARTITIONED    PARTITION_COUNT
T_IDX1        UNIQUE                                 NO    
T_IDX2        UNIQUE        LOCAL       NON_PREFIXED YES            4
T_IDX3        NONUNIQUE     LOCAL       PREFIXED     YES            4
T_IDX4        NONUNIQUE     LOCAL       NON_PREFIXED YES            4
T_IDX5        NONUNIQUE     GLOBAL      PREFIXED     YES            4
T_IDX6        NONUNIQUE     GLOBAL      PREFIXED     YES            2
T_IDX7        NONUNIQUE     GLOBAL      PREFIXED     YES            8
T_IDX8        NONUNIQUE     GLOBAL      PREFIXED     YES            4

-- T_IDX1 : UNIQUE    비파티션 인덱스
-- T_IDX2 : UNIQUE    로컬 Nonprefixed 파티션 인덱스
-- T_IDX3 : UNIQUE    로컬 Prefixed    파티션 인덱스
-- T_IDX4 : Nonunique 로컬 Nonprefixed 파티션 인덱스
-- T_IDX5 ~ T_IDX8 : Nonunique 로컬 Prefixed 파티션 인덱스


6.3.7 글로벌 파티션 인덱스의 효용성
- 경합을 분산시키려고 글로벌 해시 파티셔닝하는 경우외에는 거의 사용되지 않는 실정이다.

6.3.7.1 테이블과 같은 컬럼으로 파티셔닝 하는경우
- 전  제1 : 테이블은 날짜 컬럼 기준으로 월별 파티셔닝, 인덱스는 분기별 파티셔닝
- 전  제2 : 글로벌 파티션 인덱스에는 Prefixed 파티션만 허용되므로 날짜 컬럼을 선두에 둬야하는데
- 문제점1 : 날짜조건은 대개 범위검색조건(BETWEEN, 부등호)이 사용되므로 인덱스 스캔 효율면에서 불리하다.
           NL 조인에서 INNER 테이블 액세스를 위해 자주 사용되는 인덱스라면 비효율은 더 크게 작용
- 해결점1 : 다른 조건 컬럼 중 '='조건을 선두에 둘수 있다는 측면에선 로컬 Nonprefixed 인덱스가 훨씬 유리하다.
- 문제점2 : 두달이상의 넓은 범위 조건을 가지고 INNER 테이블 액세스를 위해 사용될 때는 로컬 Nonprefixed 인덱스가 


           비효율. 조인 액세스가 일어나는 레코드마다 인덱스 파티션을 탐색해야 하기 때문이다.
- 해결점2 : NL 조인에서 넓은 범위 조건을 가지고 INNER테이블 액세스를 위해 자중 사용된다면 


           비파티션 인덱스가 가장 좋은 선택

6.3.7.2 테이블과 다른 컬럼으로 파티셔닝 하는경우
- 테이블 파티션 기준인 날짜 이외 컬럼으로 인덱스를 글로벌 파티셔닝 할 수 있는데 


  (인덱스 경합을 분산하려는 경우가 아니라면) 그런 구성은 대개 인덱스를 적정 크기로 유지하려는데에 목적이 있다.
- 인덱스가 너무 커지면 관리하기 힘들고 인덱스 높이가 증가해 액세스 효율이 나빠지기 때문이다.
- 결론 : 로컬 파티션 인덱스로 인해 글로벌 파티션이 비파티션보다 관리상 이점은 있다고 하나 
         로컬 파티션만 못하고 인덱스 높이 조절 측면에서도 동일하다.


6.3.8.3 로컬 Nonprefixed 파티션 인덱스의 효용성
- 이력성 테이터를 효과적으로 관리할 수 있게 해 주고, 인덱스 스캔 효율성을 높이는 데에도 유리하다.

-- 일별 계좌별거래 - 거래일자별로 한 계좌당 거래 데이터가 하루에 한 개 이상일 수 있다.
-- 이력성 테이블은 대부분 날짜 컬럼을 파티션 키로 사용하므로 여기서도 거래일자 컬럼을 기준으로 


   월단위 RANGE 파티셔닝 했다.

CREATE TABLE 일별계좌별거래 (
  계좌번호 NUMBER
, 거래일자 DATE
, 거래량   NUMBER
, 거래금액 NUMBER
)
PARTITION BY RANGE(거래일자)(
  PARTITION P01 VALUES LESS THAN(TO_DATE('20090201', 'YYYYMMDD'))
, PARTITION P02 VALUES LESS THAN(TO_DATE('20090301', 'YYYYMMDD'))
, PARTITION P03 VALUES LESS THAN(TO_DATE('20090401', 'YYYYMMDD'))
, PARTITION P04 VALUES LESS THAN(TO_DATE('20090501', 'YYYYMMDD'))
, PARTITION P05 VALUES LESS THAN(TO_DATE('20090601', 'YYYYMMDD'))
, PARTITION P06 VALUES LESS THAN(TO_DATE('20090701', 'YYYYMMDD'))
, PARTITION P07 VALUES LESS THAN(TO_DATE('20090801', 'YYYYMMDD'))
, PARTITION P08 VALUES LESS THAN(TO_DATE('20090901', 'YYYYMMDD'))
, PARTITION P09 VALUES LESS THAN(TO_DATE('20091001', 'YYYYMMDD'))
, PARTITION P10 VALUES LESS THAN(TO_DATE('20091101', 'YYYYMMDD'))
, PARTITION P11 VALUES LESS THAN(TO_DATE('20091201', 'YYYYMMDD'))
, PARTITION P12 VALUES LESS THAN(MAXVALUE)
);

-- 일별 계좌별 거래 데이타 생성
DECLARE
 L_FIRST_DATE DATE;
 L_LAST_DAY NUMBER;
BEGIN
  FOR I IN 1..12
  LOOP
    L_FIRST_DATE := TO_DATE('2009' || LPAD(I, 2, '0') || '01', 'YYYYMMDD');
    L_LAST_DAY := TO_NUMBER(TO_CHAR(LAST_DAY(L_FIRST_DATE), 'DD'));
    INSERT INTO 일별계좌별거래
    SELECT ROWNUM 계좌번호
         , L_FIRST_DATE + MOD(ROWNUM, L_LAST_DAY) 거래일자
         , ROUND(DBMS_RANDOM.VALUE(100, 10000)) 거래량
         , ROUND(DBMS_RANDOM.VALUE(10000, 1000000)) 거래금액
    FROM   DUAL
    CONNECT BY LEVEL <= 10000;
  END LOOP;
END;
/

-- 해당 계좌번호에 대한 거래일자별 거래량과 거래금액의 총합계를 구한다.
SELECT SUM(거래량), SUM(거래금액)
FROM   일별계좌별거래
WHERE  계좌번호 = :ACNT_NO
AND    거래일자 BETWEEN :D1 AND :D2

6.3.8.4 로컬 Prefixed 파티션 인덱스와 비교
- 위와 같은 조건절에 최적화된 인덱스를만들려면 등치(=)조건 컬럼을 선두에 두고 BETWEEN 같은 범위검색 조건 컬럼을 뒤쪽에
  위치 시켜야한다. 그런 측면에서 거래 일자를 선두에 둔 로컬 Prefixed 파티션 인덱스는 스캔 효율이 안좋다.
  
- 득정계좌에 대한 1월 15일부터 12월 15일까지 거래 테이터를 조회할때의 인덱스 스캔범위
- 우측 로컬 Prefixed    파티션 인덱스 (거래일자가 선두일시): 계좌번호 조건을 만족하지않는 거래데이터까지 모두스캔(거래일자가 선두일시)
- 좌측 로컬 Nonprefixed 파티션 인덱스 (계좌번호가 선두일시): 인덱스 파티션마다 필요한 최소범위만 스캔

-- 로컬 Prefixed 파티션 인덱스 와 로컬 Nonprefixed 파티션 인덱스 성능 비교

-- Prefixed
CREATE INDEX LOCAL_PREFIX_INDEX    ON 일별계좌별거래(거래일자, 계좌번호) LOCAL;

-- Nonprefixed
CREATE INDEX LOCAL_NONPREFIX_INDEX ON 일별계좌별거래(계좌번호, 거래일자) LOCAL;



SELECT /*+ INDEX(T LOCAL_PREFIX_INDEX) */ SUM(거래량), SUM(거래금액)
FROM   일별계좌별거래 T
WHERE  계좌번호 = 100
AND    거래일자 BETWEEN TO_DATE('20090115', 'YYYYMMDD')
                AND     TO_DATE('20091215', 'YYYYMMDD')

Call     Count CPU Time Elapsed Time       Disk      Query    Current       Rows
------- ------ -------- ------------ ---------- ---------- ---------- ----------
Parse        1    0.031        0.045          0        124          0          0
Execute      1    0.000        0.000          0          0          0          0
Fetch        2    0.047        0.051          0        387          0          1
------- ------ -------- ------------ ---------- ---------- ---------- ----------
Total        4    0.078        0.096          0        511          0          1

Misses in library cache during parse   : 1
Optimizer Goal : ALL_ROWS
Parsing user : SCOTT (ID=57)


Rows     Row Source Operation
-------  -----------------------------------------------------------------------
      1  SORT AGGREGATE (cr=387 pr=0 pw=0 time=51306 us)
     11   PARTITION RANGE ALL PARTITION: 1 12 (cr=387 pr=0 pw=0 time=40150 us)
     11    TABLE ACCESS BY LOCAL INDEX ROWID 응볶같좋볶같렁 PARTITION: 1 12 (cr=387 pr=0 pw=0 time=51152 us)
     11     INDEX RANGE SCAN LOCAL_PREFIX_INDEX PARTITION: 1 12 (cr=376 pr=0 pw=0 time=50926 us)

********************************************************************************
-- 로컬 Prefixed 파티션 인덱스 사용시에는 387개의 블록 I/O가 발생


SELECT /*+ INDEX(T LOCAL_NONPREFIX_INDEX) */ SUM(거래량), SUM(거래금액)
FROM   일별계좌별거래 T
WHERE  계좌번호 = 100
AND    거래일자 BETWEEN TO_DATE('20090115', 'YYYYMMDD')
                AND     TO_DATE('20091215', 'YYYYMMDD')

Call     Count CPU Time Elapsed Time       Disk      Query    Current       Rows
------- ------ -------- ------------ ---------- ---------- ---------- ----------
Parse        1    0.031        0.035          0        124          0          0
Execute      1    0.000        0.000          0          0          0          0
Fetch        2    0.000        0.064         20         35          0          1
------- ------ -------- ------------ ---------- ---------- ---------- ----------
Total        4    0.031        0.099         20        159          0          1

Misses in library cache during parse   : 1
Optimizer Goal : ALL_ROWS
Parsing user : SCOTT (ID=57)


Rows     Row Source Operation
-------  -----------------------------------------------------------------------
      1  SORT AGGREGATE (cr=35 pr=20 pw=0 time=64216 us)
     11   PARTITION RANGE ALL PARTITION: 1 12 (cr=35 pr=20 pw=0 time=62501 us)
     11    TABLE ACCESS BY LOCAL INDEX ROWID 응볶같좋볶같렁 PARTITION: 1 12 (cr=35 pr=20 pw=0 time=64082 us)
     11     INDEX RANGE SCAN LOCAL_NONPREFIX_INDEX PARTITION: 1 12 (cr=24 pr=20 pw=0 time=63875 us)

********************************************************************************
-- 로컬 Nonprefixed 파티션 인덱스 사용시에는 35개의 블록 I/O가 발생

6.3.8.5 글로벌 Prefixed 파티션 인덱스와 비교
- Prefixed 파티션만 허용되므로서 거래일자처럼 범위검색 조건으로 자주사용되는 컬럼이 선두 일때
  로컬 Prefixed 파티션 인덱스 동일하게 인덱스 스캔효율이 나빠진다.
- 과거 파티션을 제거하고 신규 파티션을 추가하는등의 파티션 단위 작업 시 매번 인덱스를 재생성해야 하므로 관리적 부담이 크다.
  (ROLLING IN/OUT에대한 관리적 부담)

6.3.8.6 비파티션 인덱스와 비교
- 글로벌 파티션과 동일하게 관리적 부담
- 로컬 Nonprefixed 파티션 인덱스는 두달 이상에 걸친 넓은 범위의 거래일자 조건으로 조회할 때 
  여러 인덱스를 (수직적)탐색해야하는 비효율이 있다.
- 계좌번호를 선두에 둔 비피티션 인덱스는 여러 달에 걸친 거래일자로 조회하더라도 인덱스 스캔 상 비효율은 없다.
- 아주넓은 범위의 거래일자 조회시 계좌번호만으로 조회시 테이블 RANDOM 액세스 부하 때문에 
  비파티션도 인덱스도 제성능을 내기 어렵다.
  
SELECT SUM(거래량), SUM(거래금액)
FROM   일별계좌별거래
WHERE  계좌번호 = :ACNT_NO
  
- 이때 병렬 쿼리가 필요할 수 있는데 비파티션 인덱스에는 병렬 쿼리가 허용되지 않고 


  로컬 Nonprefixed 파티션 인덱스라면 여러 병렬프로세스가 각각 하나의 인덱스 세그먼트를 스캔하도록 함으로써 


  위 쿼리의 응답속도를 크게 향상시킬 수 있다.

6.3.8.7일단위 파티셔닝
- 계좌번호로만으로 로컬 Nonprefixed 파티션 인덱스 생성함으로써 인덱스 저장 공간을 줄이는 효과를 얻을수있다.

-- 아래 쿼리시 계좌번호로만 인덱스 생성시 거래일자를 읽기 위한 테이블 액세스가 발생하므로 불리하다.
SELECT 계좌번호, COUNT(*)
FROM   일별계좌별거래
WHERE  거래일자 BETWEEN '20090101' AND '20090115'
GROUP BY 계좌번호

-- 인덱스에 거래일자가 포함되어있을 때에는 테이블을 액세스하지않고 INDEX FAST FULL SCAN 방식으로 처리 할 수 있다.
   (1장 3절 (5)항 참조 PAGE 50)
   

6.3.9 액세스 효율을 고려한 인덱스 파티셔닝 선택 기준

6.3.9.1 DW성 애플리케이션 환경
- DW/DSS 애플리케이션에는 날짜 컬럼 기준으로 파티셔닝된이력성 대용량 테이블이 많다.
- 관리적 츠면과 병렬 쿼리 활용측면으로 로컬 파티션 인텍스가 좋은 선택이고 그중 로컬 Nonprefixed 파티션 인덱스가 
  성능면에서 유리할 때가 많다.

6.3.9.2 OLTP 애플리케이션 환경
- 비파티션 인덱스가 대개 좋은 선택
- RIGHT GROWING 인덱스에 대한 동시 INERT 경합을 분산할 목적으로 해시 파티셔닝 하는경우가 아니라면
  글로벌 파티션 인덱스는 효용성이 낮다.
- 로컬 파티션 인덱스는 테이블 파티션에 대한 DDL 작업 후 인덱스를 재생성하지 않아도 되므로 가용성측면에서 유리
- OLTP 환경에서는 로컬 인덱스 중 Prefixed 파티션이 Nonprefixed 파티션보다 유리하다고 오라클 매뉴얼을 


  포함한 여러문서에 설명
- 어떠한것이 유리하다라고 정리하기 보다 검색조건에 따라 항상 사용되는 컬럼을 파티션 키로 선정하려고 노력해야한다.
- 파티션키가 RANGE 조건으로 자주사용된다면 Nonprefixed 인덱스가 유리하고 될 수 있으면 좁은 범위검색이어야한다.
- NL조인에서 파티션키에대한 넓은 범위검색 조건을 가지고 INNER 테이블 액세스를 용도로 사용된다면 비파티션 인덱스를 사용해야한다.
   

6.3.10 액세스 효율을 고려한 인덱스 파티셔닝 선택 기준

1. UNIQUE 파티션 인덱스를 정의할때는 인덱스 파티션 키가 모두 인덱스 구성 컬럼에 포함되어야 한다.
   이제약이 없다면 인덱스 키값을 변경, 새로운 값 입력 할때마다 중복값 체크를 위해 
   매번 많은 인덱스 파티션을 탐색해야하므로 DML성능저하
2. 글로벌 파티션 인덱스는 Prefixed 파티션이어야한다.

- 인덱스를 통해 액세스할 데이터량이 아주 많아 빠른 성능을 내기 어렵고 FULL TABLE SCAN으로 처리하기에는
  너무 많은 양을 읽어야 할때 주로 파티셔닝을 실시하게 된다.
   
1. 여러 엔티티 타입을 하나로 통합해 슈퍼(SUPER)/서브(SUB) 타입 관계로 모델링
2. 물리적으로도 하나의 테이블로 통합할 때는 구분자(Discriminator) 컬럼을 둔다.
3. 통합한 테이블이 대용량일 때는 구분자 컬럼을 기준으로 파티셔닝하는 전략이 자주 사용
4. 구분자 컬럼을PK에 포함시키지 않고 일반속성으로 두더라도 파티셔닝하는데에는 전혀문제가 없다
5. 인덱스를 파티셔닝 하려는 순간에는 위의 제약 으로 인해 원하는 형태로 구현하지 못하는 일이 발생하므로
   구문자컬럼 PK컬럼에 포함 


- 상품대분류는 상품 엔티티로 반정규화한 컬럼
- 상품테이블이 파티셔니 되어있지 않은 상황에서 일별상품거래 테이블만 파티셔닝 하려는것인데
  엔티티를 하나로 통합하긴 했지만 MD조직이 상품 대분류를 기준으로 구성되다보니 애플리케이션에도
  상품대분류 조건을 항상 가지면서 독립적으로 데이타를 액세스한다. 
  물리적으로 별도 세그먼트에 저장되도록 구현하려는것이다.
- 일별상품거래는 상품번호와 거래일자 두컬럼만으로 UNIQUE 하므로 논리모델 단계에서는 상픔대분류를 일반속성으로
  정의하는것이 타당하다.
  
CREATE TABLE 상품 (
  상품번호   NUMBER
, 상품명     VARCHAR2(100)
, 상품대분류 NUMBER
, 현재가격   NUMBER
, 등록일시   DATE
, CONSTRAINT PK_상품 PRIMARY KEY (상품번호)
);

-- 거래일자 기준 RANGE 파티션, 상품대분류 기준 리스트 파티셔닝
CREATE TABLE 일별상품거래 (
  상품번호   NUMBER
, 거래일자   DATE
, 상품대분류 VARCHAR2(1)
, 판매가격   NUMBER
, 판매수량   NUMBER
, 판매금액   NUMBER
, CONSTRAINT PK_일별상품거래 PRIMARY KEY (거래일자)
)
PARTITION BY RANGE(상품대분류)(
  PARTITION PA VALUES LESS THAN('A')
, PARTITION PB VALUES LESS THAN('B')
, PARTITION PC VALUES LESS THAN('C')
, PARTITION PD VALUES LESS THAN('D')
, PARTITION PE VALUES LESS THAN('E')
, PARTITION PF VALUES LESS THAN('F')
, PARTITION PG VALUES LESS THAN('G')
);

ALTER TABLE 일별상품거래 ADD CONSTRAINT FK_일별상품거래 FOREIGN KEY(상품번호)
REFERENCES 상품(상품번호);



CREATE UNIQUE INDEX 일별상품거래_PK ON 일별상품거래(상품번호, 거래일자) LOCAL;

-- ORA-14039: partitioning columns must form a subset of key columns of a UNIQUE index
-- 파티션 키인 상품대분류가 인덱스 컬럼에 포함되지 않으므로 에러 발생

-- 관리적 이점 포기할 수 밖에 없고 테이블과 같은 파티션 키컬럼 기준으로 글로벌 파티션 인덱스 생성 시도
CREATE UNIQUE INDEX 일별상품거래_PK ON 일별상품거래(상품번호, 거래일자) GLOBAL
PARTITION BY RANGE(거래일자)(
  PARTITION PA VALUES LESS THAN('A')
, PARTITION PB VALUES LESS THAN('B')
, PARTITION PC VALUES LESS THAN('C')
, PARTITION PD VALUES LESS THAN('D')
, PARTITION PE VALUES LESS THAN('E')
, PARTITION PF VALUES LESS THAN('F')
, PARTITION PG VALUES LESS THAN('G')
);
-- ORA-14038: GLOBAL partitioned index must be prefixed
-- 글로벌 파티션 인덱스는 Prefixed 파티션이어야하기 때문에 에러 발생

- 범위검색조건으로 인덱스를 비효율적으로 스캔하는 문제는 비파티션 인덱스 또는 로컬 파티션인덱스로 해결가능하다

- 초대용량 데이터베이스 환경에서는 하나의 인덱스로 '성능' 과 '관리비용' 두가지를 고려해야한다.

-- 상품대분류를 PK에 포함시킨다면
ALTER TABLE 일별상품거래 DROP PRIMARY KEY;


--  아래와 같이 Noneprefixed 방식으로 파티셔닝 할 수 있다.
CREATE UNIQUE INDEX 일별상품거래_PK ON 일별상품거래(상품번호, 거래일자, 상품대분류) LOCAL;

ALTER TABLE 일별상품거래 ADD CONSTRAINT 일별상품거래_PK PRIMARY KEY(상품번호, 거래일자, 상품대분류)
USING INDEX 일별상품거래_PK;

- 이 인덱스는 PK 제약을 위해 사용될뿐아니라 상품번호 + 거래일자 조건 조회시 효과적 사용
- 상품대분류와 거래일자 만으로 조회할때는 한개 또는 일부 서브파티션만 FULL SCAN 하면 되므로 
   비효율 없어 다량의 데이터를 빠르게 처리 가능하다.
- 결과 : 약간의 설계 변경을 통해 원하는 형태로 파티셔닝 구현함으로써 관리상 및 데이타 액세스 효율상으로 이점이 생겼다.


오라클 고도화 원리와 해법 2 (bysql.net 2011년 1차 스터디)
작성자: 김범석 (darkbeom)
최초작성일: 2011년 6월 19일
본문서는 bysql.net 스터디 결과입니다 .본 문서를 인용하실때는 출처를 밝혀주세요. http://www.bysql.net
문서의 잘못된 점이나 질문사항은 본문서에 댓글로 남겨주세요. ^^



