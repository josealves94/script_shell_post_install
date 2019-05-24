#!/bin/bash
#
# Author : José Alves
# Date : 21/05/2019
# Descirption : start file upload to azure storage account
#
################################################

USER="root"
PASS="xxxxx" # db password
dateduj=$(date +%Y%m%d)
FILE_DMP="/mnt/ssddump/starsd/stars_${dateduj}.csv" # path to csv file
RG="RG_PROD" # ressource rgoup 
SUB="" # <-- subscription id from storage account
SACCOUNTNAME="storage" #storage account name
ACCOUNTKEY=$(az storage account keys list --resource-group "$RG" --account-name "$SACCOUNTNAME" --subscription "$SUB" --query "[0].value" | tr -d '"')
#FILE_DMP="/root/export_data_azure_test.csv"
DB="coyote"
#HOST="mysql-coyote-poi.preprod.coyote.local"
HOST="localhost"

if [ ! -f "$FILE_DMP" ]; then
/usr/bin/mysql -h $HOST -D $DB -u $USER -p$PASS -e  "SELECT ID_COYOTE, INDICE_CONFIANCE INTO OUTFILE '${FILE_DMP}' FIELDS TERMINATED BY ';' ENCLOSED BY '\"' LINES TERMINATED BY '\n' FROM coyote.COYOTE_STAT_UTILISATEUR;"

else

 echo "Le fichier $FILE_DMP est déjà présent"
 exit 1

fi
#############
# A rajouter si besoin de copier les fichiers sur Azure
if [  "$FILE_DMP" ]; then

echo "Copie du fichier vers Azure"
/usr/bin/az storage file upload --account-name "$SACCOUNTNAME" --share-name "starsd" --source "$FILE_DMP" --path "" --account-key "$ACCOUNTKEY" --subscription "$SUB"
echo "Fichier copié vers Azure"


else
  echo "Le fichier $FILE_DMP n'est pas présent"
fi
