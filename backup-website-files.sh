#!/bin/bash
# Created by José Alves in 2016 for Coyote
# BACKUp WIKI WEB SITE FILES TO destination server
#
##################################

BACKUP_SRC="files-serveur-src-`/bin/date +%s`.tar.gz"
#SOURCE="/usr/share/redmine/files"
SOURCE="/var/www/wiki_infra_new"
BACKUP_DESTINATION="/data/ftp/ssh-backups/serveur-src/files/"
BACKUP_SERVER="serveur_destination.local"
BACKUP_SERVER_USER="test"

cd $SOURCE
if [[ $? != 0 ]]
then
    echo "##`/bin/date +"%F %H:%m:%S"` - Répertoire non présent"
    exit 1
fi

echo "##`/bin/date +"%F %H:%m:%S"` - Début de la compression"
/bin/tar -zcf "/mnt/wikibackup/$BACKUP_SRC" .
if [[ $? != 0 ]]
then
    echo "##`/bin/date +"%F %H:%m:%S"` - Erreur à la compression"
    exit 1
fi

echo "##`/bin/date +"%F %H:%m:%S"` - Début du transfert vers serveur de destination"
/usr/bin/scp "/mnt/wikibackup/$BACKUP_SRC" "$BACKUP_SERVER_USER@$BACKUP_SERVER:$BACKUP_DESTINATION"
if [[ $? != 0 ]]
then
    echo "##`/bin/date +"%F %H:%m:%S"` - Erreur lors du transfert vers serveur de destination"
    exit 1
fi

#echo "##`/bin/date +"%F %H:%m:%S"` - Suppression du fichier temporaire"
#/bin/rm -f "/mnt/wikibackup/$BACKUP_SRC"
#if [[ $? != 0 ]]
#then
#    echo "##`/bin/date +"%F %H:%m:%S"` - Erreur lors de la suppression du fichier temporaire"
#    exit 1
#fi

exit 0
