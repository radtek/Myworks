set colsep ,      -- column saperator
set headsep off   -- no heading
set pagesize 0    -- no output pages
set trimspool on  -- trim whitespace after last word.

spool spoolfile.csv

SELECT department_id FROM HR.EMPLOYEES;

spool off