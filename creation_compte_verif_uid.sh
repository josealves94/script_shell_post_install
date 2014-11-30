#!/bin/bash
###################################################################
#
# Auteur Alves José
# Date 17/12/2012
# Placer le script sur le serveur nis
# sauveagarde du fichier passwd en cas de probleme 
# etapes du script
# copier coller la derniere ligne du fichier
# modifier le nom du compte
# uid + 1
# id du groupe correspondant à son unité
#
##################################################################

# verifie si l'utilisateur est root pour execution du script

if [ $EUID != 0 ]; 
then
 echo -ne " Vous devez etre root pour executer le script\n"
 exit 1
fi


#chemin fichier à modifier ci-dessous
fich="/var/yp/ypfiles/passwd"

# verifie si le fichier passwd existe
if [ -f "$fich" ]; 
then 

# sauvegarde du fichier passwd en cas de probleme
echo -ne "Sauvegarde du fichier $fich \n"
cp  /var/yp/ypfiles/passwd /var/yp/ypfiles/BACKUP/passwd.BKP.`date +%Y-%m-%d`

# grep le nom d'uilisateur à (modifier  le chemin)
echo -ne "\nmise à jour du fichier passwd ajout de ligne\n"
echo -ne "\nRecuperation du login à ajouter dans le fichier passwd ... : \n"
echo -ne "NOM_LOGIN="${NOM_LOGIN}
#read NOM_LOGIN
# verifie existence de l'utilisateur pour les doublons
# copier la dernier ligne
# concatener les elements renseignés par l'utilisateur à inscrire à la fin du fichier
if [[ "`ypmatch $NOM_LOGIN passwd 2>/dev/null|cut -d: -f1`" == "$NOM_LOGIN" ]]; then
echo -ne "\033[31mErreur le login $NOM_LOGIN existe deja\033[0m\n"
exit 1
else
 echo -ne "\n Le login $NOM_LOGIN n'existe pas \n"
# recuperer le 2 eme champ de la ligne precedente
copy=$(tail -1 $fich | cut -d: -f2)
# recuperation du 3eme champ de la ligne precedente
uid=$(tail -1 $fich | cut -d: -f3)
echo -ne "uid actuelle : $uid\n"
# incrementer l'uid user
uid=$(expr $uid + 1)
echo -ne "nouvel uid+1 : $uid\n"

#  pour gid  condition en fonction des differents poles et creation de ligne suivant le gid
#gid=$(tail -1 passwd | cut -d -f4)
#echo -ne "\033[1mVeuillez entrer le nom du pole (format 2012) de la maniere suivante :(ex : PSN-RES/SEMIA/BAST ou PRP-DGE/SCAN/BERSSIN ou PRP-HOM/SDI/LEDI-FONT\033[0m\n"
#echo -ne "\033[1m Récupération du nom du pole (format 2012)  : (ex : PSN-RES/SEMIA/BAST ou PRP-DGE/SCAN/BERSSIN ou PRP-HOM/SDI/LEDI-FONT\033[0m\n"
echo "SERVICE="$SERVICE
#read SERVICE
case $SERVICE in
	'PRP-ENV/SESURE/LS2A')
        echo "$SERVICE"
        gid='5036'
        echo "le pôle $SERVICE a le gid $gid"
        ;;
	'PRP-CRI/SESUC/BMTA')
        echo "$SERVICE"
        gid='5022'
        echo "le pôle $SERVICE a le gid $gid"
        ;;
	'PRP-DGE'|'PRP-DGE/SEDRAN/BRN')
	echo "$SERVICE"
	gid='1265'
	echo "le pôle $SERVICE a le gid $gid"
	;;
	'PRP-DGE/SRTG/LETIS')
	gid='5018'
	echo "le pôle $SERVICE a le gid $gid"
	;;
	'PRP-DGE/SEDRAN/BERIS'|'PRP-DGE/SCAN/BERSSIN')
	gid='5010'
	echo "Le pôle $SERVICE a le $gid"
	;;
        'PRP-HOM'|'PRP-HOM/SDI/LEDI-FONT'|'PRP-HOM/SER/UETP'|'PRP-HOM/SER/UES'|'PRP-HOM/SDE/LDRI')
	gid='700'
        echo "le pôle $SERVICE a le gid $gid"
	;;
        'PRP-ENV')
	echo "$SERVICE"
	;;
	'PSN-EXP'|'PSN-EXP/SNC/LNR'|'PSN-EXP/SNC/LNR/EXT')
	gid='5019'
        echo "le pôle $SERVICE a le gid $gid"
	;;
	'PSN-EXP/SES/BEGC')
	gid='5021'
	echo "le pôle $SERVICE a le gid $gid"
	;;
	'PSN-RES/SEMIA/BAST')
        gid='5037'
	echo "le pôle $SERVICE a le gid $gid"
	;;											   
	'PSN-RES'|'PSN-RES/SAG/BPHAG'|'PSN-RES/SAG/BEPAG'|'IRSN/PSN-RES/SAG/BPhAG'|'PSN-RES/SAG/B2EGR')
	gid='5023'
        echo "le pôle $SERVICE a le gid $gid"
	;;
	'PSN-RES/SEMIA/BMGS')
	gid='5025'
        echo "le pôle $SERVICE a le gid $gid"
	;;
	'PSN-RES/SEMIA/LIMAR')
	gid='1100'
        echo "le pôle $SERVICE a le gid $gid"
	;;
	'PSN-RES/SA2I/BE2I'|'IRSN/PSN-RES/SA2I/LIEI')
	gid='5012'
        echo "le pôle $SERVICE a le gid $gid"
	;;
	'PSN-RES/SEMIA/BMGS')
	gid='5025'
        echo "le pôle $SERVICE a le gid $gid"
	;;
	'PSN-SRDS'|'PSN-SRDS/SSyR/BEPS')
	# gid non trouvé
  	echo "$SERVICE"
	;;
	'PND-END')
	gid='5029'
        echo "le pôle $SERVICE a le gid $gid"
	;;
	'DG')
	# gid non defini
	echo "le pôle $SERVICE n'a pas de gid defini"
	;;
	'DSPSI/SDSI/BIE'|'IRSN/DSPSI/SDSI/BIE'|'DSPSI/SDSI/BCP')
	gid='1263'
        echo "le pôle $SERVICE a le gid $gid"
	;;
	'DSU/SSD')
	echo "$SERVICE"
        gid='5010'
        echo "le pôle $SERVICE a le gid $gid"
	;;
	'PSN-EXP/SNC/LNC')
	echo "$SERVICE"
        gid='15004'
        echo "le pôle $SERVICE a le gid $gid"
	;;
     	*)
### FAIRE QUITER LE SCRIPT SI POLE NON EXISTANT !!!
#### GBO - affectation au groupe seac par defaut
	echo "$SERVICE"
        gid='1263'
        echo "le pôle $SERVICE a le gid $gid"
	#echo "Usage veuillez mettre un pole existant: ex PSN-RES PSN-EXP PND-END PSN-RES/SEMIA/BAST"
	#exit 1
	;;   
esac

# choix du shell
        echo -ne "mshell par défaut pour l'utilisateur /bin/bash \n"
        echo -ne "Creation de la ligne dans le fichier\n"
        echo "$NOM_LOGIN:$copy:$uid:$gid:$NAME $PRENOM - $SERVICE - $LOC:/home/$NOM_LOGIN:/bin/bash" >> $fich


fi
else
 echo -ne " le fichier $fich existe pas\n"
fi

