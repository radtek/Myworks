
Script for Oracle data buffer contents 

One of the most important areas of Oracle tuning is the management of the RAM data buffers. Oracle performance will be dramatically improved if you can avoid a physical disk I/O by storing a data block inside the RAM memory of the data buffer caches. Historically, an Oracle professional would allocate an area of RAM cache with a size defined by the db_block_buffers (db_cache_size in Oracle 9i) parameter, and leave it to Oracle to manage the data blocks within this RAM area. But with the advent of support for multiple block sizes in Oracle 9i, you can manage each individual data buffer pool and segregate tables and indexes into separate data buffers.

Oracle caching in a nutshell

 When a SQL statement requests a row from a table, Oracle first checks the internal memory structures to see if the data is already in a data buffer. If the requested data is there, it's returned, saving a physical IO operation. With the very large SGAs in some 64-bit releases of Oracle, small databases can be entirely cached.

For very large databases, however, the RAM data buffers cannot hold all of the database blocks. 
Oracle has a scheme for keeping frequently used blocks in RAM. When there isn't enough room in the data buffer for the whole database, Oracle utilizes a least-recently-used algorithm to determine which database pages are to be flushed from memory. Oracle keeps an in-memory control structure for each block in the data buffer: New data blocks are inserted at the middle of the data buffer, and every time a block is requested, it is moved to the front of the list. Data blocks that aren't frequently referenced will wind up at the end of the data buffer where they will eventually be erased to make room for a new data block.

 Starting in Oracle 8, Oracle provides three separate pools of RAM to hold incoming Oracle data blocks:
•KEEP pool is used to hold tables that are frequently referenced by the application, such as small tables that have frequent full table scans and reference tables for the application. 
  
•RECYCLE pool is reserved for large tables that experience full table scans that are unlikely to be reread. The RECYCLE pool is used so that the incoming data blocks don't flush out data blocks from more frequently used tables and indexes. 
  
•DEFAULT pool is used for all table and index accesses that aren't appropriate for the KEEP or RECYCLE pools.

Remember, the KEEP and RECYCLE pools are subsets of the DEFAULT pool. Now that I've explained the basic mechanisms of the Oracle data buffers, let's look at how data dictionary queries can help you view the internal contents of the buffers.

Dictionary queries for data buffers

 Oracle provides the v$bh view to allow you to view the contents of the data buffers, along with the number of blocks for each segment type in the buffer. This view is especially useful when you are using multiple data buffers and you want to know the amount of caching used for tables and indexes. Joining the  v$bh view with dba_objects gives you a block-by-block listing of your data buffer contents and shows you how well your data buffers are caching table and index contents.

 The script in Listing A formats the data buffer information into a great report you can use to monitor the data buffer activity in your database. Figure A shows the output from this report.



  
Figure A 
 
Data buffer activity report 

 

Listing A

set pages 999

set lines 80

 

spool blocks.lst

 

ttitle 'Contents of Data Buffers'

 

drop table t1;

 

create table t1 as

select

   o.object_name    object_name,

   o.object_type    object_type,

   count(1)         num_blocks

from

   dba_objects  o,

   v$bh         bh

where

   o.object_id  = bh.objd

and

   o.owner not in ('SYS','SYSTEM')

group by

   o.object_name,

   o.object_type

order by

   count(1) desc

;

 

 

column c1 heading "Object|Name"                 format a30

column c2 heading "Object|Type"                 format a12

column c3 heading "Number of|Blocks"            format 999,999,999,999

column c4 heading "Percentage|of object|data blocks|in Buffer" format 999

 

select

   object_name       c1,

   object_type       c2,

   num_blocks        c3,

   (num_blocks/decode(sum(blocks), 0, .001, sum(blocks)))*100 c4

from

   t1,

   dba_segments s

where

   s.segment_name = t1.object_name

and

   num_blocks > 10

group by

   object_name,

   object_type,

   num_blocks

order by

   num_blocks desc

;


 A full-featured script (written by Randy Cunningham) to display details about the buffer contents is available in the online code depot in the book  Oracle Tuning: the Definitive Reference.  Here is the script, reproduced with permission:


             buf_blocks.sql

 


 ******************************************************************

--   Contents of Data Buffers
 ******************************************************************

 

set pages 999

set lines 92

 

ttitle 'Contents of Data Buffers'

 

drop table t1;

 

create table t1 as

