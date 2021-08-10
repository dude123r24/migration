# To set env variables in case you want to run oracle to postgres migration scripts on command line

export L_SEPERATOR="+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo -e $L_SEPERATOR: START
echo "MAKE SURE YOU ARE EXECUTING THIS SCRIPT using the command \"source setup2runadhocscriptlets.sh\" "
echo -e ${L_SEPERATOR}
sleep 2

unset L_POSTGRES_HOST_NAME
unset L_POSTGRES_PORT
unset L_POSTGRES_DATABASE_NAME
unset L_POSTGRES_SCHEMA_NAME
unset L_POSTGRES_SCHEMA_PASSWORD
unset L_POSTGRES_CONNECTION_USERNAME
unset L_POSTGRES_CONNECTION_PASSWORD
unset L_ORACLE_TNSNAME
unset L_ORACLE_CONNECTION_USERNAME
unset L_ORACLE_SCHEMA_PASSWORD

unset L_DB_NAME
while [ -z $L_DB_NAME ]; do
echo QUESTION: "Please enter db name"
read L_DB_NAME
done
export L_DB_NAME=$(echo $L_DB_NAME | tr "a-z" "A-Z")

echo -e ${L_SEPERATOR}

unset L_UNQ_ID
while [ -z $L_UNQ_ID ]; do
echo QUESTION: "Please enter unique id post fix for the folder you want to run commands against (should look like 20201222102443)"
read L_UNQ_ID
done
export L_UNQ_ID


function check_result ()
{
# return code, action
  [ $# -ne 2 ] && { log_this ERROR "Usage: log_this param1 param2"; return 1; } 
  
  [ ! -z "${1}" ] &&  { L_RETURN_CODE="${1}"; }
  [ ! -z "${2}" ] &&  { L_ACTION="${2}"; }

  if [ $L_RETURN_CODE = 0 ]; then
    log_this SUCCESS "${L_ACTION}"
	export RC=0
  elif [ $L_RETURN_CODE = 1 ]; then
    log_this ERROR "Return Code: $L_RETURN_CODE. ${L_ACTION}"
	export RC=1
  else
    log_this WARNING "Return Code: $L_RETURN_CODE. ${L_ACTION}"
	export RC=$L_RETURN_CODE
  fi
}

function log_this ()
{
# type, message text

  [ $# -ne 2 ] && { echo "Usage: log_this param1 param2"; return 1; } 
  
  [ ! -z "${1}" ] &&  { TYPE="${1}"; }
  [ ! -z "${2}" ] &&  { L_MESSAGE="${2}"; }

  L_TYPE=`printf '%-10s' [${TYPE}]`
  
  if [ -z $LOGFILE ]; then
    printf "${L_TYPE} : $(date '+%Y%m%d%H%M%S') %-2s : ${L_MESSAGE}\n"
  else
    printf "${L_TYPE} : $(date '+%Y%m%d%H%M%S') %-2s : ${L_MESSAGE}\n" | tee -a ${LOGFILE}
  fi
}

export ORA2PG_FOLDER="/home/postgres/ora2pg-20.0"
export ORA2PG_BIN="/usr/local/bin/ora2pg"
export ORACLE_HOME="/usr/lib/oracle/12.2/client64"
export WORKING_DIRECTORY="/home/postgres"
export MIGRATION_FOLDER="$WORKING_DIRECTORY/migration"
# Parameter to enable disable ora2pg report generation when migration_data.sh script is run.
export L_GEN_REPORT=N

source ${MIGRATION_FOLDER}/common_settings.sh
for i in $(cat ${MIGRATION_FOLDER}/${L_DB_NAME}_schemas_to_migrate.txt | grep -i ",${L_DB_NAME}," | grep -v "#"); do
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
done
export L_CONFIG_FILE="${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/config/ora2pg.conf"

# cd ${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}

echo -e ${L_SEPERATOR}: END
