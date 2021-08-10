# migration_common_settings.sh : Some common code which can be reused in your scripts

export ORA2PG_FOLDER="/home/postgres/ora2pg-20.0"
export ORA2PG_BIN="/usr/local/bin/ora2pg"
export ORACLE_HOME="/usr/lib/oracle/12.2/client64"
export WORKING_DIRECTORY="/home/postgres"
export MIGRATION_FOLDER="$WORKING_DIRECTORY/migration"

# Parameter to enable or disable ora2pg report generation when migration_data.sh script is run.
export L_GEN_REPORT=N

print_vars ()
{
   if [ ! -z $1 ]; then 
     echo "Label=$1"
   fi
   
   env | grep -i ^L_ | grep -v PASSWORD 
}

source ${MIGRATION_FOLDER}/common_settings.sh
