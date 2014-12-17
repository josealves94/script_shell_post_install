#!/bin/bash

### LIST DES SERVEURS ###
#########################
LIST_SERVERS=$(cat LIST_SSH_Dlebre1_YES.txt)

### SCRIPT A POUSSER ###
########################
FILE_BDD="bdd_serv.txt"
#export FILE_BDD="bdd_serv.txt"
echo '"NOM DU SERVEUR";"NOM DE LA BASE";"SGBD (TYPE ET VERSION)"'
for server in $LIST_SERVERS
do
        #echo $server
        #echo $server >> $FILE_BDD
        #export server="$server"
        scp -i /root/.ssh/id_dsa_gs  -q -o "BatchMode=yes"  audit_bdd.sh $server:/root
        scp -i /root/.ssh/id_dsa_gs  -q -o "BatchMode=yes"  $FILE_BDD $server:/root
        ssh -i /root/.ssh/id_dsa_gs $server /root/audit_bdd.sh
        ssh -i /root/.ssh/id_dsa_gs $server rm -f /root/audit_bdd.sh
        #echo =============== 
        #echo =============== >> $FILE_BDD

done
