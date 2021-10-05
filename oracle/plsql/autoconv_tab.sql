
DECLARE
    TYPE        tlist 
    IS
    TABLE OF    varchar2(256)
    INDEX BY    pls_integer;

    queries     clob;
    frompatt    varchar2(46);
    orapattern  varchar2(48);
    joinpattern varchar2(60);
    pattern     varchar2(4000);
    grpno       NUMBER;
    arrno       NUMBER;
    incount     NUMBER;
    outcount    NUMBER;
    jptcount    NUMBER;
    reglike     tlist;
    tablelist   tlist;
    bufferarr   sys.odcivarchar2list;

BEGIN -- PROCEDURE START ------------------------------------------------------------------------------------------
    queries := 'select sid, serial#, username 
                from   v$session vs,2ndtab 2t,(select sql_id from
     v$sql) vsq, select sql_id from v$sql, ss (select id from test11 a, test22 b, test33 c where blah) j1 
               inner join joint2 j2 on j1.id=j2.id left outer join 
               joint3 j3 on j2.id=j3.id right outer join joint4 j4
                on j3.id=j4.id
                where status=''ACTIVE'';';

    grpno :=  1;
    arrno :=  1;
    outcount := 1;
    jptcount := 0 ;
    frompatt := 'FROM\s+([a-z1-9\$\_]{1,})\s*?[a-z1-9\$\_]{0,}?';
    orapattern := '\s*?,\s*?([a-z1-9\$\_]{1,})\s*?[a-z1-9\$\_]{0,}?';
    joinpattern := '.*?\s*?.*?\s*?JOIN\s+([a-z1-9\$\_]{1,})\s*?[a-z1-9\$\_]{0,}?';

    BEGIN -- REGEX BLOCK --------------------------------------------------------------------------------------
        
        -- || get table list in texts ||
        LOOP -- REGEX OUTER LOOP
            incount := 1;    
        
            IF jptcount = 0 THEN 
                IF outcount = 1 THEN
                    pattern := frompatt;     -- SET Pattern oracle join
                ELSE 
                    pattern := pattern || orapattern;
                END IF;
            ELSE
                    pattern := joinpattern;  -- SET Pattern ansi join
            END IF; 

                LOOP -- REGEX INNER LOOP
                    reglike(arrno) := regexp_substr(queries, pattern ,1,incount,'mni',grpno);
                    EXIT WHEN reglike(arrno) IS NULL ;
                    -- For debug
                    -- dbms_output.put_line('TABLE '||TO_CHAR(arrno)||' : '||reglike(arrno)); 
                
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
            -- dbms_output.put_line('jpt '||TO_CHAR(jptcount)||' inc '||TO_CHAR(incount)||' grp '||TO_CHAR(grpno));
            -- dbms_output.put_line('outc '||TO_CHAR(outcount)||' pattern '||pattern);
    
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
    bufferarr := sys.odcivarchar2list();
    FOR r IN 1..arrno-1
        LOOP
            -- For debug
            -- dbms_output.put_line(r||' : '||reglike(r));
            
            bufferarr.extend;
            bufferarr(r) := reglike(r);     

            -- dbms_output.put_line(bufferarr(r));
    END LOOP;
    
    SELECT DISTINCT column_value 
           BULK COLLECT INTO tablelist 
    FROM table(bufferarr) 
    WHERE column_value IS NOT NULL;

    -- For debug
    dbms_output.put_line(CHR(10));
    FOR t IN 1..tablelist.count
        LOOP
            IF length(t) = 1 THEN
                dbms_output.put_line('0'||t||' : '|| tablelist(t));
            ELSE
                dbms_output.put_line(t||' : '|| tablelist(t));
            END IF;
    END LOOP;

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
