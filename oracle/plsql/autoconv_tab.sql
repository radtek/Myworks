CREATE OR REPLACE PROCEDURE ORADEV.SP_METACONV
/*
-- Column Replace Procedure (Non-Stored)

CREATE TABLE ORADEV.TB_METACONV (
SEQ NUMBER generated always as identity,
ASIS_TEXT CLOB,
CONV_TEXT CLOB,
INSDATE DATE DEFAULT SYSDATE,
RET_CONV CLOB,
LAST_HANDLE VARCHAR2(100) DEFAULT '('||USER||') '||SYS_CONTEXT('USERENV','OS_USER'),
CONSTRAINT PK_METACONV PRIMARY KEY(SEQ)
);
COMMENT ON TABLE ORADEV.METACONV IS '메타 컬럼 자동변환용';
COMMENT ON COLUMN ORADEV.METACONV.SEQ IS '일렬 번호';
COMMENT ON COLUMN ORADEV.METACONV.ASIS_TEXT IS '기존 쿼리문 텍스트';
COMMENT ON COLUMN ORADEV.METACONV.CONV_TEXT IS '컨버전 된 전환 텍스트';
COMMENT ON COLUMN ORADEV.METACONV.INSDATE IS 'INSERT 된 날짜';
COMMENT ON COLUMN ORADEV.METACONV.RET_CONV IS '전환 결과';
COMMENT ON COLUMN ORADEV.METACONV.LAST_HANDLE IS '실행자';
*/
IS
-- TYPE DEFS -----------------------------------------------------------
    TYPE        tlist 
    IS TABLE OF varchar2(256)
    INDEX BY    pls_integer;

    TYPE        defs
    IS RECORD (
    asis_col    ORADEV.TB_DEF_META.asis_column%type,
    conv_col    ORADEV.TB_DEF_META.new_def_col%type
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
    frompatt    varchar2(52);
    orapattern  varchar2(54);
    joinpattern varchar2(62);
    updatepatt  varchar2(33);
    insertpatt  varchar2(38);
    endpatt     varchar2(10);
    pattern     varchar2(4000);
    comm1       varchar2(300);
    comm2       varchar2(300);
    endcomm     varchar2(10);
    comments    varchar2(300);
    handler     varchar2(100);
    spacepatt   varchar2(10);
    spacesym    varchar2(10);
    rech        varchar2(30);
    query       clob;
    result_conv clob;
    grpno       NUMBER;
    arrno       NUMBER;
    incount     NUMBER;
    outcount    NUMBER;
    jptcount    NUMBER;
    inschem     NUMBER;
    rech_cnt    NUMBER;
    reglike     tlist;
    tablelist   tlist;
    ret_count   tlist;
    deftabs     deflist;
    queries     origlist;
    bufferarr   sys.odcivarchar2list;
    nodata      EXCEPTION;
    noupdate    EXCEPTION;

BEGIN -- PROCEDURE START ------------------------------------------------------------------------------------------
    handler := '('||USER||') '||SYS_CONTEXT('USERENV','OS_USER');
    ret_count := tlist();
    -- Regular Expression Pattern
    frompatt := 'FROM\s+([a-z1-9\$\_\.]{1,})\s*?[a-z1-9\$\_\(\)]{0,}?';
    orapattern := '\s*?,\s*?([a-z1-9\$\_\.]{1,})\s*?[a-z1-9\$\_\(\)]{0,}?';
    joinpattern := 'JOIN\s+([a-z1-9\$\_\.]{1,})\s*?[a-z1-9\$\_]{0,}?';
    updatepatt := 'UPDATE\s+([a-z1-9\$\_\.]{1,})\s*?';
    insertpatt := 'INSERT INTO\s+([a-z1-9\$\_\.]{1,})\s*?';

    -- Get data ---------------------------------------------------------------------------------------------------
    SELECT SEQ, ASIS_TEXT 
    BULK COLLECT INTO queries 
    FROM ORADEV.TB_METACONV 
    WHERE CONV_TEXT IS NULL; 

    IF queries.count = 0 THEN
        raise nodata; 
    END IF;

    FOR idx IN queries.FIRST .. queries.LAST -- GET queries
    LOOP
        -- Initialize variables
        grpno :=  1;
        arrno :=  1;
        outcount := 1;
        jptcount := 0 ;
        query := queries(idx).texts;

        -- For debug
--        dbms_output.put_line('SEQ : '  || queries(idx).seq || CHR(10)|| 'QUERY : '|| query || CHR(10));
    
        BEGIN -- REGEX BLOCK --------------------------------------------------------------------------------------
            
            -- || get table list in texts ||
            LOOP -- REGEX OUTER LOOP
                incount := 1;    
            
                IF jptcount = 0 THEN 
                    IF outcount = 1 THEN
                        pattern := frompatt;                -- SET Pattern : oracle join
                    ELSE 
                        pattern := pattern || orapattern;   -- Plus Pattern reculsively
                    END IF;
                ELSIF jptcount=1 THEN
                        pattern := joinpattern;             -- SET Pattern : ansi JOIN
                ELSIF jptcount=2 THEN
                        pattern := updatepatt;
                ELSIF jptcount=3 THEN 
                        pattern := insertpatt;
                END IF; 
    
                    LOOP -- REGEX INNER LOOP
                        reglike(arrno) := regexp_substr(queries(idx).texts, pattern ,1,incount,'mni',grpno);
                        EXIT WHEN reglike(arrno) IS NULL ;
                    
                        -- For debug
--                        dbms_output.put_line('TABLE '||TO_CHAR(arrno)||' : '||reglike(arrno)); 
                    
                        arrno := arrno+1;
                        incount := incount+1;
                    
                    END LOOP; -- REGEX INNER LOOP END
                
    
                EXIT WHEN jptcount = 3 ;  
                grpno := grpno+1;
                outcount := outcount + 1;
            
                IF incount = 1 AND reglike(arrno) IS NULL THEN 
                    grpno := 1;
                    jptcount := jptcount + 1;
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
            
                IF inschem = 0 THEN -- check contained schema_name in query
                    SELECT ASIS_COLUMN, NEW_DEF_COL
                    BULK COLLECT INTO deftabs
                    FROM ORADEV.TB_DEF_META
                    WHERE ASIS_TABLE = upper(tablelist(t))
                    AND ASIS_COLUMN IS NOT NULL
                    AND NEW_DEF_COL IS NOT NULL
                    ORDER BY 1 DESC ;
                ELSE 
                    SELECT ASIS_COLUMN, NEW_DEF_COL 
                    BULK COLLECT INTO deftabs
                    FROM ORADEV.TB_DEF_META
                    WHERE ASIS_TABLE = REPLACE(upper(substr(tablelist(t), inschem + 1)),'DBO.','')
                    AND ASIS_SCHEM = upper(substr(tablelist(t), 1, inschem - 1))
                    AND ASIS_COLUMN IS NOT NULL
                    AND NEW_DEF_COL IS NOT NULL
                    ORDER BY 1 DESC ;
                END IF;

                -- For debug
--                dbms_output.put_line(CHR(10)|| ' COUNT : ' || to_char(deftabs.count) || CHR(10));
--                dbms_output.put_line('TABLE : '||tablelist(t));
                IF upper(tablelist(t)) NOT IN ('AND','END','WHEN','THEN','ELSE','AS') THEN             
                    result_conv := result_conv||'TABLE : '||tablelist(t)||CHR(10);
                    -- || CONVERT Column_name ||-------------------------------------------------------------------------
                    IF deftabs.count > 0 THEN 
                        FOR indx IN deftabs.FIRST .. deftabs.LAST -- Compare and convert loop
                            LOOP
    
                                -- For debug
    --                            dbms_output.put_line(CHR(10)|| 'ASIS_COL : ' || to_char(deftabs(indx).asis_col) || CHR(10) ||
    --                                                 'CONV_COL : ' || to_char(deftabs(indx).conv_col));
                            
                                comm1 := deftabs(indx).conv_col||' /*'||deftabs(indx).asis_col||'*/';
                                comm2 := deftabs(indx).conv_col||' /*기존과 같음*/';
                                rech := '';
                            
    --                            IF (instr(query, comm1, 1) = 0) AND (instr(query, comm2, 1) = 0 ) THEN 
                                IF (regexp_count(query, ' \/\*.?'||deftabs(indx).asis_col||'\*\/', 1, 'mni') = 0 ) 
                                AND (regexp_count(query, deftabs(indx).conv_col||' \/\*기존과 같음\*\/', 1, 'mni') = 0 ) THEN 
                                    IF upper(deftabs(indx).asis_col) <> deftabs(indx).conv_col THEN
    
                                        -- For debug
    --                                    dbms_output.put_line('  Changed : '||deftabs(indx).asis_col||'->'||deftabs(indx).conv_col);
                                    
                                        IF regexp_count(query, deftabs(indx).asis_col, 1, 'mni') <> 0 THEN 
                                            result_conv := result_conv||'  Changed : '||deftabs(indx).asis_col||
                                                                        '->'||deftabs(indx).conv_col||CHR(10);

                                            IF regexp_count(query, upper(deftabs(indx).asis_col)||' \/\*기존과 같음\*\/', 1, 'mni') > 0 THEN 
                                                rech := ' \/\*기존과 같음\*\/';
                                            END IF;
                                            comments := comm1;
                                        ELSE 
                                            result_conv := result_conv||'  Not Found in Text : '||deftabs(indx).asis_col||CHR(10);
                                            comments := '';
                                        END IF;
    
                                    ELSIF upper(deftabs(indx).asis_col) = deftabs(indx).conv_col THEN
    
                                        -- For debug
    --                                    dbms_output.put_line('  Passed  : '||deftabs(indx).asis_col||'='||deftabs(indx).conv_col);
    
                                        IF regexp_count(query, deftabs(indx).asis_col, 1, 'mni') <> 0 THEN 
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
                                        FOR r_idx IN 1 .. 8
                                            LOOP 
                                                IF r_idx = 1 THEN spacepatt := 'SELECT\s+'; spacesym := 'SELECT ';
                                                ELSIF r_idx = 2 THEN spacepatt := ',\s*?'; spacesym := ', ';
                                                ELSIF r_idx = 3 THEN spacepatt := 'WHERE\s+'; spacesym := 'WHERE ';
                                                ELSIF r_idx = 4 THEN spacepatt := 'AND\s+'; spacesym := 'AND ';
                                                ELSIF r_idx = 5 THEN spacepatt := 'SET\s+'; spacesym := 'SET ';
                                                ELSIF r_idx = 6 THEN spacepatt := '\(\s*?'; spacesym := '(';
                                                ELSIF r_idx = 7 THEN spacepatt := '\[\s*?'; spacesym := '[';
                                                ELSE spacepatt := '\.'; spacesym := '.';
                                                END IF;
                                            
                                                FOR o_idx IN 1 .. 6
                                                    LOOP
                                                        IF rech IS NULL THEN
                                                            IF o_idx = 1 THEN endpatt := '$'; endcomm := '';
                                                            ELSIF o_idx = 2 THEN endpatt := '\s'; endcomm := ' ';
                                                            ELSIF o_idx = 3 THEN endpatt := '\)'; endcomm := ')';
                                                            ELSIF o_idx = 4 THEN endpatt := '\]'; endcomm := ']';
                                                            ELSIF o_idx = 5 THEN endpatt := '='; endcomm := '=';
                                                            ELSE endpatt := ','; endcomm := ',';
                                                            END IF;
                                                        END IF;
                                                    
                                                    query := regexp_replace(query, spacepatt||deftabs(indx).asis_col||rech||endpatt, spacesym||comments||endcomm, 1, 0, 'mi');
            
                                                END LOOP ;
                                        END LOOP;
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
                    
                        result_conv := result_conv||'  Invalid : Table name was not found in definition table.'||CHR(10);
                    END IF;
                    -- Convert END ---------------------------------------------------------------------------------------
                END IF;
            END LOOP; ------ GET def column list END

        grpno := 93;
    
        UPDATE ORADEV.TB_METACONV 
        SET CONV_TEXT = query, 
            RET_CONV = result_conv, 
            LAST_HANDLE = handler
        WHERE SEQ = queries(idx).seq
        returning seq INTO ret_count(idx);

        -- For debug
--        dbms_output.put_line(CHR(10)||'------------------------------------------------------'||CHR(10)||
--                             queries(idx).seq||' Sequence '||
--                             CHR(10)||'------------------------------------------------------'||CHR(10)||
--                             result_conv||CHR(10)||'-- Query Changed --'||CHR(10)||query||CHR(10));
    
    END LOOP; --------- GET queries END

    IF ret_count IS NOT NULL THEN            
        dbms_output.put_line('Convert query - '||ret_count.count||' rows updated.');
    ELSE
        raise noupdate;
    END IF;
    
    -- || Global Exception Area || 
    EXCEPTION 
        WHEN nodata THEN
            dbms_output.put_line('There is no data to convert.');
        WHEN noupdate THEN
            dbms_output.put_line('There is no data to update check definition table or asis_text datas.');
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