select

   o.owner          owner,

   o.object_name    object_name,

   o.subobject_name subobject_name,

   o.object_type    object_type,

   count(distinct file# || block#)         num_blocks

from

   dba_objects  o,

   v$bh         bh

where

   o.data_object_id  = bh.objd

and

   o.owner not in ('SYS','SYSTEM')

and

   bh.status != 'free'

group by

   o.owner,

   o.object_name,

   o.subobject_name,

   o.object_type

order by

   count(distinct file# || block#) desc

;

 

column c0 heading "Owner"                                    format a12

column c1 heading "Object|Name"                              format a30

column c2 heading "Object|Type"                              format a8

column c3 heading "Number of|Blocks in|Buffer|Cache"         format 99,999,999

column c4 heading "Percentage|of object|blocks in|Buffer"    format 999

column c5 heading "Buffer|Pool"                              format a7

column c6 heading "Block|Size"                               format 99,999

 

select

   t1.owner                                          c0,

   object_name                                       c1,

   case when object_type = 'TABLE PARTITION' then 'TAB PART'

        when object_type = 'INDEX PARTITION' then 'IDX PART'

        else object_type end c2,

   sum(num_blocks)                                     c3,

   (sum(num_blocks)/greatest(sum(blocks), .001))*100 c4,

   buffer_pool                                       c5,

   sum(bytes)/sum(blocks)                            c6

from

   t1,

   dba_segments s

where

   s.segment_name = t1.object_name

and

   s.owner = t1.owner

and

   s.segment_type = t1.object_type

and

   nvl(s.partition_name,'-') = nvl(t1.subobject_name,'-')

group by

   t1.owner,

   object_name,

   object_type,

   buffer_pool

having

   sum(num_blocks) > 10

order by

   sum(num_blocks) desc

;

A sample listing from this exciting report is shown below.  We can see that the report lists the tables and indexes that reside inside the data buffer.  This is important information for the Oracle professional who needs to know how many blocks for each object reside in the RAM buffer.  To effectively manage the limited RAM resources, the Oracle DBA must be able to know the ramifications of decreasing the size of the data buffer caches. 

Here is the report from  buf_blocks.sql when run against a large Oracle data warehouse (Listing 3.2).

 


                            Contents of Data Buffers

  

                                              Number of Percentage

                                              Blocks in of object

              Object            Object        Buffer    Buffer  Buffer    Block

 Owner        Name              Type          Cache     Blocks  Pool       Size

 ------------ -------------------------- ----------- ---------- ------- -------

 DW01         WORKORDER         TAB PART      94,856          6 DEFAULT   8,192

 DW01         HOUSE             TAB PART      50,674          7 DEFAULT  16,384

 ODSA         WORKORDER         TABLE         28,481          2 DEFAULT  16,384

 DW01         SUBSCRIBER        TAB PART      23,237          3 DEFAULT   4,096

 ODS          WORKORDER         TABLE         19,926          1 DEFAULT   8,192

 DW01         WRKR_ACCT_IDX     INDEX          8,525          5 DEFAULT  16,384

 DW01         SUSC_SVCC_IDX     INDEX          8,453         38 KEEP     32,768

 DW02         WRKR_DTEN_IDX     IDX PART       6,035          6 KEEP     32,768

 DW02         SUSC_SVCC_IDX     INDEX          5,485         25 DEFAULT  16,384

 DW02         WRKR_LCDT_IDX     IDX PART       5,149          5 DEFAULT  16,384

 DW01         WORKORDER_CODE    TABLE          5,000          0 RECYCLE  32,768

 DW01         WRKR_LCDT_IDX     IDX PART       4,929          4 KEEP     32,768

 DW02         WOSC_SCDE_IDX     INDEX          4,479          6 KEEP     32,768

 DW01         SBSC_ACCT_IDX     INDEX          4,439          8 DEFAULT  32,768

 DW02         WRKR_WKTP_IDX     IDX PART       3,825          7 KEEP     32,768

 DB_AUDIT     CUSTOMER_AUDIT    TABLE          3,301         99 DEFAULT   4,096

 DW01         WRKR_CLSS_IDX     IDX PART       2,984          5 KEEP     32,768

 DW01         WRKR_AHWO_IDX     INDEX          2,838          2 DEFAULT  32,768

 DW01         WRKR_DTEN_IDX     IDX PART       2,801          5 KEEP     32,768

As you can see from Listing A, this report can give you some valuable insight into the tables and indexes that reside inside the data buffer. If you happen to have limited RAM resources for the data buffer caches, this report can show you the number of blocks that currently reside in the buffer for each object.

 Oracle's midpoint insertion algorithm tends to segregate each buffer into "hot" and "cold" areas, depending on the frequency with which each data block is read. Each time a data block is re-referenced, it moves to the head of the data block chain on the "hot" side of the data buffer. I find it interesting to run the report repeatedly to watch the data blocks move from cold to hot and back again.
 
 
 
 
 
