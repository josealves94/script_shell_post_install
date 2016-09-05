#!/bin/bash
#
#
#
# Auteur : Alves José
# Date 29/01/2014
#
# Description : verifie la distribution linux (Debian/Fedora19/ubuntu12.04/14.04/CENTOS)  et deroule l'installation sur le poste
# de travail
# Etape 1 : configuration de l'interface réseau
# Etape 2 : Proxy
# Etape 3 : desactive ipv6
# Etape 4 : installe et active ntp
# Etape 5 : installe et active cups(impression)
# Etape 6 : installe et active le nis
# Etape 7 : divers (depend de la distrib)
# version 0.1 29/01/2014
# version 0.2 30/01/2014
# Version 0.3 04/02/2014 - modiifcation section ubuntu après test sur poste
# Version 0.4 12/02/2014 - Ajout de la partie fedora
# version 0.5 26/02/2014 - Ajout desactivation ipv6 sur fedora
# version 0.6 7/03/2014 - verification de l'existence du repertoire /irsn/local01
# Version 0.8 14/03/2013 - Poroposition du choix pour l'utilisateur de verifier sa connexion réseau
# Version 0.9 2/04/2014 - MAJ nis centos
# Version 0.1 08/07/2014 - Correction partie ubuntu -sed incorrect
# Version 1.0 23/07/2014 - modification réécriture du code - Test debian ok, centos ok, ubuntu ok
# Version 1.01 20/08/2014 - ajout de ubuntu 14.04 pas encore testé sur poste
###############################################################################

DEBIAN="/etc/debian_version"
DEBIANBIS=$(cat /etc/issue |grep -i 'debian' |cut -d" " -f1)
CENTOS="/etc/redhat-release"
CENTOS2=$(cat /etc/issue | grep -i 'Centos' |cut -d' ' -f1)
FICNET1="/etc/sysconfig/network-scripts/ifcfg-eth0"
#UBUNTU=$(cat /etc/issue |grep -i "Ubuntu 12" |cut -d" " -f2 |sed '$s/..$//')
UBUNTU=$(cat /etc/lsb-release |grep -i "DISTRIB_RELEASE" |cut -d"=" -f2)
UBUNTU1404=$(cat /etc/lsb-release |grep -i "DISTRIB_RELEASE" |cut -d"=" -f2)
## Variable à initialiser pour fedora
FEDORA=$(cat /etc/issue | grep -i 'fedora' |cut -d" " -f1)
FEDORA2="/usr/bin/systemctl"
IRSN_DIR="/irsn/local01"

# verifie si l'utilisateur est root pour executer le script

if [ $EUID != 0 ];
then
 echo -e "************* Vous devez être root pour executer le  script *************\n"
 exit 1
fi

# verifie si la distribution est sous Debian
if [[ -f "$DEBIAN" && $DEBIANBIS == "Debian" && -d "$IRSN_DIR" ]]; 
then
#set -x
echo -e "************* votre distribution est une debian - Debut de l'installation *************\n"
echo -e "************* Veuillez verifiez que vous avez configuré votre interface réseau en dhcp *************\n"

read -p "Souhaitez-vous continuez l'installation ? (o/N) " reponse
if [ "$reponse" = 'o' ]; 
then
# echo -e " test 1 ok\n"
 echo -e "************* desactivation de l'ipv6 *************\n"
echo "net.ipv6.conf.all.disable_ipv6=1" >> /etc/sysctl.conf
echo "************* Ajout du proxy *************\n"
echo 'Acquire::http::Proxy "http://user_int:passwd@toto.com:3128";' > /etc/apt/apt.conf

echo "************* Installation d'openssh *************\n"
apt-get install -y openssh-server
 
echo "************* installation et activation de ntp *************\n"
apt-get install -y ntp

sed -i s/server/#server/g /etc/ntp.conf
echo "server ntp.neutron.intra.irsn.fr" >> /etc/ntp.conf 
/etc/init.d/ntp restart
 
echo "************* installation du service d'impression *************\n"
apt-get install -y cups
echo "ServerName anisu202" > /etc/cups/client.conf
 
echo "************* installation et activation du nis *************\n"
apt-get install -y nis autofs
echo "domain dpei server nis-dpei-master.neutron.intra.irsn.fr
domain dpei server nis-dpei-slave.neutron.intra.irsn.fr" > /etc/yp.conf

sed -i 's/compat/nis files/g' /etc/nsswitch.conf
service ypbind restart 
echo "************* relance du service nis *************"
echo "#!/bin/sh -e
       sleep 5 
       service nis restart
       exit 0" > /etc/rc.local
