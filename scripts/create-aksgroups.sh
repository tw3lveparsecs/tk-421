#!/bin/bash

# .SYNOPSIS
#     Script: Create-AksGroups.sh
#
# .DESCRIPTION
#     This script reads input from variable file [.github/variables/aad/aad.json] and creates Azure Active Directory groups.
#
# .PARAMETER -a
#     Path to the variable file [.github/variables/aad/aad.json]
#
# .INPUTS
#     None
#
# .NOTES
#     Version         :	0.01
#     Author          : Thor Schutze (Arinco)
#
#     Creation Date   :	15/11/2021
#     Purpose/Change  :	Initial script development
#     Requirements    :	Azure CLI 2.0, Jq 1.5
#
#     Dependencies    :	None
#     Limitations     : None
#
#     Supported
#     Platforms*      : Ubuntu GitHub runner
#                       *Currently not tested against other platforms
#
#     Version History : [15/11/2021 - 0.01 - Thor Schutze]: Initial release
#
# .EXAMPLE
#     Create-AksGroups.sh -a .github/variables/aad/aad.json

while getopts a: option
do
 case "${option}"
 in
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