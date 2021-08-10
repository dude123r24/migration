-- migration_gatherdbinfo.sql
-- Script to gather information relevant to migration

set echo off
set term off
set feedback on

set lines 200
set pages 80
column HOST_NAME format a20
column PLATFORM_NAME format a25
column Feature format a50
column Feature_info_substr_65 format a66
column Feature_substr_45 format a46
column STARTUP_TIME format a19
column OPEN_MODE format a10
column DATABASE_ROLE format a14
column VERSION format a12
column OBJECT_NAME format a35
column DATA_TYPE format a30

col spoolfilename new_value spoolfilename
select 'migration_gatherdbinfo_'|| lower(gd.NAME) || '.txt' spoolfilename from v$database   gd;
spool '&spoolfilename'

set term on


Prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Prompt Basic Information
Prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

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


Prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Prompt DB Size
Prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

SELECT
    gd.name, round((
        SELECT
            SUM(bytes) / 1024 / 1024 / 1024 data_size
        FROM
            dba_data_files
    ) +(
        SELECT
            nvl(SUM(bytes), 0) / 1024 / 1024 / 1024 temp_size
        FROM
            dba_temp_files
    ) +(
        SELECT
            SUM(bytes) / 1024 / 1024 / 1024 redo_size
        FROM
            sys.v_$log
    ) +(
        SELECT
            SUM(block_size * file_size_blks) / 1024 / 1024 / 1024 controlfile_size
        FROM
            v$controlfile
    ), 1) "DB_SIZEonDISK_GB"
FROM
    dual , gv$database gd;


SELECT
    round(SUM(bytes) / 1024 / 1024/1024 , 0) DB_USED_SIZE_GB
FROM
    dba_segments
WHERE
    owner NOT IN ( 'CTXSYS', 'DBSNMP', 'EXFSYS', 'LBACSYS', 'MDSYS', 'MGMT_VIEW', 'OLAPSYS', 'ORDDATA', 'OWBSYS', 'ORDPLUGINS', 'ORDSYS', 'OUTLN', 'SI_INFORMTN_SCHEMA', 'SYS', 'SYSMAN', 'SYSTEM', 'WK_TEST', 'WKSYS', 'WKPROXY', 'WMSYS', 'XDB', 'APEX_PUBLIC_USER', 'DIP', 'FLOWS_020100', 'FLOWS_030000', 'FLOWS_040100', 'FLOWS_010600', 'FLOWS_FILES', 'MDDATA', 'ORACLE_OCM', 'SPATIAL_CSW_ADMIN_USR', 'SPATIAL_WFS_ADMIN_USR', 'XS$NULL', 'PERFSTAT', 'SQLTXPLAIN', 'DMSYS', 'TSMSYS', 'WKSYS', 'APEX_040200', 'DVSYS', 'OJVMSYS', 'GSMADMIN_INTERNAL', 'APPQOSSYS', 'MGMT_VIEW', 'ODM', 'ODM_MTR', 'TRACESRV', 'MTMSYS', 'OWBSYS_AUDIT', 'WEBSYS', 'WK_PROXY', 'OSE$HTTP$ADMIN', 'AURORA$JIS$UTILITY$', 'AURORA$ORB$UNAUTHENTICATED', 'DBMS_PRIVILEGE_CAPTURE', 'BI', 'HR', 'IX', 'OE', 'PM', 'SH' , 'PUBLIC' , 'OPS$CJENKINS' ) and owner not like ('APEX_%');

SELECT
    owner,
	round(SUM(bytes) / 1024 / 1024/1024 , 0) SCHEMA_USED_SIZE_GB
FROM
    dba_segments
