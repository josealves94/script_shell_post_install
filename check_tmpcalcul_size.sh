#!/bin/bash
#
# Auteur : Alves José
#
# Description : Affiche les 5 répertoires les utilsiateurs plus gros en taille dans  /TMPCALCUL/users
# date : 11/07/2014
#
###############################################################################

tx_util=$(df -h |grep -i TMPCALCUL | awk '{ print $4 }' | sed '$s/.$//')

$chksize=$(/usr/bin/du -xsh /TMPCALCUL/users/* |sort -rh > resultsize.txt)
sleep 90
showsize=$(head -n 5 resultsize.txt)

if [ $tx_util -gt 96 ]; then
 echo -e " Les 5 répertoires utilisateurs les plus utilisés sur farux en taille sont les suivants : \n\n $showsize \n\n Le taux d'utilisation de TMPCALCUL est de $tx_util % \n" | mutt -s "Taille critique sur les répertoires utilisateurs de Farux" infogeranceunix@irsn.fr

else

echo  "La taille de TMPCALCUL sur farux est  inférieure à 96 %" 
fi
