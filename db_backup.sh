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
# have run this command.
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

NOW=$(date +"%Y-%m-%d-%H-%M-%S")
_file="backup-$dbName-$NOW.sql.gz"

echo "Backing up the $dbName MySQL database to $_file file, please wait..."
start=$SECONDS
cd ~
mysqldump --user=$dbUser --password=$dbPass --host=$dbHost --databases $dbName | gzip >$_file
./dropbox_uploader.sh -q -f ~/.dropbox_uploader upload $_file "/MySQL_Backups/$_file" 
rm $_file
duration=$(( SECONDS - start ))
echo "Backup successfully completed in $duration seconds!"