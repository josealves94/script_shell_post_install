#!/bin/sh

# Constant definition
CUR_DATE=`date +\%F`
BACKUP_DIR=/var/lib/postgresql/backups
LOG_FILE=$BACKUP_DIR/pgsql-dump-$CUR_DATE.log
BACKUP_FILE=$BACKUP_DIR/pgsql-dump-$CUR_DATE.sql.gz


# Add message to log file
log() {
        echo `date "+%Y-%m-%d %H:%M:%S"`" $1" >> $LOG_FILE
}


# Starting PostgreSQL backup
main() {
        # Test user ID
        if [ `id -u` -ne 0  ]; then
                echo "Script must be execute with root privileges"
                exit 1
        fi

        # Test if backup directory exist. If not, create it
        if [ ! -d /srv/data/data/postgresql/ ]; then
                #log "DRBD volume not mounted. We're probably on cluster backup node. Nothing to do !"
                exit 0
        else
                echo "" > $LOG_FILE
        fi

        # Remove old backup
        log "=== Remove old backup file ==="
        find $BACKUP_DIR -regex "${BACKUP_DIR}/pgsql-dump-.*.[tar.gz|log]" -type f -print -exec rm -f {} \; >> $LOG_FILE 2>&1

        # Start backup
        log "=== Start Backup ==="
        pg_dumpall -U postgres -h 127.0.0.1 -c | gzip -c > $BACKUP_FILE
        log "=== End Backup ==="
}

main

exit 0
