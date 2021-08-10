# Script to reinstall database software 11.2.0.4
# Log in as ORACLE_BASE
# Have the installation files in /u01/software/Oracle11.2.0.4. There should be files p13390677_112040_SOLARIS64_1of7.zip and p13390677_112040_SOLARIS64_2of7.zip

echo "Database Software Installation : 11.2.0.4"
sleep 3

# Cleanup (Database and Software)

# Remove database and software
if [ -d /u01/app/oracle/product/11.2.0.4/dbhome_1 ]; then
  cp /u01/app/oracle/product/11.2.0.4/installer/deinstall_OraDBHomeorcl11204.rsp /export/home/oracle/software/oracle/deinstall_11gr2/deinstall/response/deinstall_OraDBHomeorcl11.rsp
  /export/home/oracle/software/oracle/deinstall_11gr2/deinstall/deinstall -home /u01/app/oracle/product/11.2.0.4/dbhome_1 -silent -paramfile /export/home/oracle/software/oracle/deinstall_11gr2/deinstall/response/deinstall_OraDBHomeorcl11204.rsp
fi 

# Unzipping software in /u01/app/oracle/product/11.2.0.4/installer

if [ ! -d /u01/app/oracle/product/11.2.0.4/installer ]; then
    mkdir -p /u01/app/oracle/product/11.2.0.4/installer   # Oracle Home

    if [ -f /u01/software/Oracle11.2.0.4/p13390677_112040_SOLARIS64_1of7.zip ] && [ -f /u01/software/Oracle11.2.0.4/p13390677_112040_SOLARIS64_2of7.zip ]; then
	  if [ ! -d /u01/app/oracle/product/11.2.0.4/installer/database ]; then 
        unzip -d /u01/app/oracle/product/11.2.0.4/installer/ /u01/software/Oracle11.2.0.4/p13390677_112040_SOLARIS64_1of7.zip
        unzip -d /u01/app/oracle/product/11.2.0.4/installer/ /u01/software/Oracle11.2.0.4/p13390677_112040_SOLARIS64_2of7.zip
        chown -R oracle:oinstall /u01/app/oracle/product/11.2.0.4
        ## cd /u01/app/oracle/product/11.2.0.4/installer/
        ## mv database/* .
        ## rm -rf database
	  fi 
    else
      echo "ERROR: Database software installation files not present in file not present in /u01/software/Oracle11.2.0.4/. Files needed: p13390677_112040_SOLARIS64_1of7.zip, p13390677_112040_SOLARIS64_2of7.zip"
    fi 
fi


# Make sure oraInst.loc is populated correctly. (AS ROOT)
# chown oracle:oinstall /var/opt/oracle/oraInst.loc
# chmod 664 /var/opt/oracle/oraInst.loc
# vi /var/opt/oracle/oraInst.loc
#  inventory_loc=/u01/app/oraInventory
#  inst_group=oinstall


# Install software

# chmod 700 /u01/app/oracle/product/11.2.0.4/installer/database/response/db_install.rsp
# The first time you need to cp /u01/app/oracle/product/11.2.0.4/installer/database/response/db_install.rsp /u01/app/oracle/product/11.2.0.4/installer/db_install.rsp
# Make changes to the file  /u01/app/oracle/product/11.2.0.4/installer/db_install.rsp , so if you recreate the installer, the response file isnt lost

cp /u01/app/oracle/product/11.2.0.4/installer/db_install.rsp /u01/app/oracle/product/11.2.0.4/installer/database/response/db_install.rsp

# vi /u01/app/oracle/product/11.2.0.4/installer/database/response/db_install.rsp
#  ORACLE_HOSTNAME={YOUR HOSTNAME}
#  FROM_LOCATION="/u01/app/oracle/product/11.2.0.4/installer/database/stage/products.xml"
#  ORACLE_BASE=/u01/app/oracle
#  ORACLE_HOME=/u01/app/oracle/product/11.2.0.4/dbhome_1
#  ORACLE_HOME_NAME=OraDBHomeorcl11
#  TOPLEVEL_COMPONENT={"oracle.server","11.1.0.6.0"}
#  INSTALL_TYPE="EE"
#  n_dbType=1

/u01/app/oracle/product/11.2.0.4/installer/database/runInstaller -silent -noconfig -responseFile /u01/app/oracle/product/11.2.0.4/installer/database/response/db_install.rsp -ignorePrereq -ignoreSysPrereqs -noconfig -showProgress -force


# Changing the port number to 1522 as 1521 is already used by 19c database
# cp /u01/app/oracle/product/11.2.0.4/installer/netca.rsp /u01/app/oracle/product/11.2.0.4/dbhome_1/inventory/response/netca.rsp
# netca -silent -responsefile /u01/app/oracle/product/11.2.0.4/dbhome_1/inventory/response/netca.rsp

# cp /u01/app/oracle/product/11.2.0.4/installer/listener.ora /u01/app/oracle/product/11.2.0.4/dbhome_1/network/admin/
# cp /u01/app/oracle/product/11.2.0.4/installer/tnsnames.ora  /u01/app/oracle/product/11.2.0.4/dbhome_1/network/admin/



# Create database
# mkdir -p /u01/app/oracle/oradata/orcl11



#/u01/app/oracle/product/11.2.0.4/dbhome_1/bin/dbca -silent -createDatabase \
#-templateName General_Purpose.dbc \
#-databaseType MULTIPURPOSE \
#-gdbName orcl11 -sid orcl11 \
#-sysPassword sys -systemPassword sys \
#-characterSet AL32UTF8 -nationalCharacterSet AL16UTF16 \
#-totalMemory 8192 -automaticMemoryManagement true \
#-redoLogFileSize 512 \
#-listeners LISTENER -registerWithDirService false \
#-emConfiguration NONE \
#-initparams sessions=700,open_cursors=500,processes=500,db_create_file_dest=/u01/oradata,DB_RECOVERY_FILE_DEST=/u01/flash_recovery_area,cpu_count=2


# sudo /u01/app/oracle/product/11.2.0.4/dbhome_1/root.sh


# Upgrade database (if the database is on the same server)

/u01/app/oracle/product/11.2.0.4/dbhome_1/bin/dbua -silent -sid orcl11 -oracleHome  /u01/app/oracle/product/11.1.0.7/dbhome_1 -diagnosticDest /u01/app/oracle
# LOG: /u01/app/oracle/cfgtoollogs/dbua/orcl11/upgrade1

export ORACLE_SID=orcl11
export ORAENV_ASK=NO
. oraenv
export ORAENV_ASK=YES


sqlplus / as sysdba <<EOF
    select instance_name,version,status from v$instance;
	select count(*) from dba_objects where status='INVALID';
   exit
EOF

lsnrctl start
lsnrctl status


# Reference: Patching to 11.2.0.4 
# https://updates.oracle.com/Orion/Services/download?type=readme&aru=10551208#CJGDGECD

# Backup your 11.2.0.4 database software and binaries
#mkdir -p /u01/app/oracle/backups/
#tar -zcvf /u01/app/oracle/backups/orcl11204-dbhome_1.tar.gz /u01/app/oracle/product/11.2.0.4/dbhome_1
#tar -zcvf /u01/app/oracle/backups/orcl11204-datafiles.tar.gz /u01/oradata/ORCL11/datafile
#tar -zcvf /u01/app/oracle/backups/orcl11204-redo_control.tar.gz /u01/app/oracle/oradata/orcl11