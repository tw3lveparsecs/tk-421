/* TODO
- ALERTS
- ROLE ASSIGNMENTS
- AKS
- IDENTITIES
- KV
- EVENT GRID
- POLICY ASSIGMENTS
*/

targetScope = 'subscription'

@description('Deployment environment')
param env string

@description('Subnet resource id for ACR private endpoint')
param acrPrivateEndpointSubnetId string

@description('ACR private dns zone resource id')
param acrPrivateDnsZoneId string

@description('Object containing the cluster resource group')
param clusterResourceGroup string
/*======================================================================
ACR
======================================================================*/
param acrDeploymentName string = 'acr${utcNow()}'

var acrName = '${env}tk421straightshooteracr'
var acrSku = 'Premium'
var acrIpRules = {
  defaultAction: 'Deny'
  ipRules: []
}
var acrPolicies = {
  exportPolicy: {
    status: 'disabled'
  }
  quarantinePolicy: {
    status: 'disabled'
  }
  retentionPolicy: {
    status: 'enabled'
    days: 15
  }
  trustPolicy: {
    status: 'disabled'
  }
}
var acrPublicNetworkAccess = 'Disabled'
var acrNetworkRuleBypassOptions = 'AzureServices'
var acrZoneRedundancy = 'Enabled'

module acr '../../../modules/containerisation/azure-container-registry/acr.bicep' = {
  name: acrDeploymentName
  scope: resourceGroup(clusterResourceGroup)
  params: {
    acrName: acrName
    acrSku: acrSku
    ipRules: acrIpRules
    policies: acrPolicies
    publicNetworkAccess: acrPublicNetworkAccess
    networkRuleBypassOptions: acrNetworkRuleBypassOptions
    zoneRedundancy: acrZoneRedundancy
  }
}
/*======================================================================
PRIVATE ENDPOINTS
======================================================================*/
param acrPepDeploymentName string = 'acrPep${utcNow()}'

var acrPepName = '${acr.outputs.name}-pep'

module acrPep '../../../modules/networking/private-endpoint/private-endpoint.bicep' = {
  name: acrPepDeploymentName
  scope: resourceGroup(clusterResourceGroup)
  params: {
    privateEndpointName: acrPepName
    targetResourceId: acr.outputs.id
    groupIds: [
      'registry'
    ]
    privateEndpointSubnetId: acrPrivateEndpointSubnetId
    privateDnsZoneId: acrPrivateDnsZoneId
  }
}
