# Add 2 redo members to existing groups and remove the older redo members as they were in the wrong location.

sqlplus -s / as sysdba 2>&1 > /dev/null <<EOF
whenever sqlerror exit sql.sqlcode;
set echo off 
set verify off
set feedback off
set term off
set head off
set pages 1000
set lines 200
column cmd format a180
spool /tmp/redologs_relocate.sql
select 'alter database add logfile member ' || '''' || '/u01/oradata/onlinelogs/' || substr (MEMBER, instr( MEMBER, '/', -1)+1, instr( MEMBER, '.', -1)-instr( MEMBER, '/', -1)-1 )||'a' || substr (MEMBER, instr( MEMBER, '.', -1) ) || '''' || ' to group ' || GROUP# || ' ;' cmd from v\$logfile ;
select 'alter database add logfile member ' || '''' || '/u01/oradata/onlinelogs/' || substr (MEMBER, instr( MEMBER, '/', -1)+1, instr( MEMBER, '.', -1)-instr( MEMBER, '/', -1)-1 )||'b' || substr (MEMBER, instr( MEMBER, '.', -1) ) || '''' || ' to group ' || GROUP# || ' ;' cmd from v\$logfile ;

select 'alter system archive log current;' cmd from v\$log ;
select 'alter database clear logfile group ' || GROUP# || ' ;' cmd from v\$log;
select 'alter database drop logfile member ' || '''' || member || '''' || ' ;' cmd from v\$logfile ;
select 'alter system archive log current;' cmd from v\$log ;
select 'alter database drop logfile member ' || '''' || member || '''' || ' ;' cmd from v\$logfile ;

spool off
exit
EOF

sqlplus / as sysdba @/tmp/redlogs_relocate.sql

sqlplus / as sysdba <<EOF
whenever sqlerror exit sql.sqlcode;
set echo off 
set verify off
set pages 1000
set lines 200
column member format a50
select group#, status from v\$log;
select group#, member from v\$logfile order by 1;
EOF


