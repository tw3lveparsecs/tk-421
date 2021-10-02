//  TODO
//  - add peerings
//  - get working in pipeline
//  - add nsgs
//  - add udrs

targetScope = 'subscription'
/*======================================================================
GLOBAL VARIABLES
======================================================================*/
var location = 'AustraliaEast'
var primaryLocationCode = 'syd'
var tags = {
  project: 'tk-421'
  environment: 'dev'
}
/*======================================================================
RESOURCE GROUPS
======================================================================*/
var networkResourceGroup = 'dev-network-rgp'

resource networkRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: networkResourceGroup
  location: location
  tags: tags
}
/*======================================================================
NEWORK WATCHER
======================================================================*/
var networkWatcherName = 'dev-${primaryLocationCode}-nww'

param nwDeploymentName string = 'networkWatcher${utcNow()}'

module networkWatcher '../../modules/network-watcher/main.bicep' = {
  name: nwDeploymentName
  scope: resourceGroup(networkRG.name)
  params: {
    networkWatcherName: networkWatcherName
    location: location
  }
}
/*======================================================================
VIRTUAL NETWORKS
======================================================================*/
var vnetHubName = 'dev-${primaryLocationCode}-hub-vnw'
var vnetHubAddressSpace = [
  '10.20.0.0/24'
]
var vnetHubSubnets = [
  {
    name: 'AzureFirewallSubnet'
    addressPrefix: '10.20.0.0/26'
    privateEndpointNetworkPolicies: 'disabled'
    privateLinkServiceNetworkPolicies: 'disabled'
    delegation: null
    natgatewayId: null
    nsgId: null
    udrId: null
    serviceEndpoints: null
  }
  {
    name: 'GatewaySubnet'
    addressPrefix: '10.20.0.64/27'
    privateEndpointNetworkPolicies: 'disabled'
    privateLinkServiceNetworkPolicies: 'disabled'
    delegation: null
    natgatewayId: null
    nsgId: null
    udrId: null
    serviceEndpoints: null
  }
  {
    name: 'AzureBastionSubnet'
    addressPrefix: '10.20.0.96/27'
    privateEndpointNetworkPolicies: 'disabled'
    privateLinkServiceNetworkPolicies: 'disabled'
    delegation: null
    natgatewayId: null
    nsgId: null // add nsg
    udrId: null
    serviceEndpoints: null
  }
  {
    name: 'AzureWAFSubnet'
    addressPrefix: '10.20.0.128/28'
    privateEndpointNetworkPolicies: 'disabled'
    privateLinkServiceNetworkPolicies: 'disabled'
    delegation: null
    natgatewayId: null
    nsgId: null // add nsg
    udrId: null
    serviceEndpoints: null
  }
]

param vnetHubDeploymentName string = 'vnetHub${utcNow()}'

module vnetHub '../../modules/vnet/main.bicep' = {
  name: vnetHubDeploymentName
  scope: resourceGroup(networkRG.name)
  params: {
    vnetName: vnetHubName
    location: location
    vnetAddressSpace: vnetHubAddressSpace
    subnets: vnetHubSubnets
  }
}

var vnetSpokeName = 'dev-${primaryLocationCode}-workload1-vnw'
var vnetSpokeAddressSpace = [
  '10.24.0.0/16'
]
var vnetSpokeSubnets = [
  {
    name: 'AksNodes'
    addressPrefix: '10.24.0.0/22'
    privateEndpointNetworkPolicies: 'disabled'
    privateLinkServiceNetworkPolicies: 'enabled'
    delegation: null
    natgatewayId: null
    nsgId: null //add nsg
    udrId: null //add udr
    serviceEndpoints: null
  }
  {
    name: 'AksIngressServices'
    addressPrefix: '10.24.4.0/28'
    privateEndpointNetworkPolicies: 'disabled'
    privateLinkServiceNetworkPolicies: 'disabled'
    delegation: null
    natgatewayId: null
    nsgId: null // add nsg
    udrId: null // add udr
    serviceEndpoints: null
  }
]

param vnetSpokeDeploymentName string = 'vnetSpoke${utcNow()}'

module vnetSpoke '../../modules/vnet/main.bicep' = {
  name: vnetSpokeDeploymentName
  scope: resourceGroup(networkRG.name)
  params: {
    vnetName: vnetSpokeName
    location: location
    vnetAddressSpace: vnetSpokeAddressSpace
    subnets: vnetSpokeSubnets
  }
}
