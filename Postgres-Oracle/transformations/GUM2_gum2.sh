# A row of data in one of the tables had year in date as 0000. That was causing the migration to fail. So replacing 0000 with the year of date in other columns in the same row.

source /home/postgres/migration/migration_common_settings.sh # Had to hard code here. Think of something

log_this INFO "Transforming data for table SC, File: ${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/data/SC_data.sql"

sed -i -E -r "s|0000-12-15|2001-12-15|g" ${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/data/SC_data.sql

check_result "$?" "Transforming data for table SC, File: ${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/data/SC_data.sql"
