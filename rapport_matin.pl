#!/usr/bin/perl -w 


use Data::Dumper;
use XML::Writer;
use IO::File;
#use XML::Xslt;
use MIME::Lite;

use Time::Local;
#my $time = timelocal($sec,$min,$hours,$day,$month,$year); 

#Affichage du texte en couleur dans le shell 
use Term::ANSIColor;


use Scalar::Util qw(looks_like_number);
#####################################################################
#
#       Variables de l'environnement netbackup
#
#####################################################################

my %h_masters_robots = (
                        "masterserver" => [ "robot" ],
                        "masterserver2" => [ "robot" ]
                        );
                        
                        
my %h_masters_medias = (
                        "masterserver" => [ "mediaserver" ],
                        "masterserver2" => [ "mediaserver2" ]
                        );
);
#liste des jobs 
my @jobs;
#explications des codes d'erreur
my @explanations;

#adresse mail source 
my $src_mail = "root\@asauu114v.neutron.intra.irsn.fr";
#adresse mail du rapport 
#my $dst_mail = "mail\@toto.fr,mail2\@toto.fr";
my $dst_mail = "infogeranceunix\@irsn.fr";
#my $dst_mail = "informatique.serveur.mco\@interne.fr";

#Timestamp d'execution du script

my $epoch_now = time();

#Fichier HTML utilise pour le rapport 
my $htmlfile = "/tmp/rapport_matin-$epoch_now.html";


my $colorBlack='\033[01;30m';
my $colorDarkGray='\033[01;30m';
my $colorRed='\033[00;31m';
my $colorBoldRed='\033[01;31m';
my $colorGreen='\033[00;32m';
my $colorBoldGreen='\033[01;32m';
my $colorYellow='\033[00;33m';
my $colorBoldYellow='\[\033[01;33m';
my $colorBlue='\033[00;34m';
my $colorBoldBlue='\033[01;34m';
my $colorPurple='\033[00;35m';
my $colorBoldPurple='\033[01;35m';
my $colorCyan='\033[00;36m';
my $colorBoldCyan='\033[01;36m';
my $colorLightGray='\033[00;37m';
my $colorWhite='\033[01;37m';
my $colorNormal='\033[00m';

###############################################################
#
#
#       get_end_time <date au format epoch>     
#       Renvoit la date de fin des sauvegardes 
#
#
###############################################################

sub get_end_time 
{

        my $epoch_time = shift();

        my ( $sec, $min, $hour, $mday, $month, $year, $dow ) = (localtime($epoch_time))[0,1,2,3,4,5,6];

        my $epoch_end_time = timelocal( 0, 30, 7, $mday, $month, $year, $dow );

        return $epoch_end_time;

}
###############################################################
###############################################################



###############################################################
#
#
#       get_start_time <date au format epoch>   
#       Renvoit la date de debut des sauvegardes (la veille 18h00
#               ou le vendredi 18h00 si nous sommes lundi) 
#
#
###############################################################

sub get_start_time 
{

        my $epoch_time = shift();

        my ( $sec, $min, $hour, $mday, $month, $year, $dow ) = (localtime($epoch_time))[0,1,2,3,4,5,6];

        #on ajuste l'heure pour correspondre à 18h00 
        my $epoch_end_time = timelocal( 0, 0, 16, $mday, $month, $year, $dow );
        my $epoch_start_time;
        my $back_time_sec;

        # du mardi au vendredi
        if ( ( $dow ge 2 ) && ( $dow le 5 ) )
         {
                $back_time_sec = 1 * 24 * 3600 ;
        }
        else
        {
                $back_time_sec = 3 * 24 * 3600 ;

        }
                $epoch_start_time = $epoch_end_time - $back_time_sec;

        return $epoch_start_time;

}
###############################################################
###############################################################



###################################################
#
#       Ajustement du format des champs 
#
####################################################

