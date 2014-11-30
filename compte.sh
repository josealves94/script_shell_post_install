#!/usr/bin/ksh

# Creation de compte unix NIS sur berlin
# CBO 27/10/05
# CBO 21/04/06 - Modification auto_home et noms des stations SSD
# CBO 26/04/06 - Ajout specificite licences pour ST3C 
# GPI 23/10/06 - Creation d'un lien symbolique de .profile vers .bash-profile ligne 54
# SSP 01/10/09 - Migration du script Unix vers Linux
# SSP 21/04/11 - Modification suite au nouveau filer Netapp ASTOU201
# JAL 02/01/13 - Modification appel vers le script d'ajout de ligne du fichier passwd
# JAL 03/01/13 - Export des varaibles NOM_LOGIN et SERVICE

# Variables
###########
DATE=`date '+%d%m%y.%H%M%S'`
NIS_DIR=/var/yp/ypfiles
FILER1=stockageunixfont
FILER2=belhara
FILER3=astou201
HOME_DIR=/mnt/nfs/${FILER1}/home_unix
ETC_DIR=/mnt/nfs/${FILER3}/volroot/etc
ETC_DIR_FILER2=/mnt/nfs/${FILER2}/volroot/etc
NIS_SERVER=anisu201
VOLUME=vol0
STATIONS_SSD="abuja bahia doha escondido makaha mundaka"
NETGROUP_DEI="user_pekin user_berlin user_athenes"
NETGROUP_SSD="user_ssd"
AUTO_HOME_SSD="auto.home.cluster.ssd"
AUTO_HOME="auto.home"
AUTO_HOME_OTHER="auto.home.HP-UX auto.home.IRIX64 auto.home.Linux auto.home.OSF1 auto.home.SunOS"

#Fonctions
##########
clear
Maj_Fic() 
{
echo "Ouverture de $* en cours ..."; sleep 5
vi $*
if [ $? -ne 0 ]; then
   echo "Le(s) fichier(s) $* n'existe(nt) pas"
   return 1 
fi
}

Create_Home()
{
ID=`awk -F: '$1 == "'$1'" {print $3":"$4}' $NIS_DIR/passwd`
echo -ne "DEBUG ID = $ID\n"
UNITE=`echo $2 |cut -d/ -f2`
if [ ! -d "$HOME_DIR/$1" ]; then 
   mkdir $HOME_DIR/$1 
   if [ $? -ne 0 ]; then
      echo -ne "\033[31mImpossible de creer la home directory\033[0m\n"
      exit 2
   else
      chmod 700 $HOME_DIR/$1 2>/dev/null
      ret_chmod=$?
      chown $ID $HOME_DIR/$1 2>/dev/null
      ret_chown=$?
      ( [ $ret_chown -ne 0 ] || [ $ret_chmod -ne 0 ] ) && echo -ne "\033[31mAaaaarg!Impossible de changer les droits sur $HOME_DIR/$1\033[0m\n"
      if [[ -d "$HOME_DIR/modelek" ]] ; then
         cd $HOME_DIR/modelek && cp .profile .profile.perso .bashrc .bashrc.perso $HOME_DIR/$1
         cd $HOME_DIR/$1 && chown $ID .*.perso && ln -s .bashrc .kshrc 
	 ln -s .profile $HOME_DIR/$1/.bash_profile
         perl -pi -e "s:export UNITE=:export UNITE=$UNITE:" $HOME_DIR/$1/.profile || echo -ne "\033[31mVeuillez renseigner manuellement le fichier .profile\033[0m\n"
      else echo -ne "\033[31mImpossible de copier les fichiers d'environnement sur $HOME_DIR/$1\033[0m\n"
      fi
   fi
else
   echo -ne "\033[31mImpossible de changer les droits sur $HOME_DIR/$1\033[0m\n"
fi
}

