source /home/postgres/migration/migration_common_settings.sh # Had to hard code here. Think of something

# Oracle has a column called foreign, which is a reserved keyword in postgres and therefore table creation fails in postgres. replacing foreign with foreign_modcol
sed -i 's/abroad,\"foreign\",country/abroad,foreign_modcol,country/g' ${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/data/NEW_PATH1_data.sql
check_result "$?" "column foreign replaced by foreign_modcol in ${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/data/NEW_PATH1_data.sql"

sed -i 's/foreign varchar(1),/foreign_modcol varchar(1),/g' ${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/schema/tables/table.sql
check_result "$?" "column foreign replaced by foreign_modcol in ${MIGRATION_FOLDER}/${L_POSTGRES_SCHEMA_NAME}_${L_UNQ_ID}/schema/tables/table.sql"

