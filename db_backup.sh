#!/bin/bash

#############################################################################################
# A script to backup your MySQL database to dropbox.
#
# Author: Dan @ ClickBeyond
# Website: http://clickbeyond.github.io/DropboxBackup/
# Copyright 2015
#
# Usage: $ ./db_backup.sh -l loginPathName -d dbName
#
# Before running this script for the first time make sure you execute the following commands:
# 1. $ chmod +x dropbox_uploader.sh
# 2. $ chmod +x db_backup.sh
# 3. $ ./dropbox_uploader.sh
# The last step will configure access to your dropbox account if this is the first time you
# have run dropbox_uploader.sh.
#
# Based on: http://robinadr.com/2013/10/automated-database-backups-to-dropbox
#############################################################################################

# Exit immediately if an error occurs (i.e., a command exits with a non-zero status)
set -e

usage() { echo "Usage: $0 [-l <loginPathName>] [-d <dbName>]" 1>&2; exit 1; }

while getopts ":l:d:" o; do
    case "${o}" in
        l)
            dbLogin=${OPTARG}
            ;;
		d)
            dbName=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${dbLogin}" ] || [ -z "${dbName}" ]; then
    usage
fi

TMP_DIR="tmp"
DROP_DIR="MySQL_Backups"
NOW=$(date +"%Y-%m-%d_%H-%M-%S")
SQL_FILE="backup-$dbName-$NOW.sql"
BKP_FILE="backup-$dbName-$NOW.tar.gz"
#BKP_DIRS="./dir/to/backup"
DROPBOX_UPLOADER=~/DropboxBackup/dropbox_uploader.sh
DROP_CONFIG=~/.dropbox_uploader
LOG_FILE=~/$TMP_DIR/backup.log
# Set the delete date to a multiple of the cron schedule e.g., a weekly cron schedule means data can only be deleted every 7, 14, 21, 28, etc, days
DEL_DATE=$(date --date="-28 day" +%Y-%m-%d)

# Define a date function for adding a timestamp to the log file
adddate() {
    while IFS= read -r line; do
        echo "$(date) $line"
    done
}

cd ~
# Create temp directory if it doesnt exist
mkdir -p $TMP_DIR
echo "Starting backup of the '$dbName' MySQL database to '$SQL_FILE'" | adddate >> $LOG_FILE
start=$SECONDS
cd $TMP_DIR
mysqldump --login-path=$dbLogin -B $dbName > $SQL_FILE
tar -zcf "$BKP_FILE" $SQL_FILE

#echo "Backing up the directories $BKP_DIRS"
#tar -zcf "$BKP_FILE" $BKP_DIRS $SQL_FILE

echo "Uploading to Dropbox..." | adddate >> $LOG_FILE
$DROPBOX_UPLOADER -f $DROP_CONFIG upload $BKP_FILE "/$DROP_DIR/$BKP_FILE" | adddate >> $LOG_FILE

rm -f $BKP_FILE $SQL_FILE

# Delete old backup from Dropbox
echo "Finding any existing backup that was made on '$DEL_DATE'..." | adddate >> $LOG_FILE
while read -r state size file rest
do
    if [[ $state = "[F]" && $file = "backup-$dbName-"* ]]
    then
        if [[ $file = "backup-$dbName-$DEL_DATE"* ]]
        then
			echo "Old backup found! Deleting '$file'" | adddate >> $LOG_FILE
			$DROPBOX_UPLOADER -f $DROP_CONFIG delete "/$DROP_DIR/$file" | adddate >> $LOG_FILE
        fi
    fi
done < <($DROPBOX_UPLOADER -f $DROP_CONFIG list $DROP_DIR/)

duration=$(( SECONDS - start ))
echo "Backup complete! Finished in $duration seconds!" | adddate >> $LOG_FILE