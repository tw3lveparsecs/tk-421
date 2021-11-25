@description('Key Vault name')
param keyvaultName string = 'kv${uniqueString(resourceGroup().name)}'

@description('Enable Virtual Machines to retrieve certificates stored as secrets')
param enabledForDeployment bool = false

@description('Enable Azure Disk Encryption to retrieve secrets from the vault and unwrap keys')
param enabledForDiskEncryption bool = false

@description('Enable Azure Resource Manager to retrieve secrets')
param enabledForTemplateDeployment bool = false

@description('Property to specify whether the soft delete functionality is enabled for this key vault')
param enableSoftDelete bool = false

@description('Key Vault SKU name to specify whether the key vault is a standard vault or a premium vault')
@allowed([
  'standard'
  'premium'
])
param skuName string = 'standard'

@description('Amount of days the soft deleted data is stored and available for recovery')
@minValue(7)
@maxValue(90)
param softDeleteRetentionInDays int = 7

@description('Azure Active Directory tenant ID that should be used for authenticating requests to the key vault')
param tenantId string = subscription().tenantId

@description('Aazure Key Vault Access Policies')
@metadata({
  applicationId: 'Application ID of the client making request on behalf of a principal cannot be used with - objectId'
  objectId: 'Unique object ID of a user, service principal or security group in the Azure Active Directory tenant of the vault cannot be used with - applicationId'
  permissions: {
    certificates: [
      'Specify - [] / all - or combination from below'
      'all'
      'backup'
      'create'
      'delete'
      'deleteissuers'
      'get'
      'getissuers'
      'import'
      'list'
      'listissuers'
      'managecontacts'
      'manageissuers'
      'purge'
      'recover'
      'restore'
      'setissuers'
      'update'
    ]
    keys: [
      'Specify - [] / all - or combination from below'
      'all'
      'backup'
      'create'
      'decrypt'
      'delete'
      'encrypt'
      'get'
      'import'
      'list'
      'purge'
      'recover'
      'restore'
      'sign'
      'unwrapKey'
      'update'
      'verify'
      'wrapKey'
    ]
    secrets: [
      'Specify - [] / all - or combination from below'
      'all'
      'backup'
      'delete'
      'get'
      'list'
      'purge'
      'recover'
      'restore'
      'set'
    ]
    storage: [
      'Specify - [] / all - or combination from below'
      'all'
      'backup'
      'delete'
      'deletesas'
      'get'
      'getsas'
      'list'
      'listsas'
      'purge'
      'recover'
      'regeneratekey'
      'restore'
      'set'
      'setsas'
      'update'
    ]
  }
  tenantId: 'string'
})
param accessPolicies array = []

resource keyvault 'Microsoft.KeyVault/vaults@2021-06-01-preview' = {
  name: keyvaultName
  location: resourceGroup().location
  properties: {
    enabledForDeployment: enabledForDeployment
    enabledForDiskEncryption: enabledForDiskEncryption
    enabledForTemplateDeployment: enabledForTemplateDeployment
    enableSoftDelete: enableSoftDelete
    networkAcls: {}
    accessPolicies: accessPolicies
    // publicNetworkAccess: 'string'
    sku: {
      family: 'A'
      name: skuName
    }
    softDeleteRetentionInDays: softDeleteRetentionInDays
    tenantId: tenantId
  }
}

// resource keyvaultNetworkAcls


output name string = keyvault.name
output id string = keyvault.id