sub prettyfy 
{

        my ( $txt, $mode ) = @_;

        #Renommage des policies pour plus de comprehension 

        my ( $o, $c );

        if ( $mode eq "text" )
        {
                $o="[";
                $c="]";
        }
        else
         {
                $o="";
                $c="";
        }
 $txt = $o . "Filer" . $c if  ( $txt =~ /filer/i ) ;
        $txt = $o . "VMware" . $c if  ( $txt =~ /VMware/i ) ;
        $txt = $o . "SQL" . $c if  ( $txt =~ /SQL/i ) ;
        $txt = $o . "BIG" . $c if  ( $txt =~ /BIG/i ) ;
        $txt = $o . "Applicative" . $c if  ( $txt =~ /appli/i ) ;
        $txt = $o . "Systeme" . $c if  ( $txt =~ /syst/i ) ;
        $txt = $o . "Exchange Public Folders" . $c if  ( $txt =~ /exchange.*public.*folder/i ) ;
        $txt = $o . "Exchange" . $c if  ( $txt =~ /exchange$/i ) ;
        $txt = $o . "NFS" . $c if  ( $txt =~ /nfs/i ) ;
        $txt = $o . "CIFS" . $c if  ( $txt =~ /cifs/i ) ;
if ( $mode eq "text" )
        {

                #homogeneisation de la longueur des champs à 10 

                my $len = length( $txt );
                my $max = 10;

                while ( $len < $max )
                {
                        $txt .= " ";
                        $len++;
                }

        }
        return $txt;

}
#                                  DRIVE STATUS
#
#Drv DrivePath                                             Status  Label  Ready 
#  0 {4,0,1,0}                                              DOWN     -     No   
#  1 {4,0,0,0}                                               UP     Yes    Yes 
sub getDriveStatus 
{

        my $rh_masters_medias = shift();
        my $ra_drives = [];

        my $cmd = "/usr/openv/volmgr/bin/vmoprcmd -dp ds ";

        #liste de media server assignes à un master server
        foreach my $ra_medias ( values( %$rh_masters_medias ) )
        {

                #un media server extrait de la liste des media server
                foreach my $media (@$ra_medias)
                {
       my $found = 0;

                        foreach my $ra_drive (@$ra_drives)
                        {
                                if ( $ra_drive->{'MediaServer'} eq $media )
                                {
                                        $found = 1;
                                        last;
                                }
                        }

                        push @$ra_drives, {
                                                "MediaServer" => $media,
                                                "Drives" => ""

                                        } if ( $found == 0 ) ;
                                         my @rescmd = ` $cmd -h $media 2>/dev/null`;

                        if ( ! ( $! ) && ( $#rescmd > 4 ) )
                        {

                                #print @rescmd; 

                                if ( $rescmd[1] =~ /DRIVE STATUS/ )
                                {
                                        my $ra_DS = [];

                                        for (my $idx=4;$idx<=$#rescmd;$idx++)
                                                                           #on ajoute le statut du lecteur n au tableau
                                                #printf "%d - %s\n", $idx, $rescmd[$idx]; 
                                                #$ra_drives[$#ra_drives]->{'DriveStatus'}->[$1] = $2 if ( $rescmd[$idx] =~ / *(\d+) *{\d,\d,\d,\d} *(\w+) *.*/ ); 
                                                #$ra_drives[$#ra_drives]->{'DriveStatus'}->[$1] = $2 if ( $rescmd[$idx] =~ / *(\d+) *{\d,\d,\d,\d} *(\w+) *.*/ ); 

                                                if ( $rescmd[$idx] =~ / *(\d+) *(\S+) *(\w+) *.*/ )
                                                {
                                                        my $found_drive = 0;

                                                        foreach $DS (@$ra_DS )
                                                        {

                                                                if ( $DS->{'DriveNum'} == $1 )
          #Le lecteur a deja ete vu 
                                                                        # on rajoute le nouveau chemin 

                                                                        my $path = $2;
                                                                        $path .= "       " if ( length($2) < 15);

                                                                        push @{$DS->{'Detail'}}, {
                                                                                                                "Path" => $path,
                                                                                                                "Status" => $3
                                                                                                                };

                                                                        $found_drive = 1;
                                                                        last;

                                                                }
                                                        }
                                                        if ( $found_drive == 0 )
                                                        {

                                                                push @$ra_DS, {
                                                                                "DriveNum" => $1,
                                                                                "Detail" => []
                                                                                };

                                                                my $path = $2;
                                                                $path .= "       " if ( length($2) < 15);

                                                                push @{$ra_DS->[$#ra_DS]->{'Detail'}}, {
                                                                                                        "Path" => $path,
                                                                                                        "Status" => $3
                                                                                                        };
                                                        }
                                                }

                                      }

                                        $ra_drives->[$#ra_drives]->{'Drives'} = $ra_DS;
                                }

                        }


                }

        }
                #print Dumper($ra_drives);
        return $ra_drives;
}
###################################################
#
#       Affichage du resultat sur la console
#
####################################################
sub txtOutput 
{

        my ( $txt_ra_jobs, $txt_rah_stats, $ra_drives ) = @_;
        #recherche svg en cours 
        #
        #

        printf colored ['yellow'], "\n\nLecteurs:\n\n";

        foreach my $rh_drive ( @$ra_drives )
        {

                printf "\t%s\n", $rh_drive->{'MediaServer'};

                foreach my $driveInfo (@{$rh_drive->{'Drives'}})
                {

                        printf "\t\tLecteur %d\n", $driveInfo->{'DriveNum'};

                        foreach my $rh_DIDetail (@{$driveInfo->{'Detail'}})
                         {

                                if ( ($rh_DIDetail->{'Status'}) &&  ( $rh_DIDetail->{'Status'} ne "DOWN" ) )
                                {

                                        printf "\t\t\t%s\t%s\n", $rh_DIDetail->{'Path'}, colored ['green'], $rh_DIDetail->{'Status'};
                                }
                                else
                                {
                                
                                        printf "\t\t\t%s\t%s\n", $rh_DIDetail->{'Path'}, colored ['red'], $rh_DIDetail->{'Status'};
                                }

                        }

                }


        }
 printf colored ['yellow'], "\n\nStatistiques:\n\n";

        foreach my $rh_stats ( @$rah_stats )
        {

                printf "%s\nTaille totale: %6.0f Go\nNombre de fichiers: %d\nNombre de serveurs: %d\n\n", $rh_stats->{'Name'}, $rh_stats->{'Size'} /1024 /1024, $rh_stats->{'NFiles'}, $rh_stats->{'NClients'};

        }


        my $job;

        printf colored ['yellow'], "\n\nSauvegardes en cours:\n\n";

        #for $job (@$txt_ra_jobs) 
        for $job (sort{ $a->{'client'} cmp  $b->{'client'} } @$txt_ra_jobs )
          {

                printf "\t%s\t%s\tAvancement %d%% commence le %s \n", &prettyfy( $job->{'client'}, "text" ), &prettyfy( $job->{'policy'}, "text"  ), $job->{'percent'}, $job->{'start_text'} if ( ( $job->{'state'} == 1 ) &&  ( $job->{'jobtype'} == 0 ) && ( ! ($job->{'policy'} =~ /DSSU/  ) ) && ( $job->{'schedule'} ne '-'   )  );
                #printf $job->{'client'} if ( $job && ( $job->{'state'} == 1 ) && ( ( $job->{'jobtype'} == 0 ) ||  ( $job->{'jobtype'} == 6 ) ) ); 

        }

        printf colored ['yellow'], "\n\nSauvegardes invalides:\n\n";

        #for $job (@$txt_ra_jobs) 
for $job (sort{ $a->{'client'} cmp  $b->{'client'} } @$txt_ra_jobs )
        {

                #printf "\t%s\t%s %s \n", &prettyfy( $job->{'client'}, "text"  ), &prettyfy( $job->{'policy'}, "text"  ), $job->{'explain'} if ( ( $job->{'jobtype'} == 0 ) && ( $job->{'start'} >= $start_time )  && ( $job->{'status'} ) && ( $job->{'status'} > 1 ) && ( ! ($job->{'policy'} =~ /DSSU/  ) ) && ( $job->{'schedule'} ne '-' )  ); 
                printf "\t%s\t%s %s \n", &prettyfy( $job->{'client'}, "text"  ), &prettyfy( $job->{'policy'}, "text"  ), $job->{'explain'} if ( ( $job->{'jobtype'} == 0 ) && ( $job->{'start'} >= $start_time )  && ( $job->{'status'} ) && ( $job->{'status'} > 1 ) && ( ! ($job->{'policy'} =~ /DSSU/  ) ) );

        }
          printf colored ['yellow'], "\n\nSauvegardes incompletes:\n\n";

        #for $job (sort(@$txt_ra_jobs )) 
        for $job (sort{ $a->{'client'} cmp  $b->{'client'} } @$txt_ra_jobs )
        {

                #printf "\t%s\t[%s]\n", &prettyfy( $job->{'client'} ), &prettyfy( $job->{'policy'} ) if ( ( $job->{'state'} == 0 ) &&  ( $job->{'jobtype'} == 0 )  && ( $job->{'status'} == 1  ) && ( ! ($job->{'policy'} =~ /DSSU/  ) )  && ( $job->{'schedule'} ne '-' )  ); 
                printf "\t%s\t%s\n", &prettyfy( $job->{'client'}, "text"  ), &prettyfy( $job->{'policy'}, "text"  ) if ( ( $job->{'jobtype'} == 0 )  && ( $job->{'start'} >= $start_time ) && ( $job->{'status'} ) && ( $job->{'status'} == 1  ) && ( ! ($job->{'policy'} =~ /DSSU/  ) )  && ( $job->{'schedule'} ne '-' )  );
                #printf $job->{'client'} if ( $job && ( $job->{'state'} == 1 ) && ( ( $job->{'jobtype'} == 0 ) ||  ( $job->{'jobtype'} == 6 ) ) ); 
        }




}


###################################################
#
#       Recuperation des statistiques par site
#
####################################################
sub siteStats 
{

        my ( $ra_jobs ) = @_;

        #tableau dans lequel on stocke les statistiques
        my $rah_stats = [];

        #liste des agents (serveurs sauvegardes)
        my @agents;

        foreach my $job (@$ra_jobs)
        {

                # On cherche tous les jobs de type backup 
                #  dans la plage horaire concernée 
                #   qu'ils soient valides ou non
                if ( ( $job->{'jobtype'} == 0 ) && ( $job->{'start'} >= $start_time )  && ( ! ($job->{'policy'} =~ /DSSU/  ) ) )
                {

                        my $site;

                        $site = "VES" if ( $job->{'server'} =~ /vsaus/ );
                        $site = "FAR" if ( $job->{'server'} =~ /asaus/ );
                        $site = "SACL" if ( $job->{'server'} =~ /csaus/ );
                        $site = "CAD" if ( $job->{'server'} =~ /bsaus/ );
                        $site = "OCT" if ( $job->{'server'} =~ /hsaus/ );


                        #si le site est trouve, on cherche à mettre à jour les stats
                        # sinon on ne fait rien
                        if ( $site )
                        {

                                my $site_found = 0;

                                foreach my $rh_stat (@$rah_stats )
                                {
                                                           # On a trouve le site, on met à jour les statistiques
                                        if ( $rh_stat->{'Name'} eq $site )
                                        {


                                                $rh_stat->{'Size'} += $job->{'kbytes'} if ( looks_like_number($job->{'kbytes'}) );
                                                $rh_stat->{'NFiles'} += $job->{'files'} if ( looks_like_number($job->{'files'}) );

                                                #recherche si le serveur a deja ete rencontre ou pas 
                                                my $found=0;

                                                foreach my $agent (@agents)
                                                {
                                                        if ( ( $job->{'client'} ) && ( $agent eq $job->{'client'} ) )
                                                        {
                                                                $found = 1;
                                                                last;
                                                        }
                                                }

                                                if ( $found == 0 )
                                                {
                                                        #on ajoute le client à la liste pour ne 
                                                        # pas le compter deux fois
                                                        push @agents, $job->{'client'};

                                                        #L'agent n'a pas ete vu, 
                                                        # on met à jour le compteur
                                                        $rh_stat->{'NClients'} += 1;
                                                }
                                                    #on indique que le site est trouve, on se positionne sur 
                                                # le dernier element pour ne pas boucler
                                                $site_found = 1;
                                                last;
                                        }

                                }

                                # On n'a pas trouve le site, on l'ajoute à la liste
                                push @$rah_stats, {
                                                        "Name" => $site,
                                                        "Size" => 0,
                                                        "NFiles" => 0,
                                                        "NClients" => 0
                                                } if ( $site_found == 0 );

                        }
                }

        }

        #print Dumper(@agents); 

        return $rah_stats;

}

sub get_jobs_all_sites 
{

        my $us_start_date = shift();

        my $cmd;
        my @jobscmd;


        $cmd = "/usr/openv/netbackup/bin/admincmd/bpdbjobs -most_columns";
        #$cmd = "/usr/openv/netbackup/bin/admincmd/bpdbjobs -all_columns"; 


        foreach my $master_server (keys %h_masters_robots )
        {
                # si la date en argument est valide, on filtre le resultat de la commande 
                #  pour commencer à cette date 
                #+ Modification car l'option semble ne fonctionner qu'avec asaus111v
                $cmd .= " -t \"$us_start_date\"" if ( ( $us_start_date =~ /\d{2}\/\d{2}\/\d{4} \d{2}:\d{2}:\d{2}/ ) && ( $master_server =~ /asaus111/ ) )  ;

                printf STDERR "%s\n", $cmd;
                           printf STDERR "Recuperation des jobs sur %s - ", $master_server;

                push @jobscmd, `$cmd -M $master_server`;

                printf STDERR "Nombre de lignes: %d\n", $#jobscmd;

        }


        foreach my $jobline (@jobscmd)
        {
                                 my @job = split( ",", $jobline );
                my $ra_incomplete_files;

                #Generation de la liste des fichiers non svg en cas de statut 1 (incomplet) 
                #        et si la svg n'est pas en cours (statut 1) 
                $ra_incomplete_files = &incomplete_files( $job[0], $job[25] ) if ( ( $job[3] eq 1 ) && ( $job[2] eq 0 ) ) ;


                push @jobs, {
                                "jobid" => $job[0],
                                "jobtype" => $job[1],
                                "state" => $job[2],
                                "status" => $job[3],
                                "explain" => &explain( $job[3] ),
                                "policy" => $job[4],
                                "schedule" => $job[5],
                                "client" => $job[6],
                                "server" => $job[7],
                                "start" => $job[8],
                                "start_text" => &convert_epoch_2_date( $job[8]),
                                "duration" => $job[9],
                               "end" => $job[10],
                                "end_text" => &convert_epoch_2_date( $job[10]),
                                "kbytes" => $job[14],
                                "incomplete_files" => $ra_incomplete_files,
                                "files" => $job[15],
                                "percent" => $job[17],
                                "masterserver" => $job[25],
                                };


        }

         #jobid=$1 ; jobtype=$2; state=$3;status=$4;policy=$5;schedule=$6;client=$7; server=$8; start=$9; duration=$10; end=$11; kbytes=$15; files=$16;
}


###############################################################
#
#
#       explain <error_code> 
#       Renvoit l'explication liée au code d'erreur généré 
#        par netbackup
#
#
###############################################################
sub explain 
{

        my $error_code = shift();

        #valeur arbitraire pour eviter des codes errones
        #return "" if ( ( $error_code lt 0 ) || ( $error_code gt 2000 ) ); 

        #On recherche d'abord en cache si on trouve le code d'erreur
        foreach my $explanation (@explanations )
        {
                return $explanation->{"text"} if ( $error_code eq $explanation->{"status"} );
        }

        #Le cas echeant, on utilise la commande ci-dessous pour recuperre 
        # les explications sur le code d'erreur - on les met en cache ensuite
        my $cmd = "/usr/openv/netbackup/bin/admincmd/bperror -S $error_code 2>/dev/null " ;
        printf STDERR "%s\n", $cmd;

        #my @result = `$cmd`; 
        my @result = `$cmd`;
         chomp( $result[0] ) if ( @result );

        push @explanations, {
                                "status" => $error_code,
                                "text" => $result[0]
                                };

        return $result[0];


}
###############################################################
###############################################################




sub incomplete_files
{

        my ( $jobid, $masterserver ) = @_;

        my @jobstatuscmd = ` /usr/openv/netbackup/bin/admincmd/bperror -jobid $jobid -M $masterserver 2>/dev/null  ` ;

        my $ra_files = ();

        #"s/.*t open \w\+:* \(.*\) *[(|E].*/\1/p" 
        #"s/.*t open \w\+:* \(.*\) *[(|E].*/\1/p" 
        #"s/.*t open \w\+:* \(.*\) *[(|E].*/\1/p" 

        foreach my $jobstatusline ( @jobstatuscmd )
        {
                push(@$ra_files), $1 if ( $jobstatusline =~ /.* open \w+:* (.*) *[\(|E].*/ );
        }


        return $ra_files;

}
###############################################################
#
#
#       convert_epoch_2_US_date <date au format epoch>
#       Renvoit une date au format US mm/dd/YYYY HH:MM:SS
#               à partir d'une date epoch
#
#
###############################################################
sub convert_epoch_2_US_date 
{

        my $epoch_time = shift();

        my ($sec, $min, $hour, $day,$month,$year) = (localtime($epoch_time))[0,1,2,3,4,5];
        #year = nbre d'années depuis 1900
        $year+=1900;

        $month+=1;

        #my @months = ("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec");
        #my @months = ("Jan","Fev","Mar","Avr","Mai","Jun","Jul","Aou","Sep","Oct","Nov","Dec");

#       $month = "0$month" if ( $month lt 10 ); 
#       $day = "0$day" if ( $day lt 10 ); 
#       $hour = "0$hour" if ( $hour lt 10 ); 
#       $min = "0$min" if ( $min lt 10 ); 
#       $sec = "0$sec" if ( $sec lt 10 ); 

        my $str_date = sprintf( "%02d/%02d/%d %02d:%02d:%02d", $month, $day, $year, $hour, $min, $sec);
             return $str_date;

}
###############################################################
###############################################################


###############################################################
#
#
#       convert_epoch_2_date2 <date au format epoch>
#       Renvoit une date au format "dow dd/mm/YYYY"
#               à partir d'une date epoch
#
#
###############################################################
sub convert_epoch_2_date2 
{

        my $epoch_time = shift();

        my ($sec, $min, $hour, $day, $month, $year, $wday) = (localtime($epoch_time))[0,1,2,3,4,5,6];
        #year = nbre d'années depuis 1900
        $year+=1900;

        $month+=1;

        #my @months = ("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec");
        #my @months = ("Jan","Fev","Mar","Avr","Mai","Jun","Jul","Aou","Sep","Oct","Nov","Dec");
        my @weekdays = ( "Dimanche", "Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi");

#       $month = "0$month" if ( $month lt 10 ); 
#       $day = "0$day" if ( $day lt 10 ); 
#       $hour = "0$hour" if ( $hour lt 10 ); 
#       $min = "0$min" if ( $min lt 10 ); 
#       $sec = "0$sec" if ( $sec lt 10 ); 

        #my $str_date = sprintf( "%d/%02d/%02d %02d:%02d:%02d", $year, $month, $day, $hour, $min, $sec); 
        my $str_date = sprintf( "%s %02d/%02d/%02d",  $weekdays[$wday], $day, $month, $year);


        return $str_date;
}
###############################################################
###############################################################



###############################################################
#
#
#       convert_epoch_2_date <date au format epoch>
#       Renvoit une date au format "dow dd/mm/YYYY HH:MM:SS"
#               à partir d'une date epoch
#
#
###############################################################
sub convert_epoch_2_date 
{

        my $epoch_time = shift();

        my ($sec, $min, $hour, $day, $month, $year, $wday) = (localtime($epoch_time))[0,1,2,3,4,5,6];
        #year = nbre d'années depuis 1900
        $year+=1900;

        $month+=1;

        #my @months = ("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec");
        #my @months = ("Jan","Fev","Mar","Avr","Mai","Jun","Jul","Aou","Sep","Oct","Nov","Dec");
        my @weekdays = ( "dim.", "lun.", "mar.", "mer.", "jeu.", "ven.", "sam." );

#       $month = "0$month" if ( $month lt 10 ); 
#       $day = "0$day" if ( $day lt 10 ); 
#       $hour = "0$hour" if ( $hour lt 10 ); 
#       $min = "0$min" if ( $min lt 10 ); 
#       $sec = "0$sec" if ( $sec lt 10 ); 

        #my $str_date = sprintf( "%d/%02d/%02d %02d:%02d:%02d", $year, $month, $day, $hour, $min, $sec); 
        my $str_date = sprintf( "%s %02d/%02d/%02d %02d:%02d:%02d", $weekdays[$wday], $day, $month, $year, $hour, $min, $sec);


        return $str_date;
}

###############################################################
###############################################################

sub xml_out 
{

        #&as_xml( shift @ARGV );
        my $output = IO::File->new(">$xmlout");
        #open XMLOUT, ">$xmlout" or die "Impossible d'ouvrir le fichier $xmlout en ecriture\n"; 

        my $xml_wr = new XML::Writer( OUTPUT => $output, ENCODING => "utf-8", DATA_MODE => 'true', DATA_INDENT => 2 );

        $xml_wr->startTag( 'ListeCartouchesDispo', site => "FAR", date => $epoch_now  );

        foreach my $keyrob ( keys %$stats )
        {
                $xml_wr->startTag( 'Robot', name => $keyrob );
                foreach my $keypool ( keys %{$stats->{$keyrob}->{"pool"}} )
                {
                        $xml_wr->startTag( 'Pool', name => $keypool );
                        foreach my $keycart ( keys %{$stats->{$keyrob}->{"pool"}->{$keypool}->{"cart"}} )
                        {

                                #on ne prend en compte que les cartouches connues (LTO) 
                                if ( $keycart =~ /LTO/ )
                                {
                                        $xml_wr->startTag( 'Cart', type => $keycart );
                                        foreach my $key ( keys %{$stats->{$keyrob}->{"pool"}->{$keypool}->{"cart"}->{$keycart}} )
                                        {
                                                $xml_wr->startTag( $key );
                                                $xml_wr->characters( $stats->{$keyrob}->{"pool"}->{$keypool}->{"cart"}->{$keycart}->{$key} );
                                                $xml_wr->endTag( $key );

                                        }

                                        $xml_wr->endTag( 'Cart' );
                                 }
                        }

                        $xml_wr->endTag( 'Pool' );
                }

                $xml_wr->endTag( 'Robot' );
                #$xml_wr->emptyTag( 'file', name => $path );
  }

        $xml_wr->endTag( 'ListeCartouchesDispo' );
        $xml_wr->end;

}

sub send_mail 
{
        my ( $txt_ra_jobs, $txt_rah_stats, $ra_drives ) = @_;

        my $htmlfile="/tmp/rapport-svg-$start_time.html";
        my $job;

        open HTMLOUT, "+>$htmlfile" or die "Impossible d'ouvrir le fichier $htmlfile en écriture\n";

        print HTMLOUT "<BR><BR> <U><B> $start_time_text_header => $end_time_text_header  </B> </U> <BR> <BR> <BR> \n";

print HTMLOUT <<HTML; 
<b><span style="mso-list:Ignore"><span style="font:7.0pt&quot;Times New Roman&quot;"> </span></span></b><b><u>Duplications et statut des lecteurs<o:p></o:p></u></b>
<p class="MsoNormal"><o:p> </o:p></p>
<table class="MsoTableGrid" style="border-collapse: collapse; border:medium none;" height="117" width="780" border="1" cellpadding="0" cellspacing="0">
  <tbody>
    <tr>
      <td style="width:119.3pt;border:solid windowtext
        1.0pt;background:#4F81BD;padding:0cm 5.4pt 0cm 5.4pt"
 valign="top" width="159">
        <p class="MsoNormal" style="text-align:center" align="center"><small><b>Nom du serveur</b><b><o:p></o:p></b></small></p>
      </td>
      <td style="width:119.3pt;border:solid windowtext
        1.0pt;border-left:none;background:#4F81BD;padding:0cm 5.4pt 0cm
        5.4pt" valign="top" width="120">
        <p class="MsoNormal" style="text-align:center" align="center"><small><b>Lecteur</b><b><o:p></o:p></b></small></p>
      </td>
      <td style="width:119.3pt;border:solid windowtext
        1.0pt;border-left:none;background:#4F81BD;padding:0cm 5.4pt 0cm
        5.4pt" valign="top" width="120">
        <p class="MsoNormal" style="text-align:center" align="center"><small><b>Chemin</b><b><o:p></o:p></b></small></p>
      </td>
      <td style="width:119.3pt;border:solid windowtext
        1.0pt;border-left:none;background:#4F81BD;padding:0cm 5.4pt 0cm
        5.4pt" valign="top" width="120">
        <p class="MsoNormal" style="text-align:center" align="center"><small><b>Etat</b><b><o:p></o:p></b></small></p>
      </td>
      <td style="width:119.35pt;border:solid windowtext 1.0pt;border-left:none;background:#4F81BD;padding:0cm 5.4pt 0cm 5.4pt" valign="top" width="159">
        <p class="MsoNormal" style="text-align:center" align="center"><small><b>Cause + N° de Gipsi</b><b><o:p></o:p></b></small></p>
      </td>
      <td style="width:119.35pt;border:solid windowtext 1.0pt;border-left:none;background:#4F81BD;padding:0cm 5.4pt 0cm 5.4pt" valign="top" width="250">
        <p class="MsoNormal" style="text-align:center" align="center"><small><b>Action/Décision</b><b><o:p></o:p></b></small></p>
      </td>
    </tr>
         HTML

        #pour identifier les doublons
        my $prev_media;

        foreach my $rh_drive ( @$ra_drives )
        {

                #Recuperation du nombre de lecteurs pour
                # spanner les lignes
                my $numDrivesPaths = $#{$rh_drive->{'Drives'}} + 1;

                #On parcourt les chemins pour ajouter 
                # les lignes necessaires
                foreach my $driveInfo (@{$rh_drive->{'Drives'}})
                {
                        #Recuperation du nombre de chemin par lecteur
                        # pour spanner les lignes
                        my $numPaths = $#{$driveInfo->{'Detail'}} +1  ;
                        # on ajoute uniquement quand nbre ligne > 1
                        $numDrivesPaths += $numPaths - 1 ;
                }
                    if ( ! $prev_media || ( $rh_drive->{'MediaServer'} ne $prev_media )  )
                {

                        printf HTMLOUT "<tr>\n";
                        printf HTMLOUT "<td style=\"width:119.3pt;border:solid windowtext 1.0pt;border-top:none;padding:0cm ";
                        printf HTMLOUT "5.4pt 0cm 5.4pt\" valign=\"middle\" width=\"159\" align=\"center\" rowspan=\"%d\">\n", $numDrivesPaths;
                        printf HTMLOUT "<p class=\"MsoNormal\" style=\"text-align:center\" align=\"center\">%s<o:p></o:p></p>\n", $rh_drive->{'MediaServer'};
                        printf HTMLOUT "</td>\n";

                        $prev_media = $rh_drive->{'MediaServer'};
                }
                  #pour identifier les doublons
                my $prev_drive;

                foreach my $driveInfo (@{$rh_drive->{'Drives'}})
                {
                        #Recuperation du nombre de chemin par lecteur
                        # pour spanner les lignes
                        my $numPaths = $#{$driveInfo->{'Detail'}} + 1;

                        if ( ! $prev_drive || ( $driveInfo->{'DriveNum'} ne $prev_drive ) )
                        {

                                printf HTMLOUT "<td style=\"width:119.3pt;border:solid windowtext 1.0pt;border-top:none;padding:0cm ";
                                printf HTMLOUT "5.4pt 0cm 5.4pt\" valign=\"middle\" width=\"159\" align=\"center\" rowspan=\"%d\">\n", $numPaths;
                                printf HTMLOUT "<p class=\"MsoNormal\" style=\"text-align:center\" align=\"center\">Lecteur %d<o:p></o:p></p>\n", $driveInfo->{'DriveNum'} ;
                                printf HTMLOUT "</td>\n";

                                $prev_drive = $driveInfo->{'DriveNum'};

                        }
                          foreach my $driveDetail ( @{$driveInfo->{'Detail'}} )
                        {

                                printf HTMLOUT "<td style=\"width:119.3pt;border-top:none;border-left:none;border-bottom:solid windowtext 1.0pt;border-right:solid windowtext ";
                                printf HTMLOUT "1.0pt;padding:0cm 5.4pt 0cm 5.4pt\" valign=\"middle\" width=\"120\" align=\"center\">\n";
                                printf HTMLOUT "<p class=\"MsoNormal\" style=\"text-align:center\" align=\"center\"><font ";
                                printf HTMLOUT "color=\"#333333\"><o:p> %s <br>\n", $driveDetail->{'Path'} ;
                                printf HTMLOUT "</o:p></font></p>\n";
                                printf HTMLOUT "</td>\n";

                                my $color = "003300";
                                $color = "660000" if ( $driveDetail->{'Status'} eq "DOWN");

                                printf HTMLOUT "<td style=\"width:119.3pt;border-top:none;border-left:none;border-bottom:solid windowtext 1.0pt;border-right:solid windowtext ";
                                printf HTMLOUT "1.0pt;padding:0cm 5.4pt 0cm 5.4pt\" valign=\"middle\" width=\"120\" align=\"center\">\n";
                                printf HTMLOUT "<p class=\"MsoNormal\" style=\"text-align:center\" align=\"center\"><font ";
                                printf HTMLOUT "color=\"#%s\"><o:p> <b> %s </b> <br>\n", $color, $driveDetail->{'Status'} ;
                                printf HTMLOUT "</o:p></font></p>\n";
                                printf HTMLOUT "</td>\n";
                                printf HTMLOUT "<td style=\"width:119.35pt;border-top:none;border-left:none;border-bottom:solid windowtext ";
                                printf HTMLOUT "1.0pt;border-right:solid windowtext 1.0pt;padding:0cm 5.4pt 0cm 5.4pt\" valign=\"middle\" width=\"159\" align=\"center\">\n";
                                printf HTMLOUT "<p class=\"MsoNormal\" style=\"text-align:center\" align=\"center\"><o:p> </o:p></p>\n";
                                printf HTMLOUT "</td>\n";
                                printf HTMLOUT "<td style=\"width:119.35pt;border-top:none;border-left:none;border-bottom:solid windowtext ";
                                printf HTMLOUT "1.0pt;border-right:solid windowtext 1.0pt;padding:0cm 5.4pt 0cm 5.4pt\" valign=\"middle\" width=\"250\" align=\"center\">\n";
                                printf HTMLOUT "<p class=\"MsoNormal\" style=\"text-align:center\" align=\"center\"><o:p> </o:p></p>\n";
                                printf HTMLOUT "</td>\n";

                                printf HTMLOUT "</tr>\n";

                        }
                }


        }

        printf HTMLOUT "</tbody>\n";
        printf HTMLOUT "</table>\n";
      #Volumetrie et autres statistiques

print HTMLOUT <<HTML; 
<br>
<b><u>Volumétrie des sauvegardes</u></b><br>
<br>
<table style="border-collapse: collapse; border:medium none;"
  class="MsoTableGrid" cellpadding="0" cellspacing="0" border="1"
  height="117" width="400">
  <tbody>
    <tr>
      <td style="width:119.3pt;border:solid windowtext
        1.0pt;background:#4F81BD;padding:0cm 5.4pt 0cm 5.4pt"
        valign="top" width="100">
        <p class="MsoNormal" style="text-align:center" align="center"><small><b>Site</b><b><o:p></o:p></b></small></p>
      </td>
      <td style="width:119.3pt;border:solid windowtext
        1.0pt;border-left:none;background:#4F81BD;padding:0cm 5.4pt 0cm
        5.4pt" valign="top" width="120">
        <p class="MsoNormal" style="text-align:center" align="center"><small><b>Taille</b></small></p>
      </td>
      <td style="width:119.3pt;border:solid windowtext
        1.0pt;border-left:none;background:#4F81BD;padding:0cm 5.4pt 0cm
        5.4pt" valign="top" width="120">
        <p class="MsoNormal" style="text-align:center" align="center"><small><b>Nombre de fichiers</b></small></p>
      </td>
      <td style="width:119.3pt;border:solid windowtext
        1.0pt;border-left:none;background:#4F81BD;padding:0cm 5.4pt 0cm
        5.4pt" valign="top" width="120">
        <p class="MsoNormal" style="text-align:center" align="center"><small><b>Nombre de serveurs</b></small></p>
      </td>
    </tr>
HTML
 foreach my $rh_stats ( @$rah_stats )
        {

                printf HTMLOUT "<tr>\n";
                printf HTMLOUT "<td style=\"width:119.3pt;border:solid windowtext 1.0pt;border-top:none;padding:0cm 5.4pt 0cm 5.4pt\"";
                printf HTMLOUT "align=\"center\" valign=\"middle\" width=\"100\">\n";
                printf HTMLOUT "<p class=\"MsoNormal\" style=\"text-align:center\" align=\"center\">%s</p>", $rh_stats->{'Name'};
                printf HTMLOUT "</td>";
                printf HTMLOUT "<td ";
                printf HTMLOUT "style=\"width:119.3pt;border-top:none;border-left:none;border-bottom:solid";
                printf HTMLOUT "windowtext 1.0pt;border-right:solid windowtext 1.0pt;padding:0cm";
                printf HTMLOUT "5.4pt 0cm 5.4pt\" align=\"center\" valign=\"middle\" width=\"120\">";
                printf HTMLOUT "<p class=\"MsoNormal\" style=\"text-align:center\" align=\"center\"><font";
                printf HTMLOUT "color=\"#003300\"><o:p><font color=\"#000000\">%6.0f Go</font> </o:p></font></p>", $rh_stats->{'Size'}/1024/1024;
                printf HTMLOUT "</td>";
                printf HTMLOUT "<td ";
                printf HTMLOUT "style=\"width:119.3pt;border-top:none;border-left:none;border-bottom:solid";
                printf HTMLOUT "windowtext 1.0pt;border-right:solid windowtext 1.0pt;padding:0cm";
                printf HTMLOUT "5.4pt 0cm 5.4pt\" align=\"center\" valign=\"middle\" width=\"120\">";
                printf HTMLOUT "<p class=\"MsoNormal\" style=\"text-align:center\" align=\"center\"><font";
                printf HTMLOUT "color=\"#003300\"><o:p><font color=\"#000000\">%d</font> </o:p></font></p>", $rh_stats->{'NFiles'};
                printf HTMLOUT "</td>";
                printf HTMLOUT "<td ";
                printf HTMLOUT "style=\"width:119.3pt;border-top:none;border-left:none;border-bottom:solid";
                printf HTMLOUT "windowtext 1.0pt;border-right:solid windowtext 1.0pt;padding:0cm";
                printf HTMLOUT "5.4pt 0cm 5.4pt\" align=\"center\" valign=\"middle\" width=\"120\">";
                printf HTMLOUT "<p class=\"MsoNormal\" style=\"text-align:center\" align=\"center\"><font";
                printf HTMLOUT "color=\"#003300\"><o:p><font color=\"#000000\">%s</font> </o:p></font></p>", $rh_stats->{'NClients'};
                printf HTMLOUT "</td>";
                printf HTMLOUT "</tr>";


        }
         printf HTMLOUT "</tbody><br><br></table>";

        #Sauvegardes en cours


print HTMLOUT <<HTML; 
<p class="MsoNormal"><o:p> <br>
    <br>
  </o:p></p>
<p class="MsoListParagraph" style="text-indent:-18.0pt;mso-list:l0
  level1 lfo1"><b><span style="mso-list:Ignore">2.<span
        style="font:7.0pt &quot;Times New Roman&quot;">       </span></span></b><b><u>Sauvegardes en cours<o:p></o:p></u></b></p>
<p class="MsoNormal"><o:p><br>
  </o:p></p>
<table class="MsoTableGrid" style="border-collapse: collapse; border:
  medium none;" height="385" width="991" border="1" cellpadding="0"
  cellspacing="0">
  <tbody>
    <tr>
      <td style="width:127.2pt;border:solid windowtext
        1.0pt;background:#4F81BD;padding:0cm 5.4pt 0cm 5.4pt"
        valign="top" width="170">
        <p class="MsoNormal"><small><b>Nom de serveur impacté</b><b><o:p></o:p></b></small></p>
      </td>
      <td style="width:111.4pt;border:solid windowtext
        1.0pt;border-left:none;background:#4F81BD;padding:0cm 5.4pt 0cm
        5.4pt" valign="top" width="149">
        <p class="MsoNormal"><small><b>Policie impactée</b><b><o:p></o:p></b></small></p>
 </td>
      <td style="width:111.4pt;border:solid windowtext
        1.0pt;border-left:none;background:#4F81BD;padding:0cm 5.4pt 0cm
        5.4pt" valign="top" width="149">
        <p class="MsoNormal"><small><b>Policie impactée</b><b><o:p></o:p></b></small></p>
      </td>
      <td style="width:87.05pt;border:solid windowtext
        1.0pt;border-left:none;background:#4F81BD;padding:0cm 5.4pt 0cm
        5.4pt" valign="top" width="116">
        <p class="MsoNormal"><small><b>% d’avancement</b><b><o:p></o:p></b></small></p>
      </td>
      <td style="width:127.55pt;border:solid windowtext
        1.0pt;border-left:none;background:#4F81BD;padding:0cm 5.4pt 0cm
        5.4pt" valign="top" width="240">
        <p class="MsoNormal"><small><b> Date/heure d’exécution </b><b><o:p></o:p></b></small></p>
      </td>
      <td style="width:231.9pt;border:solid windowtext
        1.0pt;border-left:none;background:#4F81BD;padding:0cm 5.4pt 0cm
        5.4pt" valign="top" width="350">
        <p class="MsoNormal"><small><b> Action/décision + N° de Gipsi</b><b><o:p></o:p></b></small></p>
      </td>
    </tr>

HTML
   #for $job (@jobs) 
        for $job (sort{ $a->{'client'} cmp  $b->{'client'} } @jobs)
        {

                printf HTMLOUT "<tr>\n\t<td valign=\"top\"> %s <br>\n\t</td>\n\t<td valign=\"top\"> %s </td>\n\t<td valign=\"top\" align=\"center\"> %d <br>\n\t<td valign=\"top\" align=\"center\"> %s <br>\n\t</td>\n\t<td valign=\"top\"> Annulation si toujours en cours à 10h00 </td>\n</tr>", $job->{'client'}, &prettyfy( $job->{'policy'}, "html" ), $job->{'percent'}, $job->{'start_text'}, "&nbsp" if ( ( $job->{'state'} == 1 ) &&  ( $job->{'jobtype'} == 0 ) && ( ! ($job->{'policy'} =~ /DSSU/  ) ) && ( $job->{'schedule'} ne '-'  )  );

        }
        printf HTMLOUT "</table>";

        #Sauvegardes en erreur
        print HTMLOUT <<HTML;
<p class="MsoNormal"><o:p><br>
    <br>
    <br>
  </o:p></p>
<p class="MsoListParagraph" style="text-indent:-18.0pt;mso-list:l0
  level1 lfo1"><b><span style="mso-list:Ignore">3.<span
        style="font:7.0pt &quot;Times New Roman&quot;">       </span></span></b><b><u>Sauvegardes en erreur<o:p></o:p></u></b></p>
<p class="MsoNormal"><o:p> </o:p></p>
<table class="MsoTableGrid" style="border-collapse:collapse;border:none"
  border="1" cellpadding="0" cellspacing="0">
  <tbody>
    <tr>
      <td style="width:127.2pt;border:solid windowtext
        1.0pt;background:#4F81BD;padding:0cm 5.4pt 0cm 5.4pt"
        valign="top" width="170">
        <p class="MsoNormal" style="text-align:center" align="center"><small><b>Nom
              de serveur impacté</b><b><o:p></o:p></b></small></p>
      </td>
      <td style="width:111.4pt;border:solid windowtext
        1.0pt;border-left:none;background:#4F81BD;padding:0cm 5.4pt 0cm
        5.4pt" valign="top" width="149">
        <p class="MsoNormal" style="text-align:center" align="center"><small><b>Policie
              impactée</b><b><o:p></o:p></b></small></p>
      </td>
      <td style="width:356.35pt;border:solid windowtext
        1.0pt;border-left:none;background:#4F81BD;padding:0cm 5.4pt 0cm
        5.4pt" valign="top" width="475">
        <p class="MsoNormal" style="text-align:center" align="center"><small><b>Message
              d’erreur</b><b><o:p></o:p></b></small></p>
      </td>
      <td style="width:92.15pt;border:solid windowtext
        1.0pt;border-left:none;background:#4F81BD;padding:0cm 5.4pt 0cm
        5.4pt" valign="top" width="123">
        <p class="MsoNormal" style="text-align:center" align="center"><small><b>N°
              de Gipsi</b><b><o:p></o:p></b></small></p>
      </td>
    </tr>
HTML
   #for $job (@jobs) 
        for $job (sort{ $a->{'client'} cmp  $b->{'client'} } @jobs)
        {

                #printf HTMLOUT "<tr>\n\t<td valign=\"top\"> %s <br>\n\t</td>\n\t<td valign=\"top\"> %s </td>\n\t<td valign=\"top\" align=\"center\"> %s <br>\n\t</td>\n\t<td valign=\"top\"> %d </td>\n</tr>", $job->{'client'}, &prettyfy( $job->{'policy'}, "html"), $job->{'explain'}, 0 if ( ( $job->{'jobtype'} == 0 ) && ( $job->{'start'} >= $start_time )  && ( $job->{'status'} ) && ( $job->{'status'} > 1 ) && ( ! ($job->{'policy'} =~ /DSSU/  ) ) && ( $job->{'schedule'} ne '-' )  ); 

                # AVEC LES SNAPSHOTS + PROCESSUS PERES
                printf HTMLOUT "<tr>\n\t<td valign=\"top\"> %s <br>\n\t</td>\n\t<td valign=\"top\"> %s </td>\n\t<td valign=\"top\" align=\"center\"> %s <br>\n\t</td>\n\t<td valign=\"top\"> %d </td>\n</tr>", $job->{'client'}, &prettyfy( $job->{'policy'}, "html"), $job->{'explain'}, 0 if ( ( $job->{'jobtype'} == 0 ) && ( $job->{'start'} >= $start_time )  && ( $job->{'status'} ) && ( $job->{'status'} > 1 ) && ( ! ($job->{'policy'} =~ /DSSU/  ) )  );

        }
        printf HTMLOUT "</table>";


        # Sauvegardes SAP 
        #
        #
print HTMLOUT <<HTML;
<BR>
<BR>
<p class="MsoListParagraph" style="text-indent:-18.0pt;mso-list:l0
  level1 lfo1"><span style="mso-list:Ignore">4.<span style="font:7.0pt &quot;Times New Roman&quot;">       </span></span><b><u>Sauvegardes SQL Agora invalides</u></b><u><o:p></o:p></u></p>
<p class="MsoNormal"><o:p> </o:p></p>
<table class="MsoTableGrid" style="border-collapse:collapse;border:none"
  cellpadding="0" cellspacing="0" border="1">
  <tbody>
    <tr>
      <td style="width:127.2pt;border:solid windowtext
        1.0pt;background:#4F81BD;padding:0cm 5.4pt 0cm 5.4pt"
        valign="top" width="170">
        <p class="MsoNormal" style="text-align:center" align="center"><small><b>Nom
              de serveur impacté</b><b><o:p></o:p></b></small></p>
      </td>
      <td style="width:111.4pt;border:solid windowtext
        1.0pt;border-left:none;background:#4F81BD;padding:0cm 5.4pt 0cm
        5.4pt" valign="top" width="149">
        <p class="MsoNormal" style="text-align:center" align="center"><small><b>Policie
              impactée</b><b><o:p></o:p></b></small></p>
      </td>
      <td style="width:356.35pt;border:solid windowtext
        1.0pt;border-left:none;background:#4F81BD;padding:0cm 5.4pt 0cm
        5.4pt" valign="top" width="475">
        <p class="MsoNormal" style="text-align:center" align="center"><small><b>Message
              d’erreur</b><b><o:p></o:p></b></small></p>
      </td>
      <td style="width:92.15pt;border:solid windowtext
        1.0pt;border-left:none;background:#4F81BD;padding:0cm 5.4pt 0cm
        5.4pt" valign="top" width="123">
        <p class="MsoNormal" style="text-align:center" align="center"><small><b>N°
              de Gipsi</b><b><o:p></o:p></b></small></p>
      </td>
    </tr>
    <tr>
      <td style="width:127.2pt;border:solid windowtext
        1.0pt;border-top:none;padding:0cm 5.4pt 0cm 5.4pt" valign="top"
        width="170">&nbsp; </td>
      <td
        style="width:111.4pt;border-top:none;border-left:none;border-bottom:solid windowtext 1.0pt;border-right:solid windowtext 1.0pt;padding:0cm
        5.4pt 0cm 5.4pt" valign="top" width="149">&nbsp;<br>
         </td>
      <td
        style="width:356.35pt;border-top:none;border-left:none;border-bottom:solid windowtext 1.0pt;border-right:solid windowtext 1.0pt;padding:0cm
        5.4pt 0cm 5.4pt" valign="top" width="475">&nbsp;<br>
      </td>
      <td
        style="width:92.15pt;border-top:none;border-left:none;border-bottom:solid windowtext 1.0pt;border-right:solid windowtext 1.0pt;padding:0cm
        5.4pt 0cm 5.4pt" valign="top" width="123">&nbsp;<br>
      </td>
    </tr>
  </tbody>
</table>
<p class="MsoNormal"><o:p></o:p></p>
HTML
   #Sauvegardes incompletes

print HTMLOUT <<HTML;
<p class="MsoNormal"><o:p> <br>
    <br>
  </o:p></p>
<p class="MsoListParagraph" style="text-indent:-18.0pt;mso-list:l0
  level1 lfo1"><span style="mso-list:Ignore">5.<span style="font:7.0pt
      &quot;Times New Roman&quot;">       </span></span><b><u>Sauvegardes incomplètes</u> </b><o:p></o:p></p>
<p class="MsoNormal"><o:p> </o:p></p>
<table class="MsoTableGrid" style="border-collapse: collapse; border:
  medium none;" height="679" width="1715" border="1" cellpadding="0"
  cellspacing="0">
  <tbody>
    <tr>
      <td style="width:127.2pt;border:solid windowtext
        1.0pt;background:#4F81BD;padding:0cm 5.4pt 0cm 5.4pt"
        valign="top" width="170">
        <p class="MsoNormal" style="text-align:center" align="center"><small><b>Nom
              de serveur impacté</b><b><o:p></o:p></b></small></p>
      </td>
      <td style="width:111.4pt;border:solid windowtext
        1.0pt;border-left:none;background:#4F81BD;padding:0cm 5.4pt 0cm
        5.4pt" valign="top" width="149">
        <p class="MsoNormal" style="text-align:center" align="center"><small><b>Policie
              impactée</b><b><o:p></o:p></b></small></p>
      </td>
      <td style="width:186.25pt;border:solid windowtext
        1.0pt;border-left:none;background:#4F81BD;padding:0cm 5.4pt 0cm
        5.4pt" valign="top" width="900"><small><b>Fichier en erreur</b></small>
      </td>
      <td style="width:6.0cm;border:solid windowtext
        1.0pt;border-left:none;background:#4F81BD;padding:0cm 5.4pt 0cm
        5.4pt" valign="top" width="227">
        <p class="MsoNormal" style="text-align:center" align="center"><small><b>Exception
              ajouté dans la policie</b><b><o:p></o:p></b></small></p>
      </td>
      <td style="width:92.15pt;border:solid windowtext
        1.0pt;border-left:none;background:#4F81BD;padding:0cm 5.4pt 0cm
        5.4pt" valign="top" width="123">
        <p class="MsoNormal" style="text-align:center" align="center"><small><b>N°
              de Gipsi</b><b><o:p></o:p></b></small></p>
      </td>
    </tr>
HTML
     for $job (sort{ $a->{'client'} cmp  $b->{'client'} } @jobs)
        {

                #printf HTMLOUT "<tr>\n\t<td valign=\"top\"> %s <br>\n\t</td>\n\t<td valign=\"top\"> %s </td>\n\t<td valign=\"top\"> %s <br>\n\t</td>\n\t<td valign=\"top\"> NON </td>\n\t<td valign=\"top\">  </td>\n</tr>", $job->{'client'}, &prettyfy( $job->{'policy'}, "html"), $job->{'incomplete_files'} if ( ( $job->{'jobtype'} == 0 )  && ( $job->{'start'} >= $start_time ) && ( $job->{'status'} ) && ( $job->{'status'} == 1  ) && ( ! ($job->{'policy'} =~ /DSSU/  ) )  && ( $job->{'schedule'} ne '-' )  ); 
                printf HTMLOUT "<tr>\n\t<td valign=\"top\"> %s <br>\n\t</td>\n\t<td valign=\"top\"> %s </td>\n\t<td valign=\"top\"> %s <br>\n\t</td>\n\t<td valign=\"top\"> NON </td>\n\t<td valign=\"top\">&nbsp;</td>\n</tr>", $job->{'client'}, &prettyfy( $job->{'policy'}, "html"), "&nbsp;" if ( ( $job->{'jobtype'} == 0 )  && ( $job->{'start'} >= $start_time ) && ( $job->{'status'} ) && ( $job->{'status'} == 1  ) && ( ! ($job->{'policy'} =~ /DSSU/  ) )  && ( $job->{'schedule'} ne '-' )  );

        }
        printf HTMLOUT "</table>";
        
        print HTMLOUT <<HTML;
<p class="MsoNormal"><u><o:p><span style="text-decoration:none"><br>
        <br>
      </span></o:p></u></p>
<p class="MsoListParagraph" style="text-indent:-18.0pt;mso-list:l0
  level1 lfo1"><span style="mso-list:Ignore">6.<span style="font:7.0pt
      &quot;Times New Roman&quot;">       </span></span><b><u>Sauvegardes rsync</u></b></p>
<p class="MsoListParagraph" style="text-indent:-18.0pt;mso-list:l0
  level1 lfo1"><br>
  <u><o:p></o:p></u></p>
<table class="MsoTableGrid" style="border-collapse:collapse;border:none"
  border="1" cellpadding="0" cellspacing="0">
  <tbody>
    <tr>
      <td style="width:127.2pt;border:solid windowtext
        1.0pt;background:#4F81BD;padding:0cm 5.4pt 0cm 5.4pt"
        valign="top" width="170">
        <p class="MsoNormal" style="text-align:center" align="center"><small><b>Nom
              de serveur impacté</b><b><o:p></o:p></b></small></p>
      </td>
      <td style="width:111.4pt;border:solid windowtext
        1.0pt;border-left:none;background:#4F81BD;padding:0cm 5.4pt 0cm
        5.4pt" valign="top" width="149">
        <p class="MsoNormal" style="text-align:center" align="center"><small><b>Nom
              de la tâche</b><b><o:p></o:p></b></small></p>
      </td>
      <td style="width:186.25pt;border:solid windowtext
        1.0pt;border-left:none;background:#4F81BD;padding:0cm 5.4pt 0cm
        5.4pt" valign="top" width="248">
        <p class="MsoNormal" style="text-align:center" align="center"><small><b>Erreur
              remarquée</b><b><o:p></o:p></b></small></p>
      </td>
      <td style="width:6.0cm;border:solid windowtext
        1.0pt;border-left:none;background:#4F81BD;padding:0cm 5.4pt 0cm
        5.4pt" valign="top" width="227">
        <p class="MsoNormal" style="text-align:center" align="center"><small><b>Solution
              apportée</b><b><o:p></o:p></b></small></p>
      </td>
      <td style="width:92.15pt;border:solid windowtext
        1.0pt;border-left:none;background:#4F81BD;padding:0cm 5.4pt 0cm
        5.4pt" valign="top" width="123">
        <p class="MsoNormal" style="text-align:center" align="center"><small><b>N°
              de Gipsi</b><b><o:p></o:p></b></small></p>
 </td>
    </tr>
    <tr>
      <td style="width:127.2pt;border:solid windowtext
        1.0pt;border-top:none;padding:0cm 5.4pt 0cm 5.4pt" valign="top"
        width="170"><br>
      </td>
      <td
        style="width:111.4pt;border-top:none;border-left:none;border-bottom:solid windowtext 1.0pt;border-right:solid windowtext 1.0pt;padding:0cm
        5.4pt 0cm 5.4pt" valign="top" width="149"><br>
      </td>
      <td
        style="width:186.25pt;border-top:none;border-left:none;border-bottom:solid windowtext 1.0pt;border-right:solid windowtext 1.0pt;padding:0cm
        5.4pt 0cm 5.4pt" valign="top" width="248"><br>
      </td>
      <td
        style="width:6.0cm;border-top:none;border-left:none;border-bottom:solid
        windowtext 1.0pt;border-right:solid windowtext 1.0pt;padding:0cm
        5.4pt 0cm 5.4pt" valign="top" width="227"><br>
      </td>
      <td
        style="width:92.15pt;border-top:none;border-left:none;border-bottom:solid windowtext 1.0pt;border-right:solid windowtext 1.0pt;padding:0cm
        5.4pt 0cm 5.4pt" valign="top" width="123"><br>
      </td>
    </tr>
  </tbody>
</table>
<p class="MsoNormal"><u><o:p><span style="text-decoration:none"><br>
        <br>
      </span></o:p></u></p>
<p class="MsoListParagraph" style="text-indent:-18.0pt;mso-list:l0
  level1 lfo1"><span style="mso-list:Ignore">7.<span style="font:7.0pt
    &quot;Times New Roman&quot;">       </span></span><b><u>Sauvegardes SnapMirror</u></b><u><o:p></o:p></u></p>
<p class="MsoNormal"><o:p> </o:p></p>
<table class="MsoTableGrid" style="border-collapse:collapse;border:none"
  border="1" cellpadding="0" cellspacing="0">
  <tbody>
    <tr>
      <td style="width:127.2pt;border:solid windowtext
        1.0pt;background:#4F81BD;padding:0cm 5.4pt 0cm 5.4pt"
        valign="top" width="170">
        <p class="MsoNormal" style="text-align:center" align="center"><small><b>Nom
              de serveur impacté</b><b><o:p></o:p></b></small></p>
      </td>
      <td style="width:111.4pt;border:solid windowtext
        1.0pt;border-left:none;background:#4F81BD;padding:0cm 5.4pt 0cm
        5.4pt" valign="top" width="149">
        <p class="MsoNormal" style="text-align:center" align="center"><small><b>Nom
              de la tâche</b><b><o:p></o:p></b></small></p>
      </td>
      <td style="width:186.25pt;border:solid windowtext
        1.0pt;border-left:none;background:#4F81BD;padding:0cm 5.4pt 0cm
        5.4pt" valign="top" width="248">
        <p class="MsoNormal" style="text-align:center" align="center"><small><b>Erreur
              remarquée</b><b><o:p></o:p></b></small></p>
      </td>
      <td style="width:6.0cm;border:solid windowtext
        1.0pt;border-left:none;background:#4F81BD;padding:0cm 5.4pt 0cm
        5.4pt" valign="top" width="227">
        <p class="MsoNormal" style="text-align:center" align="center"><small><b>Solution
              apportée</b><b><o:p></o:p></b></small></p>
      </td>
      <td style="width:92.15pt;border:solid windowtext
        1.0pt;border-left:none;background:#4F81BD;padding:0cm 5.4pt 0cm
        5.4pt" valign="top" width="123">
        <p class="MsoNormal" style="text-align:center" align="center"><small><b>N°
              de Gipsi</b><b><o:p></o:p></b></small></p>
               </td>
    </tr>
    <tr>
      <td style="width:127.2pt;border:solid windowtext
        1.0pt;border-top:none;padding:0cm 5.4pt 0cm 5.4pt" valign="top"
        width="170">
        <p class="MsoNormal"><o:p>    <br>
          </o:p></p>
      </td>
      <td
        style="width:111.4pt;border-top:none;border-left:none;border-bottom:solid windowtext 1.0pt;border-right:solid windowtext 1.0pt;padding:0cm
        5.4pt 0cm 5.4pt" valign="top" width="149">
        <p class="MsoNormal"><o:p> </o:p></p>
      </td>
      <td
        style="width:186.25pt;border-top:none;border-left:none;border-bottom:solid windowtext 1.0pt;border-right:solid windowtext 1.0pt;padding:0cm
        5.4pt 0cm 5.4pt" valign="top" width="248">
        <p class="MsoNormal"><o:p> <br>
          </o:p></p>
      </td>
      <td
        style="width:6.0cm;border-top:none;border-left:none;border-bottom:solid
        windowtext 1.0pt;border-right:solid windowtext 1.0pt;padding:0cm
        5.4pt 0cm 5.4pt" valign="top" width="227">
        <p class="MsoNormal"><o:p> </o:p></p>
      </td>
      <td
        style="width:92.15pt;border-top:none;border-left:none;border-bottom:solid windowtext 1.0pt;border-right:solid windowtext 1.0pt;padding:0cm
        5.4pt 0cm 5.4pt" valign="top" width="123">
        <p class="MsoNormal"><o:p> </o:p></p>
         </td>
    </tr>
  </tbody>
</table>
<p class="MsoNormal"><u><o:p><span style="text-decoration:none"><br>
        <br>
      </span></o:p></u></p>
<p class="MsoListParagraph" style="text-indent:-18.0pt;mso-list:l0
  level1 lfo1"><span style="mso-list:Ignore">7.<span style="font:7.0pt
      &quot;Times New Roman&quot;">       </span></span><b><u>Sauvegardes SnapMirror</u></b><u><o:p></o:p></u></p>
<p class="MsoNormal"><o:p> </o:p></p>
<table class="MsoTableGrid" style="border-collapse:collapse;border:none"
  border="1" cellpadding="0" cellspacing="0">
  <tbody>
    <tr>
      <td style="width:127.2pt;border:solid windowtext
        1.0pt;background:#4F81BD;padding:0cm 5.4pt 0cm 5.4pt"
        valign="top" width="170">
        <p class="MsoNormal" style="text-align:center" align="center"><small><b>Nom
              de serveur impacté</b><b><o:p></o:p></b></small></p>
      </td>
      <td style="width:111.4pt;border:solid windowtext
        1.0pt;border-left:none;background:#4F81BD;padding:0cm 5.4pt 0cm
        5.4pt" valign="top" width="149">
        <p class="MsoNormal" style="text-align:center" align="center"><small><b>Nom
              de la tâche</b><b><o:p></o:p></b></small></p>
      </td>
      <td style="width:186.25pt;border:solid windowtext
        1.0pt;border-left:none;background:#4F81BD;padding:0cm 5.4pt 0cm
        5.4pt" valign="top" width="248">
        <p class="MsoNormal" style="text-align:center" align="center"><small><b>Erreur
              remarquée</b><b><o:p></o:p></b></small></p>
      </td>
      <td style="width:6.0cm;border:solid windowtext
        1.0pt;border-left:none;background:#4F81BD;padding:0cm 5.4pt 0cm
        5.4pt" valign="top" width="227">
        <p class="MsoNormal" style="text-align:center" align="center"><small><b>Solution
              apportée</b><b><o:p></o:p></b></small></p>
      </td>
      <td style="width:92.15pt;border:solid windowtext
       1.0pt;border-left:none;background:#4F81BD;padding:0cm 5.4pt 0cm
        5.4pt" valign="top" width="123">
        <p class="MsoNormal" style="text-align:center" align="center"><small><b>N°
              de Gipsi</b><b><o:p></o:p></b></small></p>
      </td>
    </tr>
    <tr>
      <td style="width:127.2pt;border:solid windowtext
        1.0pt;border-top:none;padding:0cm 5.4pt 0cm 5.4pt" valign="top"
        width="170">
        <p class="MsoNormal"><o:p>    <br>
          </o:p></p>
      </td>
      <td
        style="width:111.4pt;border-top:none;border-left:none;border-bottom:solid windowtext 1.0pt;border-right:solid windowtext 1.0pt;padding:0cm
        5.4pt 0cm 5.4pt" valign="top" width="149">
        <p class="MsoNormal"><o:p> </o:p></p>
      </td>
      <td
        style="width:186.25pt;border-top:none;border-left:none;border-bottom:solid windowtext 1.0pt;border-right:solid windowtext 1.0pt;padding:0cm
        5.4pt 0cm 5.4pt" valign="top" width="248">
        <p class="MsoNormal"><o:p> <br>
          </o:p></p>
      </td>
      <td
        style="width:6.0cm;border-top:none;border-left:none;border-bottom:solid
        windowtext 1.0pt;border-right:solid windowtext 1.0pt;padding:0cm
        5.4pt 0cm 5.4pt" valign="top" width="227">
        <p class="MsoNormal"><o:p> </o:p></p>
</td>
      <td
        style="width:92.15pt;border-top:none;border-left:none;border-bottom:solid windowtext 1.0pt;border-right:solid windowtext 1.0pt;padding:0cm
        5.4pt 0cm 5.4pt" valign="top" width="123">
        <p class="MsoNormal"><o:p> </o:p></p>
      </td>
    </tr>
  </tbody>
</table>
<p class="MsoNormal"><o:p> <br>
    <br>
  </o:p></p>
<p class="MsoListParagraph" style="text-indent:-18.0pt;mso-list:l0
  level1 lfo1"><b><span style="mso-list:Ignore">8.<span
        style="font:7.0pt &quot;Times New Roman&quot;">       </span></span></b><b><u>Tache de robocopy<o:p></o:p></u></b></p>
<p class="MsoNormal"><o:p> </o:p></p>
<table class="MsoTableGrid" style="border-collapse:collapse;border:none"
  border="1" cellpadding="0" cellspacing="0">
  <tbody>
    <tr>
      <td style="width:127.2pt;border:solid windowtext
        1.0pt;background:#4F81BD;padding:0cm 5.4pt 0cm 5.4pt"
        valign="top" width="170">
        <p class="MsoNormal" style="text-align:center" align="center"><small><b>Nom
              de serveur impacté</b><b><o:p></o:p></b></small></p>
               </td>
      <td style="width:111.4pt;border:solid windowtext
        1.0pt;border-left:none;background:#4F81BD;padding:0cm 5.4pt 0cm
        5.4pt" valign="top" width="149">
        <p class="MsoNormal" style="text-align:center" align="center"><small><b>Nom
              de la tâche</b><b><o:p></o:p></b></small></p>
      </td>
      <td style="width:186.25pt;border:solid windowtext
        1.0pt;border-left:none;background:#4F81BD;padding:0cm 5.4pt 0cm
        5.4pt" valign="top" width="248">
        <p class="MsoNormal" style="text-align:center" align="center"><small><b>Erreur
              remarquée</b><b><o:p></o:p></b></small></p>
      </td>
      <td style="width:6.0cm;border:solid windowtext
        1.0pt;border-left:none;background:#4F81BD;padding:0cm 5.4pt 0cm
        5.4pt" valign="top" width="227">
        <p class="MsoNormal" style="text-align:center" align="center"><small><b>Solution
              apportée</b><b><o:p></o:p></b></small></p>
      </td>
      <td style="width:92.15pt;border:solid windowtext
        1.0pt;border-left:none;background:#4F81BD;padding:0cm 5.4pt 0cm
        5.4pt" valign="top" width="123">
        <p class="MsoNormal" style="text-align:center" align="center"><small><b>N°
              de Gipsi</b><b><o:p></o:p></b></small></p>
      </td>
    </tr>
    <tr>
      <td style="width:127.2pt;border:solid windowtext
        1.0pt;border-top:none;padding:0cm 5.4pt 0cm 5.4pt" valign="top"
        width="170">
        <p class="MsoNormal"><o:p> </o:p></p>
      </td>
      <td
        style="width:111.4pt;border-top:none;border-left:none;border-bottom:solid windowtext 1.0pt;border-right:solid windowtext 1.0pt;padding:0cm
        5.4pt 0cm 5.4pt" valign="top" width="149">
        <p class="MsoNormal"><o:p> </o:p></p>
      </td>
      <td
        style="width:186.25pt;border-top:none;border-left:none;border-bottom:solid windowtext 1.0pt;border-right:solid windowtext 1.0pt;padding:0cm
        5.4pt 0cm 5.4pt" valign="top" width="248">
         <p class="MsoNormal"><o:p> </o:p></p>
      </td>
      <td
        style="width:6.0cm;border-top:none;border-left:none;border-bottom:solid
        windowtext 1.0pt;border-right:solid windowtext 1.0pt;padding:0cm
        5.4pt 0cm 5.4pt" valign="top" width="227">
        <p class="MsoNormal"><o:p> </o:p></p>
      </td>
      <td
        style="width:92.15pt;border-top:none;border-left:none;border-bottom:solid  windowtext 1.0pt;border-right:solid windowtext 1.0pt;padding:0cm
        5.4pt 0cm 5.4pt" valign="top" width="123">
        <p class="MsoNormal"><o:p> </o:p></p>
      </td>
    </tr>

  </tbody>
</table>
<p class="MsoNormal"><o:p><br>
  </o:p></p>
<p class="MsoNormal"><br>
</p>
<p class="MsoListParagraph" style="text-indent:-18.0pt;mso-list:l0
  level1 lfo1"><b><span style="mso-list:Ignore">8.<span
        style="font:7.0pt &quot;Times New Roman&quot;"> </span></span></b><b><u>Etats

      des sauvegardes DEND<br>
    </u></b></p>
<ul>
  <li><b>GNOME =&gt; <font color="#003300">OK </font></b><u><b><br>
      </b></u></li>
  <li><b>PROTEGER =&gt; </b><b><font color="#003300">OK </font></b></li>
</ul>
<p><br>
</p>
<p class="MsoNormal"><o:p> </o:p></p>
<table class="MsoTableGrid" style="border-collapse:collapse;border:none"
  border="1" cellpadding="0" cellspacing="0">
  <tbody>
    <tr>
      <td style="width:127.2pt;border:solid windowtext
        1.0pt;background:#4F81BD;padding:0cm 5.4pt 0cm 5.4pt"
        valign="top" width="170">
        <p class="MsoNormal" style="text-align:center" align="center"><small><b>Nom
              de serveur impacté</b><b><o:p></o:p></b></small></p>
      </td>
      <td style="width:111.4pt;border:solid windowtext
        1.0pt;border-left:none;background:#4F81BD;padding:0cm 5.4pt 0cm
        5.4pt" valign="top" width="149">
        <p class="MsoNormal" style="text-align:center" align="center"><small><b>Nom
              de la tâche</b><b><o:p></o:p></b></small></p>
      </td>
      <td style="width:186.25pt;border:solid windowtext
        1.0pt;border-left:none;background:#4F81BD;padding:0cm 5.4pt 0cm
        5.4pt" valign="top" width="248">
        <p class="MsoNormal" style="text-align:center" align="center"><small><b>Erreur
              remarquée</b><b><o:p></o:p></b></small></p>
      </td>
      <td style="width:6.0cm;border:solid windowtext
        1.0pt;border-left:none;background:#4F81BD;padding:0cm 5.4pt 0cm
        5.4pt" valign="top" width="227">
          <p class="MsoNormal" style="text-align:center" align="center"><small><b>Solution
              apportée</b><b><o:p></o:p></b></small></p>
      </td>
      <td style="width:92.15pt;border:solid windowtext
        1.0pt;border-left:none;background:#4F81BD;padding:0cm 5.4pt 0cm
        5.4pt" valign="top" width="123">
        <p class="MsoNormal" style="text-align:center" align="center"><small><b>N°
              de Gipsi</b><b><o:p></o:p></b></small></p>
      </td>
    </tr>
    <tr>
      <td style="width:127.2pt;border:solid windowtext
        1.0pt;border-top:none;padding:0cm 5.4pt 0cm 5.4pt" valign="top"
        width="170">
        <p class="MsoNormal"><o:p> </o:p></p>
        <br>
      </td>
      <td
        style="width:111.4pt;border-top:none;border-left:none;border-bottom:solid

        windowtext 1.0pt;border-right:solid windowtext 1.0pt;padding:0cm
        5.4pt 0cm 5.4pt" valign="top" width="149">
        <p class="MsoNormal"><o:p> </o:p></p>
        <br>
      </td>
      <td
        style="width:186.25pt;border-top:none;border-left:none;border-bottom:solid

        windowtext 1.0pt;border-right:solid windowtext 1.0pt;padding:0cm
        5.4pt 0cm 5.4pt" valign="top" width="248">
        <p class="MsoNormal"><o:p> </o:p></p>
        <br>
      </td>
      <td
        style="width:6.0cm;border-top:none;border-left:none;border-bottom:solid
        windowtext 1.0pt;border-right:solid windowtext 1.0pt;padding:0cm
        5.4pt 0cm 5.4pt" valign="top" width="227">
        <p class="MsoNormal"><o:p> </o:p></p>
        <br>
      </td>
      <td
        style="width:92.15pt;border-top:none;border-left:none;border-bottom:solid

        windowtext 1.0pt;border-right:solid windowtext 1.0pt;padding:0cm
        5.4pt 0cm 5.4pt" valign="top" width="123">
        <p class="MsoNormal"><o:p> </o:p></p>
      </td>
    </tr>






  </tbody>
</table>
HTML
close HTMLOUT;


        ### Create the multipart container
        $msg = MIME::Lite->new (
                From => $src_mail,
                To => $dst_mail,
                Subject => 'Vérification des sauvegardes du '. $start_time_text,
                Type => 'text/html',
                Path => $htmlfile,
                Filename => $htmlfile
            ) or die "Error adding $htmlfile: $!\n";
                #Charset => 'UTF-8',
            #    ) or die "Error creating multipart container: $!\n";

                #Type =>'multipart/mixed'


#       #Add the text message part
#       $msg->attach (
#               Type => 'text/html',
#               Charset => 'ISO8859-1', 
#               Data => "\n\n<u><h4>Verification du nombre de cartouches spare</h4></u>\n\n" 
#           ) or die "Error adding the text message part: $!\n";
#
        ### Add the attachment
                #Charset => 'ISO8859-1', 
##      $msg->attach (
##              Type => 'text/html',
##              Charset => 'utf-8',
##                      Path => $htmlfile,
##              Filename => $htmlfile,
##              Disposition => 'inline'
##          ) or die "Error adding $htmlfile: $!\n";
##
        ### Send the Message
        MIME::Lite->send('smtp', 'localhost', Timeout=>60);
        $msg->send;

        #unlink $htmlfile; 

}

printf "%s\n", $epoch_now;

our $start_time = &get_start_time( $epoch_now);
our $end_time = &get_end_time( $epoch_now);
our $start_time_text = &convert_epoch_2_date( $start_time );
our $end_time_text = &convert_epoch_2_date( $end_time );
our $start_time_text_header = &convert_epoch_2_date2( $start_time );
our $end_time_text_header = &convert_epoch_2_date2( $end_time );
our $start_time_text_US = &convert_epoch_2_US_date( $start_time );

#printf STDERR "get_jobs_all_sites %s\n", $start_time_text_US; 
&get_jobs_all_sites( $start_time_text_US );

our $rah_stats = &siteStats( \@jobs );


my $ra_drives = &getDriveStatus(\%h_masters_medias);


&txtOutput( \@jobs, $rah_stats, $ra_drives ) ;


&send_mail( \@jobs, $rah_stats, $ra_drives ) ;
        

