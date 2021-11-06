#!/bin/bash

while getopts k:a: option
do
 case "${option}"
 in
 # .github/variables/keyvault/keyvault.json
 k) keyvault=${OPTARG};;
 # .github/variables/aad/aad.json
 a) aad=${OPTARG};;
 esac
done

echo ${keyvault:?"-k is not set"}
echo ${aad:?"-a is not set"}

# store current value in IFS
OLDIFS=$IFS
IFS=$'\n'

export vaultname=$(jq -r '.vaultname' ${keyvault})
export resourcegroup=$(jq -r '.resourcegroup' ${keyvault})
# export vaultname=$(jq -r '.vaultname' .github/variables/keyvault/keyvault.json)
# export resourcegroup=$(jq -r '.resourcegroup' .github/variables/keyvault/keyvault.json)

# Grab token and domain name
AZURE_TOKEN=$(az account get-access-token --resource-type ms-graph --query accessToken --output tsv)
export AZURE_TENANTDOMAIN=$(curl -s --header "Authorization: Bearer ${AZURE_TOKEN}" --request GET 'https://graph.microsoft.com/v1.0/domains' | jq -r '.value[] | select(.isDefault == true) | {id}[]')

# for row in $(jq -c -r '(.users | .[])' .github/variables/aad/aad.json); do
for row in $(jq -c -r '(.users | .[])' ${aad}); do
  # function to display json property
  _jq() {
    echo ${row} | jq -r ${1}
  }

  # variables
  displayName="$(_jq '.displayname')"
  userPrincipalName="$(_jq '.displayname')@${AZURE_TENANTDOMAIN}"
  memberOf="$(_jq '.memberof')"
  userobjectid=$(az ad user list --upn "${userPrincipalName}" --query "[].objectId" -o tsv)

  # create secret if not exist
  if [[ ! $(az keyvault secret show --name "${displayName}" --vault-name "${vaultname}" --query "value" 2>/dev/null) ]]; then
    pw=$(date +%s | md5sum | base64 | head -c 32 ; echo)
    az keyvault secret set --name ${displayName} --vault-name ${vaultname} --value "${pw}" 1>/dev/null
    if [[ $? = 0 ]];then
      echo "Added secret '${displayName}' to keyvault '${vaultname}'"
    else
      echo "Failed to add secret to keyvault '${vaultname}'"
      exit 1
    fi
  else
    echo "Secret '${displayName}' already exists"
    pw=$(az keyvault secret show --name "${displayName}" --vault-name "${vaultname}" --query "value")
  fi

  # create user if not exist
  if [[ ! -z "${userobjectid}" ]]; then
    echo "User '${userPrincipalName}' exists"
    if [[ ! $(az ad user get-member-groups --id "${userPrincipalName}" --query "[?displayName=='${memberOf}'].{displayName:displayName}" -o tsv) ]]; then
      echo "Not a member of: '${memberOf}'"
      adduser=true
    fi
  else
    userobjectid=$(az ad user create --display-name "${displayName}" --user-principal-name "${userPrincipalName}" --password "${pw}" --query objectId -o tsv)
    if [[ $? = 0 ]];then
      echo "Created user '${displayName}'"
    else
      echo "Failed to create user '${displayName}'"
      exit 1
    fi
    adduser=true
  fi
    i=1
    while [ ! $(az ad user list --upn ${userPrincipalName} --query "[].objectId" -o tsv) ]
    do
      ((i++))
      # echo "Number $i"
      if [[ "$i" == '10' ]]; then
        break
      fi
      sleep 3
    done

    if [[ ! -z "${adduser}" ]]; then
      az ad group member add -g ${memberOf} --member-id ${userobjectid}
      if [[ $? = 0 ]];then
        echo "Added user to group '${memberOf}'"
      else
        echo "Failed to add user to group '${memberOf}', check that group exists"
        exit 1
      fi
    else
      echo "User alredy a member of group '${memberOf}'"
    fi

done
IFS=$OLDIFS