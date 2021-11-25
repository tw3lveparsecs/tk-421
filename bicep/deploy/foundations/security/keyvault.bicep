/* ToDo: AddLog Analytics integration*/
targetScope = 'subscription'

@description('Airport location code or alternative short location description')
param primaryLocationCode string = 'mel'

@description('Deployment environment')
param env string = 'dev'

@description('Azure resource location')
param location string = 'australiasoutheast'

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

var coreKeyVaultName = '${env}-${primaryLocationCode}-core-kv'

param coreKvDeploymentName string = 'keyvault${utcNow()}'

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
    accessPolicies: [
      {
        // applicationId: ''
        objectId: '9b039a4f-a509-4836-a097-b9e41a293a9c'
        permissions: {
          certificates: []
          keys: []
          secrets: [
            'backup'
            'delete'
            'get'
            'list'
            'purge'
            'recover'
            'restore'
            'set'
          ]
          storage: []
        }
        tenantId: subscription().tenantId
      }
      {
        // applicationId: ''
        objectId: '07e0729e-efad-4773-91df-5c67b605814c'
        permissions: {
          certificates: []
          keys: []
          secrets: [
            'backup'
            'delete'
            'get'
            'list'
            'purge'
            'recover'
            'restore'
            'set'
          ]
          storage: []
        }
        tenantId: subscription().tenantId
      }
    ]
  }
}

