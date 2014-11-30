#!/bin/bash

USER_GROUPS="st3c semia sams sagr dsusec"

for g in ${USER_GROUPS}
do
  # construction de la liste des utilisateurs pour chaque groupe
  USERS_LIST=$(ypcat group | grep $g | cut -d : -f 4)
  if [ -z $USERS_LIST ]
  then
    continue
  fi

  USERS_LIST=$(echo $USERS_LIST | sed s:,:\ :g)

  # creation d'un repertoire pour chaque utilisateur
  for u in ${USERS_LIST}
  do
    if [ -z "$u" ]
    then
      continue
    fi

    # verifie l'existence de l'utilisateur
    id $u >& /dev/null
    if [ $? -ne 0 ]
    then
      continue
    fi

    # creation du repertoire, si necessaire
    if [ ! -d /TMPCALCUL/$u ]
    then
      mkdir /TMPCALCUL/$u
      chown $u /TMPCALCUL/$u
      chgrp $g /TMPCALCUL/$u
    fi
  done
done