echo  "************* Ajout des points de montage *************"
echo "/home yp:auto.home.Linux --timeout=300
       /produits yp:auto.produits.Linux --timeout=300" > /etc/auto.master
echo "************* creation de produits *************\n"
mkdir /produits
/etc/init.d/autofs restart
echo "************* Desactivation de la liste d'user  sous gnome *************"
sed -i '/disable-user-list=true/ s/^#//' /etc/gdm3/greeter.gsettings
#sed -i s/\#\s\disable-user-list=true/disable-user-list=true/g /etc/gdm3/greeter.gsettings



echo "************* modification des droits  sur la partition /irsn/local0X *************"
chmod 1777 -R /irsn/local0*
echo "AddressFamily inet" >> /etc/ssh/sshd_config

echo "************* Mise à jour de la machine *************"
apt-get update -y
apt-get upgrade -y
# redemerrage de la machine pour prise en compte des parametres
echo "************* Veuillez redemarrer la machine pour valider les parametres 
 N'oubliez pas de testez le compte nis *************"
sleep 1

fi
# verifie si la distribution est sous Fedora (a partir de la 17) 
elif [[ -f "$CENTOS" && "$FEDORA" == "Fedora" && -f "$FEDORA2" && -d "$IRSN_DIR"  ]]; then

echo  "votre distribution est une Fedora  - Debut de l'installation"
echo "Veuillez verifiez que vous avez configuré votre interface réseau en dhcp"
read -p "Souhaitez-vous continuez l'installation ? (o/N) " reponse

if [ "$reponse" = 'o' ]; 
then
# echo -e "test 2 ok\n"
echo "************* Ajout du proxy *************"
echo "export HTTP_PROXY='http://user_int:passwd@toto.com:3128'" >> /etc/profile
echo "proxy=http://user_int:passwd@toto.com:3128" >> /etc/yum.conf
echo "proxy_username=PROTON\a-internet" >> /etc/yum.conf
echo "proxy_password=16am*int" >> /etc/yum.conf

echo "************* Desactivation IPV6  *************"
echo "************* Backup du fichier de configuration *************"
cp /etc/default/grub /etc/default/grub.`date +%d-%m-%Y-%H%M`
sed -i 's/GRUB_CMDLINE_LINUX="/GRUB_CMDLINE_LINUX="ipv6.disable=1 /g' /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg

echo "************* Desactivation de selinux *************"
selinuxenabled
echo $?
sed -i s/enforcing/disabled/g /etc/selinux/config

echo "************* Mise à jour de la machine *************"
yum update -y
echo "************* installation et activation du nis *************"
yum install -y ypbind
chmod 1777 /home

echo "domain dpei server nis-dpei-master.toto.com
domain dpei server nis-dpei-slave.neutron.intra.irsn.fr" >> /etc/yp.conf
sed -i 's#passwd:     files#passwd: nis files#g' /etc/nsswitch.conf
sed -i 's#shadow:     files#shadow: nis files#g' /etc/nsswitch.conf
sed -i 's#group:     files#group: nis files#g' /etc/nsswitch.conf
sed -i 's#netgroup:   files#netgroup: nis files#g' /etc/nsswitch.conf
sed -i 's#automount:  files#automount: nis files#g' /etc/nsswitch.conf
systemctl enable ypbind
systemctl start  ypbind
yum install -y autofs
echo "/home yp:auto.home.Linux --timeout=300 
/produits yp:auto.produits.Linux --timeout=300" > /etc/auto.master
systemctl enable autofs
echo "************* installation et activation de cups *************"
yum install -y cups
systemctl enable cups
echo "ServerName anisu202" > /etc/cups/client.conf
echo "************* Installation de ntp *************"
yum install -y ntp

echo "************* activation de nfs *************"
yum install -y nfs-utils
systemctl enable nfs-server.service
echo "************* Veuillez redemarrer la machine pour valider les parametres 
 N'oubliez pas de testez le compte nis et pensez à desactiver ipv6 *************"
sleep 1
#init 6
fi

# verifie si la distribution est sous centos
elif [[ -f "$CENTOS" && "$CENTOS2" == "CentOS" && -d "$IRSN_DIR" ]]; then
#set -x
echo "************* votre distribution est une centos - Debut de l'installation *************"
echo "************* Veuillez verifiez que vous avez configuré votre interface réseau en dhcp *************"
read -p "Souhaitez-vous continuez l'installation ? (o/N) " reponse
if [ "$reponse" = 'o' ]; 
then
# echo -e "test 3 ok\n"
echo "managed=true" >> /etc/NetworkManager/NetworkManager.conf
echo "************* Ajout du proxy *************"
echo "export HTTP_PROXY=http://user_int:passwd@toto.com:3128" >> /etc/profile
echo "proxy=http://user_int:passwd@toto.com:3128/" >> /etc/yum.conf 
 
