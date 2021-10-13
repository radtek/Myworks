/*
CREATE SEQUENCE ORADEF.SQ_METACONV INCREMENT BY 1 MINVALUE 0 NOCYCLE NOCACHE NOORDER ;

CREATE TABLE ORADEF.TB_METACONV (
SEQ NUMBER DEFAULT ORADEF.SQ_METACONV.NEXTVAL,
ASIS_TEXT CLOB,
CONV_TEXT CLOB,
INSDATE DATE DEFAULT SYSDATE,
RET_CONV CLOB,
CONSTRAINT PK_METACONV PRIMARY KEY(SEQ)
);
COMMENT ON TABLE ORADEF.METACONV IS '메타 컬럼 자동변환용';
COMMENT ON COLUMN ORADEF.METACONV.SEQ IS '일렬 번호';
COMMENT ON COLUMN ORADEF.METACONV.ASIS_TEXT IS '기존 쿼리문 텍스트';
COMMENT ON COLUMN ORADEF.METACONV.CONV_TEXT IS '컨버전 된 전환 텍스트';
COMMENT ON COLUMN ORADEF.METACONV.INSDATE IS 'INSERT 된 날짜';
COMMENT ON COLUMN ORADEF.METACONV.RET_CONV IS '전환 결과';
*/

-- Column Replace Procedure
DECLARE
-- TYPE DEFS -----------------------------------------------------------
    TYPE        tlist 
    IS TABLE OF varchar2(256)
    INDEX BY    pls_integer;

    TYPE        defs
    IS RECORD (
    asis_col    oradev.tb_def_meta.asis_column%type,
    conv_col    oradev.tb_def_meta.new_def_col%type
    );
    TYPE        deflist
    IS TABLE OF defs
    INDEX BY    pls_integer;

    TYPE        origs
    IS RECORD (
    seq         NUMBER,
    texts       clob
    );
    TYPE        origlist
    IS TABLE OF origs
    INDEX BY    pls_integer;
-- VARIABLE DEFS -------------------------------------------------------
    frompatt    varchar2(48);
    orapattern  varchar2(50);
    joinpattern varchar2(62);
    pattern     varchar2(4000);
    comm1       varchar2(300);
    comm2       varchar2(300);
    comments    varchar2(300);
    query       clob;
    result_conv clob;
    grpno       NUMBER;
    arrno       NUMBER;
    incount     NUMBER;
    outcount    NUMBER;
    jptcount    NUMBER;
    inschem     NUMBER;
    reglike     tlist;
    tablelist   tlist;
    deftabs     deflist;
    queries     origlist;
    bufferarr   sys.odcivarchar2list;

BEGIN -- PROCEDURE START ------------------------------------------------------------------------------------------
 
    -- Get data ---------------------------------------------------------------------------------------------------
    SELECT SEQ, ASIS_TEXT 
    BULK COLLECT INTO queries 
    FROM ORADEF.TB_METACONV 
    WHERE CONV_TEXT IS NULL; 

    FOR idx IN queries.FIRST .. queries.LAST -- GET queries
    LOOP
        -- Initialize variables
        grpno :=  1;
        arrno :=  1;
        outcount := 1;
        jptcount := 0 ;
        query := queries(idx).texts;
        -- Regular Expression Pattern
        frompatt := 'FROM\s+([a-z1-9\$\_\.]{1,})\s*?[a-z1-9\$\_]{0,}?';
        orapattern := '\s*?,\s*?([a-z1-9\$\_\.]{1,})\s*?[a-z1-9\$\_]{0,}?';
        joinpattern := 'JOIN\s+([a-z1-9\$\_\.]{1,})\s*?[a-z1-9\$\_]{0,}?';

        -- For debug
--        dbms_output.put_line('SEQ : '  || queries(idx).seq || CHR(10)|| 'QUERY : '|| query || CHR(10));
    
        BEGIN -- REGEX BLOCK --------------------------------------------------------------------------------------
            
            -- || get table list in texts ||
            LOOP -- REGEX OUTER LOOP
                incount := 1;    
            
                IF jptcount = 0 THEN 
                    IF outcount = 1 THEN
                        pattern := frompatt;                -- SET Pattern oracle join
                    ELSE 
                        pattern := pattern || orapattern;   -- Plus Pattern reculsively
                    END IF;
                ELSE
                        pattern := joinpattern;             -- SET Pattern ansi join
                END IF; 
    
                    LOOP -- REGEX INNER LOOP
                        reglike(arrno) := regexp_substr(queries(idx).texts, pattern ,1,incount,'mni',grpno);
                        EXIT WHEN reglike(arrno) IS NULL ;
                        -- For debug
