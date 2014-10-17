#!/bin/bash

########################################################
# A script to download and backup the output from a web 
# cron URL.
#
# Author: Dan @ CubicApps
# Website: https://github.com/CubicApps
# Copyright 2014
#
# Usage: $ ./web_cron.sh -u URL -f FILENAME
#
# Before running this script for the first time make 
# sure you have already run the `./dropbox_uploader.sh` 
# script. Also make sure you give this script execution 
# permissions:
# $ chmod +x web_cron.sh
#
########################################################

# Exit immediately if an error occurs (i.e., a command exits with a non-zero status)
set -e

usage() { echo "Usage: $0 [-u <url>] [-f <filename>]" 1>&2; exit 1; }

while getopts ":u:f:" o; do
    case "${o}" in
        u)
            url=${OPTARG}
            ;;
        f)
            filename=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${url}" ] || [ -z "${filename}" ]; then
    usage
fi

# Save the web cron URL output to a daily log file
NOW=$(date +"%Y-%m-%d")
LOG_FILE="$filename-$NOW.log"
TMP_DIR="tmp"

cd ~
# Create a temp directory if it doesnt exist
mkdir -p $TMP_DIR
echo "Starting URL backup for '$url' to $LOG_FILE"
start=$SECONDS
wget --quiet $url -O - >> ~/$TMP_DIR/$LOG_FILE
duration=$(( SECONDS - start ))
echo "Archiving complete! Finished in $duration seconds!"

# Backup the previous days archive to Dropbox if it exists
DROP_DIR="Archive_Backups"
DROPBOX_UPLOADER=~/DropboxBackup/dropbox_uploader.sh
DROP_CONFIG=~/.dropbox_uploader
BKP_DATE=$(date --date="-1 day" +%Y-%m-%d)
PREV_DAY_LOG_FILE="$filename-$BKP_DATE.log"
BKP_LOG_FILE="$filename-backup-$BKP_DATE.tar.gz"

# Set the delete date to a multiple of the cron schedule e.g., a weekly cron schedule means data can only be deleted every 7, 14, 21, 28, etc, days
DEL_DATE=$(date --date="-28 day" +%Y-%m-%d)

if [ -f ~/$TMP_DIR/$PREV_DAY_LOG_FILE ];
then
	echo "Starting archive backup of '$PREV_DAY_LOG_FILE' to Dropbox..."
	start=$SECONDS
	cd ~/$TMP_DIR
	tar -zcf "$BKP_LOG_FILE" "$PREV_DAY_LOG_FILE"
	$DROPBOX_UPLOADER -f $DROP_CONFIG upload $BKP_LOG_FILE "/$DROP_DIR/$BKP_LOG_FILE"
	echo "Deleting '$PREV_DAY_LOG_FILE' and '$BKP_LOG_FILE'"
	rm -f $PREV_DAY_LOG_FILE $BKP_LOG_FILE
	
	# Delete old backup from Dropbox
	echo "Finding any existing archive backup that was made on '$DEL_DATE'..."
	while read -r state size file rest
	do
		if [[ $state = "[F]" && $file = "$filename-backup-"* ]]
		then
			if [[ $file = "$filename-backup-$DEL_DATE"* ]]
			then
				echo "Old backup found! Deleting '$file'"
				$DROPBOX_UPLOADER -f $DROP_CONFIG delete "/$DROP_DIR/$file"
			fi
		fi
	done < <($DROPBOX_UPLOADER -f $DROP_CONFIG list $DROP_DIR/)
	
	duration=$(( SECONDS - start ))
	echo "Archive backup complete! Finished in $duration seconds!"
else
	echo "File '$PREV_DAY_LOG_FILE' does not exist! Skipping backup to Dropbox..."
fi
