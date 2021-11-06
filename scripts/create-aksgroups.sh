#!/bin/bash

while getopts a: option
do
 case "${option}"
 in
 # .github/variables/aad/aad.json
 a) aad=${OPTARG};;
 esac
done

echo ${aad:?"-a is not set"}

# store current value in IFS
OLDIFS=$IFS
IFS=$'\n'

for row in $(jq -c -r '(.groups | .[])' ${aad}); do
  # function to display json property
  _jq() {
    echo ${row} | jq -r ${1}
  }

  if [[ ! $(az ad group list --query "[?mailNickname=='$(_jq '.displayname')'].{mailNickname:mailNickname}" -o tsv) ]]; then
    objectid=$(az ad group create --display-name "$(_jq '.displayname')" --mail-nickname "$(_jq '.mailnickname')" --description "$(_jq '.description')" --query objectId -o tsv)
    echo Created group "$(_jq '.displayname')" with objectId "${objectid}"
  else
    echo "$(_jq '.displayname') Group exists"
  fi

done
IFS=$OLDIFS