#!/bin/bash
# migration_reset_postgres_cluster.sh : Drop all users/schemas/databases in postgres and recreate them

# Checking one and only one parameter was passed.
[ $# -ne 1 ] && { echo "Usage: migration_reset_postgres_cluster.sh database_name"; exit 1; } 
export L_DB_NAME=$(echo $1 | tr '[:upper:]' '[:lower:]' )

cd ${MIGRATION_HOME}

source migration_common_settings.sh
export L_UNQ_ID=$(date '+%Y%m%d%H%M%S')
script_name `basename "$0"`
export L_LOGFILE="$MIGRATION_FOLDER/${FILENAME}_${L_UNQ_ID}.log"

echo " " |& tee -a ${L_LOGFILE}
echo " " |& tee -a ${L_LOGFILE}
echo ${L_SEPERATOR} |& tee -a ${L_LOGFILE}
echo "Start: Script migration_reset_postgres_cluster.sh" |& tee -a ${L_LOGFILE}
echo ${L_SEPERATOR} |& tee -a ${L_LOGFILE}
echo " " |& tee -a ${L_LOGFILE}
echo " " |& tee -a ${L_LOGFILE}

$MIGRATION_FOLDER/migration_checks.sh

if [ ! -f ${MIGRATION_FOLDER}/${L_DB_NAME}_schemas_to_migrate.txt ]; then
  log_this ERROR "Config file ${MIGRATION_FOLDER}/${L_DB_NAME}_schemas_to_migrate.txt not found. Exiting"
  exit_gracefully
fi  

L_COUNT_SCHEMAS=$(cat ${MIGRATION_FOLDER}/${L_DB_NAME}_schemas_to_migrate.txt | grep -i ",${L_DB_NAME}_db," | grep -v "#" | wc -l)
if [ -z "${L_COUNT_SCHEMAS}" ] || [[ $L_COUNT_SCHEMAS < 1 ]]; then 
  log_this ERROR "No schemas to process for database ${L_DB_NAME}"
  exit_gracefully
else
  log_this INFO "For database ${L_DB_NAME} we will process $L_COUNT_SCHEMAS schema/s"
fi


for i in $(cat ${MIGRATION_FOLDER}/${L_DB_NAME}_schemas_to_migrate.txt | grep -i ",${L_DB_NAME}_db," | grep -v "#"); do

  L_POSTGRES_HOST_NAME=$(echo $i | cut -d',' -f1)
  L_POSTGRES_PORT=$(echo $i | cut -d',' -f2)
  L_POSTGRES_DATABASE_NAME=$(echo $i | cut -d',' -f3)
  L_POSTGRES_SCHEMA_NAME=$(echo $i | cut -d',' -f4)
  L_POSTGRES_SCHEMA_PASSWORD=$(echo $i | cut -d',' -f5)
  L_POSTGRES_CONNECTION_USERNAME=$(echo $i | cut -d',' -f6)
  L_POSTGRES_CONNECTION_PASSWORD=$(echo $i | cut -d',' -f7)
  L_ORACLE_TNSNAME=$(echo $i | cut -d',' -f8 | tr '[:lower:]' '[:upper:]')
  L_ORACLE_CONNECTION_USERNAME=$(echo $i | cut -d',' -f9 | tr '[:upper:]' '[:lower:]')
  L_ORACLE_SCHEMA_PASSWORD=$(echo $i | cut -d',' -f10)
  
  # alias psql_cmd="psql -t -U ${L_POSTGRES_CONNECTION_USERNAME} -h ${L_POSTGRES_HOST_NAME} -p $L_POSTGRES_PORT ${L_POSTGRES_DATABASE_NAME}"
  
  log_this INFO ${L_SEPERATOR}
  log_this INFO "Schema: $L_POSTGRES_SCHEMA_NAME being deleted from Postgres Database: ${L_POSTGRES_DATABASE_NAME}"
  log_this INFO ${L_SEPERATOR}
  
# While loop and if statement to make sure the user answers y / n / exit

  if [ ! -z ${ANSWER_YES_TO_ALL} ]; then
     if [ ${ANSWER_YES_TO_ALL} = "YES" ]; then 
        L_DROP_SCHEMA_RESPONSE="Y"
     fi
  else
     unset L_DROP_SCHEMA_RESPONSE
  fi 

  while [ -z $L_DROP_SCHEMA_RESPONSE ]; do

    log_this QUESTION "!!! Do you want to drop & create, postgres database: ${L_POSTGRES_DATABASE_NAME}, schema & user: $L_POSTGRES_SCHEMA_NAME? (y/n/exit)"
    read L_DROP_SCHEMA_RESPONSE

    if [ ! -z $L_DROP_SCHEMA_RESPONSE ]; then
      if [ $L_DROP_SCHEMA_RESPONSE != "n" ] && [ $L_DROP_SCHEMA_RESPONSE != "N" ] && [ $L_DROP_SCHEMA_RESPONSE != "y" ] && [ $L_DROP_SCHEMA_RESPONSE != "Y" ] && [ $L_DROP_SCHEMA_RESPONSE != "exit" ] && [ $L_DROP_SCHEMA_RESPONSE != "EXIT" ]; then
        log_this ERROR "Invalid Choice. Try y or n or exit"
	    unset L_DROP_SCHEMA_RESPONSE
      else
        break
      fi
    fi
    export L_DROP_SCHEMA_RESPONSE
  done

  if [ $L_DROP_SCHEMA_RESPONSE = "n" ] || [ $L_DROP_SCHEMA_RESPONSE = "N" ]; then
    continue
  elif [ $L_DROP_SCHEMA_RESPONSE = "exit" ] || [ $L_DROP_SCHEMA_RESPONSE = "EXIT" ]; then
    exit
  elif [ $L_DROP_SCHEMA_RESPONSE = "y" ] || [ $L_DROP_SCHEMA_RESPONSE = "Y" ]; then

    log_this COMMAND "psql -t -U ${L_POSTGRES_CONNECTION_USERNAME} -h ${L_POSTGRES_HOST_NAME} -p $L_POSTGRES_PORT ${L_POSTGRES_DATABASE_NAME} -c \"DROP SCHEMA $L_POSTGRES_SCHEMA_NAME CASCADE;\""
    psql -t -U ${L_POSTGRES_CONNECTION_USERNAME} -h ${L_POSTGRES_HOST_NAME} -p $L_POSTGRES_PORT ${L_POSTGRES_DATABASE_NAME} -c "DROP SCHEMA $L_POSTGRES_SCHEMA_NAME CASCADE;" >> ${L_LOGFILE} 2>&1
	check_result "$?" "Drop schema ${L_POSTGRES_SCHEMA_NAME}"

#    log_this COMMAND "psql -t -U ${L_POSTGRES_CONNECTION_USERNAME} -h ${L_POSTGRES_HOST_NAME} -p $L_POSTGRES_PORT postgres -c \"DROP DATABASE ${L_POSTGRES_DATABASE_NAME};\""
#    psql -t -U ${L_POSTGRES_CONNECTION_USERNAME} -h ${L_POSTGRES_HOST_NAME} -p $L_POSTGRES_PORT postgres -c "DROP DATABASE ${L_POSTGRES_DATABASE_NAME};" >> ${L_LOGFILE} 2>&1
#	check_result "$?" "Drop database ${L_POSTGRES_DATABASE_NAME}" 

# Helps drop objects that are not cleared by drop schema cascade;
    log_this COMMAND "psql -t -U ${L_POSTGRES_CONNECTION_USERNAME} -h ${L_POSTGRES_HOST_NAME} -p $L_POSTGRES_PORT ${L_POSTGRES_DATABASE_NAME} -c \"DROP OWNED BY $L_POSTGRES_SCHEMA_NAME;\""
    psql -t -U ${L_POSTGRES_CONNECTION_USERNAME} -h ${L_POSTGRES_HOST_NAME} -p $L_POSTGRES_PORT ${L_POSTGRES_DATABASE_NAME} -c "DROP OWNED BY $L_POSTGRES_SCHEMA_NAME;" >> ${L_LOGFILE} 2>&1
	check_result "$?" "Drop owned by ${L_POSTGRES_SCHEMA_NAME}"

    log_this COMMAND "psql -t -U ${L_POSTGRES_CONNECTION_USERNAME} -h ${L_POSTGRES_HOST_NAME} -p $L_POSTGRES_PORT ${L_POSTGRES_DATABASE_NAME} -c \"DROP ROLE $L_POSTGRES_SCHEMA_NAME;\""
    psql -t -U ${L_POSTGRES_CONNECTION_USERNAME} -h ${L_POSTGRES_HOST_NAME} -p $L_POSTGRES_PORT ${L_POSTGRES_DATABASE_NAME} -c "DROP ROLE $L_POSTGRES_SCHEMA_NAME;" >> ${L_LOGFILE} 2>&1
	check_result "$?" "Drop role ${L_POSTGRES_SCHEMA_NAME}"

    log_this COMMAND "psql -t -U ${L_POSTGRES_CONNECTION_USERNAME} -h ${L_POSTGRES_HOST_NAME} -p $L_POSTGRES_PORT ${L_POSTGRES_DATABASE_NAME} -c \"CREATE USER $L_POSTGRES_SCHEMA_NAME WITH PASSWORD '$L_POSTGRES_SCHEMA_PASSWORD';\""
    psql -t -U ${L_POSTGRES_CONNECTION_USERNAME} -h ${L_POSTGRES_HOST_NAME} -p $L_POSTGRES_PORT ${L_POSTGRES_DATABASE_NAME} -c "CREATE USER $L_POSTGRES_SCHEMA_NAME WITH PASSWORD '$L_POSTGRES_SCHEMA_PASSWORD';" >> ${L_LOGFILE} 2>&1
	check_result "$?" "Create user ${L_POSTGRES_SCHEMA_NAME}"

    log_this COMMAND "psql -t -U ${L_POSTGRES_CONNECTION_USERNAME} -h ${L_POSTGRES_HOST_NAME} -p $L_POSTGRES_PORT ${L_POSTGRES_DATABASE_NAME} -c \"ALTER USER $L_POSTGRES_SCHEMA_NAME WITH superuser;\""
    psql -t -U ${L_POSTGRES_CONNECTION_USERNAME} -h ${L_POSTGRES_HOST_NAME} -p $L_POSTGRES_PORT ${L_POSTGRES_DATABASE_NAME} -c "ALTER USER $L_POSTGRES_SCHEMA_NAME WITH superuser;" >> ${L_LOGFILE} 2>&1
	check_result "$?" "Grant superuser to user ${L_POSTGRES_SCHEMA_NAME}"

    L_DB_COUNT=$(psql -t -U postgres -h ${L_POSTGRES_HOST_NAME} -p $L_POSTGRES_PORT postgres -c "select datname from pg_database where datname = '${L_POSTGRES_DATABASE_NAME}';" | xargs) 
    if [ ! -z ${L_DB_COUNT} ]; then
      log_this INFO "Database ${L_POSTGRES_DATABASE_NAME} already present. Nothing to do"
    else
      log_this INFO "Creating database ${L_POSTGRES_DATABASE_NAME}"
      log_this COMMAND "createdb -U ${L_POSTGRES_CONNECTION_USERNAME} -h ${L_POSTGRES_HOST_NAME} -p $L_POSTGRES_PORT -O ${L_POSTGRES_CONNECTION_USERNAME} ${L_POSTGRES_DATABASE_NAME}"
      createdb -U ${L_POSTGRES_CONNECTION_USERNAME} -h ${L_POSTGRES_HOST_NAME} -p $L_POSTGRES_PORT -O ${L_POSTGRES_CONNECTION_USERNAME} ${L_POSTGRES_DATABASE_NAME} >> ${L_LOGFILE} 2>&1
	  # -D ${L_POSTGRES_SCHEMA_NAME}_01_tblsp 
	  check_result "$?" "Create database ${L_POSTGRES_DATABASE_NAME}"
    fi 
    
    log_this COMMAND "psql -t -U ${L_POSTGRES_CONNECTION_USERNAME} -h ${L_POSTGRES_HOST_NAME} -p $L_POSTGRES_PORT ${L_POSTGRES_DATABASE_NAME} -c \"CREATE SCHEMA $L_POSTGRES_SCHEMA_NAME AUTHORIZATION $L_POSTGRES_SCHEMA_PASSWORD;\""
    psql -t -U ${L_POSTGRES_CONNECTION_USERNAME} -h ${L_POSTGRES_HOST_NAME} -p $L_POSTGRES_PORT ${L_POSTGRES_DATABASE_NAME} -c "CREATE SCHEMA $L_POSTGRES_SCHEMA_NAME AUTHORIZATION $L_POSTGRES_SCHEMA_PASSWORD;" >> ${L_LOGFILE} 2>&1
	check_result "$?" "Create schema ${L_POSTGRES_SCHEMA_NAME}"

  fi   

done


echo " " |& tee -a ${L_LOGFILE}
echo " " |& tee -a ${L_LOGFILE}
echo ${L_SEPERATOR} |& tee -a ${L_LOGFILE}
echo "End: Script migration_reset_postgres_cluster.sh" |& tee -a ${L_LOGFILE}
echo ${L_SEPERATOR} |& tee -a ${L_LOGFILE}
echo " " |& tee -a ${L_LOGFILE}
echo " " |& tee -a ${L_LOGFILE}

log_this INFO "Log file can be found in ${L_LOGFILE}"

list_errors ${L_LOGFILE}

exit_gracefully