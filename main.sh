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

# BEGIN Config

# Change this if your automysqlbackup is installed somewhere different.
AUTOMYSQLBACKUP_PATH='./automysqlbackup/automysqlbackup'

# Change this if your gsutil is installed somewhere different.
GSUTIL_PATH='gsutil'

# WordPress directory
WORDPRESS_UPLOADS_DIR='/home/httpd/project/web/wp-content/uploads'

# Backup data location
DATA_DIR='./data'

# Backup data location
BACKET_NAME='backup.project.com'

# END Config


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
    ${AUTOMYSQLBACKUP_PATH} -bc ./automysqlbackup.conf
    echo 'Finished automysqlbackup...'
}


#
# [Function] WordPress Files
#
backup_wp_files() {
    echo 'Starting WordPress backup...'
    # Check WordPress directory
    if [ ! -e "${WORDPRESS_UPLOADS_DIR}" ]; then
        printf "Error: wrong wordpress upload path: ${WORDPRESS_UPLOADS_DIR}\n"
        return 1
    fi

    # Reset
    if [ ! -e "${DATA_DIR}/uploads" ]; then
        mkdir ${DATA_DIR}/uploads
    fi
    rm -rf ${DATA_DIR}/uploads/*

    if [ ${DAY} = 1 ]; then
        # full backup
        cp -rfp ${WORDPRESS_UPLOADS_DIR}/* ${DATA_DIR}/uploads/
    else
        # differential backup
        cur_dir=`pwd`
        cd ${WORDPRESS_UPLOADS_DIR}
        echo $cur_dir
        num=`expr $DAY - 1`
        # cpio -d : Create leading directories where needed
        # cpio -p : Run in copy-pass mode
        # cpio -v : Verbosely list the files processed
        # cpio -m : Retain previous file modification times when creating files
        find . -mtime -$num -print0 | cpio --null -dpvm ${cur_dir}/${DATA_DIR}/uploads/
        cd ${cur_dir}
    fi
    echo 'Finished WordPress backup...'
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
backup_wp_files
if [ ! -e "${DATA_DIR}/uploads" ]; then
    printf 'Error: There is no upload files\n'
    error_handler
fi


#
# Archive and Upload to Google Cloud Storage
#
cd ${DATA_DIR}
file_name="${YEAR}${MONTH}${DAY}.tar.gz"
tar -czf ./${file_name} daily uploads

# Upload
gs_path="gs://${BACKET_NAME}/${YEAR}/${MONTH}/"
printf "Uploading to gs://${gs_path}"
${GSUTIL_PATH} cp ./${file_name} ${gs_path}

# Remove all data
rm -rf ./*

echo
echo 'Completed!!'
echo
