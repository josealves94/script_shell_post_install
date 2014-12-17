#!/bin/bash
#
#
#
# Liste des serveurs à auditer pour obtenir leur version de php
# date 12/05/2014
#############################################################################

LIST_SRV=$(cat list_srv_unix.txt)

#
#
###################################################################

liste_serv=$(echo -e "Nom du serveur ----- version de php installé\n" > php2.txt)
for server in $LIST_SRV
do
  CMD_SSH=$(ssh -i /root/.ssh/id_dsa_gs -q -o "BatchMode=yes" root@$server "hostname ; /usr/bin/php -v")
  echo $CMD_SSH >> php2.txt
done
