Here is the example how I loaded your data into my external table and created another table from it.

[oracle@testsrv1 Desktop]$ cat user.tbl 
 1|john|email@email.com|active
[oracle@testsrv1 Desktop]$ sqlplus / as sysdba

SQL*Plus: Release 11.2.0.4.0 Production on Thu Mar 3 06:45:26 2016

Copyright (c) 1982, 2013, Oracle.  All rights reserved.


Connected to:
Oracle Database 11g Enterprise Edition Release 11.2.0.4.0 - 64bit Production
With the Partitioning, Automatic Storage Management, OLAP, Data Mining
and Real Application Testing options

SQL> create user user1 identified by user1;

User created.

SQL> create directory user_dir as '/home/oracle/Desktop';

Directory created.


SQL> grant resource, connect to user1;

Grant succeeded.

SQL> grant read, write on directory user_dir to user1;

Grant succeeded.

SQL> conn user1/user1
Connected.

SQL> create table user_load(user_id number, name varchar2(20), email varchar2(50), status varchar2(10))
organization external
(default directory user_dir
access parameters
(fields terminated by '|')
location('user.tbl')
);   

Table created.

/* For Oracle_loder options 
SQL> CREATE TABLE emp_load
  2    (employee_number      CHAR(5),
  3     employee_dob         CHAR(20),
  4     employee_last_name   CHAR(20),
  5     employee_first_name  CHAR(15),
  6     employee_middle_name CHAR(15),
  7     employee_hire_date   DATE)
  8  ORGANIZATION EXTERNAL
  9    (TYPE ORACLE_LOADER
 10     DEFAULT DIRECTORY def_dir1
 11     ACCESS PARAMETERS
 12       (RECORDS DELIMITED BY NEWLINE
 13        FIELDS (employee_number      CHAR(2),
 14                employee_dob         CHAR(20),
 15                employee_last_name   CHAR(18),
 16                employee_first_name  CHAR(11),
 17                employee_middle_name CHAR(11),
 18                employee_hire_date   CHAR(10) date_format DATE mask "mm/dd/yyyy"
 19               )
 20       )
 21     LOCATION ('info.dat')
 22    );
 
Table created.
 */

SQL> select * from user_load;

   USER_ID NAME          EMAIL                  STATUS
---------- ----------   -------------------    ----------
     1 john         email@email.com        active


SQL> create table final as select * from user_load;

Table created

SQL> select * from final;

   USER_ID NAME          EMAIL                  STATUS
---------- ----------   -------------------    ----------
     1 john         email@email.com        active