WHERE
    owner NOT IN ( 'CTXSYS', 'DBSNMP', 'EXFSYS', 'LBACSYS', 'MDSYS', 'MGMT_VIEW', 'OLAPSYS', 'ORDDATA', 'OWBSYS', 'ORDPLUGINS', 'ORDSYS', 'OUTLN', 'SI_INFORMTN_SCHEMA', 'SYS', 'SYSMAN', 'SYSTEM', 'WK_TEST', 'WKSYS', 'WKPROXY', 'WMSYS', 'XDB', 'APEX_PUBLIC_USER', 'DIP', 'FLOWS_020100', 'FLOWS_030000', 'FLOWS_040100', 'FLOWS_010600', 'FLOWS_FILES', 'MDDATA', 'ORACLE_OCM', 'SPATIAL_CSW_ADMIN_USR', 'SPATIAL_WFS_ADMIN_USR', 'XS$NULL', 'PERFSTAT', 'SQLTXPLAIN', 'DMSYS', 'TSMSYS', 'WKSYS', 'APEX_040200', 'DVSYS', 'OJVMSYS', 'GSMADMIN_INTERNAL', 'APPQOSSYS', 'MGMT_VIEW', 'ODM', 'ODM_MTR', 'TRACESRV', 'MTMSYS', 'OWBSYS_AUDIT', 'WEBSYS', 'WK_PROXY', 'OSE$HTTP$ADMIN', 'AURORA$JIS$UTILITY$', 'AURORA$ORB$UNAUTHENTICATED', 'DBMS_PRIVILEGE_CAPTURE', 'BI', 'HR', 'IX', 'OE', 'PM', 'SH' , 'PUBLIC' , 'OPS$CJENKINS' ) and owner not like ('APEX_%')
GROUP BY
    owner
ORDER BY
    SCHEMA_USED_SIZE_GB desc;


Prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Prompt Features Used
Prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

SELECT
    gd.NAME,
    substr(dfus.name,1,45) Feature_substr_45,
    detected_usages,
    currently_used,
    aux_count,
    substr(feature_info,1,65) Feature_info_substr_65,
    first_usage_date,
    last_usage_date,
    last_sample_Date
FROM
    dba_feature_usage_statistics dfus , gv$database gd
WHERE
    detected_usages > 10
ORDER BY gd.NAME, FEATURE_SUBSTR_45;


Prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Prompt Jobs
Prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

SELECT
    gd.NAME, dsj.*
FROM
    dba_scheduler_jobs dsj , gv$database gd
WHERE
        owner NOT IN ( 'CTXSYS', 'DBSNMP', 'EXFSYS', 'LBACSYS', 'MDSYS', 'MGMT_VIEW', 'OLAPSYS', 'ORDDATA', 'OWBSYS', 'ORDPLUGINS', 'ORDSYS', 'OUTLN', 'SI_INFORMTN_SCHEMA', 'SYS', 'SYSMAN', 'SYSTEM', 'WK_TEST', 'WKSYS', 'WKPROXY', 'WMSYS', 'XDB', 'APEX_PUBLIC_USER', 'DIP', 'FLOWS_020100', 'FLOWS_030000', 'FLOWS_040100', 'FLOWS_010600', 'FLOWS_FILES', 'MDDATA', 'ORACLE_OCM', 'SPATIAL_CSW_ADMIN_USR', 'SPATIAL_WFS_ADMIN_USR', 'XS$NULL', 'PERFSTAT', 'SQLTXPLAIN', 'DMSYS', 'TSMSYS', 'WKSYS', 'APEX_040200', 'DVSYS', 'OJVMSYS', 'GSMADMIN_INTERNAL', 'APPQOSSYS', 'MGMT_VIEW', 'ODM', 'ODM_MTR', 'TRACESRV', 'MTMSYS', 'OWBSYS_AUDIT', 'WEBSYS', 'WK_PROXY', 'OSE$HTTP$ADMIN', 'AURORA$JIS$UTILITY$', 'AURORA$ORB$UNAUTHENTICATED', 'DBMS_PRIVILEGE_CAPTURE', 'BI', 'HR', 'IX', 'OE', 'PM', 'SH' , 'PUBLIC' , 'OPS$CJENKINS' ) and owner not like ('APEX_%');


Prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Prompt Triggers
Prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

SELECT
    gd.NAME,
    owner,
    COUNT(1)
FROM
    dba_objects , gv$database gd
