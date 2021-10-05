
DECLARE
    TYPE tlist IS
    TABLE OF varchar2(1000)
    INDEX BY pls_integer;

    queries clob;
    grpno NUMBER;
    arrno NUMBER;
    atcount NUMBER;
    reglike tlist;
    tablelist tlist;
    bufferarr sys.odcivarchar2list;

BEGIN
    queries := 'select sid, serial#, username 
                from   v$session vs,2ndtab 2t,(select sql_id from
     v$sql) vsq, select sql_id from v$sql, ss (select id from test11, test22 where blah)
                where status=''ACTIVE'';';

    grpno := 1;
    arrno := 1;

    -- || Starting get table list in texts || -----------------------------------------------------
    LOOP -- OUTER LOOP
        atcount := 1;    
        EXIT WHEN grpno > 6;
    
        LOOP -- INNER LOOP
            reglike(arrno) := regexp_substr(queries, 'FROM\s+([a-z1-9\$\_]{1,})(\s+)?([a-z1-9\$\_]{0,}?(\s+)?,(\s+)?([a-z1-9\$\_]{1,})?(\s+)?[a-z1-9\$\_]{0,}?)?',1,atcount,'mni',grpno);
        
            EXIT WHEN atcount = 10; --need CHANGE!!!!=====================================================<<<<<
            dbms_output.put_line('TABLE '||TO_CHAR(arrno)||' : '||reglike(arrno));
        
            arrno := arrno+1;
            atcount := atcount+1;
        
        END LOOP; -- INNER LOOP END
        
        grpno := grpno+5;
    
    END LOOP; -- OUTER LOOP END

    --dbms_output.put_line(chr(10));

    -- || Get rid of duplicated values || ---------------------------------------------------------
    grpno := grpno+1;
    bufferarr := sys.odcivarchar2list();
    FOR r IN 1..arrno-1
        LOOP
            --dbms_output.put_line(r||' : '||reglike(r));
            
            bufferarr.extend;
            bufferarr(r) := reglike(r);     
            --dbms_output.put_line(bufferarr(r));
        END LOOP;
    
    SELECT DISTINCT column_value 
           BULK COLLECT INTO tablelist 
    FROM table(bufferarr) 
    WHERE column_value IS NOT NULL;

    grpno := grpno+1;

    FOR t IN 1..tablelist.count
        LOOP 
            dbms_output.put_line(tablelist(t));
        END LOOP;



    -- || Exception Area || -----------------------------------------------------------------------
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
END;

