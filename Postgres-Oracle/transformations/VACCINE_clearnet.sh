# A row of data in one of the tables had year in date as 0000. That was causing the migration to fail. So replacing 0000 with the year of date in other columns in the same row.

source /home/postgres/migration/migration_common_settings.sh # Had to hard code here. Think of something

log_this INFO "Transforming view definitions (replace \" with space), File: ${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/schema/views/*.sql"

sed -i -E -r "s|\"| |g" ${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/schema/views/*.sql

check_result "$?" "Transforming view definitions (replace \" with space), File: ${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/schema/views/*.sql"