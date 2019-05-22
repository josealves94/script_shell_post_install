#!/bin/bash
##################################################
#
# Author: José Alves
# date : 07/06/2018
#
# Description : Backup and truncate ARCHIVES tables
#
#  V 0.1 08/06/2018
#  V 0.2 check partition capacity
#  V 0.3 insert statement in each line of the  mysql dump
#  V 0.4 Compare records numbers of each dump before truncate
#  V 0.5  backup each partition for each archives tables
#  V 0.6 modif check disk size on production
##################################################

MUSER="$1"
MPASS="$2"
MDB="$3"
HOST="localhost"
PATH_DMP="/mnt/ssddump" # <--- To change if the environment is different
SOCKET="/var/lib/mysql/mysql.sock"
NB_PROC="40"

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

## Modif of 12/12/2018

tx_util=$(df -h |grep -i ssddump |awk '{ print $5 }' | sed 's/.$//')


TABLES=$($MYSQL --batch --skip-column-names -u $MUSER -p$MPASS $MDB -e "show tables like '%_ARCHIVES%';" )

#PART=$(mysql --batch --skip-column-names -u root -pucrqsjdr coyote -e " SELECT PARTITION_ORDINAL_POSITION, TABLE_ROWS, PARTITION_METHOD FROM information_schema.PARTITIONS WHERE TABLE_SCHEMA = 'coyote' AND TABLE_NAME = 'COYOTE_RADAR_M_ARCHIVES';" )



# Loop on archives tables
for t in $TABLES
do


        # if mount path is available and if used space disk is  below 90 %
        if [[ -d ${PATH_DMP} && ${tx_util} -lt 90 ]]
        then
           echo "--- Backup table $t on database $MDB ---"
           echo "-------"
           $MYSQLDMP -K -S ${SOCKET} --quick --skip-extended-insert  --single-transaction --no-create-db -h ${HOST} -u ${MUSER} -p${MPASS} ${MDB} ${t} | lbzip2 --best -n${NB_PROC} > ${PATH_DMP}/${MDB}/${t}_${DATEDUJ}.dmp.sql.bz2

		   NP=$(mysql --batch --skip-column-names -u $MUSER -p$MPASS $MDB -e " SELECT PARTITION_ORDINAL_POSITION, TABLE_ROWS, PARTITION_METHOD FROM information_schema.PARTITIONS WHERE TABLE_SCHEMA = '${MDB}' AND TABLE_NAME = '${t}';" | awk '{ print $1 }' | sed 's/^//')
		   # loop on partitions to dump
		   for pt in $NP
		    do
		    echo "--- Backup partition $pt of table $t on database $MDB ---"
		    $MYSQLDMP -K -S ${SOCKET} --quick --single-transaction --no-create-db -h ${HOST} -u ${MUSER} -p${MPASS} --where='FPART=${pt}' ${MDB} ${t} | lbzip2 --best -n${NB_PROC} > ${PATH_DMP}/${MDB}/${t}_${pt}.dmp.sql.bz2
            echo "-------"
		  done
		  echo "--- check records number of  table $t on database $MDB ---"
          nbr=$(cat ${PATH_DMP}/${MDB}/${t}_${DATEDUJ}.dmp.sql.bz2 |lbzip2 -n${NB_PROC} -d -c |grep ^'INSERT INTO' |wc -l)
          echo "--- Number of records in backup archive : $nbr ---"
          tot_table=$(mysql -s -N -u ${MUSER} -p${MPASS} --database=${MDB} -e "SELECT COUNT(*) FROM ${t};")
          echo "--- Number of records in table $t : $tot_table ---"
          echo "--- End of check records in table $t ---"
        if [[ $nbr -eq $tot_table  ]]
        then


        NB=$(mysql --batch --skip-column-names -u $MUSER -p$MPASS $MDB -e " SELECT PARTITION_ORDINAL_POSITION, TABLE_ROWS, PARTITION_METHOD FROM information_schema.PARTITIONS WHERE TABLE_SCHEMA = '${MDB}' AND TABLE_NAME = '${t}';" | tail -n1 | cut -c1-2)
        PART=$(mysql --batch --skip-column-names -u $MUSER -p$MPASS $MDB -e " SELECT PARTITION_ORDINAL_POSITION, TABLE_ROWS, PARTITION_METHOD FROM information_schema.PARTITIONS WHERE TABLE_SCHEMA = '${MDB}' AND TABLE_NAME = '${t}';" | awk '{ print $1 }' | sed 's/^/P/')
        echo "The table ${t}  has ${NB} partitions"
        # Loop in the partitions
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
            echo " Error number differents in the table ${t}"
            exit 1
         fi

        else

           echo -e " The directory ${PATH_DMP} doesnt exist \n"
           exit 1
        fi
done                   
