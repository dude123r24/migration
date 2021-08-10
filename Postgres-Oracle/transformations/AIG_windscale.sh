# Views have to_date column which need to be converted to to_char here (for postgres)
# example : [^)] is to handle the greediness for the ")" char. sed does not support "?" for greediness.

source /home/postgres/migration/migration_common_settings.sh # Had to hard code here. Think of something

log_this INFO "Transforming to_date functions to to_char for ${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/schema/views/*.sql"

sed -i -E -r "s|to_date\(([^)]*)\)?|to_char\(\1,'DD-mon-YY'\)|g" ${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/schema/views/*.sql
check_result "$?" "to_date replaced by to_char in ${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/schema/views/*.sql"
