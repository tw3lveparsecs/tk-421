/* ToDo:
    Convert arrays to loops in module (change params)
    Add Private Endpoints
    Add Private DNS Zones
    Add Log Analytics integration
    Add Resource Locks
*/
targetScope = 'subscription'

@description('Airport location code or alternative short location description')
param primaryLocationCode string = 'syd'

@description('Deployment environment')
param env string = 'dev'

@description('Azure resource location')
param location string = 'australiaeast'

@description('Object containing tags')
param tags object = {
    environment: 'development'
    project: 'keyvault'
}

/*======================================================================
RESOURCE GROUPS
======================================================================*/
var hubCoreResourceGroup = '${env}-hub-core-rgp'

resource keyvaultHubRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: hubCoreResourceGroup
  location: location
  tags: tags
}

/*======================================================================
Key Vault
======================================================================*/
param coreKvDeploymentName string = 'keyvault${utcNow()}'

var coreKeyVaultName = '${env}-${primaryLocationCode}-core-kv'
var networkAcls = {
  bypass: 'AzureServices'
  defaultAction: 'Deny'
  ipRules: [
    {
      value: '121.45.227.152/32'
    }
  ]
  virtualNetworkRules: [
    // {
    //   id: '/subscriptions/3e7f7457-a6f1-4001-9ea6-7b7a9810c783/resourceGroups/rg-network-prd/providers/Microsoft.Network/virtualNetworks/vn-mel-prd-01/subnets/privateendpoints'
    //   ignoreMissingVnetServiceEndpoint: false
    // }
  ]
}
var accessPolicies = [
  // {
  //   // applicationId: ''
  //   objectId: '090e6f11-ebed-4f2c-8b8e-05a9191d1933'
  //   permissions: {
  //     certificates: []
  //     keys: []
  //     secrets: [
  //       'backup'
  //       'delete'
  //       'get'
  //       'list'
  //       'purge'
  //       'recover'
  //       'restore'
  //       'set'
  //     ]
  //     storage: []
  //   }
  //   tenantId: subscription().tenantId
  // }
  // {
  //   // applicationId: ''
  //   objectId: 'c78b51c1-bc55-4ad0-85f0-9ebf6e580dbd'
  //   permissions: {
  //     certificates: []
  //     keys: []
  //     secrets: [
  //       'backup'
  //       'delete'
  //       'get'
  //       'list'
  //       'purge'
  //       'recover'
  //       'restore'
  //       'set'
  //     ]
  //     storage: []
  //   }
  //   tenantId: subscription().tenantId
  // }
]

module keyVault '../../../modules/security/keyvault/keyvault.bicep' = {
  name: coreKvDeploymentName
  scope: resourceGroup(keyvaultHubRG.name)
  params: {
    keyvaultName: coreKeyVaultName
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: true
    enableSoftDelete: false
    skuName: 'standard'
    softDeleteRetentionInDays: 7
    tenantId: subscription().tenantId
    publicNetworkAccess: ''
    networkAcls: networkAcls
    accessPolicies: accessPolicies
  }
}

