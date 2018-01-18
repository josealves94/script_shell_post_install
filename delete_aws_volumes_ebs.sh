#!/bin/bash
#############
#
# Auteur : José Alves
# Date : 02/10/2017
# Description :Lister puis supprimer des volumes ebs inutilisées sur aws
#
#####################

echo "Nombre d'instance à supprimer : "
aws ec2 describe-volumes  | grep available | awk '{print $9}' |wc -l

for volumes in `aws ec2 describe-volumes  | grep available | awk '{print $9}' | grep vol| tr '\n' ' '`
do
        echo $volumes
 # supprimer les volumes available non-utilisés
aws ec2 delete-volume --volume-id $volumes

done

# supprimer des volumes -- ATTENTION  ci-dessous non testé en prod --
#aws ec2 delete-volume $(aws ec2 describe-volumes  | grep available | awk '{print $9}' | tr '\n' ' ')
~
