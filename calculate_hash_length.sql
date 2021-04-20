--Loop Cursor -----------------------------------------------------------------------------
SET serveroutput ON;
DECLARE 
    TYPE tablelist 
    IS TABLE OF VARCHAR2(4000)
    INDEX BY pls_integer;

    rawlist tablelist;
    hashlist tablelist;
    l_start NUMBER;
BEGIN
	l_start := DBMS_UTILITY.GET_TIME;
	FOR idx IN 1 .. 1000
	LOOP
        rawlist(idx) := LPAD('1', idx, 'A');
	    hashlist(idx) := fn_sec_sh256(rawlist(idx));
        DBMS_OUTPUT.PUT_LINE('RAW LENGTH : ' || LENGTH(rawlist(idx)) ||
                              ' => HASH LENGTH : ' || LENGTH(hashlist(idx)));
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('Elapsed time : ' || (DBMS_UTILITY.GET_TIME - l_start));
END ;
--Use Implicit Cursor #1 ----------------------------------------------------------------------------
SET serveroutput ON;
DECLARE 
    TYPE tablelist
    IS TABLE OF VARCHAR2(4000)
    INDEX BY pls_integer;

    -- rawlist dual.rawcol%type;
    rawlist tablelist;
    hashlist tablelist;
    l_start NUMBER;
BEGIN
    l_start := DBMS_UTILITY.GET_TIME;
    
    SELECT LPAD('1', LEVEL, 'A') 
    BULK COLLECT INTO rawlist
    FROM dual 
    CONNECT BY LEVEL < 1001;

    FOR idx IN 1 .. rawlist.count
    LOOP
        hashlist(idx) := fn_sec_sh256(rawlist(idx));
        DBMS_OUTPUT.PUT_LINE('RAW LENGTH : ' || LENGTH(rawlist(idx)) ||
                              ' => HASH LENGTH : ' || LENGTH(hashlist(idx)));
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('Elapsed time : ' || (DBMS_UTILITY.GET_TIME - l_start));
END ;
--Use Explicit Cursor #2 ---------------------------------------------------------------------------- 
SET serveroutput ON;
DECLARE
    CURSOR rawlist_cur
    IS 
    SELECT LPAD('1',LEVEL,'A') AS RAWCOL
    FROM dual
    CONNECT BY LEVEL < 1001;

    TYPE rawlist_table_type
    IS
    TABLE OF rawlist_cur%rowtype
    INDEX BY pls_integer;

    l_rawlist  rawlist_table_type;
    l_rawcol   VARCHAR2(4000);
    l_hashlist VARCHAR2(4000);
    l_start NUMBER;
BEGIN
	l_start := DBMS_UTILITY.GET_TIME;

	OPEN rawlist_cur;
    LOOP
        FETCH rawlist_cur
        BULK COLLECT INTO l_rawlist LIMIT 100;
        EXIT WHEN l_rawlist.count = 0;
	  FOR idx IN 1 .. l_rawlist.count 
      LOOP 
        -- system.fn_sec_sh256 
        -- or 
        -- system.pkg_crypt.fn_encrypt_aes
        l_rawcol := l_rawlist(idx).rawcol;
       -- l_hashlist := system.fn_sec_sh256(l_rawcol);  
        l_hashlist := system.pkg_crypt.fn_encrypt_aes(l_rawcol);

        DBMS_OUTPUT.PUT_LINE('RAW LENGTH : ' || LENGTH(l_rawcol) || 
                             ' => HASH LENGTH : ' || LENGTH(l_hashlist)); 
      EXIT WHEN l_rawlist.count=0;
      END LOOP;
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('Elapsed time : ' || (DBMS_UTILITY.GET_TIME - l_start));
	
	EXCEPTION
		WHEN OTHERS THEN
			DBMS_OUTPUT.PUT_LINE( SQLCODE || '-' || SQLERRM );
		RAISE;
END;
