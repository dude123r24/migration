#!/bin/bash
# migration_data.sh
# Migrate all data from postgres to oracle. Main script

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
echo "Start: Script migration_data.sh" |& tee -a ${L_LOGFILE}
echo ${L_SEPERATOR} |& tee -a ${L_LOGFILE}
echo " " |& tee -a ${L_LOGFILE}
echo " " |& tee -a ${L_LOGFILE}


$MIGRATION_FOLDER/migration_checks.sh

if [ ! -f ${MIGRATION_FOLDER}/${L_DB_NAME}_schemas_to_migrate.txt ]; then
  log_this ERROR "Config file ${MIGRATION_FOLDER}/${L_DB_NAME}_schemas_to_migrate.txt not found. Exiting"
  exit_gracefully
fi 

L_COUNT_SCHEMAS=$(cat ${MIGRATION_FOLDER}/${L_DB_NAME}_schemas_to_migrate.txt | grep -i ",${L_DB_NAME}_db," | grep -v "#" | wc -l)
if [ -z $L_COUNT_SCHEMAS ] || [[ $L_COUNT_SCHEMAS < 1 ]]; then 
  log_this ERROR "No schemas to process for database ${L_DB_NAME}"
  exit_gracefully
else
  log_this INFO "For database ${L_DB_NAME} we will process $L_COUNT_SCHEMAS schema/s"
fi

log_this INFO "Make sure pg_hba has a line 'host    all             all             0.0.0.0/0               trust'"

# While loop and if statement to make sure the user answers y / n / exit
# Defaulting answer to Y if variable ANSWER_YES_TO_ALL is set to Y, so as to minimise user input when doing many schemas. Hidden variable. Only for Amit's use, as usually we want to keep an eye on the success of migrating individual schemas
if [ ! -z ${ANSWER_YES_TO_ALL} ]; then
   if [ ${ANSWER_YES_TO_ALL} = "YES" ]; then 
      L_OBJECT_DEFN_MIG_ANS="Y"
   fi
else
   unset L_OBJECT_DEFN_MIG_ANS
fi 

while [ -z $L_OBJECT_DEFN_MIG_ANS ]; do
  log_this QUESTION "!!! Have you reset schema's, roles, databases (for all specified in file ${L_DB_NAME}_schemas_to_migrate.txt )? (y/n/exit)"
  read L_OBJECT_DEFN_MIG_ANS
 
  if [ ! -z $L_OBJECT_DEFN_MIG_ANS ]; then
    if [ $L_OBJECT_DEFN_MIG_ANS != "n" ] && [ $L_OBJECT_DEFN_MIG_ANS != "N" ] && [ $L_OBJECT_DEFN_MIG_ANS != "y" ] && [ $L_OBJECT_DEFN_MIG_ANS != "Y" ] && [ $L_OBJECT_DEFN_MIG_ANS != "exit" ] && [ $L_OBJECT_DEFN_MIG_ANS != "EXIT" ]; then
      log_this ERROR "Invalid Choice. Try y or n or exit"
      unset L_OBJECT_DEFN_MIG_ANS
     else
      break
     fi
   fi

done
 
if [ $L_OBJECT_DEFN_MIG_ANS = "n" ] || [ $L_OBJECT_DEFN_MIG_ANS = "N" ]; then
   log_this ERROR "Exiting program as schema's have not been migrated. Run AWS SCT or ora2pg ./export_schema.sh for each schema that needs to be migrated before runing this script again"
   exit_gracefully 
elif [ $L_OBJECT_DEFN_MIG_ANS = "exit" ] || [ $L_OBJECT_DEFN_MIG_ANS = "EXIT" ]; then
   log_this INFO "Terminating script"
   exit_gracefully
fi 


for i in $(cat ${MIGRATION_FOLDER}/${L_DB_NAME}_schemas_to_migrate.txt | grep -i ",${L_DB_NAME}_db," | grep -v "#"); do
  export L_POSTGRES_HOST_NAME=$(echo $i | cut -d',' -f1)
  export L_POSTGRES_PORT=$(echo $i | cut -d',' -f2)
  export L_POSTGRES_DATABASE_NAME=$(echo $i | cut -d',' -f3)
  export L_POSTGRES_SCHEMA_NAME=$(echo $i | cut -d',' -f4)
  export L_POSTGRES_SCHEMA_PASSWORD=$(echo $i | cut -d',' -f5)
  export L_POSTGRES_CONNECTION_USERNAME=$(echo $i | cut -d',' -f6)
  export L_POSTGRES_CONNECTION_PASSWORD=$(echo $i | cut -d',' -f7)
  export L_ORACLE_TNSNAME=$(echo $i | cut -d',' -f8 | tr '[:lower:]' '[:upper:]')
  export L_ORACLE_CONNECTION_USERNAME=$(echo $i | cut -d',' -f9 | tr '[:upper:]' '[:lower:]')
  export L_ORACLE_SCHEMA_PASSWORD=$(echo $i | cut -d',' -f10)

echo " " |& tee -a ${L_LOGFILE}
echo ${L_SEPERATOR} |& tee -a ${L_LOGFILE}
echo "Start: Oracle Schema: $L_POSTGRES_SCHEMA_NAME being migrated to Postgres Database: ${L_POSTGRES_DATABASE_NAME}" |& tee -a ${L_LOGFILE}
echo ${L_SEPERATOR} |& tee -a ${L_LOGFILE}
echo " " |& tee -a ${L_LOGFILE}

