#!/usr/bin/perl -lw

use strict;
#Initialisation des variabels
my @cmd;

if($ARGV[0])
{

 SWITCH: {

        $ARGV[0] eq "langage_sys" && do {
                #Commande donnant le langage du systeme
                system("echo \$LANG | cut -d'.' -f'1'");
                last SWITCH;
        };

        $ARGV[0] eq "impr_dispo" && do {
                #Liste des imprimantes disponibles
                system("`which lpstat` -a | cut -d' ' -f'1'");
                last SWITCH;
        };

        $ARGV[0] eq "countligneimpr" && do {
                # Compte le nombre de ligne retourne par la commande lpstat -a
                system("`which lpstat` -a | wc -l |tr -d '[:blank:]'");
                last SWITCH;
        };

        $ARGV[0] eq "marque_materiel" && do {
                #Commande permettant d'obtenir la marque du materiel (HP,Compaq ...) | Dependance dmidecode
                system("`which dmidecode` | grep -A 2 -i 'System Information' | head -2 | grep -i Manufacturer |tr -s '[:blank:]' ';' | cut -d';' -f'3'");
                last SWITCH;
        };

        $ARGV[0] eq "nomdomaine_machine" && do {
                #Commande donnant le nom de domaine de la machine
                system("`which nslookup` \$HOSTNAME |grep -i name |tr -s '[:blank:]' ';' | cut -d';' -f'2'");
                last SWITCH;
        };
        
        $ARGV[0] eq "typememvirt" && do {
                #Commande donnant le type de memoire utilise (SDRAM,DDR etc...) | Dependance dmidecode

                # Initialisation des variables
                my $result;

                open TEST, "`which dmidecode` | grep -A 16 'Memory Device\$' | grep 'Type:' |cut -d':' -f'2' |";
                $result =<TEST>;
                close(TEST);

                if(!($result))
                {
                        system("`which dmidecode` | grep -A 6 'Memory Bank\$' | grep 'Type:' |cut -d':' -f'2'");
                        system("`which dmidecode` | grep -A 6 'Memory Module Information\$' | grep  'Type:' | cut -d':' -f'2'");
                }
                else
                {
                        system("`which dmidecode` | grep -A 16 'Memory Device\$' | grep 'Type:' |cut -d':' -f'2'");
                }
                last SWITCH;
        };
         $ARGV[0] eq "ListeMemVirt" && do {
                # Commande donnant une liste de nomreb correspondant a la  capacite de chaque memoire virtuelle | 
                # Dependance dmidecode

                #Initialisation des variables
                my $result;

                open TEST, "`which dmidecode` | grep -A 16 'Memory Device\$' | grep 'Size:' |";
                $result=<TEST>;
                close (TEST);

                if(!($result))
                {
                        system("`which dmidecode` | grep -A 6 'Memory Bank' | grep 'Installed Size' | cut -d':' -f2 | tr -d '^ '|tr -d 'Mbyte'");
                        system("`which dmidecode` | grep -A 6 'Memory Module Information\$' | grep 'Installed Size' | cut -d':' -f2 | grep 'MB' | cut -d ' ' -f2");
                }
                else
                {
                        system("`which dmidecode` | grep -A 16 'Memory Device\$' | grep 'Size:' | tr -d '\t\t' | tr -d ' MB' | cut -d: -f2");
                }
                last SWITCH;
        };

        $ARGV[0] eq "place_memdevice" && do {
                #Commande donnant l'emplacement des Memory Devices

                #Initialisation
                my $result;

                open TEST, "`which dmidecode` | grep -A 16 'Memory Device\$' |tr -s '[:blank:]' ';' | grep '^;Locator' |";
                $result=<TEST>;
                close (TEST);

 # Si la variable result possede quelque chose alors on lance la premiere methode sinon la seconde. 
                # Differentes versions de dmidecode ne sont pas construites de la meme facon.
                if (!($result))
                {
                        system("`which dmidecode` | grep -A 6 'Memory Bank' | grep 'Socket' |cut -d':' -f 2 | tr -d '^ '");
                        system("`which dmidecode` | grep -A 6 'Memory Module Information\$' |grep 'Socket Designation' |cut -d':' -f2 | tr -d '^ '");
                }
                else
                {
                        system("`which dmidecode` | grep -A 16 'Memory Device\$' | tr -s '[:blank:]' ';' | grep '^;Locator' | cut -d';' -f'3 4' | tr -s ';' ' '");
                }
                last SWITCH;

        };
        $ARGV[0] eq "periph_scsi" && do {
                #Commande permettant de lister les peripheriques SCSI
                system("cat /proc/scsi/scsi | grep -A3 '^Host:'| tr -s '[:blank:]' ' '");
                last SWITCH;

        };

        $ARGV[0] eq "partage_nfs" && do {
                #Commande donnant la liste des differents partages NFS
                system("`which cat` /etc/exports | tr -s '[:blank:]' ' ' | grep '^/'");
                last SWITCH;
        };

        $ARGV[0] eq "listapplicationexport" && do {
                #Commande qui permet de lister toutes les applications exportees par le filer

                # Initialisation des variables
                my $taille_tab1;
                my $taille_tab2;
                my $taille_tab3;
                my $taille_tab4;
                my @resultdirectory;
                my @result;
                my @result2;
                my @result3;
                my @result4;
                my $p;
                my $i;
                my $j;
                my $h;

                # On test si le repertoire /rep existe
                if(-d '/rep')
                {
                        # on recupere tout les sous repertoires de /rep/
                        open HL, "ls /rep/ \|grep local |";
                        @resultdirectory = <HL>;
                        chomp (@resultdirectory);
                        close(HL);
                        $taille_tab1=scalar(@resultdirectory);

                        for($i=0;$i<$taille_tab1;$i++)
                        {
                                # On recupere et on stock la liste des repertoire ou fichiers en dessous de /rep/localXX/
                                open HLL, "ls /irsn/$resultdirectory[$i]/ |";
                                @result =<HLL>;
                                chomp (@result);
                                close(HLL);
                                $taille_tab2=scalar(@result);

                                for($p=0;$p<$taille_tab2;$p++)
                                {
                                        if (-d "/irsn/$resultdirectory[$i]/$result[$p]" || -e "/rep/$resultdirectory[$i]/$result[$p]")
                                        {
                                                # Si des repertoires sont nommes "appli" ou "freeware" alors on affiche 
                                                # les applications qui y sont deposees
                                                if( $result[$p] eq "appli" || $result[$p] eq "freeware")
                                                {
                                                        open HLL, "ls /rep/$resultdirectory[$i]/$result[$p] |";
                                                        @result2 =<HLL>;
                                                        chomp (@result2);
                                                        close(HLL);
                                                        $taille_tab3=scalar(@result2);

                                                        for($j=0;$j<$taille_tab3;$j++)
                                                        {
                                                                if($result2[$j]=~ m/-[0-9]/i)
                                                                {
                                                                        print $result2[$j];
                                                                }
                                                        }
                                                }
                                                # Si le sous repertoire "produits" existe alors on verifie si il y a des 
                                                # applications sinon on verifie si les repertoire "appli" et "freeware" 
                                                # existent
                                                elsif ($result[$p] eq "produits")
                                                {
                                                        open HLL, "ls /irsn/$resultdirectory[$i]/$result[$p]/ |";
                                                        @result3 =<HLL>;
                                                        chomp (@result3);
                                                        close(HLL);

                                                        $taille_tab4=scalar(@result3);

                                                        for($h=0;$h<$taille_tab4;$h++)
                                                        {
                                                                if( $result3[$h] eq "appli" || $result3[$h] eq "freeware")
                                                                {

                                                                open HLL, "ls /rep/$resultdirectory[$i]/$result[$p]/$result3[$h] |";
                                                                @result4 =<HLL>;
                                                                chomp (@result4);
                                                                close(HLL);

                                                                $taille_tab4=scalar(@result4);

                                                                        for($j=0;$j<$taille_tab4;$j++)
                                                                        {
                                                                                if($result4[$j]=~ m/-[0-9]/i)
                                                                                {
                                                                                        print $result4[$j];
                                                                                }
                                                                        }
                                                                }
                                                        }
                                                }
                                                # Si les applications se trouvent dans le repertoire localXX alors on affiche
                                                # les appliacations
                                                elsif($result[$p]=~ m/-[0-9]/)
                                                {
                                                        print $result[$p];
                                                }
                                        }
                                }
                        }
                }
                last SWITCH;
        };
 $ARGV[0] eq "listapplicationclusterexport" && do {
                #Commande qui permet de lister toutes les applications exportees par le filer

                # Initialisation des variables
                my $j;
                my $i;
                my @result1;
                my @result2;
                my $taille_tab1;
                my $taille_tab2;

                if(-d '/cluster/')
                {
                        # on recupere tout les sous repertoires de /cluster/
                        open HL, "ls /cluster/ |";
                        @result1 = <HL>;
                        chomp (@result1);
                        close(HL);
                        $taille_tab1=scalar(@result1);

                        for($j=0;$j<$taille_tab1;$j++)
                        {
                                if($result1[$j] eq "appli" || $result1[$j] eq "freeware")
                                {

                                        # on recupere tout les sous repertoires de /cluster/
                                        open HL, "ls /cluster/$result1[$j] |";
                                        @result2 = <HL>;
                                        chomp (@result2);
                                        close(HL);
                                        $taille_tab2=scalar(@result2);

                                        for($i=0;$i<$taille_tab2;$i++)
                                        {
                                                if($result2[$i]=~ m/-[0-9]/)
                                                {
                                                        print $result2[$i];
                                                }
                                        }
                                }
                                elsif($result1[$j]=~ m/-[0-9]/)
                                {
                                        print $result1[$j];
                                }
                        }
                }
                                last SWITCH;

        };

        $ARGV[0] eq "testsamba" && do {
                #Commande permettant de verifier si le service samba tourne retour 0=oui retour 1=non
                system("`which ps` -aux |tr -s '[:blank:]' ';' | cut -d';' -f'11' |grep 'smbd' > /dev/null");
                system("echo \$?");
                last SWITCH;

        };

        $ARGV[0] eq "SysExploi" && do {
                # Permet de donner le nom du systeme d'exploitation installe sur la mahchine
                # Si l'information est indisponible on affiche un 0
                if(-e '/etc/redhat-release')
                {
                        system("cat /etc/redhat-release");
                }
                elsif(-e '/etc/debian-version')
                {
                        system("cat /etc/debian-version");
                }
                else
                {
                        print "0";
                }
                last SWITCH;

        };

        $ARGV[0] eq "CountUser" && do {
                #Liste les differents utilisateurs possedant des taches dans le crontab

                #Initialisationd es variabels
                my @tab;
             my $variable=0;
                my $i;
                my $var=0;
                my $tmp;

                # On affiche le nombre de fichiers
                system("ls /var/spool/cron | wc -l");

                #Liste les differents utilisateurs possedant des taches dans le crontab
                open DATA, "ls /var/spool/cron |";
                while (<DATA>) {
                        $tab[$variable]=$_;
                        chomp ($tab[$variable]);
                        $variable=$variable + 1;
                }
                close(DATA);

                #Pour chaque fichiers de cron , on compte le nombre de ligne
                for($i=0; $i<$variable;$i++)
                {
                        open DAT, "wc -l /var/spool/cron/$tab[$i] |tr -d '[:blank:]' | cut -d'/' -f'1' |";
                        $tmp=<DAT>;
                        chomp($tmp);
                        $var=$var+$tmp;
                }
                close(DAT);
                # On affiche le nombre de lignes total dans tout les fichiers
                print $var;
                last SWITCH;

        };

        $ARGV[0] eq "UserCron" && do {
                #Initialisation des variables
                my @tab;
                my $variable=0;
                my $i;
                my $tmp;

                #Liste les utilisateurs ainsi que le nombre d'action leurs etant attribuees

                #Liste les differents utilisateurs possedant des taches dans le crontab
                open DATA, "ls /var/spool/cron |";
                while (<DATA>) {
                        $tab[$variable]=$_;
                        chomp ($tab[$variable]);
                        $variable=$variable + 1;
                }
                close(DATA);
              #Pour chaque fichiers de cron , on affiche le nom de l'utilisateur ainsi que le nombre de ligne
                for($i=0; $i<$variable;$i++)
                {
                        print $tab[$i];

                        open DAT, "wc -l /var/spool/cron/$tab[$i] |tr -d '[:blank:]' | cut -d'/' -f'1' |";
                        $tmp=<DAT>;
                        chomp($tmp);
                        print $tmp;
                }
                close(DAT);

                last SWITCH;

        };
$ARGV[0] eq "TachePlanni" && do {
                #Commande retournant les differentes taches plannifiees

                #Initialisation des variables
                my @tab;
                my $variable=0;
                my $i;

                #Liste les differents utilisateurs possedant des taches dans le crontab
                open DATA, "ls /var/spool/cron |";
                while (<DATA>) {
                        $tab[$variable]=$_;
                        chomp ($tab[$variable]);
                        $variable=$variable + 1;
                }
                close(DATA);

                for($i=0;$i<$variable;$i++)
                {
                        system ("cat /var/spool/cron/$tab[$i]");
                }

                last SWITCH;
        };

        $ARGV[0] eq "NumberSerial" && do {
                #Commande donnant le nuumero de serie de la machine
                system("`which dmidecode` | grep -A 6 'System Information' | tr -d '[:blank:]' | grep 'SerialNumber' | cut -d':' -f'2'");

                last SWITCH;
        };

        $ARGV[0] eq "KernelVersion" && do {
                #Commande donnant la version du Kernel
                system("`which uname` -r");
                last SWITCH;
        };

        $ARGV[0] eq "ModeleMachine" && do {
                #Commande donnant le modele de la machine
                system("`which dmidecode` | grep -A 4 'System Information' | grep 'Product Name' |tr -d '\t\t' | cut -d: -f2");
                last SWITCH;
        };

        $ARGV[0] eq "CpuCountInfo" && do {
                #Calcul du nombre de cpu

                my $result;

                # On lance les commandes pour savoir si avec cette methode on recolte les bonnes informations
                open DATA, "`which dmidecode` | grep 'Processor Information' |wc -l | tr -d '[:blank:]' |";
                $result=<DATA>;
                chomp ($result);
                close(DATA);
  # Si la commande renvoit 0, on lance une autre commande sinon on affiche son contenu
                if($result == 0)
                {
                        system("`which dmidecode` | tr -d '[:blank:]' | grep \^Processor\$ |wc -l | tr -d '[:blank:]'");
                }
                else
                {
                        system("`which dmidecode` | grep 'Processor Information' |wc -l | tr -d '[:blank:]'");
                }
                last SWITCH;
        };

        $ARGV[0] eq "CpuinfoName" && do {
                #Donne les differentes informations relatives aux differents cpu present

                my $result;
                my $var;
                my $var1;
                my @tabname;
                my @tab;

                # On lance les commandes pour savoir si avec cette premiere methode on recolte les bonnes informations.
                # Dmidecode a differentes synthaxe en fonction des versions.
                open DATA, "`which dmidecode` | grep 'Processor Information' |wc -l | tr -d '[:blank:]' |";
                $result=<DATA>;
                chomp ($result);
                close(DATA);

                if( $result == 0)
 {
                        # On compte le nombre de cpu
                        open NUM, "`which dmidecode` | tr -d '[:blank:]' | grep \^Processor\$ |wc -l | tr -d '[:blank:]' |";
                        $result=<NUM>;
                        chomp($result);
                        close(NUM);

                        #On recupere le nom du processeur
                        open HEN, "cat /proc/cpuinfo | grep  \^vendor_id| cut -d ':' -f2 |";
                        @tabname=<HEN>;
                        chomp(@tabname);
                        close(HEN);

                        #On recupere les informations complementaires aux CPU
                        open HEN1, "cat /proc/cpuinfo | grep 'model name' | cut -d ':' -f2 |";
                        @tab=<HEN1>;
                        chomp(@tab);
                        close(HEN1);

                        for($var=0;$var<3;$var++)
                        {
                                for($var1=0;$var1<$result;$var1++)
                                {
                                        print $tabname[$var1];
                                }
                                for($var1=0;$var1<$result;$var1++)
                                {
                                        print $tab[$var1];
                                }
                                for($var1=0;$var1<$result;$var1++)
                                {
                                        print "";
                                }
                        }

                }
                else
                {
                        system("`which dmidecode` | grep -A 10 'Processor Information' | grep 'Manufacturer' |tr -d '\t\t' | cut -d: -f2");
                        system("`which dmidecode` | grep -A 10 'Processor Information' | grep 'Family:' |tr -d '\t\t' | cut -d: -f2");
                        system("`which dmidecode` | grep -A 50 'Processor Information' | grep 'Current Speed:' |tr -d '\t\t' | cut -d ':' -f'2'");
                }
                last SWITCH;
        };
        $ARGV[0] eq  "CarteGraphique" && do {
                #Donne le nom de la carte graphique
                system("`which lspci` -v | grep 'VGA' | cut -d: -f3 |cut -d'(' -f1");
                last SWITCH;
        };

        $ARGV[0] eq "BiosInfo" && do {
                #Donne toutes les informations utiles sur le Bios | prerequis dmidecode

                system("`which dmidecode` | grep -A 2 'BIOS Information' | grep 'Vendor' | tr -d '\t\t' | cut -d: -f2");
                system("`which dmidecode` | grep -A 2 'BIOS Information'| grep 'Version' | tr -d '\t\t' | cut -d: -f2");
                system("`which dmidecode` | grep -A 5 'BIOS Information' | grep 'Release Date:' | tr -d '\t\t' | cut -d: -f2");
                last SWITCH;
        };

        $ARGV[0] eq  "datesys" && do {
                #Donne la date au format aaaa-mm-jj
                system("`which date` +\%Y-\%m-\%d");
                last SWITCH;
        };

        $ARGV[0] eq "architecture" && do {
                #Donne l'architecture machine
                system("`which uname` -m");
                last SWITCH;
        };

        $ARGV[0] eq "ServerImpression" && do {
                #Donne le nom du serveur d'impression
                if(-e '/etc/cups/cupsd.conf')
                {
                        system("`which cat` /etc/cups/cupsd.conf | grep ^'ServerName' | cut -d ' ' -f 2");
                }
                else
                {
                        print " ";
                }
                last SWITCH;
        };

        $ARGV[0] eq "Periph_info" && do {
 #Donne des indications sur les peripheriques

                # Test si un lecteur disquette existe
                if(-e '/dev/fd0')
                {
                        print "1";
                }
                else
                {
                        print "0";
                }
                # Test si un lecteur CDROM existe       
                if(-e '/dev/cdrom')
                {
                        print "1";
                }
                else
                {
                        print "0";
                }
                last SWITCH;
        };

        $ARGV[0] eq "RaidChartName" && do {
                #Donne le nom ou le nom des cartes RAID
                system("lspci -v | grep 'RAID bus controller' | cut -d':' -f3");
                last SWITCH;
        };

        $ARGV[0] eq "Nom_Interface" && do {
                #Liste le nom des interfaces ethernet
                system("`which ifconfig` | grep 'eth' | tr -s '[:blank:]' ';'| cut -d';' -f1");
                last SWITCH;
                 };

        $ARGV[0] eq "Bus_Nom_Interface" && do {
                #Liste le bus de chaque carte eternet en fonction du nom de l'interface

                #Initialisation des variables
                my @tab;
                my $compt;
                my $i;

                #Liste les differents interfaces ethernet
                open DATA, "ifconfig | grep 'eth' | tr -s '[:blank:]' ';'| cut -d';' -f1 |";
                @tab=<DATA>;
                chomp (@tab);
                $compt=($#tab + 1);
                close(DATA);

                for($i=0;$i<$compt;$i++)
                {
                        system("ethtool -i $tab[$i] | grep 'bus-info' |cut -d ' ' -f2");
                }
                last SWITCH;
        };

        $ARGV[0] eq "Nom_carte_reseau" && do {
                #Nom des differentes cartes reseaux
                system("`which lspci` | grep 'Ethernet' | cut -d':' -f3");
                last SWITCH;
        };

        $ARGV[0] eq "Bus_carte_reseau" && do {
                #Donne le bus de la ou les cartes reseaux
                system("`which lspci` | grep 'Ethernet' | cut -d' ' -f1");
                last SWITCH;
        };

        $ARGV[0] eq "MacAddress_Interface" && do {
                #Liste les adresses MAC de toutes les interfaces eth
                system("`which ifconfig` | grep 'eth'");
                last SWITCH;
        };

        $ARGV[0] eq "Address_Interface" && do {
                #Liste les adresses IP et le masque de sous reseau de toutes les interfaces eth
                system("`which ifconfig` | grep -A 2 'eth' | grep 'inet '");
                last SWITCH;
        };

        $ARGV[0] eq "PasserelleDefaut" && do {
                #Donne l'adresse de la route par defaut
                system("`which route` | grep 'default' | tr -s '[:blank:]' ':' | cut -d':' -f2");
                system("`which route` | grep 'default' | tr -s '[:blank:]' ':' | cut -d':' -f8");
                last SWITCH;
        };
         $ARGV[0] eq "ConfigDNS" && do {
                #Donne les differentes configurations DNS
                system("`which cat` /etc/resolv.conf");
                last SWITCH;
        };

        $ARGV[0] eq "Vitesse_carte_reseau" && do {
                #Liste les differentes vitesses des cartes reseaux en fonction des interfaces

                #Initialisation des variables
                my @tab;
                my $compt; #compteur 
                my $i;

                #Liste les differentes vitesses des cartes reseaux
                open DATA, "ifconfig | grep 'eth' | tr -s '[:blank:]' ';'| cut -d';' -f1 |";
                @tab=<DATA>;
                chomp (@tab);
                $compt=($#tab + 1);
                close(DATA);

                for($i=0;$i<$compt;$i++)
                {
                        system("ethtool $tab[$i] | grep 'Speed:' |cut -d ':' -f2");
                }

                last SWITCH;
        };

        $ARGV[0] eq "Duplex_carte_reseau" && do {
                #Liste les differentes configuration duplex en fonction des interfaces

                #Initialisation des variables
                my @tab;
                my $compt; #compteur 
                my $i;

                #Liste les differents duplex
                open DATA, "ifconfig | grep 'eth' | tr -s '[:blank:]' ';'| cut -d';' -f1 |";
                @tab=<DATA>;
                chomp (@tab);
                $compt=($#tab + 1);
                close(DATA);

                for($i=0;$i<$compt;$i++)
                {
                        system("ethtool $tab[$i] | grep 'Duplex:' |cut -d ':' -f2");
                }
                last SWITCH;
        };

        $ARGV[0] eq "ComptMontage" && do {
                #On compte le nombre de montages
                    system("df -h |grep '%' | wc -l");
                last SWITCH;
        };

        $ARGV[0] eq "Montage" && do {
                #Donne la liste des differeents montages
                system("df -hT | tr -s '[:blank:]' ' '");
                last SWITCH;
        };

        $ARGV[0] eq "SambaInfoConfig" && do {
                # Commande lancant un script permettant d'afficher toutes les configurations des differents partages samba

                ###################################################
                # Script permettant de relever tout les partages
                # samba de la machine
                ###################################################

                 #Initialisation des varaibles
                 my @partage;
                 my @comment;
                 my @path;
                 my @other;
                 my $compteur=0;
                 my $p;
                 my $longueur_other;

                 # On ouvre le fichier de conf de samba en lecture
                 if(open (FU, "/etc/samba/smb.conf"))
                 {
                         # On stock tout le fichier dans un tableau t
                         my @t = <FU>;


                        # Pour chaque ligne, on parse en fonction des
                        # informations que l'on souhaite garder
                        foreach my $line(@t)
                        {
                                # On supprimer les retour chariot
                                chomp($line);
                                # Si une ligne presente des tabulations, on les supprime
                                $line=~ s/^\t//g ;
                                #Si une ligne commence par des espaces on les supprime
                                if(!($line=~ m/^$/) && $line=~ m/^ /)
                                {
                                        while($line=~ m/^ /)
                                        {
                                                $line=~ s/^ //;
                                        }
                                }
                                # Si la ligne commence par un [ et n'est pas [global] alors on commence
                                # a parser
                                if($line=~ m/^\[/ && !($line=~ m/^\[global\]/))
                                        # Incrementation du compteur
                                        $compteur=$compteur + 1;
                                        # On stock la premiere information pour chaque partage
                                        # il sagit du nom du partage
                                        $partage[$compteur]=$line;
                                }
                                # Si on a une ligne "vide" alors on reprend depuis le debut
                                # en repositionnant les varaibles avec de bonnes valeurs
                                elsif($line=~ m/^path =/)
                                {
                                        $path[$compteur]=$line;
                                }
                                # Si il sagit d'une ligne presentant une chaines de caracteres alors
                                # On traite cette donnee
                                elsif($line=~ m/^comment =/)
                                {
                                        $comment[$compteur]=$line;
                                }
                                #Si la ligne commence par une lettre
                                elsif($line=~ m/^[a-z]/)
                                {
                                        if(!($other[$compteur]))
                                        {
                                                $other[$compteur]=$line;
                                        }
                                        else
                                        {
                                                $other[$compteur]=$other[$compteur].";".$line;
                                        }
                                }
                        }
                        #Pour chaque elements, on affiche la ligne type en OUPUT
                        for ($p=1;$p<=$compteur;$p++)
                        {

                                $longueur_other= length($other[$p]);
                                # Si les parties n'existent pas alors on initialise les variebles
                                if(!($comment[$p]))
                                {
                                        $comment[$p]="";
                                }
                                elsif(!($path[$p]))
                                {
                                        $path[$p]="";
                                }
                                # Si la chiane de caractere n'existe pas ou depasse 210 caractere, on lui attribue ensemble vide
                                # A partir d'une longueur donnee l'oid snmp transforme le contenu en hexadecimal
                                elsif(!($other[$p]) || $longueur_other> 210)
                                 {
                                        $other[$p]="";
                                }
                                print "partages/samba|$partage[$p]|$comment[$p]|$path[$p]|$other[$p]|";
                        }                                                                                                                                                                                                                                                                       }
                last SWITCH;
        };
        $ARGV[0] eq "SambaTestActivite" && do {

                #Initialisation des varaibles
                my $chaine;
                my $result;

                # Test si au runlevel actuel, le service samba tourne

                # On lance les commandes
                open DATA, "runlevel | cut -d' ' -f2 |";

                # On recupere le resultat de la commande
                $chaine=<DATA>;

                # On supprime les retours chariot
                chomp($chaine);

                # On ferme les handlefile       
                close(DATA);

                system("`which chkconfig` --level $chaine smb");

                # On lance les commandes
                open DATI, "echo $? |";

                # On recupere le resultat de la commande
                $result=<DATI>;

                # On supprime les retours chariot
                chomp ($result);

                # On ferme les handlefile       
                close (DATI);

                # En fonction du resultat, on affiche on pour "lance" sinon off pour "eteint"           
                if($result == "0")
                {
                        print "on";
                }
                else
                {
                        print "off";
                }

                last SWITCH;
        };
        $ARGV[0] eq "SambaListingPartage" && do {

                # Fonction permettant de lister uniquement les partages. En effet si le fichier smb.conf est assez important, 
                #on affiche uniquement les partages. Mode econome

                # On ouvre le fichier de conf de samba en lecture
                 if(open (FU, "/etc/samba/smb.conf"))
                 {
                         # On stock tout le fichier dans un tableau t
                         my @t = <FU>;


                        # Pour chaque ligne, on parse en fonction des
                        # informations que l'on souhaite garder
                        foreach my $line(@t)
                        {
                                # Si la ligne commence est du type [....] alors on affiche la ligne car il sagit d'un partage
                                if($line=~ m/^\[/ && $line=~ m/\]$/ && !($line=~ m/\[global\]/))
                                {
                                        # On supprime le retour charriot
                                        chomp($line);
                                        # On affiche la valeur de la lugne que l'on introduit dans la mib
                                        print $line;
                                }
                        }
                }
                last SWITCH;
        };
        $ARGV[0] eq "RunLevel" && do {
                # Commande renseignant sur le runlevel actuel
                system("`which runlevel` | `which cut` -d' ' -f2");
                last SWITCH;
        };
        
         $ARGV[0] eq "CompteSamba" && do {
                # Commande permettant d'obtenir tous les comptes samba locaux ou pas

                if (-e '/usr/bin/pdbedit')
                {
                        system("`which pdbedit` -L | cut -d ':' -f1");
                }
                elsif(-e '/etc/samba/smbpasswd')
                {
                        system("`which cat` /etc/samba/smbpasswd | cut -d ':' -f1");
                }
                last SWITCH;
        };
         $ARGV[0] eq "DomainNIS" && do {
                # Commande donnant le nom du domaine NIS dont est ratache la machine
                system("`which domainname`");
                last SWITCH;
        };

        $ARGV[0] eq "NISServeurMaitre" && do {
                # Commande permmettant d'avoir le nom du serveur maitre NIS
                system("ypwhich -d `domainname`");
                last SWITCH;
        };
         $ARGV[0] eq "AutoMontage" && do {
                # Commande permettant d'obtenir les differentes lignes de montages locaux ou NIS

                ###################################################
                # Script permettant de relever tout les montages
                # ( locaux ou NIS) sur la machine
                ###################################################

                # On ouvre le fichier de conf en lecture
                if(open (FU, "/etc/auto.master"))
                {
                        # On stock tout le fichier dans un tableau t
                        my @t = <FU>;

                        # Pour chaque ligne, on parse en fonction des
                        # informations que l'on souhaite garder
                        foreach my $line(@t)
                        {
                                if(!($line=~ m/^#/) && !($line=~ m/^ /) && !($line=~ m/^$/))
                                {
                                 chomp ($line);
                                 $line=~ s/ / /g;
                                 print $line;
                                }
                        }
                        close (FU);
                }

                last SWITCH;
        };
         $ARGV[0] eq "ListingAccountSys_Name" && do {

                # Recuperation de tout les noms de comptes application
                # Initialisation des variables
                my @tab;
                my $i;
                my $p;

                if(open (FU, "/etc/passwd"))
                {
                        # On stock tout le fichier dans un tableau t
                        my @t = <FU>;

                        foreach my $line(@t)
                        {
                                #On decoupe chaque ligne en prenant comme separateur le caractere :
                                #recuperation du nom de l'application
                                @tab = split(/:/, $line);

                                if($tab[2] == "0" && $tab[0] ne "root" || $tab[2] < 65500 && $tab[2] > 100 && !($tab[0]=~ m/^#/))
                                {
                                # On affiche le nom du compte chiffre
                                        chomp($tab[0]);
                                        # On inverse les chaines de caracteres pour plus de securite
                                        $tab[0]= reverse($tab[0]);
                                        #On affiche le nom du compte crypter
                                        chomp $tab[0];
                                        print $tab[0];
                                }
                        }
                }
                close (FU);

                last SWITCH;
        };
         $ARGV[0] eq "ListingAccountSys_Com" && do {

                # Recuperation de tout les commentaires de comptes application
                # Initialisation des variables
                my @tab;
                my $i;
                my $p;

                if(open (FU, "/etc/passwd"))
                {
                        # On stock tout le fichier dans un tableau t
                        my @t = <FU>;

                        foreach my $line(@t)
                        {
                                #On decoupe chaque ligne en prenant comme separateur le caractere :
                                #recuperation du nom de l'application
                                @tab = split(/:/, $line);

                                if($tab[2] == "0" && $tab[0] ne "root" || $tab[2] < 65500 && $tab[2] > 100 )
                                {
                                        if ($tab[4] eq "")
                                        {
                                                print "nucuA"; # Aucun
                                        }
                                        else
                                        {
                                        # On affiche le nom du compte chiffre 
                                                chomp ($tab[4]);
                                                # On inverse chaque chaine de caracteres pour plus de securite
                                                $tab[4]= reverse($tab[4]);
                                                chomp ($tab[4]);
                                                #On affiche les nouvelles chaines formees 
                                                print $tab[4];
                                        }
                                }
                        }
                }
                close (FU);

                last SWITCH;
        };
        $ARGV[0] eq "ListingAccountSys_Direc" && do {

                # Recuperation de tous les home directory des comptes application
                # Initialisation des variables
                my @tab;
                my $i;
                my $p;

                if(open (FU, "/etc/passwd"))
                {
                        # On stock tout le fichier dans un tableau t
                        my @t = <FU>;

                        foreach my $line(@t)
                        {
                                #On decoupe chaque ligne en prenant comme separateur le caractere :
                                #recuperation du nom de l'application
                                @tab = split(/:/, $line);

                                if($tab[2] == "0" && $tab[0] ne "root" || $tab[2] < 65500 && $tab[2] > 100 )
                                {
                                # On affiche le nom du compte chiffre 
                                        chomp ($tab[5]);
                                        # On inverse les chaines de caracteres pour plus de securite
                                        $tab[5]= reverse($tab[5]);
                                        chomp($tab[5]);
                                        #On affiche les nouvelles chaines formees
                                        print $tab[5];
                                }
                        }
                }
                close (FU);

                last SWITCH;
        };
         $ARGV[0] eq "RpmListingMake" && do {

                #Fonction permettant de creer ou de mettre a jour un fichier ListingRPM contenant toute la liste des rpm installes
                # on utilise un filehandle pour obtenir l' hostname de la machine qui lance le Main script

                my $path;
                open RE, "hostname |";
                my $hostname=<RE>;
                chomp($hostname);
                close(RE);
                if($hostname=~ m/.ipsn.fr/ || $hostname=~ m/.toto.fr/ || $hostname=~ m/.nono.intra.toto.fr/)
                {
                        if($hostname=~ m/.ipsn.fr/)
                        {
                                $hostname=~ s/.toto.fr//;
                        }
                        elsif($hostname=~ m/.nono.intra.toto.fr/)
                        {
                                $hostname=~ s/.neutron.intra.irsn.fr//;
                        }
                        elsif($hostname=~ m/.proton.intra.irsn.fr/)
                        {
                                $hostname=~ s/.proton.intra.irsn.fr//;
                        }
                        elsif($hostname=~ m/.irsn.fr/)
                        {
                                $hostname=~ s/.irsn.fr//;
                        }
                }
                $path="/tmp/ListingRPM"."_"."$hostname";

                if(-e $path)
                {
                        system(" rpm -qa > $path");
                }
                else
                {
                        system(" touch $path");
                        system(" rpm -qa > $path");
                }

                last SWITCH;
        };
         $ARGV[0] eq "DateInstall" && do {

                # Fonction permettant d'obtenir la date d'intallation de l'OS sur la machine
                if (-e '/root/install.log')
                {
                        system("`which stat` /root/install.log | grep 'Modify:' | cut -d' ' -f2");
                }
                else
                {
                        print " ";
                }
                last SWITCH;
        };
  }
}
