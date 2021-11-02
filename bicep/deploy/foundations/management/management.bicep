targetScope = 'subscription'

@description('Organisation short name')
param orgShortName string

@description('Airport location code or alternative short location description')
param primaryLocationCode string

@description('Deployment environment')
param env string

@description('Azure resource location')
param location string

@description('Object containing tags')
param tags object
/*======================================================================
RESOURCE GROUPS
======================================================================*/
var monitorResourceGroup = '${env}-hub-monitoring-rgp'

resource monitorHubRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: monitorResourceGroup
  location: location
  tags: tags
}
/*======================================================================
LOG ANALYTICS
======================================================================*/
var logAnalyticsName = '${env}-${orgShortName}-${primaryLocationCode}-core-law'
var lawSku = 'PerGB2018'
var lawRetention = 30
var lawSolutions = [
  {
    name: 'AzureActivity'
    product: 'OMSGallery/AzureActivity'
    publisher: 'Microsoft'
    promotionCode: ''
  }
]

param lawDeploymentName string = 'logAnalytics${utcNow()}'

module logAnalytics '../../../modules/monitoring/log-analytics/loganalytics.bicep' = {
  name: lawDeploymentName
  scope: resourceGroup(monitorHubRG.name)
  params: {
    name: logAnalyticsName
    sku: lawSku
    retentionInDays: lawRetention
    solutions: lawSolutions
  }
}
/*======================================================================
STORAGE
======================================================================*/
var flowlogsStorageName = '${env}${orgShortName}${primaryLocationCode}flowlogsstg'
var storageKind = 'StorageV2'
var storageSku = 'Standard_LRS'
var storageTier = 'Hot'
var deleteRetentionPolicy = 30

param storDeploymentName string = 'storage${utcNow()}'

module flowLogsStorage '../../../modules/management/storage/storage.bicep' = {
  name: storDeploymentName
  scope: resourceGroup(monitorHubRG.name)
  params: {
    storageAccountName: flowlogsStorageName
    storageKind: storageKind
    storageSku: storageSku
    storageTier: storageTier
    deleteRetentionPolicy: deleteRetentionPolicy
  }
}
/*======================================================================
OUTPUTS
======================================================================*/
output logAnalyticsId string = logAnalytics.outputs.id
output flowlogsStorageId string = flowLogsStorage.outputs.id
