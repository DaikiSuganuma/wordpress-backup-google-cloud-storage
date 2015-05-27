WordPress Backup to Google Cloud Storage
========================================

This is shell script for backup WordPress Database and upload files located wp-content/uploads.

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

		# vi automysqlbackup.conf

8. Update "WORDPRESS_UPLOADS_DIR" for location of wordpress uploads directory

		# vi main.sh

9. Update "BUCKET_NAME". this is the bucket name of Google Cloud Storage

		# vi main.sh

10. Run. You can check outputs of script.

		# ./main.sh

11. As cron job

		# vi /etc/cron.d/backup
		MAILTO="info@hoge.com"
		00 3 * * * root /home/cron/wordpress-backup-google-cloud-storage/main.sh
