#!/usr/bin/perl -w 

######################################################################################################################################
##
##  Description : Script qui afiche l'activité nfs des utilisateurs
##
##  Date : 21/05/2014
##
##  Auteurs : GBO et JAL
##
##
#####################################################################################################################################

use Data::Dumper; 

my @result = ` lsof -N -a` ;

my @list_open_files; 

#while()
#{
foreach my $line (@result) 
{


	my @extract = split( " ", $line ); 
	

	if ( $extract[9] =~ m/TMPCALCUL/i  ||  $extract[9] =~ m/irsn/i  ||  $extract[9] =~ m/unixfont/i  ||  $extract[9] =~ m/mejanne/i  ||  $extract[9] =~ m/st3c/i   ||  $extract[9] =~ m/hydrogene/i  ||  $extract[9] =~ m/malibu1/i)
	{

		push @list_open_files, { 
						"Path" => $extract[8], 
						"Prog" => $extract[0], 
						"Pid" => $extract[1], 
						"User" => $extract[2] 
					};


	}



}


#print Dumper(@list_open_files); 

my $logfile="log_user.txt";

foreach my $rh_output ( sort{ $a->{'User'} cmp  $b->{'User'} }  @list_open_files ) 
{

	printf "%s\t%s\t%s\t%s\n", $rh_output->{'User'}, $rh_output->{'Prog'}, $rh_output->{'Pid'}, $rh_output->{'Path'}; 
        
        open (FH, ">>", "$logfile") or die "imposible d'ouvrir le fichier : $! "; 
        printf FH "%s\t%s\t%s\t%s\n", $rh_output->{'User'}, $rh_output->{'Prog'}, $rh_output->{'Pid'}, $rh_output->{'Path'};
        

}

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
my $dateUs =  $mday."/".($mon+1)."/".(1900+$year);
printf FH "================ Le fichier de logs nfs utilisateurs a été executé le $dateUs à $hour:$min ================\n\n";

close (FH);

