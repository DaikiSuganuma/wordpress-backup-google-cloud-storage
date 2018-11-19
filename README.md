WordPress Backup to Google Cloud Storage
========================================

This is shell script for backup WordPress Database and upload files located wp-content/uploads.

I created this script for my WordPress sites, but you can use any site for editing "BACKUP_DIRS" in config.conf

This is using "[AutoMySQLBackup](http://sourceforge.net/projects/automysqlbackup/)" for database backup.


Setup
-----
1. Register for Google Cloud Services
2. Install gsutil
3. Create a bucket in the [Google Developers Console](https://console.developers.google.com/)
4. Configure gsutil to work with your account

		gsutil config

5. Clone files somewhere in your server

		# mkdir /home/cron
		# cd /home/cron
		# git clone https://github.com/DaikiSuganuma/wordpress-backup-google-cloud-storage

6. Change file permission

		# cd wordpress-backup-google-cloud-storage/
		# chmod +x main.sh automysqlbackup/automysqlbackup

7. Update "CONFIG_mysql_dump_password" for connecting database

		# vi config.conf

8. Update "WEB_SOURCE_ROOT" for location of backup directories

		# vi config.conf

9. Update "BUCKET_NAME". this is the bucket name of Google Cloud Storage

		# vi config.conf

10. Run. You can check outputs of this script.

		# ./main.sh

11. As cron job

		# vi /etc/cron.d/backup
		MAILTO="info@hoge.com"
		00 3 * * * root /home/cron/wordpress-backup-google-cloud-storage/main.sh