log_this INFO "L_UNQ_ID = ${L_UNQ_ID}"

# Creating ORA2PG migration project folder
ora2pg --project_base ${MIGRATION_FOLDER} --init_project ${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID} >> ${L_LOGFILE} 2>&1
check_result "$?" "Create project folder for migration of schema ${L_POSTGRES_SCHEMA_NAME}: Folder: ${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}"


# Add an alias to ~/.bash_profile to enable logging in to the database easily
if [ -f ~/.bash_profile ]; then 
  sed -i -e "s/^alias psql_${L_POSTGRES_SCHEMA_NAME}.*//g" ~/.bash_profile
  echo "alias psql_${L_POSTGRES_SCHEMA_NAME}='psql -U ${L_POSTGRES_SCHEMA_NAME} -h ${L_POSTGRES_HOST_NAME} ${L_POSTGRES_DATABASE_NAME}'" >> ${L_CONFIG_FILE}
fi

# SETUP CONFIG FILE

# Set variable for the path to ora2pg.conf file
export L_CONFIG_FILE="${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/config/ora2pg.conf"
log_this INFO "L_CONFIG_FILE = ${L_CONFIG_FILE}"

if [ ! -f ${L_CONFIG_FILE} ]; then 
  echo "ERROR   : Config file ${L_CONFIG_FILE} does not exist. Please investigate"
  exit_gracefully 
fi 


# Printing main variables in the log file in case L_DEBUG_MODE is set to Y  
  [ -z "${L_DEBUG_MODE}" ] &&  { L_DEBUG_MODE="N" ; } 
  if [ $L_DEBUG_MODE = "Y" ] || [ $L_DEBUG_MODE = "y" ]; then
    echo "Start DEBUG data"
    echo "export L_POSTGRES_HOST_NAME=${L_POSTGRES_HOST_NAME}; export L_POSTGRES_PORT=${L_POSTGRES_PORT} ; export L_POSTGRES_DATABASE_NAME=${L_POSTGRES_DATABASE_NAME} ;"
    echo "export L_POSTGRES_SCHEMA_NAME=${L_POSTGRES_SCHEMA_NAME}; export L_POSTGRES_SCHEMA_PASSWORD=${L_POSTGRES_SCHEMA_PASSWORD}; export L_POSTGRES_CONNECTION_USERNAME=${L_POSTGRES_CONNECTION_USERNAME}"
    echo "export L_POSTGRES_CONNECTION_PASSWORD=${L_POSTGRES_CONNECTION_PASSWORD}; export L_ORACLE_TNSNAME=${L_ORACLE_TNSNAME}; export L_ORACLE_CONNECTION_USERNAME=${L_ORACLE_CONNECTION_USERNAME}"
    echo "export L_ORACLE_SCHEMA_PASSWORD=${L_ORACLE_SCHEMA_PASSWORD}; export L_UNQ_ID=${L_UNQ_ID}; L_LOGFILE=${L_LOGFILE};"
    echo "export L_CONFIG_FILE=${L_CONFIG_FILE}; export MIGRATION_FOLDER=${MIGRATION_FOLDER}; cd ${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}"
    echo "End DEBUG data"
  fi


log_this INFO "Taking backup of config file to ${L_CONFIG_FILE}_${L_UNQ_ID} and removing existing parameters"
cp ${L_CONFIG_FILE} ${L_CONFIG_FILE}_${L_UNQ_ID}
check_result "$?" "Taking backup of config file"




####################################################### Remove previous entries from ora2pg.conf

sed -i -e "s/^ORACLE_DSN.*//g" ${L_CONFIG_FILE}
sed -i -e "s/^ORACLE_USER.*//g" ${L_CONFIG_FILE}
sed -i -e "s/^ORACLE_PWD.*//g" ${L_CONFIG_FILE}
sed -i -e "s/^DEFAULT_PARALLELISM_DEGREE.*//g" ${L_CONFIG_FILE}
sed -i -e "s/^PARALLEL_TABLES.*//g" ${L_CONFIG_FILE}
sed -i -e "s/^PG_DSN.*//g" ${L_CONFIG_FILE}
sed -i -e "s/^PG_USER.*//g" ${L_CONFIG_FILE}
sed -i -e "s/^PG_PWD.*//g" ${L_CONFIG_FILE}
sed -i -e "s/^SCHEMA.*//g" ${L_CONFIG_FILE}
sed -i -e "s/^TYPE.*//g" ${L_CONFIG_FILE}
#sed -i -e "s/^EXPORT_SCHEMA.*//g" ${L_CONFIG_FILE}
sed -i -e "s/^PG_SCHEMA.*//g" ${L_CONFIG_FILE}
sed -i -e "s/^CREATE_SCHEMA.*//g" ${L_CONFIG_FILE}

sed -i -e "s/^DEFAULT_NUMERIC.*//g" ${L_CONFIG_FILE}
sed -i -e "s/^PG_NUMERIC_TYPE.*//g" ${L_CONFIG_FILE}
#sed -i -e "s/^DATA_TYPE.*//g" ${L_CONFIG_FILE}

sed -i -e "s/^EXCLUDE.*//g" ${L_CONFIG_FILE}
sed -i -e "s/^TRUNCATE_TABLE.*/^\#TRUNCATE_TABLE.*/g" ${L_CONFIG_FILE}
# sed -i -e "s/^OUTPUT.*//g" ${L_CONFIG_FILE}
check_result "$?" "Cleaning up old parameters in config file: ${L_CONFIG_FILE}"

