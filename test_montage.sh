#!/bin/bash
#
# Auteur : Alves José
# Description : verifie si le point de montage Metiers est bien monté
#
#
################################################
dir="/mnt/cifs/dafcj/metiers"
cmd=$(stat -fc%t:%T "$dir")
cmd2=$(stat -fc%t:%T "$dir/..")

#set -x
if [ "$cmd" != "$cmd2" ]; then
# set -x  
 echo "$dir est bien monté sur aadmu202v"  | mail -s "Point de montage Metiers fonctionnel pour le script dafcj sur aadmu202v"  infogeranceunix@irsn.fr
else
 #set -x
  echo "$dir n'est pas monté sur aadmu202v"  | mail -s "Erreur de  montage  Metiers pour le script dafcj sur aadmu202v"  infogeranceunix@irsn.fr
  echo "Tentative de montage du partage metiers"
  # trouver un moyen de monter le partage sans que le mot de passe soit en clair
  #mount -t cifs //stockagefont/metiers /mnt/cifs/dafcj/metiers -o username=s-achat,password='4chAt!rsn',domain=PROTON,iocharset=iso8859-15,file_mode=0755,dir_mode=0755
fi
