#!/bin/bash

###################################################
# A script to backup your log file to dropbox.
#
# Author: Dan @ CubicApps
# Website: https://github.com/CubicApps
# Copyright 2014
#
# Usage: $ ./log_backup.sh
#
# Before running this script for the first time make 
# sure you have already run the `./db_backup.sh` script. 
# Also make sure you give this script execution 
# permissions:
# $ chmod +x log_backup.sh
#
###################################################

TMP_DIR="tmp"
LOG_FILE=~/$TMP_DIR/backup.log

if [ -f $LOG_FILE ];
then
	echo "Starting backup of 'backup.log' to dropbox..."
	start=$SECONDS
	cd ~/tmp
	BKP_LOG_FILE="log-backup-$(date +"%Y-%m-%d_%H-%M-%S").tar.gz"
	tar -zcf "$BKP_LOG_FILE" "backup.log"
	~/DropboxBackup/dropbox_uploader.sh -f ~/.dropbox_uploader upload $BKP_LOG_FILE "/Log_Backups/$BKP_LOG_FILE"
	rm -f $BKP_LOG_FILE
	duration=$(( SECONDS - start ))
	echo "Log backup complete! Finished in $duration seconds!"
else
	echo "File '$LOG_FILE' does not exist! Please run './db_backup.sh' before running this script."
fi