WHERE
    object_type = 'TRIGGER'
    AND owner NOT IN ( 'CTXSYS', 'DBSNMP', 'EXFSYS', 'LBACSYS', 'MDSYS', 'MGMT_VIEW', 'OLAPSYS', 'ORDDATA', 'OWBSYS', 'ORDPLUGINS', 'ORDSYS', 'OUTLN', 'SI_INFORMTN_SCHEMA', 'SYS', 'SYSMAN', 'SYSTEM', 'WK_TEST', 'WKSYS', 'WKPROXY', 'WMSYS', 'XDB', 'APEX_PUBLIC_USER', 'DIP', 'FLOWS_020100', 'FLOWS_030000', 'FLOWS_040100', 'FLOWS_010600', 'FLOWS_FILES', 'MDDATA', 'ORACLE_OCM', 'SPATIAL_CSW_ADMIN_USR', 'SPATIAL_WFS_ADMIN_USR', 'XS$NULL', 'PERFSTAT', 'SQLTXPLAIN', 'DMSYS', 'TSMSYS', 'WKSYS', 'APEX_040200', 'DVSYS', 'OJVMSYS', 'GSMADMIN_INTERNAL', 'APPQOSSYS', 'MGMT_VIEW', 'ODM', 'ODM_MTR', 'TRACESRV', 'MTMSYS', 'OWBSYS_AUDIT', 'WEBSYS', 'WK_PROXY', 'OSE$HTTP$ADMIN', 'AURORA$JIS$UTILITY$', 'AURORA$ORB$UNAUTHENTICATED', 'DBMS_PRIVILEGE_CAPTURE', 'BI', 'HR', 'IX', 'OE', 'PM', 'SH' , 'PUBLIC' , 'OPS$CJENKINS' ) and owner not like ('APEX_%')
GROUP BY
    gd.NAME, owner;


Prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Prompt DB Links
Prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

SELECT
    gd.NAME, ddl.*
FROM
    dba_db_links ddl , gv$database gd;


Prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Prompt Object types in database
Prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

SELECT
    gd.name,
    object_type,
    COUNT(1)
FROM
    dba_objects , gv$database gd
WHERE
        owner NOT IN ( 'CTXSYS', 'DBSNMP', 'EXFSYS', 'LBACSYS', 'MDSYS', 'MGMT_VIEW', 'OLAPSYS', 'ORDDATA', 'OWBSYS', 'ORDPLUGINS', 'ORDSYS', 'OUTLN', 'SI_INFORMTN_SCHEMA', 'SYS', 'SYSMAN', 'SYSTEM', 'WK_TEST', 'WKSYS', 'WKPROXY', 'WMSYS', 'XDB', 'APEX_PUBLIC_USER', 'DIP', 'FLOWS_020100', 'FLOWS_030000', 'FLOWS_040100', 'FLOWS_010600', 'FLOWS_FILES', 'MDDATA', 'ORACLE_OCM', 'SPATIAL_CSW_ADMIN_USR', 'SPATIAL_WFS_ADMIN_USR', 'XS$NULL', 'PERFSTAT', 'SQLTXPLAIN', 'DMSYS', 'TSMSYS', 'WKSYS', 'APEX_040200', 'DVSYS', 'OJVMSYS', 'GSMADMIN_INTERNAL', 'APPQOSSYS', 'MGMT_VIEW', 'ODM', 'ODM_MTR', 'TRACESRV', 'MTMSYS', 'OWBSYS_AUDIT', 'WEBSYS', 'WK_PROXY', 'OSE$HTTP$ADMIN', 'AURORA$JIS$UTILITY$', 'AURORA$ORB$UNAUTHENTICATED', 'DBMS_PRIVILEGE_CAPTURE', 'BI', 'HR', 'IX', 'OE', 'PM', 'SH' , 'PUBLIC' , 'OPS$CJENKINS' ) and owner not like ('APEX_%')
GROUP BY
    gd.name, object_type
ORDER BY
    object_type;

SELECT
    gd.name, 
    owner,
    object_type,
    COUNT(1)
FROM
    dba_objects, gv$database gd
WHERE
    object_type IN (
        'EVALUATION CONTEXT',
        'JAVA CLASS',
        'INDEXTYPE',
        'JAVA RESOURCE',
        'LIBRARY',
        'OPERATOR',
        'RULE SET',
        'TRIGGER'
    )
    AND     owner NOT IN ( 'CTXSYS', 'DBSNMP', 'EXFSYS', 'LBACSYS', 'MDSYS', 'MGMT_VIEW', 'OLAPSYS', 'ORDDATA', 'OWBSYS', 'ORDPLUGINS', 'ORDSYS', 'OUTLN', 'SI_INFORMTN_SCHEMA', 'SYS', 'SYSMAN', 'SYSTEM', 'WK_TEST', 'WKSYS', 'WKPROXY', 'WMSYS', 'XDB', 'APEX_PUBLIC_USER', 'DIP', 'FLOWS_020100', 'FLOWS_030000', 'FLOWS_040100', 'FLOWS_010600', 'FLOWS_FILES', 'MDDATA', 'ORACLE_OCM', 'SPATIAL_CSW_ADMIN_USR', 'SPATIAL_WFS_ADMIN_USR', 'XS$NULL', 'PERFSTAT', 'SQLTXPLAIN', 'DMSYS', 'TSMSYS', 'WKSYS', 'APEX_040200', 'DVSYS', 'OJVMSYS', 'GSMADMIN_INTERNAL', 'APPQOSSYS', 'MGMT_VIEW', 'ODM', 'ODM_MTR', 'TRACESRV', 'MTMSYS', 'OWBSYS_AUDIT', 'WEBSYS', 'WK_PROXY', 'OSE$HTTP$ADMIN', 'AURORA$JIS$UTILITY$', 'AURORA$ORB$UNAUTHENTICATED', 'DBMS_PRIVILEGE_CAPTURE', 'BI', 'HR', 'IX', 'OE', 'PM', 'SH' , 'PUBLIC' , 'OPS$CJENKINS' ) and owner not like ('APEX_%')
