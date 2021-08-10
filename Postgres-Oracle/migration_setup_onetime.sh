#!/bin/bash
# migration_setup_onetime.sh : Setup migration environment : run once only

source migration_common_settings.sh

# HARDCODED ${ORACLE_HOME}/lib path.
# If ORACLE_HOME variable is set and Oracle libraries are present, then setup bash_profile
if [ ! -z ${ORACLE_HOME} ] && [ -d ${ORACLE_HOME}/lib ]; then
  log_this "INFO" "Updating ~/.bash_profile"
  [ ! -f ~/.bash_profile ] && touch ~/.bash_profile || cp ~/.bash_profile ~/.bash_profile.$(date '+%Y%m%d%H%M%S')
  cat ~/.bash_profile | grep -i "^export LD_LIBRARY_PATH" || echo "export LD_LIBRARY_PATH=${ORACLE_HOME}/lib:${ORACLE_HOME}" >> ~/.bash_profile
  cat ~/.bash_profile | grep -i "^export ORACLE_HOME" || echo "export ORACLE_HOME=\"/usr/lib/oracle/12.2/client64\"" >> ~/.bash_profile
  cat ~/.bash_profile | grep -i "^export ORACLE_CLIENT" || echo "export ORACLE_CLIENT=${ORACLE_HOME}" >> ~/.bash_profile
  cat ~/.bash_profile | grep -i "^export TNS_ADMIN" || echo "export TNS_ADMIN=\"$ORACLE_HOME/lib/network/admin\"" >> ~/.bash_profile
  cat ~/.bash_profile | grep -i "^alias tns" || echo "alias tns=\"vi $ORACLE_CLIENT/lib/network/admin/tnsnames.ora\"" >> ~/.bash_profile
  cat ~/.bash_profile | grep -i "^export POSTGRES_HOME" || echo "export POSTGRES_HOME=\"/usr/pgsql-13\"" >> ~/.bash_profile
  cat ~/.bash_profile | grep -i "^export PATH" || echo "export PATH=\${ORACLE_HOME}/bin:\${POSTGRES_HOME}/bin:\$PATH" >> ~/.bash_profile
  cat ~/.bash_profile | grep -i "^export ORA2PG_FOLDER" || echo "export ORA2PG_FOLDER=\"/home/postgres/ora2pg-20.0\"" >> ~/.bash_profile
  cat ~/.bash_profile | grep -i "^export PERL5LIB" || echo "export PERL5LIB=\"\${ORA2PG_FOLDER}\"" >> ~/.bash_profile
  cat ~/.bash_profile | grep -i "^export PGDATA" || echo "export PGDATA=\"/var/lib/pgsql/13/data\"" >> ~/.bash_profile
  cat ~/.bash_profile | grep -i "^alias postgresql" || echo "alias postgresql=\"vi $PGDATA/postgresql.conf\"" >> ~/.bash_profile
  cat ~/.bash_profile | grep -i "^alias pg_hba" || echo "alias pg_hba=\"vi $PGDATA/pg_hba.conf\"" >> ~/.bash_profile
  cat ~/.bash_profile | grep -i "^alias pglog" || echo "alias pglog=\"cd $PGDATA/log; ls -lrth\"" >> ~/.bash_profile
  cat ~/.bash_profile | grep -i "^export MIGRATION_HOME" || echo "export MIGRATION_HOME=\"/home/postgres/migration\"" >> ~/.bash_profile 
  cat ~/.bash_profile | grep -i "^alias pgrestart" || echo "alias pgrestart=\"pg_ctl -D $PGDATA stop; pg_ctl -D $PGDATA start\"" >> ~/.bash_profile

   . ~/.bash_profile

else
  log_this "ERROR" "Variable ORACLE_HOME = ${ORACLE_HOME} , Check path ${ORACLE_HOME}/lib. Oracle needs to be installed and environment variables set"
  exit
fi



# Create the base migration folder
[ ! -d ${MIGRATION_FOLDER} ] && { mkdir "${MIGRATION_FOLDER}"; log_this "INFO" "Directory ${MIGRATION_FOLDER} created" ; } || log_this "INFO" "Directory ${MIGRATION_FOLDER} exists"

[ ! -d ${MIGRATION_FOLDER}/exclusions ] && { mkdir "${MIGRATION_FOLDER}/exclusions"; log_this "INFO" "Directory ${MIGRATION_FOLDER}/exclusions created" ; } || log_this "INFO" "Directory ${MIGRATION_FOLDER}/exclusions exists"

[ ! -d ${MIGRATION_FOLDER}/transformations ] && { mkdir "${MIGRATION_FOLDER}/transformations"; log_this "INFO" "Directory ${MIGRATION_FOLDER}/transformations created" ; } || log_this "INFO" "Directory ${MIGRATION_FOLDER}/transformations exists"

[ ! -d ${MIGRATION_FOLDER}/inclusions ] && { mkdir "${MIGRATION_FOLDER}/inclusions"; log_this "INFO" "Directory ${MIGRATION_FOLDER}/inclusions created" ; } || log_this "INFO" "Directory ${MIGRATION_FOLDER}/inclusions exists"

