# Backup your Migration code files manually

if [ -z $MIGRATION_HOME ]; then echo "MIGRATION HOME not set. Exiting"; exit 1; fi
L_UNQ_ID=$(date '+%Y%m%d%H%M%S')
L_FOLDER="$MIGRATION_HOME/../backup_migration/${L_UNQ_ID}"

mkdir -p ${L_FOLDER}
cp $MIGRATION_HOME/*.txt ${L_FOLDER}/
cp $MIGRATION_HOME/*.sh ${L_FOLDER}/
cp $MIGRATION_HOME/*.sql ${L_FOLDER}/
cp $MIGRATION_HOME/secret ${L_FOLDER}/
cp -r $MIGRATION_HOME/inclusions ${L_FOLDER}/
cp -r $MIGRATION_HOME/exclusions ${L_FOLDER}/
cp -r $MIGRATION_HOME/replacements ${L_FOLDER}/
cp -r $MIGRATION_HOME/transformations ${L_FOLDER}/
cp -r $MIGRATION_HOME/pre-migration-sqls ${L_FOLDER}/

echo "Backed up in folder: $L_FOLDER"
