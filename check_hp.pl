#! /usr/bin/perl -w
#
# check_hp - nagios plugin

use POSIX;
use strict;
use lib "/usr/local/nagios/libexec";
use utils qw($TIMEOUT %ERRORS &print_revision &support);

use Net::SNMP;
use Getopt::Long;
&Getopt::Long::config('bundling');

my $PROGNAME = "check_hp";
#my $REVISION = "$Rev: 8 $";
my $REVISION = " 8 ";
sub print_help ();
sub usage ();
sub process_arguments ();

my $DEBUG = 0;

my $timeout;
my $hostname;
my $session;
my $error;
my $response;
my $opt_h;
my $opt_V;
my $key;
my $lastc;
my $name;
my $status;
my $state = 'OK';
my $answer = "";
my $community = "public";
my $snmp_version = 1;
my $maxmsgsize = 1472; # Net::SNMP default is 1472
my ($seclevel, $authproto, $secname, $authpass, $privpass, $auth, $priv);
my $context = "";
my $port = 161;
my @snmpoids;
my $debug;
my $countComponents = 0;


# Compaq/HP system states

my %cpqGenericStates = (
        '1','other',
        '2','ok',
        '3','degraded',
        '4','failed');

my %cpqDaLogDrvStates = (
        '1','other',
        '2','ok',
        '3','failed',
        '4','unconfigured',
        '5','recovering',
        '6','readyForRebuild',
        '7','rebuilding',
        '8','wrongDrive',
        '9','badConnect',
        '10','overheating',
        '11','shutdown',
        '12','expanding',
        '13','notAvailable',
        '14','queuedForExpansion');

my %cpqDaPhyDrvStates = (
        '1','other',
        '2','ok',
        '3','failed',
        '4','predictiveFailure');

my %cpqDaPhyDrvSmartStates = (
        '1','other',
        '2','ok',
        '3','replaceDrive');

my %cpqSeCpuStates = (
        '1','unknown',
        '2','ok',
        '3','degraded',
        '4','failed',
        '5','disabled');

# Compaq/HP system OIDs (ascending numeric order)

my $cpqSeCpuStatus = '1.3.6.1.4.1.232.1.2.2.1.1.6';
my $cpqDaCntlrCondition = '1.3.6.1.4.1.232.3.2.2.1.1.6';
my $cpqDaLogDrvStatus = '1.3.6.1.4.1.232.3.2.3.1.1.4';
my $cpqDaLogDrvCondition = '1.3.6.1.4.1.232.3.2.3.1.1.11';
my $cpqDaPhyDrvStatus = '1.3.6.1.4.1.232.3.2.5.1.1.6';
my $cpqDaPhyDrvCondition = '1.3.6.1.4.1.232.3.2.5.1.1.37';
my $cpqDaPhyDrvSmartStatus = '1.3.6.1.4.1.232.3.2.5.1.1.57';
my $cpqHeThermalSystemFanStatus = '1.3.6.1.4.1.232.6.2.6.4';
my $cpqHeThermalCpuFanStatus = '1.3.6.1.4.1.232.6.2.6.5';
my $cpqHeFltTolFanCondition = '1.3.6.1.4.1.232.6.2.6.7.1.9';
my $cpqHeTemperatureCondition = '1.3.6.1.4.1.232.6.2.6.8.1.6';
my $cpqHeFltTolPwrSupplyCondition = '1.3.6.1.4.1.232.6.2.9.1';
my $cpqHeFltTolPowerSupplyCondition = '1.3.6.1.4.1.232.6.2.9.3.1.4';
my $cpqRackCommonEnclosureFanCondition = '1.3.6.1.4.1.232.22.2.3.1.3.1.11';
my $cpqRackPowerSupplyCondition = '1.3.6.1.4.1.232.22.2.5.1.1.1.17';
my $cpqSiMemModuleECCStatus = '1.3.6.1.4.1.232.6.2.3.1.0';

my @cpqComponents = (
        $cpqSeCpuStatus,
        $cpqDaCntlrCondition,
        $cpqDaLogDrvStatus,
        $cpqDaLogDrvCondition,
        $cpqDaPhyDrvStatus,
        $cpqDaPhyDrvCondition,
        $cpqDaPhyDrvSmartStatus,
        $cpqHeThermalSystemFanStatus,
        $cpqHeThermalCpuFanStatus,
        $cpqHeFltTolFanCondition,
        $cpqHeTemperatureCondition,
        $cpqHeFltTolPwrSupplyCondition,
        $cpqHeFltTolPowerSupplyCondition,
        $cpqRackCommonEnclosureFanCondition,
        $cpqRackPowerSupplyCondition,
        $cpqSiMemModuleECCStatus);

