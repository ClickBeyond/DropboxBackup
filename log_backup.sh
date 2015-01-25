#!/bin/bash

###################################################
# A script to backup your log file to dropbox.
#
# Author: Dan @ ClickBeyond
# Website: http://clickbeyond.github.io/DropboxBackup/
# Copyright 2015
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

# Exit immediately if an error occurs (i.e., a command exits with a non-zero status)
set -e

TMP_DIR="tmp"
DROP_DIR="Log_Backups"
LOG_FILE="backup.log"
DROPBOX_UPLOADER=~/DropboxBackup/dropbox_uploader.sh
DROP_CONFIG=~/.dropbox_uploader
# Set the delete date to a multiple of the cron schedule e.g., a weekly cron schedule means data can only be deleted every 7, 14, 21, 28, etc, days
DEL_DATE=$(date --date="-28 day" +%Y-%m-%d)

if [ -f ~/$TMP_DIR/$LOG_FILE ];
then
	echo "Starting backup of 'backup.log' to Dropbox..."
	start=$SECONDS
	cd ~/$TMP_DIR
	BKP_LOG_FILE="log-backup-$(date +"%Y-%m-%d_%H-%M-%S").tar.gz"
	tar -zcf "$BKP_LOG_FILE" "backup.log"
	$DROPBOX_UPLOADER -f $DROP_CONFIG upload $BKP_LOG_FILE "/$DROP_DIR/$BKP_LOG_FILE"
	rm -f $BKP_LOG_FILE $LOG_FILE
	
	# Delete old backup from Dropbox
	echo "Finding any existing backup that was made on '$DEL_DATE'..."
	while read -r state size file rest
	do
		if [[ $state = "[F]" && $file = "log-backup-"* ]]
		then
			if [[ $file = "log-backup-$DEL_DATE"* ]]
			then
				echo "Old backup found! Deleting '$file'"
				$DROPBOX_UPLOADER -f $DROP_CONFIG delete "/$DROP_DIR/$file"
			fi
		fi
	done < <($DROPBOX_UPLOADER -f $DROP_CONFIG list $DROP_DIR/)
	
	duration=$(( SECONDS - start ))
	echo "Log backup complete! Finished in $duration seconds!"
else
	echo "File '~/$TMP_DIR/$LOG_FILE' does not exist! Please run './db_backup.sh' before running this script again."
fi
