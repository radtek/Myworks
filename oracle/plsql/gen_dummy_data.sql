/*
INSERT INTO ORADEV.OZ_TEST
(NSEQ, DCCODE, SLIPNUM, TDATE, CAR, BAT, TRANS, "STATEMENT", CLIENT, SHIPF, SHIPFCODE, PRODUCT, PRODUCTCODE, DCUSTOMER, BOX, COUNT, QUANTITY, WEIGHT, RWEIGHT, ORDERTYPE, DNUMBER, VTYPE)
VALUES("ORADEV"."ISEQ$$_106030".nextval, 0, 0, '', '', '', '', '', '', '', '', '', 0, '', 0, 0, 0, '', '', '', '', '');


CEIL(DBMS_RANDOM.VALUE(1000, 1005)) -- DCCODE
TO_CHAR(TRUNC(SYSDATE) - DBMS_RANDOM.VALUE(1, 3), 'YYYY-MM-DD HH24:MI:SS') -- TDATE
TO_CHAR(CEIL(DBMS_RANDOM.VALUE(20001, 20003))) -- BAT
'0'||TO_CHAR(CEIL(DBMS_RANDOM.VALUE(2001, 2005)))-- STATEMENT
DBMS_RANDOM.STRING('U',1) -- CLIENT
SELECT DBMS_RANDOM.STRING('U',1) FROM DUAL CONNECT BY LEVEL < 11 ;

SELECT TO_CHAR(TRUNC(SYSDATE) + DBMS_RANDOM.VALUE(0, 1), 'YYYY-MM-DD HH24:MI:SS')  FROM DUAL CONNECT BY LEVEL < 20;

*/

DECLARE
    SDATE       DATE;
    TDATE       VARCHAR2(20);
    CAR         VARCHAR2(20);
    BAT         VARCHAR2(20);
    STAM        VARCHAR2(20);
    CLI         VARCHAR2(20);
    SHIPF       VARCHAR2(40);
    SHIPFCODE   VARCHAR2(20);
    PRODUCT     VARCHAR2(40);
    PRODUCTCODE NUMBER;
    ORDERTYPE   VARCHAR2(20);
    DNUM        VARCHAR2(20);
    VTYPE       VARCHAR2(12);
    RANDN       NUMBER;
    LOOPS       NUMBER;
BEGIN
    SDATE   := TO_DATE('2021-10-25','YYYY-MM-DD');
    FOR idx IN 1 .. 4 LOOP 
        LOOPS := 200000 * idx;
        STAM    := '0200'||to_char(idx);
        BAT     := '2000'||to_char(idx);
        CLI     := DBMS_RANDOM.STRING('U',1);
    
        FOR indx IN 1 .. LOOPS LOOP 
            TDATE   := TO_CHAR(TRUNC(SDATE) + DBMS_RANDOM.VALUE(0, 2), 'YYYY-MM-DD HH24:MI:SS') ;
        
            IF STAM = '02001' THEN
                SHIPF := '롯데마트 XX 센터';
                SHIPFCODE := '000000104';
                PRODUCT := '곰표밀가루 1KG';
                PRODUCTCODE := 0110000014;
            ELSIF STAM = '02002' THEN
                SHIPF := '이미트 00 센터';
                SHIPFCODE := '000000201';
                PRODUCT := '맥스봉 50개입';
                PRODUCTCODE := 0100002381;
            ELSIF STAM = '02003' THEN
                SHIPF := '온마트 ㅁㅁ 센터';
                SHIPFCODE := '000002132';
                PRODUCT := '참크래커 20개입 박스';
                PRODUCTCODE := 0112900039;
            ELSIF STAM = '02004' THEN
                SHIPF := '스타벅스 ㅇㅇ 센터';
                SHIPFCODE := '000010023';
                PRODUCT := '크로크무슈 12개입 박스';
                PRODUCTCODE := 0290023780;
            END IF;
        
            ORDERTYPE := CLI||STAM;
            DNUM := TO_CHAR(SDATE,'YYYYMMDD')||CLI;
            VTYPE := '정상';
        
            INSERT INTO ORADEV.OZ_TEST
            (TDATE, BAT, "STATEMENT", CLIENT, SHIPF, SHIPFCODE, PRODUCT, PRODUCTCODE, BOX, 
             COUNT, QUANTITY, WEIGHT, RWEIGHT, ORDERTYPE, DNUMBER, VTYPE)
            VALUES(TDATE, BAT, STAM, CLI, SHIPF, SHIPFCODE, PRODUCT, PRODUCTCODE, 
                    0, 0, 0, '0', '0', ordertype, dnum, vtype);
        END LOOP;
        --SDATE := SDATE + 1;
        
    END LOOP;
END;