my @cpqComponentName = (
        'cpqSeCpuStatus',
        'cpqDaCntlrCondition',
        'cpqDaLogDrvStatus',
        'cpqDaLogDrvCondition',
        'cpqDaPhyDrvStatus',
        'cpqDaPhyDrvCondition',
        'cpqDaPhyDrvSmartStatus',
        'cpqHeThermalCpuFanStatus',
        'cpqHeThermalSystemFanStatus',
        'cpqHeFltTolFanCondition',
        'cpqHeTemperatureCondition',
        'cpqHeFltTolPwrSupplyCondition',
        'cpqHeFltTolPowerSupplyCondition',
        'cpqRackCommonEnclosureFanCondition',
        'cpqRackPowerSupplyCondition',
        'Status_barette_memoire');

my @cpqComponentStateType = (
        'cpqSeCpuStates',
        'cpqGenericStates',
        'cpqDaLogDrvStates',
        'cpqGenericStates',
        'cpqDaPhyDrvStates',
        'cpqGenericStates',
        'cpqDaPhyDrvSmartStates',
        'cpqGenericStates',
        'cpqGenericStates',
        'cpqGenericStates',
        'cpqGenericStates',
        'cpqGenericStates',
        'cpqGenericStates',
        'cpqGenericStates',
        'cpqGenericStates',
        'cpqDaPhyDrvStates');

## Validate Arguments

process_arguments();


## Just in case of problems, let's not hang Nagios

$SIG{'ALRM'} = sub {
     print ("ERROR: No snmp response from $hostname (alarm)\n");
     exit $ERRORS{"UNKNOWN"};
};

alarm($timeout);


## Main function

print "Compaq/HP Agent Check:";
for (my $i = 0; $i < @cpqComponents; $i++ ) {
        fetch_status($cpqComponents[$i], $cpqComponentName[$i], $cpqComponentStateType[$i]);
}
if ($countComponents == 0) {
        $state = "UNKNOWN";
        print " no cpq/hp component found\n";
} elsif (!defined $debug && $state eq 'OK') {
        print " overall system state OK\n";
} else {
        print "\n";
}
exit $ERRORS{$state};

### subroutines

sub fetch_status {
        my $value;

        if (!defined ($response = $session->get_table($_[0]))) {
                # tree not found, ignore!
                return -1;
        }

        while ( ($key, $value) = each %{$response} ) {
                if ($value > 2) {
                        # 1 = other/unknow  => assume OK
                        # 2 = ok            => OK
                        # 3 = failure/worse => CRITICAL
                        $state = 'CRITICAL';
                }
                if (defined $debug || $value > 2) {
                        print " " . $_[1] . " (" . substr($key, length($_[0])+1) . ":";
                        if ($_[2] eq 'cpqGenericStates') { print $cpqGenericStates{$value} }
                        elsif ($_[2] eq 'cpqDaLogDrvStates') { print $cpqDaLogDrvStates{$value} }
                        elsif ($_[2] eq 'cpqDaPhyDrvStates') { print $cpqDaPhyDrvStates{$value} }
                        elsif ($_[2] eq 'cpqDaPhyDrvSmartStates') { print $cpqDaPhyDrvSmartStates{$value} }
                        elsif ($_[2] eq 'cpqSeCpuStates') { print $cpqSeCpuStates{$value} };
                        print ")";
                }
                $countComponents++;
        }
}

sub usage() {
  printf "\nMissing arguments!\n";
  printf "\n";
  printf "usage: \n";
  printf "check_hp -H <HOSTNAME> [-C <community>] [-d]\n";
  printf "Copyright (C) 2008 Guenther Mair\n";
  printf "\n\n";
  exit $ERRORS{"UNKNOWN"};
}

sub print_help() {
        printf "check_hp plugin for Nagios\n";
        printf "\nUsage:\n";
        printf "   -H (--hostname)   Hostname to query - (required)\n";
        printf "   -C (--community)  SNMP read community (defaults to public,\n";
        printf "                     used with SNMP v1 and v2c\n";
        printf "   -v (--snmp_version)  1 for SNMP v1 (default)\n";
        printf "                        2 for SNMP v2c\n";
        printf "                        SNMP v2c will use get_bulk for less overhead\n";
        printf "   -d (--debug)      debug / verbose mode (print checked details)\n";
        printf "   -L (--seclevel)   choice of \"noAuthNoPriv\", \"authNoPriv\", or     \"authPriv\"\n";
        printf "   -U (--secname)    username for SNMPv3 context\n";
        printf "   -A (--authpass)   authentication password (cleartext ascii or localized key\n";
        printf "                     in hex with 0x prefix generated by using   \"snmpkey\" utility\n";
        printf "                     auth password and authEngineID\n";
        printf "   -a (--authproto)  Authentication protocol ( MD5 or SHA1)\n";
        printf "   -X (--privpass)   privacy password (cleartext ascii or localized key\n";
        printf "                     in hex with 0x prefix generated by using   \"snmpkey\" utility\n";
        printf "                     privacy password and authEngineID\n";
        printf "   -p (--port)       SNMP port (default 161)\n";
        printf "   -M (--maxmsgsize) Max message size - usefull only for v1 or v2c\n";
        printf "   -t (--timeout)    seconds before the plugin times out (default=$TIMEOUT)\n";
        printf "   -V (--version)    Plugin version\n";
        printf "   -h (--help)       usage help \n\n";
        print_revision($PROGNAME, '$Revision: 8 $');

}