Maj_Netgroup()
{
NOM_NETGRP=`cat $NIS_DIR/netgroup | awk '$1 ~ /^'$netgrp'[0-9]*$/ {print $1}'|sort|tail -1`
NETGRP=`cat $NIS_DIR/netgroup | awk '$1 ~ /^'$netgrp'[0-9]*$/ {print} '|sort|tail -1|awk 'length($0)>800 {print}'`
\cp -p $NIS_DIR/netgroup $NIS_DIR/old/netgroup.$DATE
if [[ "X$NETGRP" != X ]] ; then
   echo $NETGRP | awk '{printf("Veuillez creer %s%s dans le fichier netgroup\n",substr($1,1,length($1)-1),substr($1,length($1))+1)}'
else
   echo "Ajout de $NOM_LOGIN dans le netgroup $netgrp..."; sleep 5
   set noclobber
   awk '{if ( $1 ~ /^'$NOM_NETGRP'$/) {print $0,"(,'$NOM_LOGIN',)";next} {print}}' $NIS_DIR/netgroup>$NIS_DIR/netgroup.new
    \mv $NIS_DIR/netgroup.new $NIS_DIR/netgroup
   unset noclobber
fi
}


#Main
#####
if [ "$(hostname -a)" != "$NIS_SERVER" ]; then 
   echo "Vous n'etes pas sur la bonne machine"
   exit 1
fi
echo -ne "\033[1m***********************************\033[0m"
echo -ne "\n\033[1mCreation de compte NIS sur $NIS_SERVER\033[0m\n" 
echo -ne "\033[1m***********************************\033[0m\n\n"

## INFOS UTIL
echo -ne "\033[1m **** Informations requises ****\033[0m\n"
echo ""
echo -n "Entrez le NOM de l'utilisateur en maj. (ex: DESESQUELLES) : "
read NAME
echo -n "Entrez le PRENOM de l'utilisateur en maj. (ex: JEREMI) : "
read PRENOM
NOM_LOGIN=`echo $NAME |cut -c1-5``echo $PRENOM |cut -c1-2`
echo "Le login de l'utilisateur sera le suivant : $NOM_LOGIN"

export NOM_LOGIN="$NOM_LOGIN"
export NAME="$NAME"
export PRENOM="$PRENOM"
typeset -r NOM_LOGIN
typeset -r NAME
typeset -r PRENOM

if [[ "`ypmatch $NOM_LOGIN passwd 2>/dev/null|cut -d: -f1`" == "$NOM_LOGIN" ]]; then
   echo "Erreur le login $NOM_LOGIN existe deja"
   exit 1
