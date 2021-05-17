Here are the steps that needs to be carried out to re-install the JAVA Virtual Machine.

1.To uninstall (if already installed) the current installation of JAVA Virtual Machine, execute the following scripts at the SQL prompt connected as sys user.

  startup mount;
  alter system set "_system_trig_enabled" = false scope=memory;
  alter system enable restricted session;
  alter database open;
  @?/rdbms/admin/catnojav.sql
  @?/xdk/admin/rmxml.sql
  @?/javavm/install/rmjvm.sql
  truncate table java$jvm$status;

Once all the above commands have been executed successfully, restart the database. Shutdown of the database is necessary to ensure that the changes are synchronized with the disk after removal of JAVA Virtual Machine.

2.To install the JAVA Virtual Machine execute the following scripts at the SQL prompt connected as sys user.

startup mount
alter system set "_system_trig_enabled" = false scope=memory;
alter database open;
@?/javavm/install/initjvm.sql
@?/xdk/admin/initxml.sql
@?/xdk/admin/xmlja.sql
@?/rdbms/admin/catjava.sql
shutdown immediate;

3.Start the database and resolve any INVALID objects by executing the utlrp.sql script.


@?/rdbms/admin/utlrp.sql

Now the JVM should be fully installed and functional.


SQL> select comp_name, version, status from dba_registry;

Please go through Knowlege Mgmt Note ID  757771.1 How to Reload the JVM in 10.1.0.X and 10.2.0.X in Oracle Support (formerly metalink ) to go through a much detailed step by step process (with video) to resolve any issues that you may be facing. This note also consists of several other Notes that resolve different issues.
