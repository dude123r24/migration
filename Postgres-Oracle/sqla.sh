# Script to execute migration_gatherdbinfo.sql or another SQL file (if cmd line parameter 2 is specified) on database name specified on command prompt. 
# Assumption. Username amit exists with password set to what's in secret file

[ $# -ne 1 ] && { echo "Usage: sqla.sh database_name"; exit 1; } 

export L_DB_NAME=$(echo $1 | tr '[:upper:]' '[:lower:]' )


if [  -z $2 ]; then
  script="migration_gatherdbinfo.sql"
else
  script="$2"
fi

echo "script=$script"

if [ -z $script ]; then echo "ERROR: No script specified"; exit 1; fi

pwd=`cat secret|grep -i amit_pwd | cut -d'=' -f2`
sqlplus amit/${pwd}@${L_DB_NAME} @${script}