GROUP BY
    gd.name,
    owner,
    object_type;


Prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Prompt DB Objects that might need special consideration
Prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

SELECT
    gd.name,
    owner,
	object_type,
    count(object_type)
FROM
    dba_objects,
    gv$database gd
WHERE
    owner NOT IN ( 'CTXSYS', 'DBSNMP', 'EXFSYS', 'LBACSYS', 'MDSYS', 'MGMT_VIEW', 'OLAPSYS', 'ORDDATA', 'OWBSYS', 'ORDPLUGINS', 'ORDSYS', 'OUTLN', 'SI_INFORMTN_SCHEMA', 'SYS', 'SYSMAN', 'SYSTEM', 'WK_TEST', 'WKSYS', 'WKPROXY', 'WMSYS', 'XDB', 'APEX_PUBLIC_USER', 'DIP', 'FLOWS_020100', 'FLOWS_030000', 'FLOWS_040100', 'FLOWS_010600', 'FLOWS_FILES', 'MDDATA', 'ORACLE_OCM', 'SPATIAL_CSW_ADMIN_USR', 'SPATIAL_WFS_ADMIN_USR', 'XS$NULL', 'PERFSTAT', 'SQLTXPLAIN', 'DMSYS', 'TSMSYS', 'WKSYS', 'APEX_040200', 'DVSYS', 'OJVMSYS', 'GSMADMIN_INTERNAL', 'APPQOSSYS', 'MGMT_VIEW', 'ODM', 'ODM_MTR', 'TRACESRV', 'MTMSYS', 'OWBSYS_AUDIT', 'WEBSYS', 'WK_PROXY', 'OSE$HTTP$ADMIN', 'AURORA$JIS$UTILITY$', 'AURORA$ORB$UNAUTHENTICATED', 'DBMS_PRIVILEGE_CAPTURE', 'BI', 'HR', 'IX', 'OE', 'PM', 'SH' , 'PUBLIC' , 'OPS$CJENKINS' ) and owner not like ('APEX_%')
    AND object_type NOT IN (
        'INDEX',
        'TABLE',
        'VIEW',
        'SYNONYM',
        'SEQUENCE'
    )
  GROUP BY gd.name, owner, object_type
  ORDER BY gd.name, owner, object_type;


Prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Prompt Possibly incompatible data types
Prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

SELECT
    gd.name, 
    owner,
    data_type,
    COUNT(1)
FROM
    dba_tab_cols , gv$database gd
WHERE
    data_type NOT IN (
        'DATE',
        'CHAR',
        'VARCHAR2',
        'NUMBER'
    )
    AND     owner NOT IN ( 'CTXSYS', 'DBSNMP', 'EXFSYS', 'LBACSYS', 'MDSYS', 'MGMT_VIEW', 'OLAPSYS', 'ORDDATA', 'OWBSYS', 'ORDPLUGINS', 'ORDSYS', 'OUTLN', 'SI_INFORMTN_SCHEMA', 'SYS', 'SYSMAN', 'SYSTEM', 'WK_TEST', 'WKSYS', 'WKPROXY', 'WMSYS', 'XDB', 'APEX_PUBLIC_USER', 'DIP', 'FLOWS_020100', 'FLOWS_030000', 'FLOWS_040100', 'FLOWS_010600', 'FLOWS_FILES', 'MDDATA', 'ORACLE_OCM', 'SPATIAL_CSW_ADMIN_USR', 'SPATIAL_WFS_ADMIN_USR', 'XS$NULL', 'PERFSTAT', 'SQLTXPLAIN', 'DMSYS', 'TSMSYS', 'WKSYS', 'APEX_040200', 'DVSYS', 'OJVMSYS', 'GSMADMIN_INTERNAL', 'APPQOSSYS', 'MGMT_VIEW', 'ODM', 'ODM_MTR', 'TRACESRV', 'MTMSYS', 'OWBSYS_AUDIT', 'WEBSYS', 'WK_PROXY', 'OSE$HTTP$ADMIN', 'AURORA$JIS$UTILITY$', 'AURORA$ORB$UNAUTHENTICATED', 'DBMS_PRIVILEGE_CAPTURE', 'BI', 'HR', 'IX', 'OE', 'PM', 'SH' , 'PUBLIC' , 'OPS$CJENKINS' ) and owner not like ('APEX_%')
