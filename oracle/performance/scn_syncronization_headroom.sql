In the end we to interpret some of the information in the alert log:

Information: 
Wed May 30 15:09:53 2012 
Completed crash recovery at 
Thread 1: logseq 3059, block 19516, scn 12754630269552 
2120 Blocks read 2120 Data Blocks written, 19513 redo BLOCKS read 
..... 
Wed May 30 15:09:57 2012 
Advanced SCN by 68093 minutes worth to 0 × 0ba9.4111a520, by distributed transaction remote logon, remote DB: xxxx. 
Client info: DB logon user xxxx, machine xxxx, program oracle @ xxxx (J001), and OS user oracle 
Here is that, the forward SCN (jump) Ascending 68,098 minutes, the increment of the SCN is 0 × 0ba9.4111a520. Note that the minute calculation is based on of SCN per second maximum possible growth rate to 16K. We calculate: 
The 0 × 0ba94111a520 converted into decimal 12821569053984. 
In the alert log, this information is just open the database crash recovery when scn can be used as the current SCN of the approximate value of 12,754,630,269,552: 
(12821569053984-12754630269552) / 16384/60 = 68093.65278320313 
Value of 16384 SCN DPS maximum possible growth rate, and can see that the calculation result is very close.
Let us calculate the SCN headroom:

SQL> select   
((((
3 ((to_number (to_char (cur_date, 'YYYY')) -1988) * 12 * 31 * 24 * 60 * 60) +
4 ((to_number (to_char (cur_date, 'MM')) -1) * 31 * 24 * 60 * 60) +
5 (((to_number (to_char (cur_date, 'DD')) -1)) * 24 * 60 * 60) +
6 (to_number (to_char (cur_date, 'HH24')) * 60 * 60) +
7 (to_number (to_char (cur_date, 'MI')) * 60) +
8 (to_number (to_char (cur_date, 'SS')))
9) * (16 * 1024)) - 12,821,569,053,984)
10 / (16 * 1024 * 60 * 60 * 24)
11) headroom
12 from (select to_date ('2012-05-30 15:09:57 ',' yyyy-mm-dd hh24: mi: ss') cur_date from dual);
  
HEADROOM
----------   
24.1496113
You can see the results of 24 days, this when _external_scn_rejection_threshold_hours parameter value is 24, that is, one day, although there is such a big jump, but the SCN is still growing success.

Information: 
Wed May 30 12:02:00 2012 
Rejected the attempt to advance SCN over limit by 166 hours worth to 0 × 0ba9.3caec689, by distributed transaction remote logon, remote DB: xxxx. 
Client info: DB logon user xxxx, machine xxxx, program oracle @ xxxx (J000), and OS user oracle 
In this message, rejecting the db link due to increase in SCN. Calculate the SCN Headroom: 
0 × 0ba93caec689 converted into decimal 12821495465609 

The current time is 2012-05-30 12:02:00

SQL> select   
((((
3 ((to_number (to_char (cur_date, 'YYYY')) -1988) * 12 * 31 * 24 * 60 * 60) +
4 ((to_number (to_char (cur_date, 'MM')) -1) * 31 * 24 * 60 * 60) +
5 (((to_number (to_char (cur_date, 'DD')) -1)) * 24 * 60 * 60) +
6 (to_number (to_char (cur_date, 'HH24')) * 60 * 60) +
7 (to_number (to_char (cur_date, 'MI')) * 60) +
8 (to_number (to_char (cur_date, 'SS')))
9) * (16 * 1024)) - 12,821,495,465,609)
10 / (16 * 1024 * 60 * 60 * 24)
11) headroom
12 from (select to_date ('2012-05-30 12:02:00 ',' yyyy-mm-dd hh24: mi: ss') cur_date from dual);
  
HEADROOM
----------   
24.0710752
The this time _external_scn_rejection_threshold_hours parameters is 744, or 31 days, calculated headroom within this threshold, refused to increase the SCN. 
(31-24.0710752) * 24 = 166.2941952, just 166 hours.