
# Cleanup (Database and Software)

# Remove database
if [ -d /u01/app/oracle/product/11.1.0.7/dbhome_1 ]; then

#  cd /u01/app/oracle/product/11.1.0.7/dbhome_1/bin
#  ./dbca -silent -deleteDatabase -sourceDB orcl11 -sysPassword sys

# Remove software
#cd /export/home/oracle/software/oracle/
#ls -l solaris.sparc64_11gR2_deinstall.zip
#mkdir -p /export/home/oracle/software/oracle/deinstall_11gr2
#unzip -d /export/home/oracle/software/oracle/deinstall_11gr2 solaris.sparc64_11gR2_deinstall.zip

# Remove software 

cp /u01/app/oracle/product/11.1.0.7/installer/deinstall_OraDBHomeorcl11.rsp /export/home/oracle/software/oracle/deinstall_11gr2/deinstall/response/deinstall_OraDBHomeorcl11.rsp

/export/home/oracle/software/oracle/deinstall_11gr2/deinstall/deinstall -home /u01/app/oracle/product/11.1.0.7/dbhome_1 -silent -paramfile /export/home/oracle/software/oracle/deinstall_11gr2/deinstall/response/deinstall_OraDBHomeorcl11.rsp

# Remove directory (if not already removed)
# rm -rf /u01/app/oracle/product/11.1.0.7/dbhome_1
# rm -rf /u01/app/oracle/oradata/orcl11

fi 

if [ ! -d /u01/app/oracle/product/11.1.0.7/installer ]; then

  mkdir -p /u01/app/oracle/product/11.1.0.7/installer   # Oracle Home
  cd /export/home/oracle/software/oracle/Oracle11gR1/ 
  unzip -d /u01/app/oracle/product/11.1.0.7/installer/ /software/SPARC/Oracle/Oracle11g/Oracle11gR1/solaris.sparc64_11gR1_database_1013.zip
  unzip -d /u01/app/oracle/product/11.1.0.7/installer/ /software/SPARC/Oracle/Oracle11g/Oracle11gR1/p6890831_orcl110_SOLARIS64.zip
  ## cd /u01/app/oracle/product/11.1.0.7/installer/
  ## mv database/* .
  ## rm -rf database

fi


# Make sure oraInst.loc is populated correctly. (AS ROOT)
# chown oracle:oinstall /var/opt/oracle/oraInst.loc
# chmod 664 /var/opt/oracle/oraInst.loc
# vi /var/opt/oracle/oraInst.loc
#  inventory_loc=/u01/app/oraInventory
#  inst_group=oinstall


# Install software

# chmod 700 /u01/app/oracle/product/11.1.0.7/installer/database/install/response/ee.rsp
cp /u01/app/oracle/product/11.1.0.7/installer/ee.rsp /u01/app/oracle/product/11.1.0.7/installer/database/install/response/ee.rsp

# vi /u01/app/oracle/product/11.1.0.7/installer/database/install/response/ee.rsp
#  FROM_LOCATION="/u01/app/oracle/product/11.1.0.7/installer/database/stage/products.xml"
#  ORACLE_BASE=/u01/app/oracle
#  ORACLE_HOME=/u01/app/oracle/product/11.1.0.7/dbhome_1
#  ORACLE_HOME_NAME=OraDBHomeorcl11
#  TOPLEVEL_COMPONENT={"oracle.server","11.1.0.6.0"}
#  INSTALL_TYPE="EE"
#  n_dbType=1

/u01/app/oracle/product/11.1.0.7/installer/database/runInstaller -silent -noconfig -responseFile /u01/app/oracle/product/11.1.0.7/installer/database/install/response/ee.rsp

sudo /u01/app/oracle/product/11.1.0.7/dbhome_1/root.sh

# Changing the port number to 1522 as 1521 is already used by 19c database
# cp /u01/app/oracle/product/11.1.0.7/installer/netca.rsp /u01/app/oracle/product/11.1.0.7/dbhome_1/inventory/response/netca.rsp
# netca -silent -responsefile /u01/app/oracle/product/11.1.0.7/dbhome_1/inventory/response/netca.rsp

cp /u01/app/oracle/product/11.1.0.7/installer/listener.ora /u01/app/oracle/product/11.1.0.7/dbhome_1/network/admin/
cp /u01/app/oracle/product/11.1.0.7/installer/tnsnames.ora  /u01/app/oracle/product/11.1.0.7/dbhome_1/network/admin/



# Create database
mkdir -p /u01/app/oracle/oradata/orcl11



/u01/app/oracle/product/11.1.0.7/dbhome_1/bin/dbca -silent -createDatabase \
-templateName General_Purpose.dbc \
-databaseType MULTIPURPOSE \
-gdbName orcl11 -sid orcl11 \
-sysPassword sys -systemPassword sys \
-characterSet AL32UTF8 -nationalCharacterSet AL16UTF16 \
-totalMemory 8192 -automaticMemoryManagement true \
-redoLogFileSize 512 \
-listeners LISTENER -registerWithDirService false \
-emConfiguration NONE \
-initparams sessions=700,open_cursors=500,processes=500,db_create_file_dest=/u01/oradata,DB_RECOVERY_FILE_DEST=/u01/flash_recovery_area,cpu_count=2


sudo /u01/app/oracle/product/11.1.0.7/dbhome_1/root.sh

export ORACLE_SID=orcl11
export ORAENV_ASK=NO
. oraenv
export ORAENV_ASK=YES


sqlplus / as sysdba <<EOF
   ALTER SYSTEM SET LOCAL_LISTENER='MYLISTENER' SCOPE=BOTH;
   exit
EOF

 



# Patching to 11.1.0.7
#https://updates.oracle.com/Orion/Services/download?type=readme&aru=10551208#CJGDGECD


cp /u01/app/oracle/product/11.1.0.7/installer/patchset.rsp.works /export/home/oracle/software/oracle/Oracle11gR1/1117_patch/Disk1/response/

lsnrctl stop

sqlplus / as sysdba <<EOF
   shutdown immediate
   exit
EOF
   

/export/home/oracle/software/oracle/Oracle11gR1/1117_patch/Disk1/runInstaller -silent -ignoreSysPrereqs -responseFile /export/home/oracle/software/oracle/Oracle11gR1/1117_patch/Disk1/response/patchset.rsp.works

sudo /u01/app/oracle/product/11.1.0.7/dbhome_1/root.sh

sqlplus / as sysdba <<EOF
   STARTUP UPGRADE
   SPOOL upgrade_info.log 
   @?/rdbms/admin/utlu111i.sql
   SPOOL OFF
   
   SPOOL patch.log
   @?/rdbms/admin/catupgrd.sql
   SPOOL OFF
   
   SHUTDOWN IMMEDIATE
   STARTUP
   
   @?/rdbms/admin/utlrp.sql
   set lines 200
   set pages 100
   column COMP_NAME format a40
   column status format a10
   column version format a15
   SELECT COMP_NAME, VERSION, STATUS FROM SYS.DBA_REGISTRY;
   exit
EOF

lsnrctl start