sub process_arguments() {
        $status = GetOptions(
                        "V"   => \$opt_V, "version"    => \$opt_V,
                        "h"   => \$opt_h, "help"       => \$opt_h,
                        "d"   => \$debug, "debug"      => \$debug,
                        "v=i" => \$snmp_version, "snmp_version=i"  => \$snmp_version,
                        "C=s" => \$community, "community=s" => \$community,
                        "L=s" => \$seclevel, "seclevel=s" => \$seclevel,
                        "a=s" => \$authproto, "authproto=s" => \$authproto,
                        "U=s" => \$secname,   "secname=s"   => \$secname,
                        "A=s" => \$authpass,  "authpass=s"  => \$authpass,
                        "X=s" => \$privpass,  "privpass=s"  => \$privpass,
                        "p=i" => \$port,  "port=i" =>\$port,
                        "H=s" => \$hostname, "hostname=s" => \$hostname,
                        "M=i" => \$maxmsgsize, "maxmsgsize=i" => \$maxmsgsize,
                        "t=i" => \$timeout,    "timeout=i" => \$timeout,
                        );

        if ($status == 0){
                print_help();
                exit $ERRORS{'OK'};
        }

        if ($opt_V) {
                print_revision($PROGNAME,'$Revision: 8 $');
                exit $ERRORS{'OK'};
        }

        if ($opt_h) {
                print_help();
                exit $ERRORS{'OK'};
        }

        if (! utils::is_hostname($hostname)){
                usage();
                exit $ERRORS{"UNKNOWN"};
        }

        unless (defined $timeout) {
                $timeout = $TIMEOUT;
        }
        
           if ($snmp_version =~ /3/ ) {
                # Must define a security level even though default is noAuthNoPriv
                # v3 requires a security username
                if (defined $seclevel  && defined $secname) {

                        # Must define a security level even though defualt is noAuthNoPriv
                        unless ( grep /^$seclevel$/, qw(noAuthNoPriv authNoPriv authPriv) ) {
                                usage();
                                exit $ERRORS{"UNKNOWN"};
                        }

                        # Authentication wanted
                        if ( $seclevel eq 'authNoPriv' || $seclevel eq 'authPriv' ) {

                                unless ( $authproto eq 'MD5' || $authproto eq 'SHA1' ) {
                                        usage();
                                        exit $ERRORS{"UNKNOWN"};
                                }

                                if ( !defined $authpass) {
                                        usage();
                                        exit $ERRORS{"UNKNOWN"};
                                }else{
                                        if ($authpass =~ /^0x/ ) {
                                                $auth = "-authkey => $authpass" ;
                                        }else{
                                                $auth = "-authpassword => $authpass";
                                        }
                                }

                        }

   # Privacy (DES encryption) wanted
                        if ($seclevel eq  'authPriv' ) {
                                if (! defined $privpass) {
                                        usage();
                                        exit $ERRORS{"UNKNOWN"};
                                }else{
                                        if ($privpass =~ /^0x/){
                                                $priv = "-privkey => $privpass";
                                        }else{
                                                $priv = "-privpassword => $privpass";
                                        }
                                }
                        }

                        # Context name defined or default

                }else {
                                        usage();
                                        exit $ERRORS{'UNKNOWN'}; ;
                }
        } # end snmpv3

   if ( $snmp_version =~ /[12]/ ) {
        ($session, $error) = Net::SNMP->session(
                        -hostname  => $hostname,
                        -community => $community,
                        -port      => $port,
                        -version        => $snmp_version,
                        -maxmsgsize => $maxmsgsize
                );

                if (!defined($session)) {
                        $state='UNKNOWN';
                        $answer=$error;
                        print ("$state: $answer");
                        exit $ERRORS{$state};
                }

        }elsif ( $snmp_version =~ /3/ ) {

                if ($seclevel eq 'noAuthNoPriv') {
                        ($session, $error) = Net::SNMP->session(
                                -hostname  => $hostname,
                                -port      => $port,
                                -version  => $snmp_version,
                                -username => $secname,
                        );

                }elsif ( $seclevel eq 'authNoPriv' ) {
                        ($session, $error) = Net::SNMP->session(
                                -hostname  => $hostname,
                                -port      => $port,
                                -version  => $snmp_version,
                                -username => $secname,
                                $auth,
                                -authprotocol => $authproto,
                        );
                }elsif ($seclevel eq 'authPriv' ) {
                        ($session, $error) = Net::SNMP->session(
                                -hostname  => $hostname,
                                -port      => $port,
                                -version  => $snmp_version,
                                -username => $secname,
                                $auth,
                                -authprotocol => $authproto,
                                $priv
                        );
                }
              if (!defined($session)) {
                                        $state='UNKNOWN';
                                        $answer=$error;
                                        print ("$state: $answer");
                                        exit $ERRORS{$state};
                }

        }else{
                $state='UNKNOWN';
                print ("$state: No support for SNMP v$snmp_version yet\n");
                exit $ERRORS{$state};
        }

}
## End validation
         
                
