RMAN Backup and Restore Validate 옵션

-- Backup file validate 수행, 실제로 백업이나 리스토어 되지는 않음
-- 날짜는 "to_date('2018-07-19 22:58:37','YYYY-MM-DD HH24:MI:SS')" 형태로 사용가능
RMAN> restore database until time '14-JUL-18' validate ;

-- archive는 database validate 수행시 함께 검증되지 않는다. 따로수행해야한다.
-- archivelog과 archivelog backupset을 함께 체크하면서 검증한다.
RMAN> restore archivelog from time '13-JUL-18' until time '17-JUL-18' validate ;

