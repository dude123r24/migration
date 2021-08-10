# Script to kick off to reset postgres database and migrate data from Oracle to postgres. 
# This script uses tmux, in order for our ssh sessions to detach / timeout and not affect running of the script

[ $# -ne 1 ] && { echo "Usage: migration_onestep.sh database_name (database_name in small case)"; return 1; }
tmux new-session -d -s "data_migr" "export ANSWER_YES_TO_ALL=YES; /home/postgres/migration/migration_reset_postgres_cluster.sh $1 ; echo +++++++++++++++++++++++++ ; /home/postgres/migration/migration_data.sh $1"
sleep 3
tmux ls
sleep 2
watch tmux capture-pane -pt "data_migr"