# Parameter to defer fkey creation in postgres so invalid data and disabled constraints in Oracle do not cause trouble in Postgres
sed -i -e "s/^FKEY_DEFERRABLE.*//g" ${L_CONFIG_FILE}
sed -i -e "s/^DEFER_FKEY.*//g" ${L_CONFIG_FILE}
sed -i -e "s/^DROP_FKEY.*//g" ${L_CONFIG_FILE}
sed -i -e "s/^SKIP fkeys.*//g" ${L_CONFIG_FILE}
sed -i -e "s/^DISABLE_TRIGGERS.*//g" ${L_CONFIG_FILE}

# To help with exporting grants
sed -i -e "s/^USER_GRANTS.*//g" ${L_CONFIG_FILE}


# To prevent packages creating a new schema everytime. Also this behaviour was trying to create roles. Sometimes those roles pre-existed, so the migration would fail.
sed -i -e "s/^PACKAGE_AS_SCHEMA.*//g" ${L_CONFIG_FILE}



####################################################### Add new entries to ora2pg.conf

echo "# Params updated by PHE data migration automation script" >> ${L_CONFIG_FILE}
echo "ORACLE_DSN dbi:Oracle:${L_ORACLE_TNSNAME}" >> ${L_CONFIG_FILE}
echo "ORACLE_USER ${L_ORACLE_CONNECTION_USERNAME}" >> ${L_CONFIG_FILE}
echo "ORACLE_PWD ${L_ORACLE_SCHEMA_PASSWORD}" >> ${L_CONFIG_FILE}
echo "DEFAULT_PARALLELISM_DEGREE 5" >> ${L_CONFIG_FILE}
echo "PARALLEL_TABLES 5" >> ${L_CONFIG_FILE}
echo "SCHEMA ${L_POSTGRES_SCHEMA_NAME}" >> ${L_CONFIG_FILE}

# Changed this to enable extracting table definitions (part of code to extract using ora2pg as opposed to AWS SCT)
# echo "TYPE COPY" >> ${L_CONFIG_FILE}
# Removed Package from below as packages were causing us a lot of trouble
echo "TYPE COPY TABLE PARTITION VIEW SEQUENCE GRANT FUNCTION PROCEDURE TRIGGER " >> ${L_CONFIG_FILE}
# echo "TYPE TABLE PACKAGE COPY VIEW SEQUENCE TRIGGER FUNCTION PROCEDURE GRANT" >> ${L_CONFIG_FILE}

# Disabled as i was having to disable statement SET search_path = util; from the create type statement
echo "#EXPORT_SCHEMA 1" >> ${L_CONFIG_FILE}
echo "PG_SCHEMA ${L_POSTGRES_SCHEMA_NAME}" >> ${L_CONFIG_FILE}

# Commented CREATE_SCHEMA as it was dropping and recreating the schema
echo "CREATE_SCHEMA 0" >> ${L_CONFIG_FILE}

# Added this is numeric columns with decimals were being converted into bigint (by ORA2PG) which does not allow any decimals. Below helps us map data types between Oracle and Postgres. To add moreuse comma as a seperator 
#echo "DATA_TYPE NUMBER:numeric(64,30)" >> ${L_CONFIG_FILE}

# 22/01/2021: Amit: Commented out DEFAULT_NUMERIC as data type conversion below was creating problems in dev schema import for table ORGAN_REQ - Foreign Key "rcp_organ_req_fk"
echo "DEFAULT_NUMERIC real" >> ${L_CONFIG_FILE}
# 22/01/2021: Amit: Changed value from 0 to 1, as we need the default conversions to take place
echo "PG_NUMERIC_TYPE 1" >> ${L_CONFIG_FILE}
# 22/01/2021: Amit: added below param, as we need the default conversions to take place
echo "PG_INTEGER_TYPE 0" >> ${L_CONFIG_FILE}

# Foreign keys were creating a problem when importing data. So making them deferable/ skipping them
echo "FKEY_DEFERRABLE 1" >> ${L_CONFIG_FILE}
echo "DROP_FKEY 1" >> ${L_CONFIG_FILE}
echo "DEFER_FKEY 1" >> ${L_CONFIG_FILE}
echo "SKIP fkeys" >> ${L_CONFIG_FILE}
echo "DISABLE_TRIGGERS" >> ${L_CONFIG_FILE}

# To help with exporting grants
echo "USER_GRANTS 0" >> ${L_CONFIG_FILE}

# To prevent packages creating a new schema everytime. Also this behaviour was trying to create roles. Sometimes those roles pre-existed, so the migration would fail.
echo "PACKAGE_AS_SCHEMA 0" >> ${L_CONFIG_FILE}

check_result "$?" "Adding parameters in config file: ${L_CONFIG_FILE}"





####################################################### Add exclude parameters

