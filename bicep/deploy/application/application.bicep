targetScope = 'subscription'
/*======================================================================
COMMON VARIABLES
======================================================================*/
var orgShortName = 'tk421'
var location = 'AustraliaEast'
var primaryLocationCode = 'syd'
var env = 'dev'
var tags = {
  project: 'tk-421'
  environment: env
  application: 'straight-shooter'
}
var appName = 'straightshooter'
/*======================================================================
MONITORING
======================================================================*/
param monitorDeploymentName string = 'monitoring${utcNow()}'

module monitoring 'monitoring/monitoring.bicep' = {
  name: monitorDeploymentName
  params: {
    env: env
    orgShortName: orgShortName
    primaryLocationCode: primaryLocationCode
    location: location
    tags: tags
    appName: appName
  }
}
/*======================================================================
CLUSTER
======================================================================*/
param clusterDeploymentName string = 'cluster${utcNow()}'

var spokeVnetResourceGroup = '${env}-spoke-network-rgp'
var spokeVnetName = '${env}-${primaryLocationCode}-straightshooter-vnw'
var acrPrivateEndpointSubnetName = 'AksNodes'
var acrDnsZoneName = 'privatelink.azurecr.io'
var acrDnsZoneResourceGroup = '${env}-hub-network-rgp'
var hubSubscription = subscription().subscriptionId // replace with hub subscription id if hub exists in a different subscription to spoke

resource spokeVnet 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  name: spokeVnetName
  scope: resourceGroup(spokeVnetResourceGroup)
}

resource acrDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: acrDnsZoneName
  scope: resourceGroup(hubSubscription, acrDnsZoneResourceGroup)
}

module cluster 'cluster/cluster.bicep' = {
  name: clusterDeploymentName
  params: {
    env: env
    location: location
    tags: tags
    acrPrivateEndpointSubnetId: '${spokeVnet.id}/subnets/${acrPrivateEndpointSubnetName}'
    acrPrivateDnsZoneId: acrDnsZone.id
  }
}