--                        dbms_output.put_line('TABLE '||TO_CHAR(arrno)||' : '||reglike(arrno)); 
                    
                        arrno := arrno+1;
                        incount := incount+1;
                    
                    END LOOP; -- REGEX INNER LOOP END
                
    
                EXIT WHEN jptcount = 1 ;  
                grpno := grpno+1;
                outcount := outcount + 1;
            
                IF incount = 1 AND reglike(arrno) IS NULL THEN 
                    grpno := 1;
                    jptcount := 1;
                    outcount := 1;
                END IF;
                -- For debug
--                dbms_output.put_line('jpt '||TO_CHAR(jptcount)||' inc '||TO_CHAR(incount)||' grp '||TO_CHAR(grpno));
--                dbms_output.put_line('outc '||TO_CHAR(outcount)||' pattern '||pattern);
        
            END LOOP; -- REGEX OUTER LOOP END
            
            -- || Regex exception Area ||
            EXCEPTION 
                WHEN OTHERS THEN 
                        dbms_output.put_line(CHR(10)||
                                             '--------------------------------------------------------'||
                                             CHR(10)||'EXCEPTION ocurred in REGEXP Block' ||CHR(10)||
                                             '--------------------------------------------------------'||
                                             CHR(10)||'ERR LOCATE : '|| grpno);
                        dbms_output.put_line('PROBLEM ==> '||SQLERRM||CHR(10)||
                                             '--------------------------------------------------------'||
                                             CHR(10));
                
        END; -- REGEX BLOCK END -----------------------------------------------------------------------------------
    
        -- || Get rid of duplicated values ||
        grpno := 90;
        bufferarr := sys.odcivarchar2list();
        FOR r IN 1..arrno-1     -- Nested TABLE insert (FOR sort uniq)
            LOOP
                
                bufferarr.extend;
                bufferarr(r) := reglike(r);     
    
                -- For debug
--                dbms_output.put_line(bufferarr(r));

        END LOOP;  ---------------- Nested TABLE insert END
        
        grpno := 91;
        SELECT DISTINCT column_value    --- GET rid OF duplicates
               BULK COLLECT INTO tablelist 
        FROM table(bufferarr) 
        WHERE column_value IS NOT NULL;
    
        -- For debug
--        dbms_output.put_line(CHR(10));
        
        -- || Get def column values ||
        grpno := 92;
        result_conv := '';
        FOR t IN 1..tablelist.count -- GET Def column list
            LOOP

                -- For debug
--                IF length(t) = 1 THEN
--                    dbms_output.put_line('0'||t||' : '|| tablelist(t));
--                ELSE
--                    dbms_output.put_line(t||' : '|| tablelist(t));
--                END IF;
--                
                inschem := instr(tablelist(t), '.');

                -- For debug
--                dbms_output.put_line(CHR(10)|| 'IN SCHEMA DOT : ' || inschem);
            
                IF inschem = 0 THEN -- check has contained schema_name in query
                    SELECT ASIS_COLUMN, NEW_DEF_COL
                    BULK COLLECT INTO deftabs
                    FROM ORADEV.TB_DEF_META
                    WHERE ASIS_TABLE = upper(tablelist(t))
                    AND ASIS_COLUMN IS NOT NULL
                    AND NEW_DEF_COL IS NOT NULL;
                ELSE 
                    SELECT ASIS_COLUMN, NEW_DEF_COL 
                    BULK COLLECT INTO deftabs
                    FROM ORADEV.TB_DEF_META
                    WHERE ASIS_TABLE = upper(substr(tablelist(t), inschem + 1))
                    AND ASIS_SCHEM = upper(substr(tablelist(t), 1, inschem - 1))
                    AND ASIS_COLUMN IS NOT NULL
                    AND NEW_DEF_COL IS NOT NULL;
                END IF;

                -- For debug
--                dbms_output.put_line(CHR(10)|| ' COUNT : ' || to_char(deftabs.count) || CHR(10));
--                dbms_output.put_line('TABLE : '||tablelist(t));
            
                result_conv := result_conv||'TABLE : '||tablelist(t)||CHR(10);
            
                -- || CONVERT Column_name ||-------------------------------------------------------------------------
                IF deftabs.count > 0 THEN 
                    FOR indx IN deftabs.FIRST .. deftabs.LAST -- Compare and convert loop
                        LOOP

                            -- For debug
