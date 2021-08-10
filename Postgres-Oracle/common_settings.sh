#!/usr/bin/bash
# common_settings.sh : Some common code which can be reused in your scripts

# Variables that can form a common header for your LOG messages
export L_SEPERATOR="+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

# function to format and log messages on screen and in logfile
function log_this ()
{
# type, message text

  [ $# -ne 2 ] && { echo "Usage: log_this param1 param2"; return 1; } 
  
  [ ! -z "${1}" ] &&  { TYPE="${1}"; }
  [ ! -z "${2}" ] &&  { L_MESSAGE="${2}"; }

  L_TYPE=`printf '%-10s' [${TYPE}]`
  
  if [ -z $L_LOGFILE ]; then
    printf "${L_TYPE} : $(date '+%Y%m%d%H%M%S') %-2s : ${L_MESSAGE}\n"
  else
    printf "${L_TYPE} : $(date '+%Y%m%d%H%M%S') %-2s : ${L_MESSAGE}\n" | tee -a ${L_LOGFILE}
  fi
}

# function to check the $? result after execution of a command
function check_result ()
{
# return code, action
  [ $# -ne 2 ] && { log_this ERROR "Usage: log_this param1 param2"; return 1; } 
  
  [ ! -z "${1}" ] &&  { L_RETURN_CODE="${1}"; }
  [ ! -z "${2}" ] &&  { L_ACTION="${2}"; }

  if [ $L_RETURN_CODE = 0 ]; then
    log_this SUCCESS "${L_ACTION}"
	export RC=0
  elif [ $L_RETURN_CODE = 1 ]; then
    log_this ERROR "Return Code: $L_RETURN_CODE. ${L_ACTION}"
	export RC=1
  else
    log_this WARNING "Return Code: $L_RETURN_CODE. ${L_ACTION}"
	export RC=$L_RETURN_CODE
  fi
}

# function to split a full filename to filename + extension 
function script_name ()
{
  [ $# -ne 1 ] && { echo "Usage: script_name param1"; return 1; } 
  [ ! -z "${1}" ] &&  { FULLNAME="${1}"; }
  
# `basename "$0"`

  FULLNAME=$1
  FILENAME=$(basename -- "$FULLNAME")
  export EXTENSION="${FILENAME##*.}"
  export FILENAME="${FILENAME%.*}"
}

list_errors ()
{
  [ $# -ne 1 ] && { echo "Usage: list_errors param1"; return 1; }
  L_LOGFILE=$1

  echo " "
  echo " " 
  echo ${L_SEPERATOR} 
  echo "LISTING ERRORS AND WARNINGS" 
  echo ${L_SEPERATOR} 
  echo " " 
  L_ERRORS_PRESENT=$(cat $L_LOGFILE | egrep "ERROR|error|WARNING|not found|does not exist|No such" | wc -l)
  if [ ${L_ERRORS_PRESENT} -gt 0 ]; then
    cat $L_LOGFILE | egrep "ERROR|error|WARNING|not found|does not exist|No such" 
  else
    echo "No ERRORS"
  fi
  echo " " 
  echo " " 
}

exit_gracefully ()
{
  exit
}