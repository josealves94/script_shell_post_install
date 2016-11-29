#!/bin/bash

#####################################################################
# Auteur : José Alves
# Date : 08/09/2016
#
#
# Usage : ./check_elsaticsearch_health HOSt_ADRESS
#  ex: ./check_elasticsearch_health localhost
#
#####################################################################

#Memo for Nagios outputs
#STATE_OK=0
#STATE_WARNING=1
#STATE_CRITICAL=2
#STATE_UNKNOWN=3

type curl >/dev/null 2>&1 || { echo >&2 "This plugin require curl but it's not installed."; exit 3; }

HOST=$*

#STATUS=$(/usr/bin/curl -s $HOST/_cluster/health?pretty|grep status|awk '{print $3}'|cut -d\" -f2)
STATUS=$(/usr/bin/curl --insecure -s $HOST/_cluster/health?pretty|grep status|awk '{print $3}'|cut -d\" -f2)

if [[ ${STATUS} && "${STATUS}" != "green" ]]; then
echo "CRITICAL - Status is ${STATUS}"
exit 2
fi

if [[ "${STATUS}" == "green" ]]; then
echo "OK - Status is ${STATUS}"
exit 0
fi

echo "UNKNOW - No data were returned by elastisearch on host ${HOST}"
exit 3
