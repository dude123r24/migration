-- directories_files.sql

set echo off
set term off
set feedback on

set lines 200
set pages 80
column HOST_NAME format a20
column PLATFORM_NAME format a25
column STARTUP_TIME format a19

column name format a40
column value format a60

column TABLESPACE_NAME format a20
column FILE_NAME format a60
column FILENAME format a60
column member format a40
column IS_RECOVERY_DEST_FILE format a22
column MEMBER format a50
col spoolfilename new_value spoolfilename
select 'directories_files_'|| lower(gd.NAME) || '.txt' spoolfilename from v$database   gd;
spool '&spoolfilename'

set term on


Prompt #########################################
Prompt Basic Information
Prompt #########################################

SELECT
    instance_name,
    host_name,
    platform_name,
    version,
    to_char(startup_time, 'dd-mon-yyyy hh24:mi') startup_time,
    created,
    resetlogs_time,
    open_mode,
    protection_mode,
    database_role,
    dataguard_broker,
    log_mode
FROM
    gv$instance   gi,
    gv$database   gd
WHERE
    gi.inst_id = gd.inst_id;


Prompt #########################################
Prompt Datafiles (db_create_file_dest)
Prompt #########################################

select tablespace_name, file_name from dba_data_files ;


Prompt #########################################
Prompt Recovery file dest (db_create_file_dest)
Prompt #########################################

select name, value from v$parameter where name = 'db_create_file_dest' ;


Prompt #########################################
Prompt Redo Logs
Prompt #########################################

select group#, member, IS_RECOVERY_DEST_FILE from v$logfile;

Prompt #########################################
Prompt ControlFiles
Prompt #########################################

column value format a150
select name, value from v$parameter where name = 'control_files' ;
column value format a60

Prompt #########################################
Prompt Audit Files (audit_file_dest)
Prompt #########################################

select name, value from v$parameter where name = 'audit_file_dest' ;

Prompt #########################################
Prompt Recovery file dest (db_recovery_file_dest)
Prompt #########################################

select name, value from v$parameter where name = 'db_recovery_file_dest' ;

Prompt #########################################
Prompt Archive log dest
Prompt #########################################

select name, value from v$parameter where name = 'log_archive_dest' or  name = 'log_archive_dest_1' or name = 'log_archive_dest_state_1' ;

archive log list


Prompt #########################################
Prompt Block Change Tracking
Prompt #########################################

select * from V$BLOCK_CHANGE_TRACKING ;


spool off