echo "************* Desactivation de selinux *************"
selinuxenabled
echo $?
sed -i s/enforcing/disabled/g /etc/selinux/config

echo "************* installation et activation du nis *************"
yum install -y ypbind 
chmod 1777 /home

echo "domain dpei server nis-dpei-master.neutron.intra.irsn.fr
domain dpei server nis-dpei-slave.neutron.intra.irsn.fr" >> /etc/yp.conf
sed -i 's#passwd:     files#passwd:     nis files#g' /etc/nsswitch.conf
sed -i 's#shadow:     files#shadow:     nis files#g' /etc/nsswitch.conf
sed -i 's#group:      files#group:      nis files#g' /etc/nsswitch.conf
sed -i 's#netgroup:   files#netgroup:   nis files#g' /etc/nsswitch.conf
sed -i 's#automount:  files#automount:  nis files#g' /etc/nsswitch.conf
chkconfig ypbind on
service ypbind start
echo "************* instalation et activation de autofs *************"
yum install -y autofs
echo "/home yp:auto.home.Linux --timeout=300 
/produits yp:auto.produits.Linux --timeout=300" > /etc/auto.master
chkconfig autofs on

echo "************* installation et activation de cups *************"
yum install -y cups
chkconfig cups on
echo "ServerName anisu202" > /etc/cups/client.conf 

echo "************* activation de nfs *************"
chkconfig nfs on

echo "************* Veuillez redemarrer la machine pour valider les parametres 
 N'oubliez pas de testez le compte nis *************"
sleep 1
fi

# verifie si c'est une distribution ubuntu 12.04 modif du 20/08/2014
elif [[ -f "$DEBIAN" && -f "/etc/lsb-release" && "$UBUNTU" == "12.04" && $EUID -eq 0 && -d "$IRSN_DIR" ]]; then
#set -x
echo "*************  cette distribution est une ubuntu 12.04 - Debut de l'installation *************"
echo "************* Veuillez verifiez que vous avez configuré votre interface réseau en dhcp *************"
read -p "Souhaitez-vous continuez l'installation ? (o/N) " reponse
if [ "$reponse" = 'o' ]; 
then
 #echo -e "test 4 ok\n"
 echo  "************* Configuration du proxy *************"
 echo 'ACQUIRE { http::proxy "http://user_int:passwd@toto.com:3128" }' > /etc/apt/apt.conf.d/02proxy

 echo "export http_proxy=http://user_int:passwd@toto.com:3128" >> /etc/profile

 echo "************* Desactivation de l'ipv6 *************"

 echo "net.ipv6.conf.all.disable_ipv6=1" >> /etc/sysctl.conf 

 echo "************* Mise à jour de la machine *************"
 apt-get update -y
#apt-get upgrade -y


 echo "************* Installation d'openssh *************"
 apt-get install -y openssh-server

 echo "************* installation et activation de nfs  *************"
apt-get install -y nfs-common
apt-get install -y nfs-kernel-server
echo "************* installation et activation de ntp  *************"
apt-get install -y ntp 
sed -i s/server/#server/g /etc/ntp.conf
echo "server ntp.neutron.intra.irsn.fr" >> /etc/ntp.conf
/etc/init.d/ntp restart

echo "************* Installation de cups (impression  *************"
echo "ServerName anisu202" > /etc/cups/client.conf

echo "************* Installation du nis *************"
apt-get install -y nis autofs 
echo "domain dpei server nis-dpei-master.neutron.intra.irsn.fr
domain dpei server nis-dpei-slave.neutron.intra.irsn.fr" > /etc/yp.conf
sed -i 's/compat/nis files/g' /etc/nsswitch.conf
service ypbind stop
service ypbind start
echo "************* relance du service nis *************"
echo "#!/bin/sh -e
sleep 10
service ypbind restart
exit 0" > /etc/rc.local
echo  "Ajout des points de montage"
echo "/home yp:auto.home.Linux --timeout=300
/produits yp:auto.produits.Linux --timeout=300" > /etc/auto.master
echo "************* creation de produits *************"
mkdir /produits
service autofs restart
echo "************* Désactivation du guest-user et de la liste d'utilisateurs au login GUI *************"
#sed -i s/greeter-hide-users=false/greeter-hide-users=true/g /etc/lightdm/lightdm.conf
echo "greeter-hide-users=true" >> /etc/lightdm/lightdm.conf
echo "allow-guest=false" >> /etc/lightdm/lightdm.conf
chmod 1777 -R /irsn/local0*
echo "AddressFamily inet" >> /etc/ssh/sshd_config

