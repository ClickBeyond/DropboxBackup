#!/bin/bash

##########################################################################################################
# A script to backup your MySQL database to dropbox.
#
# Author: Dan @ CubicApps
# Website: https://github.com/CubicApps
# Copyright 2014
#
# Usage: $ ./db_backup.sh -u dbUsername -p dbPassword -h dbHost -d dbName
#
# Before running this script for the first time make sure you execute the following commands:
# 1. $ chmod +x dropbox_uploader.sh
# 2. $ chmod +x db_backup.sh
# 3. $ ./dropbox_uploader.sh
# The last step will configure access to your dropbox account if this is the first time you
# have run dropbox_uploader.sh.
#
# Based on: http://robinadr.com/2013/10/automated-database-backups-to-dropbox
##########################################################################################################

usage() { echo "Usage: $0 [-u <dbUsername>] [-p <dbPassword>] [-h <dbHost>] [-d <dbName>]" 1>&2; exit 1; }

while getopts ":u:p:h:d:" o; do
    case "${o}" in
        u)
            dbUser=${OPTARG}
            ;;
        p)
            dbPass=${OPTARG}
            ;;
		h)
            dbHost=${OPTARG}
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

if [ -z "${dbUser}" ] || [ -z "${dbPass}" ] || [ -z "${dbHost}" ] || [ -z "${dbName}" ]; then
    usage
fi

TMP_DIR="tmp"
NOW=$(date +"%Y-%m-%d_%H-%M-%S")
SQL_FILE="backup-$dbName-$NOW.sql"
BKP_FILE="backup-$NOW.tar.gz"
#BKP_DIRS="./dir/to/backup"
DROPBOX_UPLOADER=~/DropboxBackup/dropbox_uploader.sh
LOG_FILE=~/$TMP_DIR/backup.log

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
mysqldump --user=$dbUser --password=$dbPass --host=$dbHost --databases $dbName > $SQL_FILE
tar -zcf "$BKP_FILE" $SQL_FILE

#echo "Backing up the directories $BKP_DIRS"
#tar -zcf "$BKP_FILE" $BKP_DIRS $SQL_FILE

echo "Uploading to Dropbox..." | adddate >> $LOG_FILE
$DROPBOX_UPLOADER -f ~/.dropbox_uploader upload $BKP_FILE "/MySQL_Backups/$BKP_FILE" | adddate >> $LOG_FILE

rm -fr $BKP_FILE $SQL_FILE
duration=$(( SECONDS - start ))
echo "Backup complete! Finished in $duration seconds!" | adddate >> $LOG_FILE