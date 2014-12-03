#!/usr/bin/perl -w
################################################################################################################
#
# Description : script qui verifie le quota utilisateur 
# 
# Date : 13/08/2014
# Auteur : JAL
# Modifications :
# - 21/08/2014 : verifie si la chaine de caractères fournie par l'utilisateur est vide
# - 22/08/2014 : ajout de la fonction check_quota (modification à ajouter par la suite
# - 25/08/2014 : choix du chemin de quota
# - 26/08/2014 : Ajout de la fonction de verification de quota
# - 28/08/2014 : Modification/ajout des 2 fonctions pour lire ecrire dans les fichiers recus en entree
# - 02/09/2014 : Modification de la regex
##############################################################################################################

use Data::Dumper;
use Switch;
use strict;

# fonction pour lire dans un fichier
#
sub read_file {
    my ($filename) = @_;
 
    open my $in, '<:encoding(UTF-8)', $filename or die "impossible d'ouvrir '$filename' pour lire $!";
    local $/ = undef;
    my $all = <$in>;
    close $in;
 
    return $all;
}

#
# fonction pour ecrire dans un fichier

sub write_file{
 my ($filename, $content) = @_;
 open my $out, '>:encoding(UTF-8)', $filename or die "impossible d'ouvrir '$filename' pour ecrire $!";
 print $out $content;
 close $out;
 return;
}

# fonction pour verifier le quota
sub check_quota()
{
my $qt_file = "quotas";
print "*********************************************\n";
print "*Verification du quota sur le filer astou201*\n";
print "* Veuillez saisir le nom de l'utilisateur   *\n";
print "*********************************************\n";
my $line = readline(*STDIN);
chomp($line);
#my@command = `/usr/bin/rsh filer1  quota report |/bin/grep -i $line` ;

#print "$line\n";
#my @command = `/usr/bin/rsh filer1  quota report |grep -i $line` ;

# verifie si en entree on recoit un espace vide ou rien d'autre
my $data = read_file($qt_file);
 if ($line !~ /^[a-z-A-Z]*$/)
 {
  print "Veuillez indiquer un nom d'utilisateur correct\n";
 #  exit($returnc >> 8);
 }
 else
 {
 my @command = `/usr/bin/rsh filer1  quota report |/bin/grep -i $line` ; 
 my @quota_report;

  foreach my $ligne (@command)
  {
	my @extract = split(" ", $ligne);


	if ( $extract[0] =~ m/user/i )
	{
		push @quota_report, {
					"Utilisateur" => $extract[1],
					"Volume" => $extract[2],
 					"Qtree" => $extract[3],
					"Quota utilisé" => $extract[4],
					"Limite quota" => $extract[5],
					
				
				};

	}

 }

#print Dumper(@quota_report);
 printf " Utilisateur\tVolume\tQTree\tQuota utilisé\tLimite quota\n";
 printf " -----------\t------\t-----\t-------------\t------------\n";
 foreach my $qt_output (sort{ $a->{'Utilisateur'} cmp $b->{'Utilisateur'} } @quota_report)
 {
 	printf "%s\t%s\t%s\t%s\t%s\n", $qt_output->{'Utilisateur'}, $qt_output->{'Volume'}, $qt_output->{'Qtree'}, $qt_output->{'Quota utilisé'}, $qt_output->{'Limite quota'};	
 }
}
}