GROUP BY
    gd.name, 
    owner,
    data_type
ORDER BY
    owner, data_type;


Prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Prompt Most active schemas 
Prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Ignores all schemas with less than 3 objects. 

SELECT
    owner,
    MAX(last_ddl_time)
FROM
    dba_objects
WHERE
    owner NOT IN ( 'CTXSYS', 'DBSNMP', 'EXFSYS', 'LBACSYS', 'MDSYS', 'MGMT_VIEW', 'OLAPSYS', 'ORDDATA', 'OWBSYS', 'ORDPLUGINS', 'ORDSYS', 'OUTLN', 'SI_INFORMTN_SCHEMA', 'SYS', 'SYSMAN', 'SYSTEM', 'WK_TEST', 'WKSYS', 'WKPROXY', 'WMSYS', 'XDB', 'APEX_PUBLIC_USER', 'DIP', 'FLOWS_020100', 'FLOWS_030000', 'FLOWS_040100', 'FLOWS_010600', 'FLOWS_FILES', 'MDDATA', 'ORACLE_OCM', 'SPATIAL_CSW_ADMIN_USR', 'SPATIAL_WFS_ADMIN_USR', 'XS$NULL', 'PERFSTAT', 'SQLTXPLAIN', 'DMSYS', 'TSMSYS', 'WKSYS', 'APEX_040200', 'DVSYS', 'OJVMSYS', 'GSMADMIN_INTERNAL', 'APPQOSSYS', 'MGMT_VIEW', 'ODM', 'ODM_MTR', 'TRACESRV', 'MTMSYS', 'OWBSYS_AUDIT', 'WEBSYS', 'WK_PROXY', 'OSE$HTTP$ADMIN', 'AURORA$JIS$UTILITY$', 'AURORA$ORB$UNAUTHENTICATED', 'DBMS_PRIVILEGE_CAPTURE', 'BI', 'HR', 'IX', 'OE', 'PM', 'SH' , 'PUBLIC' , 'OPS$CJENKINS' ) and owner not like ('APEX_%')
GROUP BY
    owner 
HAVING
    COUNT(1) > 3
ORDER BY
    owner;

SELECT
    owner,
    object_type,
    MAX(last_ddl_time),
    COUNT(1)
FROM
    dba_objects
WHERE
    owner NOT IN ( 'CTXSYS', 'DBSNMP', 'EXFSYS', 'LBACSYS', 'MDSYS', 'MGMT_VIEW', 'OLAPSYS', 'ORDDATA', 'OWBSYS', 'ORDPLUGINS', 'ORDSYS', 'OUTLN', 'SI_INFORMTN_SCHEMA', 'SYS', 'SYSMAN', 'SYSTEM', 'WK_TEST', 'WKSYS', 'WKPROXY', 'WMSYS', 'XDB', 'APEX_PUBLIC_USER', 'DIP', 'FLOWS_020100', 'FLOWS_030000', 'FLOWS_040100', 'FLOWS_010600', 'FLOWS_FILES', 'MDDATA', 'ORACLE_OCM', 'SPATIAL_CSW_ADMIN_USR', 'SPATIAL_WFS_ADMIN_USR', 'XS$NULL', 'PERFSTAT', 'SQLTXPLAIN', 'DMSYS', 'TSMSYS', 'WKSYS', 'APEX_040200', 'DVSYS', 'OJVMSYS', 'GSMADMIN_INTERNAL', 'APPQOSSYS', 'MGMT_VIEW', 'ODM', 'ODM_MTR', 'TRACESRV', 'MTMSYS', 'OWBSYS_AUDIT', 'WEBSYS', 'WK_PROXY', 'OSE$HTTP$ADMIN', 'AURORA$JIS$UTILITY$', 'AURORA$ORB$UNAUTHENTICATED', 'DBMS_PRIVILEGE_CAPTURE', 'BI', 'HR', 'IX', 'OE', 'PM', 'SH' , 'PUBLIC' , 'OPS$CJENKINS' ) and owner not like ('APEX_%')
