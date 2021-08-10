#!/bin/bash

############# Setting Options
if [ $# -eq 6 ]; then
  echo "\nINFO  : `date +"%Y_%m_%d:%H_%M_%S"`: Using command line parameters for options"
  echo "\nINFO  : `date +"%Y_%m_%d:%H_%M_%S"`: setting DELETE_DATABASE=$1, DELETE_SOFTWARE=$2, INSTALL_SOFTWARE=$3, CREATE_DATABASE=$4, ORACLE_VERSION=$5, ORACLE_SID=$ORACLE_SID"
  export DELETE_DATABASE=$1
  export DELETE_SOFTWARE=$2
  export INSTALL_SOFTWARE=$3
  export CREATE_DATABASE=$4
  export ORACLE_VERSION=$5
  export ORACLE_SID=$6
elif [ ! -z $hardcode ]; then
  echo "\nINFO  : `date +"%Y_%m_%d:%H_%M_%S"`: Using values set in script for options"
  echo "\nINFO  : `date +"%Y_%m_%d:%H_%M_%S"`: setting DELETE_DATABASE=$1, DELETE_SOFTWARE=$2, INSTALL_SOFTWARE=$3, CREATE_DATABASE=$4, ORACLE_VERSION=$5, ORACLE_SID=$ORACLE_SID"
  export DELETE_DATABASE=NO
  export DELETE_SOFTWARE=NO
  export INSTALL_SOFTWARE=NO
  export CREATE_DATABASE=NO
  export ORACLE_VERSION="11.2.0.4"
  export ORACLE_SID="ORCLTEST"
else
  echo "\nINFO  : `date +"%Y_%m_%d:%H_%M_%S"`: Usage: ./createdb.sh DELETE_DATABASE(y/n) DELETE_SOFTWARE(y/n) INSTALL_SOFTWARE(y/n) CREATE_DATABASE(y/n) ORACLE_VERSION ORACLE_SID"
  echo "\nINFO  : `date +"%Y_%m_%d:%H_%M_%S"`: Exiting script. Nothing to do"
  exit
fi

############# Variables
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=${ORACLE_BASE}/product/${ORACLE_VERSION}/dbhome_1
export PATH=${ORACLE_HOME}/bin:$PATH
export SYS_SYSTEM_PASSWORD="sys"
export DATA_HOME="/u01/oradata"
export DEINSTALL_DIR="/export/home/oracle/software/oracle/deinstall_11gr2"
export db_recovery_file_dest="/u01/flash_recovery_area"

source bash_palette.sh

echo "\n${PALETTE_BLINK}WARN${PALETTE_RESET}  : `date +"%Y_%m_%d:%H_%M_%S"`: ${PALETTE_BOLD}Executing on host ${PALETTE_BLINK}$(hostname)${PALETTE_RESET}"


if [ ${DELETE_DATABASE} = "Y" ] || [ ${DELETE_DATABASE} = "y" ] ; then
  echo "\n${PALETTE_BLINK}WARN${PALETTE_RESET}  : `date +"%Y_%m_%d:%H_%M_%S"`: DELETING DATABASE on host ${PALETTE_BLINK}$(hostname)${PALETTE_RESET}"
  sleep 3


# Delete database method 2
  $ORACLE_HOME/bin/dbca -silent -deleteDatabase -sourceDB ${ORACLE_SID} -sysPassword sys


# Delete database method 1
sqlplus / as sysdba <<EOF
shutdown abort
startup mount exclusive  restrict
exit
EOF

sqlplus / as sysdba <<EOF
drop database;
exit
EOF 

sqlplus / as sysdba <<EOF
shutdown abort
exit
EOF



# Delete folders
  echo "\n${PALETTE_BLINK}WARN${PALETTE_RESET}  : `date +"%Y_%m_%d:%H_%M_%S"`: DELETING FOLDERS on host ${PALETTE_BLINK}$(hostname)${PALETTE_RESET}"
  sleep 3
  rm -rf $DATA_HOME/${ORACLE_SID}/
  rm -rf ${db_recovery_file_dest}/${ORACLE_SID}/
  rm -rf ${ORACLE_BASE}/oradata/${ORACLE_SID}
  # rm -rf ${ORACLE_BASE}/admin/${ORACLE_SID}/adump # Delete audit area
  rm -rf ${ORACLE_BASE}/oradata/${ORACLE_SID} # Delete control files area
  rm -rf ${ORACLE_BASE}/oradata/${ORACLE_SID} # Delete redo log area
  rm -rf $DATA_HOME/onlinelogs/${ORACLE_SID} # Delete redo log area
  rm -rf $DATA_HOME/controlfiles/${ORACLE_SID} # Delete control files area
  rm -rf $DATA_HOME/datafile/${ORACLE_SID} # Delete datafiles area
  rm -rf $DATA_HOME/archivelogs/${ORACLE_SID} # Delete archivelogs area

# Remove oratab entry
  if [ $(cat /var/opt/oracle/oratab | grep ${ORACLE_SID} | wc -l) = 1 ]; then
    echo "\nINFO  : `date +"%Y_%m_%d:%H_%M_%S"`: Deleting oratab entry"
	sudo sed -e "/$ORACLE_SID/d" /var/opt/oracle/oratab > /tmp/oratab.tmp
	sudo cp /tmp/oratab.tmp /var/opt/oracle/oratab
    #printf "%s\n" 'g/$ORACLE_SID/d' w q | ed /var/opt/oracle/oratab
    echo "\nINFO  : `date +"%Y_%m_%d:%H_%M_%S"`: Deleted oratab entry"
  fi

  echo "\nINFO  : `date +"%Y_%m_%d:%H_%M_%S"`: DELETED DATABASE on host ${PALETTE_BLINK}$(hostname)${PALETTE_RESET}"
fi

if [ ${DELETE_SOFTWARE} = "Y" ] || [ ${DELETE_SOFTWARE} = "y" ] ; then
  echo "\n${PALETTE_BLINK}WARN${PALETTE_RESET}  : `date +"%Y_%m_%d:%H_%M_%S"`: DELETING SOFTWARE on host ${PALETTE_BLINK}$(hostname)${PALETTE_RESET}"
  sleep 3
  
# Creating response file  
  cp ${DEINSTALL_DIR}/deinstall/response/deinstall_OraDBHome_TEMPLATE.rsp ${DEINSTALL_DIR}/deinstall/response/deinstall_OraDBHome${ORACLE_SID}.rsp

  cat ${DEINSTALL_DIR}/deinstall/response/deinstall_OraDBHome${ORACLE_SID}.rsp | sed -e "s/orcl11/$ORACLE_SID/g" > /tmp/deinstall_OraDBHome${ORACLE_SID}.rsp
  sed -e "/ORACLE_HOME=/d" /tmp/deinstall_OraDBHome${ORACLE_SID}.rsp > /tmp/deinstall_OraDBHome${ORACLE_SID}.rsp1
  cp /tmp/deinstall_OraDBHome${ORACLE_SID}.rsp1 /tmp/deinstall_OraDBHome${ORACLE_SID}.rsp
  
  sed -e "/ORACLE_BASE=/d" /tmp/deinstall_OraDBHome${ORACLE_SID}.rsp > /tmp/deinstall_OraDBHome${ORACLE_SID}.rsp1
  cp /tmp/deinstall_OraDBHome${ORACLE_SID}.rsp1 /tmp/deinstall_OraDBHome${ORACLE_SID}.rsp

  cat /tmp/deinstall_OraDBHome${ORACLE_SID}.rsp | sed -e "s/11.1.0.7/$ORACLE_VERSION/g" > /tmp/deinstall_OraDBHome${ORACLE_SID}.rsp1
  cp /tmp/deinstall_OraDBHome${ORACLE_SID}.rsp1 /tmp/deinstall_OraDBHome${ORACLE_SID}.rsp


  echo "ORACLE_BASE=$ORACLE_BASE" >> /tmp/deinstall_OraDBHome${ORACLE_SID}.rsp
  echo "ORACLE_HOME=$ORACLE_HOME" >> /tmp/deinstall_OraDBHome${ORACLE_SID}.rsp
  
  cp /tmp/deinstall_OraDBHome${ORACLE_SID}.rsp ${DEINSTALL_DIR}/deinstall/response/deinstall_OraDBHome${ORACLE_SID}.rsp
  rm /tmp/deinstall_OraDBHome${ORACLE_SID}.rsp 
  rm /tmp/deinstall_OraDBHome${ORACLE_SID}.rsp1
  
  ${DEINSTALL_DIR}/deinstall/deinstall -home ${ORACLE_BASE}/product/${ORACLE_VERSION}/dbhome_1 -silent -paramfile ${DEINSTALL_DIR}/deinstall/response/deinstall_OraDBHome${ORACLE_SID}.rsp
  echo "\nINFO  : `date +"%Y_%m_%d:%H_%M_%S"`: DELETED SOFTWARE"
fi


if [ ${INSTALL_SOFTWARE} = "Y" ] || [ ${INSTALL_SOFTWARE} = "y" ] ; then
  echo "\nINFO  : `date +"%Y_%m_%d:%H_%M_%S"`: INSTALLING SOFTWARE on host ${PALETTE_BLINK}$(hostname)${PALETTE_RESET} - NOT IMPLEMENTED YET"
  sleep 3

fi 


if [ ${CREATE_DATABASE} = "Y" ] || [ ${CREATE_DATABASE} = "y" ] ; then
  echo "\nINFO  : `date +"%Y_%m_%d:%H_%M_%S"`: CREATING DATABASE on host ${PALETTE_BLINK}$(hostname)${PALETTE_RESET}"
  sleep 3

# Create folders  
# Needed as dbca creates the control file here by default.
mkdir ${db_recovery_file_dest}/${ORACLE_SID}/

#  mkdir -p ${ORACLE_BASE}/oradata/${ORACLE_SID}
#  mkdir -p ${ORACLE_BASE}/oradata/${ORACLE_SID} # Create control files area
#  mkdir -p ${ORACLE_BASE}/oradata/${ORACLE_SID} # Create redo log area

  mkdir -p ${ORACLE_BASE}/admin/${ORACLE_SID}/adump # Create audit area


cp $ORACLE_HOME/dbs/init${ORACLE_SID}.ora $ORACLE_HOME/dbs/init${ORACLE_SID}.ora.bak.$(date +"%Y_%m_%d_%H_%M_%S")

echo "${ORACLE_SID}.__db_cache_size=1929379840
${ORACLE_SID}.__java_pool_size=16777216
${ORACLE_SID}.__large_pool_size=33554432
${ORACLE_SID}.__oracle_base='${ORACLE_BASE}'#ORACLE_BASE set from environment
${ORACLE_SID}.__pga_aggregate_target=536870912
${ORACLE_SID}.__sga_target=2684354560
${ORACLE_SID}.__shared_io_pool_size=0
${ORACLE_SID}.__shared_pool_size=536870912
${ORACLE_SID}.__streams_pool_size=0
*.audit_file_dest='${ORACLE_BASE}/admin/${ORACLE_SID}/adump'
*.compatible='11.1.0.0.0'
*.control_files='${DATA_HOME}/controlfiles/${ORACLE_SID}/control01.ctl','${DATA_HOME}/controlfiles/${ORACLE_SID}/control02.ctl','${DATA_HOME}/controlfiles/${ORACLE_SID}/control03.ctl'
*.db_block_size=32768
*.db_create_file_dest='${DATA_HOME}/datafile'
*.db_create_online_log_dest_1='${DATA_HOME}/onlinelogs'
*.db_create_online_log_dest_2='${DATA_HOME}/onlinelogs'
*.db_file_name_convert='/bidb/oracle/oradata/${ORACLE_SID}','${DATA_HOME}/datafile/${ORACLE_SID}'
*.db_name='${ORACLE_SID}'
*.db_recovery_file_dest=$db_recovery_file_dest
*.db_recovery_file_dest_size=536870912000
*.db_unique_name='${ORACLE_SID}'
*.diagnostic_dest='${ORACLE_BASE}'
*.log_archive_dest_1='LOCATION=${DATA_HOME}/archivelogs/${ORACLE_SID}'
*.log_checkpoint_timeout=9000
*.log_file_name_convert='/bidb/oracle/oradata/${ORACLE_SID}','${DATA_HOME}/onlinelogs/${ORACLE_SID}'
*.sga_target=2560M
" >> $ORACLE_HOME/dbs/init${ORACLE_SID}.ora

#  mkdir -p $DATA_HOME/${ORACLE_SID}/controlfile
#  mkdir -p $DATA_HOME/${ORACLE_SID}/datafile # Create datafiles area
#  mkdir -p $DATA_HOME/onlinelogs/${ORACLE_SID} # Create redo log area
#  mkdir -p $DATA_HOME/controlfiles/${ORACLE_SID} # Create control files area
#  mkdir -p $DATA_HOME/datafile/${ORACLE_SID} # Create datafiles area
#  mkdir -p $DATA_HOME/archivelogs/${ORACLE_SID} # Create archivelogs area

  ${ORACLE_BASE}/product/${ORACLE_VERSION}/dbhome_1/bin/dbca -silent -createDatabase \
-templateName General_Purpose.dbc \
-databaseType MULTIPURPOSE \
-gdbName ${ORACLE_SID} -sid ${ORACLE_SID} \
-sysPassword ${SYS_SYSTEM_PASSWORD} -systemPassword ${SYS_SYSTEM_PASSWORD} \
-characterSet AL32UTF8 -nationalCharacterSet AL16UTF16 \
-totalMemory 8192 -automaticMemoryManagement true \
-redoLogFileSize 512 \
-listeners LISTENER -registerWithDirService false \
-emConfiguration NONE \
-datafileDestination "${DATA_HOME}/" \
-initparams sessions=700,open_cursors=500,processes=500,db_create_file_dest=${DATA_HOME},DB_RECOVERY_FILE_DEST=/u01/flash_recovery_area,cpu_count=2



# Add oratab entry
# Check if the entry is not already present
  if [ $(cat /var/opt/oracle/oratab | grep ${ORACLE_SID} | wc -l) = 0 ]; then
    echo "\nINFO  : `date +"%Y_%m_%d:%H_%M_%S"`: Creating oratab entry"
    echo "${ORACLE_SID}:${ORACLE_HOME}:n" >> /var/opt/oracle/oratab
    echo "\nINFO  : `date +"%Y_%m_%d:%H_%M_%S"`: Created oratab entry"
  fi
  
# Start listener if not already started
  lsnrctl reload
  lsnrctl status

  echo "\nINFO  : `date +"%Y_%m_%d:%H_%M_%S"`: CREATED DATABASE on host ${PALETTE_BLINK}$(hostname)${PALETTE_RESET}"

export ORACLE_SID=${ORACLE_SID}
export ORAENV_ASK=NO
. oraenv
export ORAENV_ASK=YES

sqlplus / as sysdba <<EOF
    select instance_name,version,status from v\$instance;
   exit
EOF

fi