# fonction pour modifier les  quotas
sub mod_quota()
{
#my $qt_file = "quotas";
print "*********************************************\n";
print "*Modification du quota sur le filer astou201*\n";
print "* Veuillez saisir le nom de l'utilisateur   *\n";
print "*********************************************\n";
my $lnm = readline(*STDIN);
chomp($lnm);
 #if ($lign =~ /^ *$/){
 if ($lnm !~ /^[a-z-A-Z]*$/){
	 print "Veuillez indiquer un nom d'utilisateur \n";

  }
  else
  {
  # test avec fichier de quota de test dans le repertoire courant - changer le chemin vers /filers/astou201/volroot/etc/quotas une fois sur du fonctionnement
    my @cmd = `cat /root/admin/scripts/JAL/quota_filers/quotas |grep -i $lnm`;
     my @quota_report_mod;
     my $qt_file = "quotas";
# backup du fichier de quotas
print "==========\tSauvegarde du fichier de quotas\t==========\n";
 system("cp quotas quotas.`date +%Y%m%d.BAK`");
print "==========\tSauvegarde du fichier terminée\t==========\n";
	foreach my $ln (@cmd)
	{
		my @extract = split(" ", $ln);

	# si volume unix on modifie sinon si volume pst on modifie sinon si volume windows volhome on modifie etc 
	print "Plusieurs volumes sont présents (volunix) , (volpst) et (volhome) \n";
	print " Veuillez choisir le volume en fonction de votre demande gipsi: \n";
	print "Taper (v) pour volunix ou taper (p) pour volpst ou taper (u) pour volhome \n";
	
	my $vol_input = readline(*STDIN);
	chomp($vol_input);
	if ($extract[1] =~ m/volunix/i && $vol_input =~ /^[vV]$/)
	{	
		
		push @quota_report_mod, {
					"Utilisateur" => $extract[0],
					"Volume" => $extract[1],
					"quota" => $extract[2]
					};
		print "Modification du quota  sur le volume volunix (unix)\n";
		print "Veuillez indiquez le quota sous la forme suivante \n";
		print "Par exemple en Gigaoctet : 20G pour gigaoctet	  \n";
		print "Par exemple en Megaoctect : 40000M en Megaoctet	  \n";
		my $qt_input = readline(*STDIN);
		#print $extract[2];
		 if ($qt_input !~ /^[0-9]*[MG]$/) {
         		print "Veuillez indiquer un quota correct\n";
		}
		else
		{
		 my $data = read_file($qt_file);
		 $data =~ s/$extract[2]/$qt_input/g;
		 write_file($qt_file, $data);
		print "redimensionnement du volume volunix effectué ...\n";
		 # resize du volume sur le filer
		 # system("/usr/bin/rsh filer1 quota resize volunix");
		 exit;
		}	
	}
	elsif ($extract[1] =~ m/volpst/i && $vol_input =~ /^[pP]$/)
	{
		push @quota_report_mod, {
					 "Utilisateur" => $extract[0],
                                        "Volume" => $extract[1],
                                        "quota" => $extract[2]
					};
		print "modification du quota sur le volume volpst (mail)\n";
		print "Veuillez indiquez le quota sous la forme suivante \n";
                print "Par exemple en Gigaoctet : 20G pour gigaoctet     \n";
                print "Par exemple en Megaoctect : 40000M en Megaoctet   \n";
		#print "Votre quota actuel :\n";
                #print $extract[2];  
		my $qt_input2 = readline(*STDIN);
		  #chomp($qt_input2);
			#if ($qt_input2 =~ /^ *$/){ 
			#if ($qt_input2 !~ /^[0-9][a-zA-Z]{1,1}+$/) {
			 if ($qt_input2 !~ /^[0-9]*[MG]$/){
                        	print "Veuillez indiquer un quota correct\n";
                	}
                	else
                	{
			my $data2 = read_file($qt_file);
			$data2 =~ s/$extract[2]/$qt_input2/g;
			write_file($qt_file, $data2);
			  # resize du volume sur le filer
			  #  system("/usr/bin/rsh filer1 quota resize volpst");
			print "redimensionnement du volume volpst effectué ...\n";
			exit;
			}
	
	}
	elsif ($extract[1] =~ m/volhome/i &&  $vol_input =~ /^[uU]$/)
	{
		 push @quota_report_mod, {
                                         "Utilisateur" => $extract[0],
                                        "Volume" => $extract[1],
                                        "quota" => $extract[2]
                                        };
	print "modification du quota Windows volhome\n";
	print "Veuillez indiquez le quota sous la forme suivante \n";
        print "Par exemple en Gigaoctet : 20G pour gigaoctet     \n";
        print "Par exemple en Megaoctect : 40000M en Megaoctet   \n";
	  my $qt_input3 = readline(*STDIN);

	if ($qt_input3 !~ /^[0-9]*[MG]$/) {
                        print "Veuillez indiquer un quota correct\n";
                }
		else
		{
	 	my $data3 = read_file($qt_file);
         	$data3 =~ s/$extract[2]/$qt_input3/g;
		write_file($qt_file, $data3);
		# resize du volume sur le filer
		#  system("/usr/bin/rsh filer1 quota resize volhome");
		print "redimensionnement du volume volhome windows effectuée ...\n";
		exit;
		}
	}
	elsif (defined($extract[1]))#=~ /^ *$/)
	{
	  print "Le volume choisi pour cet utilisateur n'existe pas\n";
	  exit;
	}

    	
   }


#print Dumper(@quota_report_mod);

}


}

# menu des choix
print "******************************************************************	*\n";
print "*Verification/modification  du quota sur le filer astou201		*\n";
print "* Pour modifier le quota taper (m)			         	*\n";
print "* Pour verifier le quota taper (c)			   		*\n";
print "* Pour quitter  taper (q)                		 	 	*\n";
print "******************************************************************	*\n";
my $lineg = readline(*STDIN);
chomp ($lineg);

switch ($lineg) {
 case "c" {
	   &check_quota();
	  }
 case "m" {
 	   &mod_quota(); 
	  }
 case "q" {
	last;
	   #exit 0;
	  }
 case /.*/ {
	   exit 0;
	   }
}
