#!/bin/bash
# migration_checks.sh
# Checks all the folders are present. All the relevant files are present. The files have the relevant data to populate variables.

source migration_common_settings.sh

if [ -z ${L_LOGFILE} ]; then
  export L_UNQ_ID=$(date '+%Y%m%d%H%M%S')
  script_name `basename "$0"`
  export L_LOGFILE="$MIGRATION_FOLDER/${FILENAME}_${L_UNQ_ID}.log"
fi 

log_this INFO "Performing some basic checks ..."

[ ! -f ${ORA2PG_BIN} ] && { log_this ERROR "ora2pg executable not found at ${ORA2PG_BIN}. If its installed at a different location update migration_common_settings.sh, variable ORA2PG_BIN" ; export L_RC=1; } || log_this SUCCESS "ora2pg executable found at ${ORA2PG_BIN}"

[ ! -d ${MIGRATION_FOLDER} ] && { log_this ERROR "${MIGRATION_FOLDER} does not exist." ; export L_RC=1; } || log_this SUCCESS "Migration folder, ${MIGRATION_FOLDER} exist"

[ ! -d ${MIGRATION_FOLDER}/exclusions ] && { log_this ERROR "${MIGRATION_FOLDER}/exclusions does not exist." ; export L_RC=1; } || log_this SUCCESS "Migration folder, ${MIGRATION_FOLDER}/exclusions exist"

[ ! -d ${MIGRATION_FOLDER}/inclusions ] && { log_this ERROR "${MIGRATION_FOLDER}/inclusions does not exist." ; export L_RC=1; } || log_this SUCCESS "Migration folder, ${MIGRATION_FOLDER}/inclusions exist"

[ ! -d ${MIGRATION_FOLDER}/transformations ] && { log_this ERROR "${MIGRATION_FOLDER}/transformations does not exist." ; export L_RC=1; } || log_this SUCCESS "Migration folder, ${MIGRATION_FOLDER}/transformations exist"



if [ ! -f ${MIGRATION_FOLDER}/${L_DB_NAME}_schemas_to_migrate.txt ]; then
  log_this ERROR "${MIGRATION_FOLDER}/\${L_DB_NAME}_schemas_to_migrate.txt file does not exist. This file needs to be created with Oracle and postgres details of the schema/s to be migrated"
  log_this INFO "Format should be #POSTGRES_HOST_NAME, POSTGRES_PORT, POSTGRES_DATABASE_NAME, POSTGRES_SCHEMA_NAME, POSTGRES_SCHEMA_PASSWORD, POSTGRES_CONNECTION_USERNAME, POSTGRES_CONNECTION_PASSWORD, ORACLE_TNSNAME, ORACLE_SCHEMA_NAME, ORACLE_SCHEMA_PASSWORD "
  export L_RC=1
else
  log_this SUCCESS "File ${MIGRATION_FOLDER}/${L_DB_NAME}_schemas_to_migrate.txt exists"
  export L_RC=0
fi


# Checking if the ${MIGRATION_FOLDER}/${L_DB_NAME}_schemas_to_migrate.txt file has all entries populated for each schema
if [ $L_RC = 0 ]; then 
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

      if [ -z ${L_POSTGRES_HOST_NAME} ] || [ -z ${L_POSTGRES_DATABASE_NAME} ] || [ -z ${L_POSTGRES_SCHEMA_NAME} ] || [ -z ${L_POSTGRES_SCHEMA_PASSWORD} ] || [ -z ${L_POSTGRES_CONNECTION_USERNAME} ] || [ -z ${L_POSTGRES_CONNECTION_PASSWORD} ] || [ -z ${L_ORACLE_TNSNAME} ] || [ -z ${L_ORACLE_CONNECTION_USERNAME} ] || [ -z ${L_ORACLE_SCHEMA_PASSWORD} ]; then
        log_this ERROR "Please check file ${MIGRATION_FOLDER}/${L_DB_NAME}_schemas_to_migrate.txt for data related to Postgres schema name = $L_POSTGRES_SCHEMA_NAME"
        continue
      else
        log_this SUCCESS "Variables for schema ${L_POSTGRES_SCHEMA_NAME} are populated"
      fi
      
      
      psql -t -U ${L_POSTGRES_CONNECTION_USERNAME} -h ${L_POSTGRES_HOST_NAME} -p $L_POSTGRES_PORT ${L_POSTGRES_DATABASE_NAME} -c "SELECT CURRENT_DATE ;" 2>&1 > /dev/null
      check_result "$?" "Checking connectivity for schema ${L_POSTGRES_SCHEMA_NAME}"
    done
else
	log_this ERROR "Not checking contents of the \${L_DB_NAME}_schemas_to_migrate.txt file"
fi 

exit $L_RC

# End migration_checks.sh
