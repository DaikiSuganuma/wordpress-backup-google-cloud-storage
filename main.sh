#!/bin/sh
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#

# Set Current Directory for cron job
cd $(dirname $0)

# Load config file
source ./config.conf


#
# Defines
#

# Change this if your automysqlbackup is installed somewhere different.
AUTOMYSQLBACKUP_PATH='./automysqlbackup/automysqlbackup'

# Backup data location. must be same as "CONFIG_backup_dir" of automysqlbackup.conf
DATA_DIR='./data'

# Change this if your gsutil is installed somewhere different.
GSUTIL_PATH='/usr/bin/gsutil'

# Date
YEAR=$(date +"%Y")
MONTH=$(date +"%m")
DAY=$(date +"%d")


#
# [Function] "automysqlbackup" Script
# @see http://sourceforge.net/projects/automysqlbackup/
#
backup_db() {
    echo 'Starting automysqlbackup...'
    ${AUTOMYSQLBACKUP_PATH} -bc ./config.conf
    echo 'Finished automysqlbackup...'
}


#
# [Function] Backup Files
#
backup_files() {
    echo '======================================================================'
    echo 'Starting backup files...'
    echo

    cur_dir=`pwd`

    # Reset
    if [ ! -e "${DATA_DIR}/files" ]; then
        mkdir ${DATA_DIR}/files
    fi
    rm -rf ${DATA_DIR}/files/*

    # Loop
    dirs=(`find ${WEB_SOURCE_ROOT} -name 'uploads' -type d`)
    for dir_path in "${dirs[@]}"; do
        echo "Backup Directory ( ${dir_path} )"
        # Check WordPress directory
        if [ -e "${dir_path}" ]; then
            # Directory Name
            dir_name=`echo $dir_path | sed -e 's/\//_/g' `
            dir_name=`echo $dir_name | sed -e 's/_wp-content_uploads//' `
            dir_name=`echo $dir_name | sed -e 's/^_//' `
            echo ${dir_name}

            # Backup
            if [ ${DAY} = "01" ]; then
                # full backup
                mkdir ${cur_dir}/${DATA_DIR}/files/${dir_name}/
                # cp -r : copy directories recursively
                # cp -f : if an existing destination file cannot be opened, remove it and try again
                # cp -p : preserve the specified attributes
                cp -rfp ${dir_path}/* ${cur_dir}/${DATA_DIR}/files/${dir_name}/
            else
                # differential backup
                cd ${dir_path}
                num=`expr $DAY - 1`
                # cpio -d : Create leading directories where needed
                # cpio -p : Run in copy-pass mode
                # cpio -m : Retain previous file modification times when creating files
                find . -mtime -$num -print0 | cpio --null -dpm ${cur_dir}/${DATA_DIR}/files/${dir_name}/
            fi
        fi

    done

    cd ${cur_dir}

    # Show Results
    echo 
    echo "Size - Location"
    echo `du -hsH "${cur_dir}/${DATA_DIR}/files"`

    echo 
    echo 'Finished backup files...'
    echo '======================================================================'

    return 0
}


#
# [Function] Error
#
error_handler() {
    exit 1
}


#
# Main
#
echo 
echo 'WordPress Backup to Google Cloud Storage'
echo


#
# Backup Database
#
backup_db
if [ ! -e "${DATA_DIR}/daily" ]; then
    printf 'Error: There is no backup files\n'
    error_handler
fi


#
# Backup Upload Files
#
backup_files
if [ ! -e "${DATA_DIR}/files" ]; then
    printf 'Error: There is no files\n'
    error_handler
fi


#
# Archive and Upload to Google Cloud Storage
#
cd ${DATA_DIR}
file_name="${YEAR}${MONTH}${DAY}.tar.gz"
tar -czf ./${file_name} daily files

# Upload
HOSTNAME=`hostname`
gs_path="gs://${BUCKET_NAME}/${HOSTNAME}/${YEAR}/${MONTH}/"
printf "Uploading to ${gs_path}"
${GSUTIL_PATH} cp ./${file_name} ${gs_path}

# Remove all data
rm -rf ./*

echo
echo 'Completed!!'
echo
