#!/bin/bash
##########################
#   STATICS VARIABLES    #
##########################

red='\033[01;31m'
blue='\033[01;34m'
norm='\033[00m'

pathbck='/mnt/hamster/nba'
date=$(date +'%Y%m%d')
dir='dmp'
path="${pathbck}/${dir}_${date}"
mail="toto@toto.com"


##########################
#  CREDENTIAL VARIABLES  #
##########################
user='coyotadmin'
passwd='*******'
db='coyote'
#static_options='--skip-tz-utc'
static_options=''
mysqldump="mysqldump -u ${user} -p${passwd} ${static_options} ${db}"
mysql="mysql -u ${user} -p${passwd} -D ${db}"
compress='lbzip2 -n12'

if [[ $# -eq 0 ]]
        then
        echo -e  "\n${red}  USAGE: $0 <table0> ... <tableN> ${norm}\n"
        exit 1
        else
        tables=$*
fi

if [[ ! -d ${path} ]]
        then
#echo   mkdir -p ${path}
        mkdir -p ${path}

fi

for t in ${tables}
        do
        requet="truncate table ${t};"
#echo   "${mysqldump} $t |${compress} > ${path}/${t}.dmp.sql.bz2 && ${mysql} -e "${requet}""
        ${mysqldump} $t |${compress} > ${path}/${t}.dmp.sql.bz2 && ${mysql} -vv -e "${requet}"
        mail -s "$(echo -e "HIPPO[1-2] : DUMP & SHRINK $t \nContent-Type: text/html")" $mail <<EOT
<h1 style="color:red"> Hippo[1-2]: Table $t had been TRUNCATE </h1>
<p>
$(date)<br><br>
${t} had been DUMP to spp-lbck001:${path}/${t}.dmp.sql.bz2 <br>
<h2 style="color:blue"> Hippo[1-2]: Free space: $(df -hP  |awk '$6 ~ /\/data$/{print $4}') </h2>
</p>

Regards, <br>
dump-and-drop-tables.sh script <br><br>

EOT

done