--                            dbms_output.put_line(CHR(10)|| 'ASIS_COL : ' || to_char(deftabs(indx).asis_col) || CHR(10) ||
--                                                 'CONV_COL : ' || to_char(deftabs(indx).conv_col));
                        
                            comm1 := ' /*'||deftabs(indx).asis_col||'*/';
                            comm2 := deftabs(indx).conv_col||' /*기존과 같음*/';
                        
                            IF (instr(query, comm1, 1) = 0) AND (instr(query, comm2, 1) = 0 ) THEN 
                                IF upper(deftabs(indx).asis_col) <> deftabs(indx).conv_col THEN

                                    -- For debug
--                                    dbms_output.put_line('  Changed : '||deftabs(indx).asis_col||'->'||deftabs(indx).conv_col);
                                
                                    IF instr(query, deftabs(indx).asis_col, 1) <> 0 THEN 
                                        result_conv := result_conv||'  Changed : '||deftabs(indx).asis_col||
                                                                    '->'||deftabs(indx).conv_col||CHR(10);
                                        comments := comm1;
                                    ELSE 
                                        result_conv := result_conv||'  Not Found in Text : '||deftabs(indx).asis_col||CHR(10);
                                        comments := '';
                                    END IF;
                                                              
                                ELSIF upper(deftabs(indx).asis_col) = deftabs(indx).conv_col THEN

                                    -- For debug
--                                    dbms_output.put_line('  Passed  : '||deftabs(indx).asis_col||'='||deftabs(indx).conv_col);

                                    IF instr(query, deftabs(indx).asis_col, 1) <> 0 THEN 
                                        result_conv := result_conv||'  Passed  : '||deftabs(indx).asis_col||
                                                                '='||deftabs(indx).conv_col||CHR(10);
                                        comments := comm2;
                                    ELSE
                                        result_conv := result_conv||'  Not Found in Text : '||deftabs(indx).asis_col||CHR(10);
                                        comments := '';
                                    END IF;

                                ELSE 
                                
                                    -- For debug
--                                    dbms_output.put_line('  Invalid : '||deftabs(indx).asis_col||'??'||deftabs(indx).conv_col);
                                
                                    result_conv := result_conv||'  Invalid : '||deftabs(indx).asis_col||
                                                                '??'||deftabs(indx).conv_col||CHR(10);
                                END IF;
                            
                                IF comments IS NOT NULL THEN 
                                    query := regexp_replace(query, deftabs(indx).asis_col, deftabs(indx).conv_col||comments, 1, 0, 'mni');
                                END IF;
                        
                            ELSE 
                            
                                -- For debug
--                                dbms_output.put_line('  Already changed : '||deftabs(indx).asis_col);
                            
                                result_conv := result_conv||'  Already changed : '||deftabs(indx).asis_col||CHR(10);
                            END IF;
                        END LOOP; ------ Compare and convert loop end 
                ELSE
                
                    -- For debug
--                    dbms_output.put_line('  Invalid : Table not found.');
                
                    result_conv := result_conv||'  Invalid : Table name not found in definition table.'||CHR(10);
                END IF;
                -- Convert END ---------------------------------------------------------------------------------------
            
            END LOOP; ------ GET def column list END
        
        UPDATE ORADEF.TB_METACONV 
        SET CONV_TEXT = query, RET_CONV = result_conv 
        WHERE SEQ = queries(idx).seq;
            
        -- For debug
--        dbms_output.put_line(CHR(10)||'------------------------------------------------------'||CHR(10)||
--                             queries(idx).seq||' Sequence '||
--                             CHR(10)||'------------------------------------------------------'||CHR(10)||
--                             result_conv||CHR(10)||'-- Query Changed --'||CHR(10)||query||CHR(10));
    
    END LOOP; --------- GET queries END

    -- || Global Exception Area || 
    EXCEPTION 
        WHEN OTHERS THEN 
            dbms_output.put_line(CHR(10)||
                                 '--------------------------------------------------------'||
                                 CHR(10)||'EXCEPTION ocurred ' ||CHR(10)||
                                 '--------------------------------------------------------'||
                                 CHR(10)||'ERR LOCATE : '|| grpno);
            dbms_output.put_line('PROBLEM ==> '||SQLERRM||CHR(10)||
                                 '--------------------------------------------------------'||
                                 CHR(10));
                             
END; -- PROCEDURE END ---------------------------------------------------------------------------------------------
