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
        
