#### Removing database

$ORACLE_HOME/bin/dbca -silent -deleteDatabase -sourceDB orcl11 -sysPassword sys


#### Removing Software
# (update paths etc below)


# /export/home/oracle/software/deinstall/deinstall/deinstall -home /u01/app/oracle/product/19.0.0/dbhome_1/ -silent -paramfile /export/home/oracle/software/deinstall/deinstall/response/deinstall_OraDBHomeorcl11.rsp
# sudo rm -rf /var/opt/oracle/oraInst.loc


#### Installing Software

http://www.br8dba.com/install-oracle-19c-database-software-in-silent-mode/

# AS ROOT, do pre install steps (create user, set OS parameters etc)
pkg list oracle-database-preinstall-19c
# >> pkg list: No packages matching 'oracle-database-preinstall-19c' installed

pkg list -n oracle-database-preinstall-19c
# NAME (PUBLISHER)                                  VERSION                    IFO
# group/prerequisite/oracle/oracle-database-preinstall-19c 11.4-11.4.17.0.1.3.0       ---

pkg install oracle-database-preinstall-19c

df -h (check where you are going to install Oracle software)

# AS ROOT, create oracle software home and change ownership
mkdir -p /u01/app/oracle # Oracle Base
mkdir -p /u01/app/oraInventory # Oracle Inventory Location
mkdir -p /u01/app/oracle/product/19.0.0/dbhome_1 # Oracle Home
mkdir -p /u01/app/oracle/product/19.0.0/installer/ # Software installer
mkdir -p /u01/oradata # Datafiles 

chown -R oracle:oinstall /u01/app
chown -R oracle:oinstall /u01/oradata
chmod -R 775 /u01/app
chmod -R 775 /u01/oradata
chmod 777 /u01/app/oracle/product/19.0.0/installer/

# AS ORACLE, copy and unzip the software

cp SOLARIS.SPARC64_193000_db_home.zip /u01/app/oracle/product/19.0.0/installer/
unzip -d /u01/app/oracle/product/19.0.0/dbhome_1/ /u01/app/oracle/product/19.0.0/installer/SOLARIS.SPARC64_193000_db_home.zip
rm /u01/app/oracle/product/19.0.0/installer/SOLARIS.SPARC64_193000_db_home.zip


vi ~/.bash_profile
PS1="\u@\H \A {\W} $ "

export ORACLE_BASE=/u01/app/oracle
export oh19="$ORACLE_BASE/product/19.0.0/dbhome_1"
alias oh19="cd $oh19"

export oh="$ORACLE_HOME"
if [ -z $ORACLE_HOME ]; then
  export PATH=$oh19/bin:$PATH
else
  export PATH=$ORACLE_HOME/bin:$PATH
fi
export tns_admin="$ORACLE_HOME/network/admin"

alias oh="cd $oh"
alias tns="vi $tns_admin/tnsnames.ora"
alias sqlp="sqlplus / as sysdba"

alias dus="du | sort -nr | head -15 | cut -f2- | xargs du -hs"
alias oratab="vi /var/opt/oracle/oratab"

export alert="/u01/app/oracle/diag/rdbms/orcl11/orcl11/trace"
alias alert="vi $alert/alert_orcl11.log"


# export gh="/u01/app/oracle/product/19.0.0/grid"
# alias gh="cd $gh"

#cd oracle/grid
#./runcluvfy.sh stage -pre hacfg -verbose

chmod 777 /u01/app/oracle/product/19.0.0/dbhome_1/install/response/db_install.rsp # to allow scp to copy the file to another server using a different user

cd /u01/app/oracle/product/19.0.0/dbhome_1
# cp /u01/app/oracle/product/19.0.0/dbhome_1/install/response/db_install.rsp /tmp; chmod 777 /tmp/db_install.rsp
# scp /tmp/db_install.rsp itsysadm@orazoracol02:/tmp
# cp /tmp/db_install.rsp /u01/app/oracle/product/19.0.0/dbhome_1/install/response/db_install.rsp; chown oracle:oinstall /u01/app/oracle/product/19.0.0/dbhome_1/install/response/db_install.rsp
cp /u01/app/oracle/product/19.0.0/dbhome_1/install/response/db_install.rsp /u01/app/oracle/product/19.0.0/dbhome_1/install/response/db_install.rsp.bak

vi /u01/app/oracle/product/19.0.0/dbhome_1/install/response/db_install.rsp # needed if you need to make changes to response file. 


# As Oracle, run installer for silent install 
cd /u01/app/oracle/product/19.0.0/dbhome_1/
/u01/app/oracle/product/19.0.0/dbhome_1/runInstaller -executePrereqs -silent -responseFile /u01/app/oracle/product/19.0.0/dbhome_1/install/response/db_install.rsp

Ignore 
    ORACHK PKG requirement (if not cluster)
	[WARNING] [INS-13014] Target environment does not meet some optional requirements.



/u01/app/oracle/product/19.0.0/dbhome_1/runInstaller -silent -responseFile /u01/app/oracle/product/19.0.0/dbhome_1/install/response/db_install.rsp
IGNORE the below 
	[WARNING] [INS-32047] The location (/u01/app/oraInventory) specified for the central inventory is not empty.
    [WARNING] [INS-13014] Target environment does not meet some optional requirements.

Run root scripts as instructed by above command

vi ~/.bash_profile
export ORACLE_HOME=/u01/app/oracle/product/19.0.0/dbhome_1
export oh="$ORACLE_HOME"
alias oh="cd $oh"
export PATH=/u01/app/oracle/product/19.0.0/dbhome_1/bin:$PATH;
export LD_LIBRARY_PATH="$ORACLE_HOME/lib:/lib:/usr/lib"
export CLASSPATH="$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib"



#### Creating database
https://dbaora.com/install-oracle-database-19c-in-silent-mode-on-oel8/

dbca -silent \
-createDatabase \
-createAsContainerDatabase true  \
-templateName General_Purpose.dbc \
-gdbname cdb1 \
-sid cdb1 \
-responseFile NO_VALUE \
-characterSet AL32UTF8 \
-SYSPASSWORD sys \
-SYSTEMPASSWORD system \
-redoLogFileSize 1024 \
-initparams open_cursors=1300,processes=3000,enable_pluggable_database=true


    Look at the log file "/u01/app/oracle/cfgtoollogs/dbca/cdb1/cdb1.log" for further details.



#### Creating a listener

cd /u01/app/oracle/product/19.0.0/dbhome_1/assistants/netca
cp /u01/app/oracle/product/19.0.0/dbhome_1/assistants/netca/netca.rsp /u01/app/oracle/product/19.0.0/dbhome_1/assistants/netca/netca.rsp.bck
netca -silent -responseFile /u01/app/oracle/product/19.0.0/dbhome_1/assistants/netca/netca.rsp
IGNORE ERRORS
	ProfileException: Could not save Profile: TNS-04415: File i/o error
	caused by: java.io.FileNotFoundException: /u01/app/oracle/product/19.0.0/dbhome_1/lib/network/admin/sqlnet.ora (No such file or directory)

