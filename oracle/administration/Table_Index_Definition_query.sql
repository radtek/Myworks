--------------------------------------------------------------------
-- 자료사전 양식
--------------------------------------------------------------------
SELECT DTCOL.TABLE_NAME AS "테이블명",
       DTCOL.COLUMN_ID AS SEQ,
       DCCOM.COMMENTS AS "명칭", 
       DTCOL.COLUMN_NAME AS "영문명", 
       CASE WHEN DTCOL.DATA_TYPE = 'NUMBER' 
              THEN DTCOL.DATA_TYPE||'('||DTCOL.DATA_PRECISION||','||DTCOL.DATA_SCALE||')'
            WHEN DTCOL.DATA_TYPE LIKE 'TIMESTAMP%'
              THEN DTCOL.DATA_TYPE
            ELSE DTCOL.DATA_TYPE||'('||DTCOL.DATA_LENGTH||')'
       END AS "형식",
       '' AS "비고"
FROM DBA_TAB_COLS DTCOL
LEFT OUTER JOIN DBA_COL_COMMENTS DCCOM
ON DTCOL.TABLE_NAME = DCCOM.TABLE_NAME
AND DTCOL.COLUMN_NAME = DCCOM.COLUMN_NAME
AND DTCOL.OWNER = DCCOM.OWNER
WHERE DTCOL.OWNER = 'IMSADM';

--------------------------------------------------------------------
-- 인덱스 정의서 양식
--------------------------------------------------------------------
SELECT DTCOM.COMMENTS AS "테이블명",
       DICOL.TABLE_NAME AS "테이블ID", 
       DICOL.INDEX_NAME AS "인덱스명", 
       CASE WHEN DIND.UNIQUENESS = 'UNIQUE' 
              THEN 'Yes'
            ELSE 'No'
       END AS "UNIQUE",
       DICOL.COLUMN_NAME AS "컬럼ID",
       CASE WHEN DTCOL.DATA_TYPE = 'NUMBER' 
              THEN DTCOL.DATA_TYPE||'('||DTCOL.DATA_PRECISION||','||DTCOL.DATA_SCALE||')'
            WHEN DTCOL.DATA_TYPE LIKE 'TIMESTAMP%'
              THEN DTCOL.DATA_TYPE
            ELSE DTCOL.DATA_TYPE||'('||DTCOL.DATA_LENGTH||')'
       END AS "형식",
       '' AS "비고"
FROM DBA_IND_COLUMNS DICOL
     LEFT OUTER JOIN DBA_TAB_COMMENTS DTCOM
                     ON DICOL.TABLE_OWNER = DTCOM.OWNER
                     AND DICOL.TABLE_NAME = DTCOM.TABLE_NAME
     LEFT OUTER JOIN DBA_INDEXES DIND
                     ON DICOL.INDEX_OWNER = DIND.OWNER
                     AND DICOL.INDEX_NAME = DIND.INDEX_NAME
     LEFT OUTER JOIN DBA_TAB_COLS DTCOL
                     ON DICOL.TABLE_OWNER = DTCOL.OWNER
                     AND DICOL.TABLE_NAME = DTCOL.TABLE_NAME
                     AND DICOL.COLUMN_NAME = DTCOL.COLUMN_NAME
WHERE DICOL.TABLE_OWNER = 'IMSADM'
ORDER BY DICOL.TABLE_NAME, DICOL.INDEX_NAME, DICOL.COLUMN_POSITION;