echo "************* Suppression des paquets unity-scope *************"
apt-get remove --purge -y unity-scope-musicstores ubuntuone-* rhythmbox-ubuntuone python-ubuntuone-* empathy* nautilus-sendto-empathy telepathy-* libtelepathy-* libfolks-telepathy25 indicator-status-provider-mc5 transmission-* gwibber* libgwibber* deja-dup duplicity simple-scan remmina* aisleriot gnomine mahjongg gnome-sudoku ibus


# redemarrage de la machine pour prise en compte des parametres 
echo "************* Veuillez redemarrer la machine pour valider les parametres 
 N'oubliez pas de testez le compte nis *************"
sleep 1
fi
# Modification du 20/08/2014 ajout de ubuntu - pas encore testé sur poste - commenter si cela pose problème
elif [[ -f "$DEBIAN" && -f "/etc/lsb-release" && "$UBUNTU1404" == "14.04" && $EUID -eq 0 && -d "$IRSN_DIR" ]]; then

echo "*************  cette distribution est une ubuntu 14.04 - Debut de l'installation *************"
echo "************* Veuillez verifiez que vous avez configuré votre interface réseau en dhcp *************"
read -p "Souhaitez-vous continuez l'installation ? (o/N) " reponse
if [ "$reponse" = 'o' ];
then
 #echo -e "test 4 ok\n"
 echo  "************* Configuration du proxy *************"
 echo 'ACQUIRE { http::proxy "http://user_int:passwd@toto.com:3128" }' > /etc/apt/apt.conf.d/02proxy

 echo "export http_proxy=http://user_int:passwd@toto.com:3128" >> /etc/profile

 echo "************* Desactivation de l'ipv6 *************"

 echo "net.ipv6.conf.all.disable_ipv6=1" >> /etc/sysctl.conf

 echo "************* Mise à jour de la machine *************"
 apt-get update -y

echo "************* Installation d'openssh *************"
 apt-get install -y openssh-server

 echo "************* installation et activation de nfs  *************"
 apt-get install -y nfs-common
 apt-get install -y nfs-kernel-server

echo "************* installation et activation de ntp  *************"
apt-get install -y ntp
sed -i s/server/#server/g /etc/ntp.conf
echo "server ntp.neutron.intra.irsn.fr" >> /etc/ntp.conf
/etc/init.d/ntp restart

echo "************* Installation de cups (impression)  *************"
echo "ServerName anisu202" > /etc/cups/client.conf

echo "************* Installation du nis *************"
apt-get install -y nis autofs

echo "81.194.4.16         anisu201.neutron.intra.irsn.fr  anisu201" >> /etc/hosts
echo "81.194.4.2           anisu202.neutron.intra.irsn.fr  anisu202" >> /etc/hosts
echo "ypserver 81.194.4.16" >> /etc/yp.conf
echo "ypserver 81.194.4.2" >> /etc/yp.conf
sed -i 's/compat/nis files/g' /etc/nsswitch.conf
echo "************* relance du service nis *************"
service ypbind stop
service ypbind start

echo  "Ajout des points de montage"
echo "/home yp:auto.home.Linux --timeout=300
/produits yp:auto.produits.Linux --timeout=300" > /etc/auto.master



echo -e "************* creation de produits *************\n"
mkdir /produits
service autofs restart
echo -e "************* Désactivation du guest-user et de la liste d'utilisateurs au login GUI *************\n"

echo "allow-guest=false" >> /usr/share/lightdm/lightdm.conf.d/50-ubuntu.conf
echo "greeter-hide-users=true" >> /usr/share/lightdm/lightdm.conf.d/50-ubuntu.conf
echo "greeter-show-manual-login=true" >> /usr/share/lightdm/lightdm.conf.d/50-ubuntu.conf
chmod 1777 -R /irsn/local0*
echo "AddressFamily inet" >> /etc/ssh/sshd_config

echo "************* Suppression des paquets unity-scope *************"
apt-get remove --purge -y unity-scope-musicstores ubuntuone-*  empathy* nautilus-sendto-empathy telepathy-* libtelepathy-* libfolks-telepathy25 indicator-status-provider-mc5 transmission-* gwibber* libgwibber* deja-dup duplicity simple-scan remmina* aisleriot gnomine mahjongg gnome-sudoku ibus

# redemarrage de la machine pour prise en compte des parametres 
echo "************* Veuillez redemarrer la machine pour valider les parametres 
 N'oubliez pas de testez le compte nis *************"
sleep 1


fi

else 
#set -x
 echo -e "Vous n'avez pas une distribution Linux compatible pour éxécuter ce programme \n"


fi


