#!/bin/bash
#################################################
#
# Description : script qui verifie si tous les triggers sont bien actifs
# AUteur : José Alves
# Date : 17/12/2018
#
#
###################################################

STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

USER="XXXXX"
PASS='XXXXX'
HOST='XXXXXXX'
#FIC_TRIG="/tmp/fich_temp_check_trigger.tmp_${dateduj}"
#dateduj=$(date +%Y-%m-%d )
MDB="$1"
MDB2="$1"
hduj=$(date +%H:%M)

if [ $# -ne 1 ]
then
        echo "Usage: $0 {MySQL-Database-Name}"
        echo "check triggers on database Hippo"
        exit 1
fi


#mysql -u $USER -p$PASS -e 'select TYPE, DATE_TRT, LIB from ${MDB}.HISTO_LOG WHERE TYPE = "PURGE_COYOTE_POI_SESSION";'

trig=$(mysql -u $USER -p$PASS -h $HOST $MDB -e 'show triggers\G' |grep -i Trigger |awk -F: '{ print $2 }' |wc -l ) 

trig_poi=$(mysql -u $USER -p$PASS $MDB2 -h $HOST -e 'show triggers\G' |grep -i Trigger |awk -F: '{ print $2 }' |wc -l)

# cat "${FIC_TMP}"

#res=$(grep FINI $FIC_TMP |awk -F" " '{ print $4 }')

if [[ $trig -eq 46  && $MDB == "coyote" ]]; then
 echo "OK - Number of triggers in ${MDB} is Ok | nb_triggers_coyote=${trig}"
 exit 0
else
  echo "CRITICAL - Number of triggers in ${MDB} is KO | nb_triggers_coyote=${trig}"
 exit 2
fi

if [[ $trig_poi -eq  11 && $MDB2 == "coyote_poi" ]]; then

 echo "OK - Number of triggers in ${MDB2} is Ok | nb_triggers_coyote=${trig_poi}"
 exit 0
else
 echo "CRITICAL - Number of triggers in ${MDB2} is KO | nb_triggers_coyote=${trig_poi}"
 exit 2
fi

echo "UNKNOW - No data were returned  on host Hippo"
exit 3