# Code to add the exclude parameter to ora2pg config file 
if [ -d ${MIGRATION_FOLDER}/exclusions ]; then
  if [ -f ${MIGRATION_FOLDER}/exclusions/${L_DB_NAME}_${L_POSTGRES_SCHEMA_NAME}.txt ]; then
    sed -i -e ':a;N;$!ba;s/\n/ /g' ${MIGRATION_FOLDER}/exclusions/${L_DB_NAME}_${L_POSTGRES_SCHEMA_NAME}.txt   # Combine multi lines into single line
    sed -i -e "s/^exclude / /gi" ${MIGRATION_FOLDER}/exclusions/${L_DB_NAME}_${L_POSTGRES_SCHEMA_NAME}.txt # Remove exclude keyword if at the start of the file
    sed -i -e "s/^/EXCLUDE /g" ${MIGRATION_FOLDER}/exclusions/${L_DB_NAME}_${L_POSTGRES_SCHEMA_NAME}.txt # Add EXCLUDE at the start of the line in the file

    cat ${MIGRATION_FOLDER}/exclusions/${L_DB_NAME}_${L_POSTGRES_SCHEMA_NAME}.txt >> ${L_CONFIG_FILE} # Add the exclusion into the config file
    log_this INFO "Excluding the following objects from export. File: ${MIGRATION_FOLDER}/exclusions/${L_DB_NAME}_${L_POSTGRES_SCHEMA_NAME}.txt"
    log_this INFO "`cat ${MIGRATION_FOLDER}/exclusions/${L_DB_NAME}_${L_POSTGRES_SCHEMA_NAME}.txt`"
    check_result "$?" "Add exclude parameters to config file for schema ${L_POSTGRES_SCHEMA_NAME}" 
  fi 
fi 

####################################################### Add extra schema specific parameters

# Code to add the additional schema specific parameters to ora2pg config file 
if [ -d ${MIGRATION_FOLDER}/inclusions ]; then
  if [ -f ${MIGRATION_FOLDER}/inclusions/${L_DB_NAME}_${L_POSTGRES_SCHEMA_NAME}.txt ]; then
    cat ${MIGRATION_FOLDER}/inclusions/${L_DB_NAME}_${L_POSTGRES_SCHEMA_NAME}.txt >> ${L_CONFIG_FILE} # Add the additional parameters into the config file
    log_this INFO "Additional config parameters included below. File: ${MIGRATION_FOLDER}/inclusions/${L_DB_NAME}_${L_POSTGRES_SCHEMA_NAME}.txt"
    log_this INFO "`cat ${MIGRATION_FOLDER}/inclusions/${L_DB_NAME}_${L_POSTGRES_SCHEMA_NAME}.txt`"
    check_result "$?" "Add additional parameters to config file for schema ${L_POSTGRES_SCHEMA_NAME}" 
  fi 
fi 

####################################################### End of setting up config file





# Testing oracle connectivity from ora2pg
cd ${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}
log_this COMMAND "Running ora2pg -t SHOW_VERSION -c ${L_CONFIG_FILE}"
ora2pg -t SHOW_VERSION -c ${L_CONFIG_FILE} && log_this SUCCESS "Testing connectivity to Oracle database"  >> ${L_LOGFILE} 2>&1
check_result "$?" "Testing connectivity to Oracle database"


