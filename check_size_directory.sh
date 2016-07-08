#!/bin/bash
#
#
#
# Auteur : Alves José
#
# Description : verifie que la taille du /data de serveur1/2 et envoie un mail a toto@toto.com si la taille depasse 90%
#
#######################

red='\033[01;31m'
blue='\033[01;34m'
norm='\033[00m'
dir='/data'

mail="toto@toto.com"

tx_util=$(df -h |grep -i data |awk '{ print $5 }' | sed 's/.$//')
#tx_util='95'

if [ $tx_util -gt 90 ]; then

mail -s "$(echo -e "HIPPO[1-2] : TAILLE du repertoire /DATA critique  \nContent-Type: text/html")" $mail <<EOT

<h1 style="color:red"> Hippo[1-2]: Le repertoire $dir est plein à 90%  </h1>
<p> Merci de purger les binary logs et de vider les tables histo</p>
EOT
fi
