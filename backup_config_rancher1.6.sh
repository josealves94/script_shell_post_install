#!/bin/sh
##############################
# description : run rancher export config with Rancher API - redmine (35922)
# Author : José Alves
# Date : 17/08/2020
# Version : 0.1
# Version : 0.2  transform json stack files to yaml 02/09/2020
##############################

RANCHER_ACCESS_KEY=""
RANCHER_SECRET_KEY=""
ERROR=0
DATEOFDAY=$(date +%F)
BACKUP="/opt/backup/backup_rancher_conf_${DATEOFDAY}.tgz"

MAILTO='<alves@intechinfo.fr>'
# Error Function

# Mail error
SUBJECT="[$(echo ${HOSTNAME} | tr '[:lower:]' '[:upper:]')] $(basename $0) KO !"
function merror() {
  (
  echo "From: webexp@${HOSTNAME}"
  echo "To: ${MAILTO}"
  echo "Subject: ${SUBJECT}"
  echo ""
  date
  echo $1
  ) | /usr/sbin/sendmail -t
  exit 1;
}




# Get Environment

TMPDIR=$(mktemp -d)

for RANCHER_ENV in 1bx 1axx 1axxx; do


EXPORTDIR="${TMPDIR}/${RANCHER_ENV}"
mkdir ${EXPORTDIR}

# display stack names by env
# echo -e " Stacks for environment infrastructure ${RANCHER_ENV}"
RANCHER_STACK_INF=$(curl -s -u "${RANCHER_ACCESS_KEY}:${RANCHER_SECRET_KEY}" \
-X GET \
-H 'Accept: application/json' \
-H 'Content-Type: application/json' \
"http://rancher.pvcp.intra:8080/v2-beta/projects/${RANCHER_ENV}/stacks/" | jq -r .data[].id )
#echo -e "######################################"

# display rancher services per stack
for service_inf in ${RANCHER_STACK_INF} ; do

#echo  -e "\n### Services for stack ${service_inf}"
if RANCHER_SERVICE_INF=$(curl -s -u "${RANCHER_ACCESS_KEY}:${RANCHER_SECRET_KEY}" \
-X GET \
-H 'Accept: application/json' \
-H 'Content-Type: application/json' \
"http://rancher.pvcp.intra:8080/v2-beta/projects/${RANCHER_ENV}/stacks/${service_inf}/" | jq -er  '.serviceIds | @csv ' ) ; then
# run rancher export  config by service group in each stack
read -ra serv <<< "$RANCHER_SERVICE_INF"
for i in "${serv[@]}"; do
curl -s -u "${RANCHER_ACCESS_KEY}:${RANCHER_SECRET_KEY}" \
-X POST \
-H 'Accept: application/json' \
-H 'Content-Type: application/json' \
-d '{"serviceIds":['$i']}' \
"http://rancher.pvcp.intra:8080/v2-beta/projects/${RANCHER_ENV}/stacks/${service_inf}/?action=exportconfig" | jq '.' > ${EXPORTDIR}/${service_inf}.json
        #echo -n "$i"
# create new line after pattern "\r\n"
sed  -i 's/\\r\\n/\n&/g' ${stack_dir}/${service_inf}.json
# remove "\r" and "\n" from json file
sed  -i  's/\\r\\n//g'   ${stack_dir}/${service_inf}.json
# clean source file 6 lines from the beginning
sed  -i '1,6d' ${stack_dir}/${service_inf}.json
# remove tag dockercomposeConfig
sed -i 's/"dockerComposeConfig": "//g' ${stack_dir}/${service_inf}.json
# remove comma before tag rancherComposeConfig
sed -i 's/",//g' ${stack_dir}/${service_inf}.json
# remove tag rancherComposeConfig
sed -i 's/"rancherComposeConfig": "//g' ${stack_dir}/${service_inf}.json
# remove the 2 last lines
sed -i '$ d' ${stack_dir}/${service_inf}.json && sed -i '$ d' ${stack_dir}/${service_inf}.json
# split files into 2 parts based on  patterns version
cd ${stack_dir}
/bin/csplit ${service_inf}.json -s --elide-empty-files --prefix='docker-compose'  --suffix-format='%d.yml'  "/version: '2'/" "/version: '2'/"

done <<< "$RANCHER_SERVICE_INF"

else

 echo "Failed to parse JSON, or got false/null"
 ERROR=1
fi


done

done

cd $TMPDIR
#pwd
tar cvzf ${BACKUP} . >/dev/null
cd ~ && rm -rf $TMPDIR

# Delete older backup (Decomment if ok)
/bin/find /opt/backup/ -type f -name "backup_rancher_conf_*.tgz" -mtime +1 -delete

# check error
if [ $( tar tzvf ${BACKUP}  |grep -c ".yml" ) -eq 0 ] ; then merror "Export Rancher KO"; fi
# if [ $( tar tzvf ${BACKUP} | grep -c '*.json' ) -eq 0 -o ${ERROR} -ne 0 ] ; then merror "Export Rancher KO"; fi
#tar tzvf /opt/backup/backup_rancher_conf_2020-08-19.tgz  --wildcards "*.json"
