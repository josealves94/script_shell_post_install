#!/bin/bash
#
####################################
# script audit des bases de données 
# Date: 03/10/2012
# Réalisé par Jérémi Desesquelles 
# Version : 0.1
# Modifié par José ALves le 02/05/2013
#
#####################################
#
# OS=REDHAT

if [ -f /etc/redhat-release ]; then
# nom d'hote de la machine
        NOM_SERV_R=$(echo $HOSTNAME)
        #echo "Nom des bases qui tournent : "
        #NOM_BASE_R=$(ps -edf |grep -v grep |grep sql) 
         NOM_BASE_R=$(ps -eo cmd,args |grep -v grep |grep -i 'sql')
         VERSION_R=$(rpm -qa |grep -i 'postgresql\|mysql-server')
#        echo "versions des paquet installés"
         echo "$NOM_SERV_R;$NOM_BASE_R;$VERSION_R"

#        echo "----------------"
#        echo ""
#        echo "Sauvegarde : "
#        echo ""
#        echo "Cron:"
#       cat /var/spool/cron/* 
#        echo ""

#       echo "----------------"
#       echo ""
#        echo "COMMANDE A REALISER A LA MAIN "
#        echo ""
#       echo "TAILLE DES BDD : du -sm \$DIRECTORY"
#       echo "DATE DES DERNIERES SAUVEGARDES : ls -lht \$BACKUP_DIR/\$BASE/\$TYPE_SVG/"
#        echo ""

exit 0
fi
# OS=DEBIAN
if [ -f /etc/debian_version ]; then
        NOM_SERV_D=$(echo $HOSTNAME)
        #echo "Nom des bases qui tournent : "
        #NOM_BASE_D=$(ps -edf |grep -v grep |grep sql)
        NOM_BASE_D=$(ps -eo cmd,args |grep -v grep |grep -i 'sql')
        VERSION_D=$(dpkg -l  |grep -i 'postgres\|mysql-server' |awk -F' ' '{ print $2 $3 }')
#       echo "versions des paquets installés"
        echo "$NOM_SERV_D;$NOM_BASE_D;$VERSION_D"

#        echo "----------------"
#        echo ""
#        echo "Sauvegarde : "
#        echo ""
#        echo "Cron:"
#        cat /var/spool/cron/*
#        echo ""

 #       echo "----------------"
 #       echo ""
 #       echo "COMMANDE A REALISER A LA MAIN "
 #       echo ""
  #      echo "TAILLE DES BDD : du -sm \$DIRECTORY"
  #      echo "DATE DES DERNIERES SAUVEGARDES : ls -lht \$BACKUP_DIR/\$BASE/\$TYPE_SVG/"
  #      echo ""

exit 0
fi

# OS=INCONNU
echo "Impossible de déterminer le type d'OS!"
exit 0