fi
if [ ${#NOM_LOGIN} -gt 8 ] ; then
   echo "Le login ne doit pas exceder 8 caracteres"
   exit 2
elif [[ $NOM_LOGIN != +([a-zA-Z0-9][-_][a-zA-Z0-9]|[a-zA-Z0-9]) ]];then
   echo "Le nom de login n'est pas correct"
   exit 2
fi

echo -n "Entrez la localisation (ex: Bat 25 Piece 106) : "
read LOC 
export LOC="$LOC"
typeset -r LOC

echo "Entrez le nom de l'unite de l'utilisateur (en entier : important!) : 
ex :  Rappel des differents poles (format 2013) : 
  PRP-DGE/SEDRAN/BRN 
  PRP-DGE/SRTG/LETIS 
  PRP-DGE/SEDRAN/BERIS 
  PRP-DGE/SCAN/BERSSIN 
  PRP-HOM/SDI/LEDI-FONT 
  PRP-ENV/SESURE/LS2A
  PRP-CRI/SESUC/BMTA
  PSN-EXP/SNC/LNR 
  PSN-EXP/SNC/LNR/EXT 
  PSN-EXP/SES/BEGC
  PSN-RES/SEMIA/BAST 
  PSN-RES/SAG/BPHAG 
  PSN-RES/SAG/BEPAG 
  IRSN/PSN-RES/SAG/BPhAG 
  PSN-RES/SEMIA/BMGS 
  PSN-RES/SEMIA/LIMAR 
  PSN-RES/SA2I/BE2I 
  IRSN/PSN-RES/SA2I/LIEI 
  PSN-RES/SEMIA/BMGS 
  PND-END DSPSI/SDSI/BIE 
  IRSN/DSPSI/SDSI/BIE 
  DSPSI/SDSI/BCP 
  DSU/SSD
  "
echo -n "Service de l'utilisateur : "
read SERVICE
# export de la variable service pour le script creation_compte_verif_uid.sh
export SERVICE="$SERVICE"
SERVICE_SSD=`echo $SERVICE|grep -w DSU/SSD`
SERVICE_DEI=`echo $SERVICE|grep -w DEI`
SERVICE_ST3C=`echo $SERVICE|grep -w DSR/ST3C`

# appel du script creation_compte_verif_uid.sh d'ajout de la ligne du compte user
#Maj_Fic $NIS_DIR/passwd
echo ""
echo ""
echo -ne "\033[1m **** Operation Check en cours ****\033[0m\n"
echo ""
bash $NIS_DIR/creation_compte_verif_uid.sh
for autohome in $AUTO_HOME; do
   echo "Mise a jour du fichier $autohome...";sleep 5
   \cp -p $NIS_DIR/$autohome $NIS_DIR/old/$autohome.$DATE
   print "$NOM_LOGIN\t$FILER1:/home_unix/&" >> $NIS_DIR/$autohome
done 
if [ -n "$SERVICE_SSD" ] ; then
   for autohome in $AUTO_HOME_SSD; do
      echo "Mise a jour du fichier $autohome...";sleep 5
      \cp -p $NIS_DIR/$autohome $NIS_DIR/old/$autohome.$DATE
      print "$NOM_LOGIN\tcurium:/export/home/&" >> $NIS_DIR/$autohome
   done 
   for netgrp in $NETGROUP_SSD ; do
      Maj_Netgroup 
   done
   if [ ! -d "$ETC_DIR_FILER2" ]; then 
      mkdir $ETC_DIR_FILER2
      mount $FILER2:/vol/$VOLUME $ETC_DIR_FILER2 
      echo "\033[31mVeuillez mettre a jour /etc/usermap.cfg sur $FILER2 manuellement\033[0m"
      else
      Maj_Fic $ETC_DIR_FILER2/usermap.cfg
      umount $ETC_DIR_FILER2 && rmdir /mnt/$FILER2
      echo "\033[31mVeuillez renseigner manuellement le fichier /etc/auto.home.windows sur $STATIONS_SSD\033[0m"
  fi
else
   for autohome in $AUTO_HOME_OTHER 
   do
      echo "Mise a jour du fichier $autohome...";sleep 5
      \cp -p $NIS_DIR/$autohome $NIS_DIR/old/$autohome.$DATE
      print "$NOM_LOGIN\t$FILER1:/home_unix/&" >> $NIS_DIR/$autohome
   done 
fi
if [ -n "$SERVICE_DEI" ] ; then
   for netgrp in $NETGROUP_DEI ; do
   Maj_Netgroup
  done
fi
if [ -n "$SERVICE_ST3C" ] ; then
      echo "Mise a jour des fichiers d'options des licences flexlm simail, ensight, cfx et ansys"
      echo "\033[31mVeuillez mettre a jour le fichier bridgetown:/export/produits01/ensight/license/users.allow manuellement\033[0m"
      echo "\033[31mVeuillez mettre a jour le fichier bridgetown:/export/produits01/simail/licenses/simulogd.opt manuellement\033[0m"
      echo "\033[31mVeuillez mettre a jour le fichier macao:/export/produits01/ansys/licenses/license.opt manuellement\033[0m"
      echo "\033[31mVeuillez mettre a jour le fichier macao:/export/produits01/cfx/licenses/license.opt manuellement\033[0m"
fi
echo "Mise a jour du fichier shadow...";sleep 5
\cp -p $NIS_DIR/shadow $NIS_DIR/old/shadow.$DATE
echo "$NOM_LOGIN:::::::">> $NIS_DIR/shadow 
echo "Mise a jour des map NIS"
cd $NIS_DIR && ./nismake 
if [ $? -eq 0 ]; then
   yppasswd $NOM_LOGIN &
   wait
else 
   echo "\033[31mErreur de mise a jour des map nis\033[0m"
fi
Create_Home $NOM_LOGIN $SERVICE
echo "Le quota a allouer a utilisateur est-il different de 2Go?"
read QUOTA
typeset -l QUOTA
if [[ "$QUOTA" == [yo] || "$QUOTA" == "yes" || "$QUOTA" == "oui" ]]; then 
   Maj_Fic $ETC_DIR/quotas 
   rsh $FILER1 quota resize $VOLUME 
fi
echo "Ne pas oublier de tester le compte!"
