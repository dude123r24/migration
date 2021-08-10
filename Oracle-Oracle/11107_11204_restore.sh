# 11107_11204_restore.sh
#!/bin/bash

# Upgrading 11.1.0.7 to 11.2.0.4
# Created to test upgrading 11.1.0.7 TEST DATABASE on orazoracol01 to 11.2.0.4 on orazoracol02 (different server)


############### TARGET Server


if [ $# -lt 3 ]; then
  echo "\nERROR  : `date +"%Y_%m_%d:%H_%M_%S"`: Usage: 11107_11204_restore.sh Backup_level date(YYYY_MM_DD) ORACLE_SID **********"
  exit
elif [ 1 -eq 2 ]; then
  export l_bkup_level=0
  export l_date=2021_06_28
  export SOURCE_ORACLE_SID=ORCL11
  export TARGET_ORACLE_SID=${SOURCE_ORACLE_SID}
else
  export l_bkup_level=$1
  export l_date=$2
  export SOURCE_ORACLE_SID=$3
  export TARGET_ORACLE_SID=${SOURCE_ORACLE_SID}
fi

export ORACLE_VERSION="11.2.0.4"
export ORACLE_SID=${TARGET_ORACLE_SID}
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=${ORACLE_BASE}/product/${ORACLE_VERSION}/dbhome_1
export PATH=${ORACLE_HOME}/bin:$PATH

export SOURCE_SERVER="158.119.102.35"
export TARGET_SERVER="158.119.102.36"
export SOURCE_SSH_USER=itsysadm
export TARGET_SSH_USER=itsysadm
export db_recovery_file_dest="/u01/flash_recovery_area" 
export DATA_HOME="/u01/oradata/"
export ORACLE_11107_HOME="${ORACLE_BASE}/product/${ORACLE_VERSION}/dbhome_1"
export ORACLE_11204_HOME="${ORACLE_BASE}/product/${ORACLE_VERSION}/dbhome_1"
export ORACLE_19C_HOME="${ORACLE_BASE}/product/${ORACLE_VERSION}/dbhome_1"



# as ROOT 
# usermod -G dba,oinstall itsysadm


if [ $l_bkup_level = 0 ] &&  [ $(cat /var/opt/oracle/oratab | grep -i ${TARGET_ORACLE_SID} | wc -l) -ge  1 ] ; then

  export ORACLE_SID=$TARGET_ORACLE_SID
  export ORAENV_ASK=NO
  . oraenv
  export ORAENV_ASK=YES

  echo " "
  echo "++++++++++ Droping database. Is this the right server? ---> `hostname`. Sleeping 5 secs before deleting ++++++++++"
  echo " "
  sleep 5

  echo "include createdb with the right parameters here to delete database"
  
fi 

if [ $l_bkup_level = 0 ]; then
# Add oratab entry
# Check if the entry is not already present
  if [ $(cat /var/opt/oracle/oratab | grep ${ORACLE_SID} | wc -l) = 0 ]; then
    echo "\nINFO  : `date +"%Y_%m_%d:%H_%M_%S"`: Creating oratab entry"
    echo "${ORACLE_SID}:${ORACLE_HOME}:n" >> /var/opt/oracle/oratab
    echo "\nINFO  : `date +"%Y_%m_%d:%H_%M_%S"`: Created oratab entry"
  fi
fi

export ORACLE_SID=${TARGET_ORACLE_SID}
export ORAENV_ASK=NO
. oraenv
export ORAENV_ASK=YES

  echo " "
  echo "++++++++++ Creating backup folders if not already present ++++++++++"
  echo " "
  [ -d ${db_recovery_file_dest}/${TARGET_ORACLE_SID}/backupset/$l_date ] || mkdir -p ${db_recovery_file_dest}/${TARGET_ORACLE_SID}/backupset/$l_date # Rman backup area - same as source server path
  [ -d ${db_recovery_file_dest}/${TARGET_ORACLE_SID}/autobackup/$l_date ] || mkdir -p ${db_recovery_file_dest}/${TARGET_ORACLE_SID}/autobackup/$l_date # Control file autobackup area - same as source server path

if [ $l_bkup_level = 0 ]; then

echo " "
echo "++++++++++ Creating database folders (adump, controlfile, data, redo ++++++++++"
echo " "

  mkdir -p ${ORACLE_BASE}/admin/${ORACLE_SID}/adump # Create audit area
  mkdir -p $DATA_HOME/${TARGET_ORACLE_SID}/archivelogs # General area for oracle files. Will contain most things (including archivelogs)


#  mkdir -p /u01/app/oracle/admin/${TARGET_ORACLE_SID}/adump # Create audit area 
#  mkdir -p /u01/app/oracle/oradata/${TARGET_ORACLE_SID} # Create control files area
#  mkdir -p $DATA_HOME/${TARGET_ORACLE_SID}/controlfile
#  mkdir -p /u01/app/oracle/oradata/${TARGET_ORACLE_SID}/ # Create redo log area
#  mkdir -p $DATA_HOME/${TARGET_ORACLE_SID}/datafile/ # Create datafiles area

#  mkdir -p $DATA_HOME/onlinelogs/${TARGET_ORACLE_SID} # Create redo log area
#  mkdir -p $DATA_HOME/controlfiles/${TARGET_ORACLE_SID} # Create control files area
#  mkdir -p $DATA_HOME/datafile/${TARGET_ORACLE_SID} # Create datafiles area
#  mkdir -p $DATA_HOME/archivelogs/${TARGET_ORACLE_SID} # Create archivelogs area
  
  
echo " "
echo "++++++++++ Copying init, spfile, password file ++++++++++"
echo " "

echo "Manually edit and copy the init file, orapwd file from /tmp/${TARGET_ORACLE_SID} to ${ORACLE_11204_HOME}/dbs/"
  sudo chown oracle:dba /tmp/${TARGET_ORACLE_SID}/init${TARGET_ORACLE_SID}.ora
#  sudo chown oracle:dba /tmp/${TARGET_ORACLE_SID}/spfile${TARGET_ORACLE_SID}.ora
  sudo chown oracle:dba /tmp/${TARGET_ORACLE_SID}/orapw${TARGET_ORACLE_SID}

#  sudo cp /tmp/${TARGET_ORACLE_SID}/init${TARGET_ORACLE_SID}.ora ${ORACLE_11204_HOME}/dbs/
#  sudo cp /tmp/${TARGET_ORACLE_SID}/spfile${TARGET_ORACLE_SID}.ora ${ORACLE_11204_HOME}/dbs/
#  sudo cp /tmp/${TARGET_ORACLE_SID}/orapw${TARGET_ORACLE_SID} ${ORACLE_11204_HOME}/dbs/


  sudo chown oracle:dba ${ORACLE_11204_HOME}/dbs/init${TARGET_ORACLE_SID}.ora
  sudo chown oracle:dba ${ORACLE_11204_HOME}/dbs/spfile${TARGET_ORACLE_SID}.ora
  sudo chown oracle:dba ${ORACLE_11204_HOME}/dbs/orapw${TARGET_ORACLE_SID}

fi


#echo " "
#echo "++++++++++ Copying backup files from staging to database's default backup area ++++++++++"
#echo " "
  
#sudo cp /tmp/${TARGET_ORACLE_SID}/autobackup/$l_date/* ${db_recovery_file_dest}/${TARGET_ORACLE_SID}/autobackup/$l_date/
#sudo cp /tmp/${TARGET_ORACLE_SID}/backupset/$l_date/* ${db_recovery_file_dest}/${TARGET_ORACLE_SID}/backupset/$l_date/

sudo chown -R oracle:dba ${db_recovery_file_dest}

export PATH=/usr/bin:$ORACLE_HOME/bin



echo " "
echo "++++++++++ Restart DB in nomount for Level 0 restore ++++++++++"
echo " "

sqlplus / as sysdba <<EOF
shutdown abort
startup nomount
EOF


#if [ $l_bkup_level = 0 ]; then
#
#else
#
#echo " "
#echo "++++++++++ Restart DB in mount for Level 1 restore ++++++++++"
#echo " "
#
#sqlplus / as sysdba <<EOF
#shutdown abort
#startup mount
#EOF
#fi



echo " "
echo "++++++++++ Restore Control file ++++++++++"
echo " "

rman target / <<EOF
restore controlfile from autobackup recovery area '${db_recovery_file_dest}' db_name '${TARGET_ORACLE_SID}';
EOF


sqlplus / as sysdba <<EOF
alter database mount;
EOF


if [ $l_bkup_level = 0 ]; then


echo " "
echo "++++++++++ Create spfile from pfile for Level 0 restore ++++++++++"
echo " "

sqlplus / as sysdba <<EOF
create spfile from pfile;
EOF


  if [ -f ${ORACLE_11204_HOME}/dbs/init${TARGET_ORACLE_SID}.ora ]; then 
    echo "spfile=${ORACLE_11204_HOME}/dbs/spfile${TARGET_ORACLE_SID}.ora" > ${ORACLE_11204_HOME}/dbs/init${TARGET_ORACLE_SID}.ora
  fi

echo " "
echo "++++++++++ Changing init parms (db_recovery_file_dest_size) for Level 0 restore ++++++++++"
echo " "

# Size parameter will need to be changed as per requirement
sqlplus / as sysdba <<EOF
shutdown abort
startup mount
alter system set db_recovery_file_dest_size=500G scope=both ;
EOF
  
fi 


echo " "
echo "++++++++++ Catalog Backups ++++++++++"
echo " "

# Catalog all backup files (Not needed, if the backup files have been retored to the same location on target, as source location)
rman target / <<EOF
catalog db_recovery_file_dest noprompt ;

# catalog start with '${db_recovery_file_dest}' noprompt;
EOF




if [ $l_bkup_level = 0 ]; then
# If restore database fails, run rman "list incarnation;" on source and target. Then on target, set the incarnation to source database's current incarnation using rman "reset database to incarnation _;"

echo " "
echo "++++++++++ Perform Level 0 restore ++++++++++"
echo " "

rman target / <<EOF
restore database ;
# restore database from TAG='db-lvl-0';
EOF

else 

echo " "
echo "++++++++++ Perform Level 1 restore ++++++++++"
echo " "

rman target / <<EOF
restore database ;
# restore database from TAG='DB-LVL-1';
# restore database from TAG='ARCH-LVL-1';

EOF
fi






if [ $l_bkup_level = 1 ]; then

export SCN=$(cat /tmp/${ORACLE_SID}_SCN)

echo "recover database until scn $SCN ;" > /tmp/rman_recover.cmd
rman target / @/tmp/rman_recover.cmd

sqlplus / as sysdba <<EOF
alter database open resetlogs;
# Should see error: ORA-39700: database must be opened with UPGRADE option
EOF

sqlplus / as sysdba <<EOF
shutdown immediate 
startup upgrade

set lines 200
set pages 100
column comp_name format a40

select
    comp_id,
    comp_name,
    version,
    status
from
    dba_registry; 
EOF

${ORACLE_11204_HOME}/bin/dbua -silent -sid ${ORACLE_SID} -oracleHome  ${ORACLE_11204_HOME} -diagnosticDest ${ORACLE_BASE}

sqlplus / as sysdba <<EOF
set lines 200
set pages 100
column comp_name format a40

select
    comp_id,
    comp_name,
    version,
    status
from
    dba_registry; 
EOF