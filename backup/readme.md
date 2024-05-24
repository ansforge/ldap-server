# Cron à mettre en place
* 2 * * * /root/ldap_backup.sh > /var/backup/LDAP/rhodecode_backup-cron-`date +\%F`.log 2>&1