GROUP BY
    owner,
    object_type
HAVING
    COUNT(1) > 3
ORDER BY
    owner,
    object_type,
    COUNT(1) DESC;


Prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Prompt Objects with spaces in name 
Prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

SELECT
    owner,
    object_type,
    object_name
FROM
    dba_objects
WHERE
    object_name LIKE '% %' and 
    owner NOT IN ( 'CTXSYS', 'DBSNMP', 'EXFSYS', 'LBACSYS', 'MDSYS', 'MGMT_VIEW', 'OLAPSYS', 'ORDDATA', 'OWBSYS', 'ORDPLUGINS', 'ORDSYS', 'OUTLN', 'SI_INFORMTN_SCHEMA', 'SYS', 'SYSMAN', 'SYSTEM', 'WK_TEST', 'WKSYS', 'WKPROXY', 'WMSYS', 'XDB', 'APEX_PUBLIC_USER', 'DIP', 'FLOWS_020100', 'FLOWS_030000', 'FLOWS_040100', 'FLOWS_010600', 'FLOWS_FILES', 'MDDATA', 'ORACLE_OCM', 'SPATIAL_CSW_ADMIN_USR', 'SPATIAL_WFS_ADMIN_USR', 'XS$NULL', 'PERFSTAT', 'SQLTXPLAIN', 'DMSYS', 'TSMSYS', 'WKSYS', 'APEX_040200', 'DVSYS', 'OJVMSYS', 'GSMADMIN_INTERNAL', 'APPQOSSYS', 'MGMT_VIEW', 'ODM', 'ODM_MTR', 'TRACESRV', 'MTMSYS', 'OWBSYS_AUDIT', 'WEBSYS', 'WK_PROXY', 'OSE$HTTP$ADMIN', 'AURORA$JIS$UTILITY$', 'AURORA$ORB$UNAUTHENTICATED', 'DBMS_PRIVILEGE_CAPTURE', 'BI', 'HR', 'IX', 'OE', 'PM', 'SH' , 'PUBLIC' , 'OPS$CJENKINS' )
ORDER BY
    owner;


Prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Prompt Columns with spaces in name 
Prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

SELECT
    owner,
    table_name,
    column_name
FROM
    dba_tab_cols
WHERE
    column_name LIKE '% %'
and 
    owner NOT IN ( 'CTXSYS', 'DBSNMP', 'EXFSYS', 'LBACSYS', 'MDSYS', 'MGMT_VIEW', 'OLAPSYS', 'ORDDATA', 'OWBSYS', 'ORDPLUGINS', 'ORDSYS', 'OUTLN', 'SI_INFORMTN_SCHEMA', 'SYS', 'SYSMAN', 'SYSTEM', 'WK_TEST', 'WKSYS', 'WKPROXY', 'WMSYS', 'XDB', 'APEX_PUBLIC_USER', 'DIP', 'FLOWS_020100', 'FLOWS_030000', 'FLOWS_040100', 'FLOWS_010600', 'FLOWS_FILES', 'MDDATA', 'ORACLE_OCM', 'SPATIAL_CSW_ADMIN_USR', 'SPATIAL_WFS_ADMIN_USR', 'XS$NULL', 'PERFSTAT', 'SQLTXPLAIN', 'DMSYS', 'TSMSYS', 'WKSYS', 'APEX_040200', 'DVSYS', 'OJVMSYS', 'GSMADMIN_INTERNAL', 'APPQOSSYS', 'MGMT_VIEW', 'ODM', 'ODM_MTR', 'TRACESRV', 'MTMSYS', 'OWBSYS_AUDIT', 'WEBSYS', 'WK_PROXY', 'OSE$HTTP$ADMIN', 'AURORA$JIS$UTILITY$', 'AURORA$ORB$UNAUTHENTICATED', 'DBMS_PRIVILEGE_CAPTURE', 'BI', 'HR', 'IX', 'OE', 'PM', 'SH' , 'PUBLIC' , 'OPS$CJENKINS' )
ORDER BY
    owner;


spool off

exit
