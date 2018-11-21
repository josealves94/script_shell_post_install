#!/bin/bash
##################################################
#
# Author: José Alves
# date : 07/06/2018
#
# Description : Backup and truncate ARCHIVES tables
#
#  V 0.1 08/06/2018
##################################################

MUSER="$1"
MPASS="$2"
MDB="$3"
HOST="localhost"
PATH_DMP="/mnt/hamster" # <--- A adapter selon le serveur


# Detect paths
MYSQL=$(which mysql)
MYSQLDMP=$(which mysqldump)
AWK=$(which awk)
GREP=$(which grep)
BZIP2=$(which lbzip2)
DATEDUJ=$(date +%F)

if [ $# -ne 3 ]
then
        echo "Usage: $0 {MySQL-User-Name} {MySQL-User-Password} {MySQL-Database-Name}"
        echo "Backup and Truncate all ARCHIVES TABLES from  HIPPO DATABASES"
        exit 1
fi

TABLES=$($MYSQL --batch --skip-column-names -u $MUSER -p$MPASS $MDB -e "show tables like '%_ARCHIVES%';" )

#PART=$(mysql --batch --skip-column-names -u root -pucrqsjdr coyote -e " SELECT PARTITION_ORDINAL_POSITION, TABLE_ROWS, PARTITION_METHOD FROM information_schema.PARTITIONS WHERE TABLE_SCHEMA = 'coyote' AND TABLE_NAME = 'COYOTE_RADAR_M_ARCHIVES';" )



# Boucle sur les tables archives
for t in $TABLES
do
        # si point de montage vers hamster dispo sinon erreur
        if [[ -d ${PATH_DMP} ]]
        then
           echo "Backup table $t "
           echo "-------"
           $MYSQLDMP -K -e  -q --single-transaction --no-create-db -h ${HOST} -u ${MUSER} -p${MPASS} ${MDB} ${t} | lbzip2 -n4 > ${PATH_DMP}/${MDB}/export_${t}_${DATEDUJ}.dmp.sql.bz2
           echo "-------"
        NB=$(mysql --batch --skip-column-names -u $MUSER -p$MPASS $MDB -e " SELECT PARTITION_ORDINAL_POSITION, TABLE_ROWS, PARTITION_METHOD FROM information_schema.PARTITIONS WHERE TABLE_SCHEMA = '${MDB}' AND TABLE_NAME = '${t}';" |tail -n1 | awk "{ print $1 }")
        PART=$(mysql --batch --skip-column-names -u $MUSER -p$MPASS $MDB -e " SELECT PARTITION_ORDINAL_POSITION, TABLE_ROWS, PARTITION_METHOD FROM information_schema.PARTITIONS WHERE TABLE_SCHEMA = '${MDB}' AND TABLE_NAME = '${t}';" | awk '{ print $1 }' | sed 's/^/P/')
        echo "The table ${t}  has ${NB} partitions"
        # Boucle dans les partitions
        for p in $PART
         do
            echo "Truncating table $t from $MDB Database..."
            echo "-------"
            echo "Removing partition ${p} in table ${t}"
            $MYSQL -u ${MUSER} -p${MPASS} ${MDB} -e " alter table ${MDB}.${t} truncate partition ${p};"
            sleep 300
            echo "-------"
         done
        else

           echo -e " The directory ${PATH_DMP} doesnt exist \n"
           exit 1
        fi
done
