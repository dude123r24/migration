# 11107_11204_backup_and_transfer.sh

# Make sure archiving is on
# Make sure block change tracking file is present

#!/bin/bash

# Upgrading 11.1.0.7 to 11.2.0.4
# Created to test upgrading 11.1.0.7 TEST DATABASE on orazoracol01 to 11.2.0.4 on orazoracol02 (different server)


############### SOURCE Server


if [ $# -lt 3 ]; then
  echo "\nERROR  : `date +"%Y_%m_%d:%H_%M_%S"`: Usage: 11107_11204_backup_and_transfer.sh Backup_level date(YYYY_MM_DD) ORACLE_SID **********"
  exit
elif [ ! -z $hardcode ]; then
  export l_bkup_level=0
  export l_date=2021_06_28
  export SOURCE_ORACLE_SID=ORCL11
  export TARGET_ORACLE_SID=${SOURCE_ORACLE_SID}
else
  export l_bkup_level=$1
  export l_date=$2
  export SOURCE_ORACLE_SID=$3
  export SOURCE_ORACLE_SID=$3
  export TARGET_ORACLE_SID=${SOURCE_ORACLE_SID}
fi



if [ -z "$l_date" ]; then
  export l_date=`date +"%Y_%m_%d"`
fi 
if [ -z "$l_bkup_level" ]; then
  export l_bkup_level=0
fi 

if [ -z ${SOURCE_ORACLE_SID} ]; then 
  echo "\nERROR  : `date +"%Y_%m_%d:%H_%M_%S"`: MISSING ORACLE_SID value. "
  exit
fi  

# export SOURCE_ORACLE_SID=ORCL11


export ORACLE_VERSION="11.2.0.4"
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=${ORACLE_BASE}/product/${ORACLE_VERSION}/dbhome_1
export PATH=${ORACLE_HOME}/bin:$PATH

export SOURCE_SERVER="158.119.102.35"
export TARGET_SERVER="158.119.102.36"
export SOURCE_SSH_USER=itsysadm
export TARGET_SSH_USER=itsysadm
export db_recovery_file_dest="/u01/flash_recovery_area"
export ORACLE_11107_HOME="${ORACLE_BASE}/product/${ORACLE_VERSION}/dbhome_1"
export ORACLE_11204_HOME="${ORACLE_BASE}/product/${ORACLE_VERSION}/dbhome_1"
export ORACLE_19C_HOME="${ORACLE_BASE}/product/${ORACLE_VERSION}/dbhome_1"
export DATA_HOME="/u01/oradata/"


export ORACLE_SID=$SOURCE_ORACLE_SID
export ORAENV_ASK=NO
. oraenv
export ORAENV_ASK=YES


sqlplus -s / as sysdba <<EOF
set echo off 
set feedback off 
set verify off

set lines 200
set pages 100
SELECT TO_CHAR(completion_time, 'YYYY-MON-DD') completion_time, type, round(sum(bytes)/1048576) MB, round(sum(elapsed_seconds)/60) time
FROM
(
SELECT
CASE
  WHEN s.backup_type='L' THEN 'ARCHIVELOG'
  WHEN s.controlfile_included='YES' THEN 'CONTROLFILE'
  WHEN s.backup_type='D' AND s.incremental_level=0 THEN 'LEVEL0'
  WHEN s.backup_type='I' AND s.incremental_level=1 THEN 'LEVEL1'
END type,
TRUNC(s.completion_time) completion_time, p.bytes, s.elapsed_seconds
FROM v\$backup_piece p, v\$backup_set s
WHERE p.status='A' AND p.recid=s.recid
UNION ALL
SELECT 'DATAFILECOPY' type, TRUNC(completion_time), output_bytes, 0 elapsed_seconds FROM v\$backup_copy_details
)
GROUP BY TO_CHAR(completion_time, 'YYYY-MON-DD'), type
ORDER BY 1 ASC,2,3
;

EOF


if [ $l_bkup_level = 0 ]; then

echo "++++++++++ Creating Backup Incremental Level 0 (also cleaning up expired and obsolete backups) ++++++++++"

rman target / <<EOF
CONFIGURE CONTROLFILE AUTOBACKUP ON;
backup incremental level 0 database tag 'db-lvl-0' plus archivelog  tag 'arch-lvl-0';
# backup database tag 'db-lvl-0' plus archivelog  tag 'arch-lvl-0';
EOF

elif [ $l_bkup_level = 1 ]; then

echo "++++++++++ Creating Backup Incremental Level 1 (also cleaning up expired and obsolete backups) ++++++++++"

rman target / <<EOF
CONFIGURE CONTROLFILE AUTOBACKUP ON;
backup incremental level 1 CUMULATIVE database tag 'db-lvl-1' plus archivelog  tag 'arch-lvl-1';
EOF

else
echo "********** ERROR: no backup taken as backup level isn't 1 or 2 **********"
exit
fi


# Get the SCN number till which recovery will be performed on TARGET database. The SCN number is written to a file on the TARGET SERVER
export SCN=$(sqlplus -s / as sysdba <<EOF
set pagesize 0 feedback off verify off heading off echo off;
select * from (select NEXT_CHANGE# from v\$archived_log order by sequence# desc) where rownum=1;
exit;
EOF
)

echo $SCN > /tmp/${ORACLE_SID}_SCN

sudo su - ${SOURCE_SSH_USER} -c "scp -r /tmp/${ORACLE_SID}_SCN ${TARGET_SSH_USER}@${TARGET_SERVER}:/tmp/"

# Backup Size is 356G for L0


if [ $l_bkup_level = 0 ]; then

  if [ -z $db_recovery_file_dest ]; then 
    echo "ERROR: Environment variables are not set"
  else
    echo "++++++++++ Cleaning up staging directory on ${TARGET_SERVER} ++++++++++"
    sudo su - ${SOURCE_SSH_USER} -c "ssh  ${TARGET_SSH_USER}@${TARGET_SERVER} \"sudo rm -rf ${db_recovery_file_dest}/$ORACLE_SID/autobackup/$l_date\""

    sudo su - ${SOURCE_SSH_USER} -c "ssh  ${TARGET_SSH_USER}@${TARGET_SERVER} \"sudo rm -rf ${db_recovery_file_dest}/$ORACLE_SID/backupset/$l_date\""
    
    sudo su - ${SOURCE_SSH_USER} -c "ssh  ${TARGET_SSH_USER}@${TARGET_SERVER} \"mkdir -p /tmp/$ORACLE_SID/\""

    sudo su - ${SOURCE_SSH_USER} -c "ssh  ${TARGET_SSH_USER}@${TARGET_SERVER} \"chmod 777 /tmp/$ORACLE_SID/\""
    sudo su - ${SOURCE_SSH_USER} -c "ssh  ${TARGET_SSH_USER}@${TARGET_SERVER} \"sudo chown -R oracle:dba /tmp/$ORACLE_SID/\""
    
  fi
fi

if [ -z $db_recovery_file_dest ]; then 
  echo "ERROR: Environment variables are not set"
else
  echo "++++++++++ Creating staging directory on ${TARGET_SERVER} ++++++++++"
  sudo su - ${SOURCE_SSH_USER} -c "ssh  ${TARGET_SSH_USER}@${TARGET_SERVER} \"mkdir -p ${db_recovery_file_dest}/$ORACLE_SID/autobackup/$l_date\""
  
  sudo su - ${SOURCE_SSH_USER} -c "ssh  ${TARGET_SSH_USER}@${TARGET_SERVER} \"mkdir -p ${db_recovery_file_dest}/$ORACLE_SID/backupset/$l_date\""


  sudo su - ${SOURCE_SSH_USER} -c "ssh  ${TARGET_SSH_USER}@${TARGET_SERVER} \"sudo chown -R itsysadm:staff ${db_recovery_file_dest}/$ORACLE_SID/autobackup/$l_date\""
  
  sudo su - ${SOURCE_SSH_USER} -c "ssh  ${TARGET_SSH_USER}@${TARGET_SERVER} \"sudo chown -R itsysadm:staff ${db_recovery_file_dest}/$ORACLE_SID/backupset/$l_date\""  
  
  echo "++++++++++ Copying backup to staging directory on ${TARGET_SERVER} ++++++++++"
  sudo su - ${SOURCE_SSH_USER} -c "rsync -a --ignore-existing ${db_recovery_file_dest}/$SOURCE_ORACLE_SID/autobackup/$l_date  ${TARGET_SSH_USER}@${TARGET_SERVER}:${db_recovery_file_dest}/$ORACLE_SID/autobackup/"

  sudo su - ${SOURCE_SSH_USER} -c "rsync -a --ignore-existing ${db_recovery_file_dest}/$SOURCE_ORACLE_SID/backupset/$l_date  ${TARGET_SSH_USER}@${TARGET_SERVER}:${db_recovery_file_dest}/$ORACLE_SID/backupset/"


  sudo su - ${SOURCE_SSH_USER} -c "ssh  ${TARGET_SSH_USER}@${TARGET_SERVER} \"sudo chown -R oracle:dba ${db_recovery_file_dest}/$ORACLE_SID/autobackup/$l_date\""
  
  sudo su - ${SOURCE_SSH_USER} -c "ssh  ${TARGET_SSH_USER}@${TARGET_SERVER} \"sudo chown -R oracle:dba ${db_recovery_file_dest}/$ORACLE_SID/backupset/$l_date\""  

  
fi


if [ $l_bkup_level = 0 ]; then
  if [ -z $db_recovery_file_dest ]; then 
    echo "ERROR: Environment variables are not set"
  else
    sudo su - ${SOURCE_SSH_USER} -c "ssh  ${TARGET_SSH_USER}@${TARGET_SERVER} \"mkdir -p /tmp/${TARGET_ORACLE_SID}\""


export ORACLE_SID=$SOURCE_ORACLE_SID
export ORAENV_ASK=NO
. oraenv
export ORAENV_ASK=YES


sqlplus / as sysdba <<EOF
create pfile='/tmp/init${SOURCE_ORACLE_SID}.ora' from spfile;
EOF

echo "Manually edit and copy the init file, orapwd file to /tmp/${TARGET_ORACLE_SID}"

#    sudo su - ${SOURCE_SSH_USER} -c "scp -r /tmp/init${SOURCE_ORACLE_SID}.ora  ${TARGET_SSH_USER}@${TARGET_SERVER}:/tmp/${TARGET_ORACLE_SID}/init${TARGET_ORACLE_SID}.ora"
#    sudo su - ${SOURCE_SSH_USER} -c "scp -r ${ORACLE_11107_HOME}/dbs/orapw${SOURCE_ORACLE_SID}  ${TARGET_SSH_USER}@${TARGET_SERVER}:/tmp/${TARGET_ORACLE_SID}/orapw${TARGET_ORACLE_SID}"
#    sudo su - ${SOURCE_SSH_USER} -c "scp -r ${ORACLE_11107_HOME}/dbs/spfile${SOURCE_ORACLE_SID}.ora  ${TARGET_SSH_USER}@${TARGET_SERVER}:/tmp/${TARGET_ORACLE_SID}/spfile${TARGET_ORACLE_SID}.ora"

#    sudo su - ${SOURCE_SSH_USER} -c "scp -r ${ORACLE_BASE}/product/11.2.0.4/installer/database/response/db_install.rsp  ${TARGET_SSH_USER}@${TARGET_SERVER}:/tmp/${TARGET_ORACLE_SID}/db_install.rsp"
  fi
fi

echo "++++++++++ Listing staging backup directories on ${TARGET_SERVER} ++++++++++"
sudo su - ${SOURCE_SSH_USER} -c "ssh  ${TARGET_SSH_USER}@${TARGET_SERVER} \"ls -l ${db_recovery_file_dest}/$ORACLE_SID/autobackup/$l_date\""
sudo su - ${SOURCE_SSH_USER} -c "ssh  ${TARGET_SSH_USER}@${TARGET_SERVER} \"ls -l ${db_recovery_file_dest}/$ORACLE_SID/backupset/$l_date\""


############### TARGET Server
# Use this if the mkdir , rm, scp after backup does not work. Replace oracle:dba with whatever are the values in your environment
# export db_recovery_file_dest="/u01/flash_recovery_area"
# chown oracle:dba /u01
# chmod 777 ${db_recovery_file_dest}
