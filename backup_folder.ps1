$repsource = "C:\SOURCE"
$repdest = "C:\Destination_test"
$logfile ="C:\resultat.log"

robocopy $repsource $repdest /E /MIR /R:2 /ETA /LOG:$logfile
