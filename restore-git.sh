#!/bin/bash
#
# Date: 14/10/2016
#  Auteur : José Alves
#
# Description : restauration de  gitalb-ce en cas de crash
#
######################################


if [[ -d "/mnt/backup" && grep -qs 'backup' /proc/mounts ]]; then

   echo "Le montage nfs /mnt/backup vers hamster "
   echo "Arret des service connecté à la base gitlab"
  /usr/bin/gitlab-ctl stop unicorn
  /usr/bin/gitlab-ctl stop sidekiq
 # recupere la derniere sauvegarde via son timestamp
   echo "Restauration de la derniere sauvegarde a partir du timestamp"
TIMESTP=$(ls -larth /mnt/backup/*.tar |tail -n 1 |cut -d"/" -f4 |awk -F"_" '{ print $1 }')
   gitlab-rake gitlab:backup:restore BACKUP=${TIMESTP}
  echo "restauration terminéé"
  echo "*** Demmarage de gitlab + check ***"
  /usr/bin/gitlab-ctl start
  gitlab-rake gitlab:check SANITIZE=true
else
  echo "le montage nfs  /mnt/backup vers hasmter n'est pas actif"
  exit 1
fi
