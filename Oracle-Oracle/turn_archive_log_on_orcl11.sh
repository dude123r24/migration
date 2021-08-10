export ORACLE_SID=ORCLTEST
export ORAENV_ASK=NO
. oraenv
export ORAENV_ASK=YES


sqlplus / as sysdba <<EOF
   alter system set log_archive_dest_1='LOCATION=/u01/oradata/ORCLTEST/archivelogs' scope = both;
   shutdown immediate
   startup mount
   alter database archivelog;
   alter database open;

   ALTER DATABASE ENABLE BLOCK CHANGE TRACKING USING FILE '/u01/oradata/ORCLTEST/block_chage_tracking.dbf';

   exit
EOF


