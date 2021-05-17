
How to get Oracle execution plans with Starts, E-Rows, A-Rows and A-Time columns
This can probably be found elsewhere as well, but here’s a short wrap-up how to get the most out of your execution plans, quickly

1. Be sure the actual rows and time statistics are collected.
You can do this with

-- login as user sys
alter system set statistics_level = all;

2. Execute your bad SQL.
I can’t give you an example, because I don’t write bad SQL.

3. ;-)

4. Find your sql_id with this STATEMENT

-- these are the most important columns
select last_active_time, sql_id, child_number, sql_text
from v$sql
-- filter for your statement
where upper(sql_fulltext) like
  upper('%[put some text from your SQL statement here]%')
-- this orders by the most recent activity
order by last_active_time desc;

5. Get the cursor and plan for that statement

select rownum, t.* from table(dbms_xplan.display_cursor(
  -- Put the previously retrieved sql_id here
  sql_id => '6dt9vvx9gmd1x',
  -- The cursor child number, in case there are
  -- several plans per cursor
  cursor_child_no => 0,
  -- Some formatting instructions to get Starts,
  -- E-Rows, A-Rows and A-Time
  FORMAT => 'ALL ALLSTATS LAST')) t;

6. Purge the cursors, if needed:

select address || ',' || hash_value from v$sqlarea
where sql_id = '6dt9vvx9gmd1x';
 
begin
  sys.dbms_shared_pool.purge(
    '00000000F3471988,2224337167','C',1);
end;

7. Delete all execution plans
-- login as user sys
alter system flush shared_pool;

8. Delete buffer cache (IO cache)
-- login as user sys
alter system flush buffer_cache;