#!/bin/bash
# Created by jose alves in 2016

USER="root"
PASS="Dsq45qd%$[45"
BACKUP_FILE="db-srv-src-`date +%s`.sql.gz"
BACKUP_DESTINATION="/data/ftp/ssh-backups/srv-src/db/"
BACKUP_SERVER="serveur_destination.local"
BACKUP_SERVER_USER="user_sql"
EXIT=0

main() {
        /bin/echo "##`date +"%F %H:%m:%S"` - Début du backup de la base"
        /usr/bin/mysqldump -u $USER -p$PASS wiki_infra_new | /bin/gzip > /mnt/wikibackup/$BACKUP_FILE
        #/usr/bin/mysqldump -u $USER -p$PASS test | /bin/gzip > /mnt/wikibackup/$BACKUP_FILE
        if [[ $? != 0 ]]
        then
                /bin/echo "##`date +"%F %H:%m:%S"` - Erreur lors du backup"
                exit 1
        fi

        /bin/echo "##`date +"%F %H:%m:%S"` - Début du transfert vers serveur de destination"
        /usr/bin/scp "/mnt/wikibackup/$BACKUP_FILE" "$BACKUP_SERVER_USER@$BACKUP_SERVER:$BACKUP_DESTINATION"
        if [[ $? != 0 ]]
        then
                /bin/echo "##`date +"%F %H:%m:%S"` - Erreur lors du transfert vers serveur de destination"
                exit 1
        fi

#       /bin/echo "##`date +"%F %H:%m:%S"` - Suppression du fichier temporaire"
#       /bin/rm -f "/mnt/wikibackup/$BACKUP_FILE"
#       if [[ $? != 0 ]]
#       then
 #              /bin/echo "##`date +"%F %H:%m:%S"` - Erreur pendant la suppression du fichier temporaire"
  #             exit 1
#       fi
}

main
exit "$EXIT"