# Code to generate migration report. Its only generated if variable L_GEN_REPORT is set to Y in migration_common_settings.sh
if [ -z $L_GEN_REPORT ] || [ $L_GEN_REPORT = 'Y' ]; then
  log_this INFO "Generating ora2pg migration report. This may take some time"

  ora2pg -t SHOW_REPORT --estimate_cost --cost_unit_value 30 -c ${L_CONFIG_FILE} 2>&1 > ${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/ora2pg_migration_report.txt > /dev/null
  check_result "$?" "Generated ora2pg migration report. Please check file ${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/ora2pg_migration_report.txt"
  echo "Press any key to continue. Ctrl + c to exit"
  read L_CONTINUE
fi


####################################################### Export schema using export_schema.sh

log_this INFO "The export_schema command takes time and the screen wont progress for a little bit. Please wait"
log_this COMMAND "${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/export_schema.sh"
${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/export_schema.sh 

check_result "$?" "Export Schema using ora2pg"


####################################################### Exporting data using data.sql

log_this COMMAND "${ORA2PG_BIN} -t COPY -o data.sql -b ${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/data -c ${L_CONFIG_FILE}"

${ORA2PG_BIN} -t COPY -o data.sql -b ${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/data -c ${L_CONFIG_FILE} 

check_result "$?" "Export data for schema ${L_POSTGRES_SCHEMA_NAME} using ora2pg"




####################################################### Adding Postgres database connectivity parameters to ora20g.conf file. It imp to do it here, as if done earlier, the export process will try to directly send it to postgres database. We cannot do that, as we need to customise and control the import process.

# Add new entries to ora2pg.conf
echo "PG_DSN dbi:Pg:dbname=${L_POSTGRES_DATABASE_NAME};host=${L_POSTGRES_HOST_NAME};port=${L_POSTGRES_PORT}" >> ${L_CONFIG_FILE}
echo "PG_USER ${L_POSTGRES_SCHEMA_NAME}" >> ${L_CONFIG_FILE}
echo "PG_PWD ${L_POSTGRES_SCHEMA_PASSWORD}" >> ${L_CONFIG_FILE}


# If you wanted to see the data in files and then import, move adding the parameter PG_DSN, PG_USER, PG_PWD to L_CONFIG_FILE/ora2pg.conf file, just before this statement. 
# You will need to disable the L_TABLE_COUNT check 
# The sed command to remove these parameters from the L_CONFIG_FILE/ora2pg.conf file should stay where it is.
# The below statement is not necessary for direct export-import. Its only needed when you want to export to file and then import. ie in 2 stages.



####################################################### Run transformations on data and schema source files, specific to this schema


# Run transformations for this schema. First checking if the transformations folder exists. Then checking if there is a corresponding transformation file for this schema

# Debug 
# print_vars BEFORE_CALLING_TRANSFORMATIONS |& tee -a ${L_LOGFILE}

export L_POSTGRES_SCHEMA_NAME

if [ -d ${MIGRATION_FOLDER}/transformations ]; then
  if [ -f ${MIGRATION_FOLDER}/transformations/${L_DB_NAME}_${L_POSTGRES_SCHEMA_NAME}.sh ]; then
    log_this INFO "Executing transformations. File: ${MIGRATION_FOLDER}/transformations/${L_DB_NAME}_${L_POSTGRES_SCHEMA_NAME}.sh"
	
    ${MIGRATION_FOLDER}/transformations/${L_DB_NAME}_${L_POSTGRES_SCHEMA_NAME}.sh "${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}"
    check_result "$?" "Run transformations for schema ${L_POSTGRES_SCHEMA_NAME}"
	
  fi 
fi 


####################################################### Modifying import_all.sh and other files to customise the import process.


# Disabling drop and recreate database in import_schema.sh

log_this INFO "Disabling drop and recreate database in ${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/import_all.sh as we create it in the migration_reset script"
sed -i -e "s/^\s*dropdb\$DB/echo \" \" # Amit: Commented by migration script as this was recreating the DB, which we had already setup # dropdb\$DB/g" "${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/import_all.sh"

sed -i -e "s/^\s*createdb\$DB/echo \" \" # Amit: Commented by migration script as this was recreating the DB, which we had already setup # createdb\$DB/g" "${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/import_all.sh"

sed -i -e "s/^\s*echo \"Running: dropdb\$DB/echo \" \" # Amit: Commented by migration script as this comment was not needed # echo \"Running: dropdb\$DB/g" "${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/import_all.sh"

sed -i -e "s/^\s*echo \"Running: createdb\$DB/echo \" \" # Amit: Commented by migration script as this comment was not needed # echo \"Running: createdb\$DB/g" "${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/import_all.sh"



# Disabling creating oracle tablespaces, as we do not need them as of now

log_this INFO "Disabling create tablespace in ${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/import_all.sh as it's not needed"
sed -i -e "s/psql \$DB\_HOST\$DB\_PORT -U postgres -d \$DB\_NAME -f \$NAMESPACE\/schema\/tablespaces\/tablespace.sql/# Commented by migration script # psql \$DB\_HOST\$DB\_PORT -U postgres -d \$DB\_NAME -f \$NAMESPACE\/schema\/tablespaces\/tablespace.sql/g" "${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/import_all.sh"

sed -i -r "s/^EXPORT_TYPE=\"(.*)TABLESPACE\ (.*)/EXPORT_TYPE=\"\1\2/g" "${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/import_all.sh"


# Disabling executing triggers, as sometimes these triggers depend on objects in other schemas (and DDL fails as those users and/or objects are not yet created)

# psql --single-transaction $DB_HOST$DB_PORT -U $DB_OWNER -d $DB_NAME -f $NAMESPACE/schema/triggers/trigger.sql
log_this INFO "DISABLING executing triggers in ${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/import_all.sh as triggers depend on ..."
log_this INFO "... objects in other schemas (and DDL fails as those users and/or objects are not yet created). Execute them later"

sed -i -e "s/psql --single-transaction \$DB\_HOST\$DB\_PORT -U \$DB\_OWNER -d \$DB\_NAME -f \$NAMESPACE\/schema\/triggers\/trigger.sql/# Commented by migration script # psql --single-transaction \$DB\_HOST\$DB\_PORT -U \$DB\_OWNER -d \$DB\_NAME -f \$NAMESPACE\/schema\/triggers\/trigger.sql/g" "${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/import_all.sh"

sed -i -r "s/^EXPORT_TYPE=\"(.*)TRIGGER\ (.*)/EXPORT_TYPE=\"\1\2/g" "${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/import_all.sh"


# Disable importing packages (related to the TYPE parameter ... I've removed packages from there as well)
log_this INFO "DISABLING executing triggers in ${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/import_all.sh as triggers depend on ..."

sed -i -r "s/^EXPORT_TYPE=\"(.*)PACKAGE\ (.*)/EXPORT_TYPE=\"\1\2/g" "${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/import_all.sh"



# psql$DB_HOST$DB_PORT -U $DB_OWNER -d $DB_NAME -f $NAMESPACE/schema/tables/FKEYS_table.sql
# ora2pg$IMPORT_JOBS -c config/ora2pg.conf -t LOAD -i $NAMESPACE/schema/tables/FKEYS_table.sql


# Creating directory for the create role, create user and other SQL statements.
if [ ! -d ${MIGRATION_FOLDER}/pre-migration-sqls ]; then 
   mkdir -p ${MIGRATION_FOLDER}/pre-migration-sqls
fi

if [ -f ${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/schema/grants/grant.sql ]; then

  if [ `cat ${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/schema/grants/grant.sql | grep "CREATE USER" | wc -l` -ge 1 ]; then 

     # Before commenting, we extract the create user statements in a .sql file so that we can execute it before doing the import.  
     cat ${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/schema/grants/grant.sql | grep "CREATE USER" > ${MIGRATION_FOLDER}/pre-migration-sqls/${L_DB_NAME}_${L_POSTGRES_SCHEMA_NAME}_users.sql

     # Comment out the create user statements in the grant.sql file
     sed -i -r "s/^CREATE USER\ /-- CREATE USER\ /g" "${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/schema/grants/grant.sql"

  fi

  if [ `cat ${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/schema/grants/grant.sql | grep "CREATE ROLE" | wc -l` -ge 1 ]; then 

     # Before commenting, we extract the create role statements in a .sql file so that we can execute it before doing the import.  
     cat ${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/schema/grants/grant.sql | grep "CREATE ROLE" > ${MIGRATION_FOLDER}/pre-migration-sqls/${L_DB_NAME}_${L_POSTGRES_SCHEMA_NAME}_roles.sql

     # Comment out the create role statements in the grant.sql file. These statements need to be run seperately as if they fail, it causes the entire migration to fail  
     sed -i -r "s/^CREATE ROLE\ /-- CREATE ROLE\ /g" "${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/schema/grants/grant.sql"
  fi 
  
fi
  



####################################################### Remove " for column names in select statements for views



if [ `ls -l ${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/schema/views/*.sql 2>/dev/null | wc -l` -ge 1 ]; then
  log_this INFO "Transforming view definitions (replace \" with space), File: ${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/schema/views/*.sql"
  sed -i -E -r "s|\"| |g" ${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/schema/views/*.sql
  check_result "$?" "Transforming view definitions (replace \" with space), File: ${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/schema/views/*.sql"
fi



####################################################### Replace some hardcoded scripts

if [ -d ${MIGRATION_FOLDER}/replacements/${L_ORACLE_TNSNAME}/${L_POSTGRES_SCHEMA_NAME}/schema ]; then
  log_this INFO "Replacing scripts from ${MIGRATION_FOLDER}/replacements/${L_ORACLE_TNSNAME}/${L_POSTGRES_SCHEMA_NAME}/schema to ${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/schema"
  cp -r ${MIGRATION_FOLDER}/replacements/${L_ORACLE_TNSNAME}/${L_POSTGRES_SCHEMA_NAME}/schema/* ${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/schema/
fi 




####################################################### Execute pre migration SQLs


# Creating users

if [ -f ${MIGRATION_FOLDER}/pre-migration-sqls/${L_DB_NAME}_${L_POSTGRES_SCHEMA_NAME}_users.sql ]; then
   log_this INFO "Executing pre migration create user script. File: ${MIGRATION_FOLDER}/pre-migration-sqls/${L_DB_NAME}_${L_POSTGRES_SCHEMA_NAME}_users.sql"
   log_this COMMAND "  psql -t -U ${L_POSTGRES_SCHEMA_NAME} -h ${L_POSTGRES_HOST_NAME} -p $L_POSTGRES_PORT ${L_POSTGRES_DATABASE_NAME} -o ${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/pre_migration_users.out -c \"\\i ${MIGRATION_FOLDER}/pre-migration-sqls/${L_DB_NAME}_${L_POSTGRES_SCHEMA_NAME}_users.sql\"   "
   psql -t -U ${L_POSTGRES_SCHEMA_NAME} -h ${L_POSTGRES_HOST_NAME} -p $L_POSTGRES_PORT ${L_POSTGRES_DATABASE_NAME} -o ${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/pre_migration_users.out -c "\i ${MIGRATION_FOLDER}/pre-migration-sqls/${L_DB_NAME}_${L_POSTGRES_SCHEMA_NAME}_users.sql"  2>&1 > /dev/null
   check_result "$?" "Run pre migration create user script for schema ${L_POSTGRES_SCHEMA_NAME}"
fi 

# Creating roles

if [ -f ${MIGRATION_FOLDER}/pre-migration-sqls/${L_DB_NAME}_${L_POSTGRES_SCHEMA_NAME}_roles.sql ]; then
   log_this INFO "Executing pre migration create role script. File: ${MIGRATION_FOLDER}/pre-migration-sqls/${L_DB_NAME}_${L_POSTGRES_SCHEMA_NAME}_roles.sql"
   log_this COMMAND "  psql -t -U ${L_POSTGRES_SCHEMA_NAME} -h ${L_POSTGRES_HOST_NAME} -p $L_POSTGRES_PORT ${L_POSTGRES_DATABASE_NAME} -o ${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/pre_migration_roles.out -c \"\\i ${MIGRATION_FOLDER}/pre-migration-sqls/${L_DB_NAME}_${L_POSTGRES_SCHEMA_NAME}_roles.sql\"   "
   psql -t -U ${L_POSTGRES_SCHEMA_NAME} -h ${L_POSTGRES_HOST_NAME} -p $L_POSTGRES_PORT ${L_POSTGRES_DATABASE_NAME} -o ${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/pre_migration_roles.out -c "\i ${MIGRATION_FOLDER}/pre-migration-sqls/${L_DB_NAME}_${L_POSTGRES_SCHEMA_NAME}_roles.sql"  2>&1 > /dev/null
   check_result "$?" "Run pre migration grants for schema ${L_POSTGRES_SCHEMA_NAME}"
fi 




# executing any pre-migration SQL's

if [ -f ${MIGRATION_FOLDER}/pre-migration-sqls/${L_DB_NAME}_${L_POSTGRES_SCHEMA_NAME}.sql ]; then
log_this INFO "Executing pre migration sqls. File: ${MIGRATION_FOLDER}/pre-migration-sqls/${L_DB_NAME}_${L_POSTGRES_SCHEMA_NAME}.sql"

log_this COMMAND "  psql -t -U ${L_POSTGRES_SCHEMA_NAME} -h ${L_POSTGRES_HOST_NAME} -p $L_POSTGRES_PORT ${L_POSTGRES_DATABASE_NAME} -o ${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/pre_migration_sqls.out -c \"\\i ${MIGRATION_FOLDER}/pre-migration-sqls/${L_DB_NAME}_${L_POSTGRES_SCHEMA_NAME}.sql\"   "

psql -t -U ${L_POSTGRES_SCHEMA_NAME} -h ${L_POSTGRES_HOST_NAME} -p $L_POSTGRES_PORT ${L_POSTGRES_DATABASE_NAME} -o ${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/pre_migration_sqls.out -c "\i ${MIGRATION_FOLDER}/pre-migration-sqls/${L_DB_NAME}_${L_POSTGRES_SCHEMA_NAME}.sql"  2>&1 > /dev/null

check_result "$?" "Run pre migration sqls for schema ${L_POSTGRES_SCHEMA_NAME}"

fi 



####################################################### Importing schema and data using import_all.sh

cd ${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}

log_this COMMAND "${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/import_all.sh -d ${L_POSTGRES_DATABASE_NAME} -o ${L_POSTGRES_SCHEMA_NAME} -U ${L_POSTGRES_SCHEMA_NAME} -y -h ${L_POSTGRES_HOST_NAME} -p ${L_POSTGRES_PORT}"

${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/import_all.sh -d ${L_POSTGRES_DATABASE_NAME} -o ${L_POSTGRES_SCHEMA_NAME} -U ${L_POSTGRES_SCHEMA_NAME} -y -h ${L_POSTGRES_HOST_NAME} -p ${L_POSTGRES_PORT} -j 2 -P 2 -x |& tee -a ${L_LOGFILE}

check_result "$?" "Import Schema using ora2pg. Logfile ${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/import.log"




####################################################### TABLE_COUNT Check
# Checking if table structures have been created

  L_TABLE_COUNT=$(psql -t -U ${L_POSTGRES_SCHEMA_NAME} -h ${L_POSTGRES_HOST_NAME} -p $L_POSTGRES_PORT ${L_POSTGRES_DATABASE_NAME} -c "select count(1) from information_schema.tables where table_schema='${L_POSTGRES_SCHEMA_NAME}';" | xargs) 
  if [ ! -z ${L_TABLE_COUNT} ] && [[ ${L_TABLE_COUNT} < 1 ]]; then
    log_this WARNING "No tables in the current schema. Nothing to do"
    continue 
  else
    log_this INFO "Checking tables created. Table count = $L_TABLE_COUNT"
  fi 


################ creating files to tally number of rows in Oracle and Postgres tables

################ Postgres
# Generating POSTGRES row count statements dynamically.
log_this COMMAND "psql -t -U ${L_POSTGRES_SCHEMA_NAME} -h ${L_POSTGRES_HOST_NAME} -p $L_POSTGRES_PORT ${L_POSTGRES_DATABASE_NAME} -o ${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/postgres_table_counts.sql -c \"select 'select ' || '''' || schemaname || '.' || tablename || '''' || ' , count(1) from ' || schemaname || '.' || tablename  || ' ; ' from pg_tables where schemaname = '${L_POSTGRES_SCHEMA_NAME}' order by tablename; \" "

psql -t -U ${L_POSTGRES_SCHEMA_NAME} -h ${L_POSTGRES_HOST_NAME} -p $L_POSTGRES_PORT ${L_POSTGRES_DATABASE_NAME} -o ${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/postgres_table_counts.sql -c "select 'select ' || ''''  || tablename || '''' || ' , count(1) from ' || schemaname || '.' || tablename  || ' ; ' from pg_tables where schemaname = '${L_POSTGRES_SCHEMA_NAME}' order by tablename;"  2>&1 > /dev/null

check_result "$?" "Generated SQL statements to select count from all tables in POSTGRES schema ${L_POSTGRES_SCHEMA_NAME}"


# Executing dynamically genereated POSTGRES row count statements.
log_this COMMAND "psql -t -U ${L_POSTGRES_SCHEMA_NAME} -h ${L_POSTGRES_HOST_NAME} -p $L_POSTGRES_PORT ${L_POSTGRES_DATABASE_NAME} -o ${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/postgres_table_counts.out -c \"\i  ${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/postgres_table_counts.sql\""

psql -t -U ${L_POSTGRES_SCHEMA_NAME} -h ${L_POSTGRES_HOST_NAME} -p $L_POSTGRES_PORT ${L_POSTGRES_DATABASE_NAME} -o ${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/postgres_table_counts.out -AF $',' -c "\i  ${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/postgres_table_counts.sql"  2>&1 > /dev/null

check_result "$?" "Executed select count for for POSTGRES tables in schema ${L_POSTGRES_SCHEMA_NAME}"

sed -i 's/[[:space:]]*//g' ${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/postgres_table_counts.out
sed -i '/^$/d' ${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/postgres_table_counts.out


################ Oracle


cd ${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}

log_this COMMAND "select 'select ' || '''' || table_name || ',' || '''' || ' , count(1) from ' || owner || '.' || '\"' || table_name || '\"' || ' ;' from dba_tables where owner = upper('$L_POSTGRES_SCHEMA_NAME') order by table_name ;"

sqlplus -s ${L_ORACLE_CONNECTION_USERNAME}/${L_ORACLE_SCHEMA_PASSWORD}@${L_ORACLE_TNSNAME} 2>&1 > /dev/null <<EOF
whenever sqlerror exit sql.sqlcode;
set echo off 
set verify off
set feedback off
set head off
set pages 1000
set lines 200
spool ${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/oracle_table_counts.sql

select 'set echo off 
set verify off
set feedback off
set head off
' from dual;

select 'spool ${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/oracle_table_counts.out' from dual;
select 'select ' || '''' || table_name || ',' || '''' || ' , count(1) from ' || owner || '.' || '"' || table_name || '"' || ' ;' from dba_tables where owner = upper('$L_POSTGRES_SCHEMA_NAME') order by table_name ;
select 'spool off' from dual;
select 'exit' from dual;
spool off
exit
EOF

check_result "$?" "Generated SQL statements to select count from all tables in ORACLE schema ${L_POSTGRES_SCHEMA_NAME}"

log_this COMMAND "sqlplus -s ${L_ORACLE_CONNECTION_USERNAME}/PASSWORD@${L_ORACLE_TNSNAME} @${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/oracle_table_counts.sql"  
sqlplus -s ${L_ORACLE_CONNECTION_USERNAME}/${L_ORACLE_SCHEMA_PASSWORD}@${L_ORACLE_TNSNAME} @${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/oracle_table_counts.sql 2>&1 > /dev/null

check_result "$?" "Executed select count for for ORACLE tables in schema ${L_POSTGRES_SCHEMA_NAME}"

sed -i 's/[[:space:]]*//g' ${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/oracle_table_counts.out # remove spaces
sed -i '/^$/d' ${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/oracle_table_counts.out # remove empty lines


################ Removing tables which have been excluded from export, from row count files

#if [ -d ${MIGRATION_FOLDER}/exclusions ]; then
#  if [ -f ${MIGRATION_FOLDER}/exclusions/${L_DB_NAME}_${L_POSTGRES_SCHEMA_NAME}.txt ]; then
#    log_this INFO "Removing tables which have been excluded from export, from Oracle and Postgres row count files"


#    log_this INFO "Renaming tables which have been renamed in export, from Postgres row count file"

#    check_result "$?" "Add exclude parameters to config file for schema ${L_POSTGRES_SCHEMA_NAME}" 
#  fi 
#fi 


################ Comparing files generated above to check row counts. Oracle used as source to compare.

for tbl in $(cat ${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/oracle_table_counts.out); do
  L_ORACLE_TAB=$(echo $tbl | cut -d ',' -f1)
  L_ORACLE_TAB_ROW_CNT=$(echo $tbl | cut -d ',' -f2)
  L_POSTGRES_ROWEXISTS=$(cat ${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/postgres_table_counts.out | grep -i "^$L_ORACLE_TAB,") || { log_this ERROR "Table Count for table $L_ORACLE_TAB not available in Postgres"; continue; } 
  # && { log_this INFO "Table Count for table $L_ORACLE_TAB available"; } 
  L_POSTGRES_TAB=$(echo $L_POSTGRES_ROWEXISTS | cut -d ',' -f1)
  L_POSTGRES_TAB_ROW_CNT=$(echo $L_POSTGRES_ROWEXISTS | cut -d ',' -f2)
  
#  echo "L_ORACLE_TAB=$L_ORACLE_TAB , L_ORACLE_TAB_ROW_CNT=$L_ORACLE_TAB_ROW_CNT , L_POSTGRES_TAB=$L_POSTGRES_TAB , L_POSTGRES_TAB_ROW_CNT=$L_POSTGRES_TAB_ROW_CNT"

  if [[ $L_ORACLE_TAB_ROW_CNT -ne $L_POSTGRES_TAB_ROW_CNT ]]; then
    log_this ERROR "Table Count for table $L_ORACLE_TAB is not the same. Oracle=${L_ORACLE_TAB_ROW_CNT}, Postgres=${L_POSTGRES_TAB_ROW_CNT}."
  else
    log_this INFO "Table Count for table $L_ORACLE_TAB is the same in Oracle and Postgres"
  fi
done
  
# Listing Tables and corresponding rows
log_this INFO "Postgres table row counts in file ${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/postgres_table_counts.out"
log_this INFO "Oracle table row counts in file ${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/oracle_table_counts.out"

echo " " |& tee -a ${L_LOGFILE}
echo ${L_SEPERATOR} |& tee -a ${L_LOGFILE}
echo "END: Oracle Schema: $L_POSTGRES_SCHEMA_NAME migrated to Postgres Database: ${L_POSTGRES_DATABASE_NAME}" |& tee -a ${L_LOGFILE}
echo ${L_SEPERATOR} |& tee -a ${L_LOGFILE}
echo " " |& tee -a ${L_LOGFILE}

done

log_this INFO "Please revoke superuser privileges from the user ${L_POSTGRES_SCHEMA_NAME}. Grant appropriate privs"
log_this INFO "REMOVE line from pg_hba.conf: 'host    all             all             0.0.0.0/0               trust' after all migrations are done"

echo " " |& tee -a ${L_LOGFILE}
echo " " |& tee -a ${L_LOGFILE}
echo ${L_SEPERATOR} |& tee -a ${L_LOGFILE}
echo "End: Script migration_data.sh" |& tee -a ${L_LOGFILE}
echo ${L_SEPERATOR} |& tee -a ${L_LOGFILE}
echo " " |& tee -a ${L_LOGFILE}
echo " " |& tee -a ${L_LOGFILE}

cp -f ${L_LOGFILE} ${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/
log_this INFO "Log file can be found in ${L_LOGFILE}"


list_errors ${L_LOGFILE}

exit_gracefully