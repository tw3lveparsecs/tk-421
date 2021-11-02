targetScope = 'subscription'

@description('Airport location code or alternative short location description')
param primaryLocationCode string

@description('Deployment environment')
param env string

@description('Azure resource location')
param location string

@description('Object containing tags')
param tags object

@description('Log Analytics Workspace resource id')
param logAnalyticsWorkspaceId string

@description('Flow logs storage account resource id')
param flowLogsStorageId string
/*======================================================================
RESOURCE GROUPS
======================================================================*/
var hubVnetResourceGroup = '${env}-hub-network-rgp'
var spokeVnetResourceGroup = '${env}-spoke-network-rgp'

resource networkHubRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: hubVnetResourceGroup
  location: location
  tags: tags
}

resource networkSpokeRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: spokeVnetResourceGroup
  location: location
  tags: tags
}
/*======================================================================
NEWORK WATCHER
======================================================================*/
var networkWatcherName = '${env}-${primaryLocationCode}-nww'

param nwDeploymentName string = 'networkWatcher${utcNow()}'

module networkWatcher '../../../modules/networking/network-watcher/networkwatcher.bicep' = {
  name: nwDeploymentName
  scope: resourceGroup(networkHubRG.name)
  params: {
    networkWatcherName: networkWatcherName
    location: location
  }
}
/*======================================================================
NSGs
======================================================================*/
var bastionNsgName = '${env}-${primaryLocationCode}-bastion-nsg'
var bastionFlowLogName = '${bastionNsgName}-flw'
var appGwNsgName = '${env}-${primaryLocationCode}-appgw-nsg'
var appGwFlowLogName = '${appGwNsgName}-flw'
var aksNodesNsgName = '${env}-${primaryLocationCode}-aksnodes-nsg'
var aksNodesFlowLogName = '${aksNodesNsgName}-flw'
var aksIngressNsgName = '${env}-${primaryLocationCode}-aksingress-nsg'
var aksIngressFlowLogName = '${aksIngressNsgName}-flw'

param bastionNsgDeploymentName string = 'bastionnsg${utcNow()}'
param bastionFlowDeploymentName string = 'bastionflowlogs${utcNow()}'
param appGwNsgDeploymentName string = 'appgwnsg${utcNow()}'
param appGwFlowDeploymentName string = 'appgwflowlogs${utcNow()}'
param aksNodesNsgDeploymentName string = 'aksnodesnsg${utcNow()}'
param aksNodesFlowDeploymentName string = 'aksnodesflowlogs${utcNow()}'
param aksIngressNsgDeploymentName string = 'aksingressnsg${utcNow()}'
param aksIngressFlowDeploymentName string = 'aksingressflowlogs${utcNow()}'

module bastionNsg '../../../modules/networking/nsgs/nsgs.bicep' = {
  name: bastionNsgDeploymentName
  scope: resourceGroup(networkHubRG.name)
  params: {
    nsgName: bastionNsgName
    enableDiagnostics: true
    diagnosticStorageAccountId: flowLogsStorageId
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    securityRules: [
      {
        name: 'AllowWebExperienceInBound'
        properties: {
          description: 'Allow our users in. Update this to be as restrictive as possible.'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'Internet'
          destinationPortRange: '443'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowControlPlaneInBound'
        properties: {
          description: 'Service Requirement. Allow control plane access. Regional Tag not yet supported.'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'GatewayManager'
          destinationPortRange: '443'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowHealthProbesInBound'
        properties: {
          description: 'Service Requirement. Allow Health Probes.'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationPortRange: '443'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 120
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowBastionHostToHostInBound'
        properties: {
          description: 'Service Requirement. Allow Required Host to Host Communication.'
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationPortRanges: [
            '8080'
            '5701'
          ]
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 130
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyAllInBound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 1000
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowSshToVnetOutBound'
        properties: {
          description: 'Allow SSH out to the VNet'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: 22
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowRdpToVnetOutBound'
        properties: {
          protocol: 'Tcp'
          description: 'Allow RDP out to the VNet'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '3389'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 110
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowControlPlaneOutBound'
        properties: {
          description: 'Required for control plane outbound. Regional prefix not yet supported'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '443'
          destinationAddressPrefix: 'AzureCloud'
          access: 'Allow'
          priority: 120
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowBastionHostToHostOutBound'
        properties: {
          description: 'Service Requirement. Allow Required Host to Host Communication.'
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationPortRanges: [
            '8080'
            '5701'
          ]
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 130
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowBastionCertificateValidationOutBound'
        properties: {
          description: 'Service Requirement. Allow Required Session and Certificate Validation.'
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: 80
          destinationAddressPrefix: 'Internet'
          access: 'Allow'
          priority: 140
          direction: 'Outbound'
        }
      }
      {
        name: 'DenyAllOutBound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 1000
          direction: 'Outbound'
        }
      }
    ]
  }
}

module bastionFlowLogs '../../../modules/networking/flow-logs/flowlogs.bicep' = {
  name: bastionFlowDeploymentName
  scope: resourceGroup(networkHubRG.name)
  params: {
    flowlogName: bastionFlowLogName
    location: location
    flowLogStorageAccountId: flowLogsStorageId
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    networkWatcherName: networkWatcher.outputs.name
    nsgId: bastionNsg.outputs.id
  }
}

module appGwNsg '../../../modules/networking/nsgs/nsgs.bicep' = {
  name: appGwNsgDeploymentName
  scope: resourceGroup(networkHubRG.name)
  params: {
    nsgName: appGwNsgName
    enableDiagnostics: true
    diagnosticStorageAccountId: flowLogsStorageId
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    securityRules: [
      {
        name: 'Allow443InBound'
        properties: {
          description: 'Allow ALL web traffic into 443. (If you wanted to allow-list specific IPs, this is where you would list them.)'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'Internet'
          destinationPortRange: '443'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowControlPlaneInBound'
        properties: {
          description: 'Allow Azure Control Plane in. (https://docs.microsoft.com/azure/application-gateway/configuration-infrastructure#network-security-groups)'
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: 'Internet'
          destinationPortRange: '65200-65535'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowHealthProbesInBound'
        properties: {
          description: 'Allow Azure Health Probes in. (https://docs.microsoft.com/azure/application-gateway/configuration-infrastructure#network-security-groups)'
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationPortRange: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 120
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyAllInBound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 1000
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowAllOutBound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1000
          direction: 'Outbound'
        }
      }
    ]
  }
}

module appGwFlowLogs '../../../modules/networking/flow-logs/flowlogs.bicep' = {
  name: appGwFlowDeploymentName
  scope: resourceGroup(networkHubRG.name)
  params: {
    flowlogName: appGwFlowLogName
    location: location
    flowLogStorageAccountId: flowLogsStorageId
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    networkWatcherName: networkWatcher.outputs.name
    nsgId: appGwNsg.outputs.id
  }
}

module aksNodesNsg '../../../modules/networking/nsgs/nsgs.bicep' = {
  name: aksNodesNsgDeploymentName
  scope: resourceGroup(networkSpokeRG.name)
  params: {
    nsgName: aksNodesNsgName
    enableDiagnostics: true
    diagnosticStorageAccountId: flowLogsStorageId
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
  }
}

module aksNodesFlowLogs '../../../modules/networking/flow-logs/flowlogs.bicep' = {
  name: aksNodesFlowDeploymentName
  scope: resourceGroup(networkHubRG.name)
  params: {
    flowlogName: aksNodesFlowLogName
    location: location
    flowLogStorageAccountId: flowLogsStorageId
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    networkWatcherName: networkWatcher.outputs.name
    nsgId: aksNodesNsg.outputs.id
  }
}

module aksIngressNsg '../../../modules/networking/nsgs/nsgs.bicep' = {
  name: aksIngressNsgDeploymentName
  scope: resourceGroup(networkSpokeRG.name)
  params: {
    nsgName: aksIngressNsgName
    enableDiagnostics: true
    diagnosticStorageAccountId: flowLogsStorageId
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
  }
}

module aksIngressFlowLogs '../../../modules/networking/flow-logs/flowlogs.bicep' = {
  name: aksIngressFlowDeploymentName
  scope: resourceGroup(networkHubRG.name)
  params: {
    flowlogName: aksIngressFlowLogName
    location: location
    flowLogStorageAccountId: flowLogsStorageId
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    networkWatcherName: networkWatcher.outputs.name
    nsgId: aksIngressNsg.outputs.id
  }
}
/*======================================================================
ROUTE TABLES
======================================================================*/
var defaultUdrName = '${env}-${primaryLocationCode}-defaultout-udr'

param udrDeploymentName string = 'udr${utcNow()}'

module defaultUdr '../../../modules/networking/route-table/routetable.bicep' = {
  name: udrDeploymentName
  scope: resourceGroup(networkHubRG.name)
  params: {
    routeTableName: defaultUdrName
    routes: [
      //add route to firwall once provisioned
      // {
      //   name: 'to-firewall'
      //   addressPrefix: '0.0.0.0/0'
      //   nextHopType: 'VirtualAppliance'
      //   nextHopIpAddress: '10.0.x.x.' 
      // }
    ]
  }
}
/*======================================================================
VIRTUAL NETWORKS
======================================================================*/
var vnetHubName = '${env}-${primaryLocationCode}-hub-vnw'
var vnetHubAddressSpace = [
  '10.20.0.0/24'
]
var vnetHubSubnets = [
  {
    name: 'AzureFirewallSubnet'
    addressPrefix: '10.20.0.0/26'
    privateEndpointNetworkPolicies: 'disabled'
    privateLinkServiceNetworkPolicies: 'disabled'
  }
  {
    name: 'GatewaySubnet'
    addressPrefix: '10.20.0.64/27'
    privateEndpointNetworkPolicies: 'disabled'
    privateLinkServiceNetworkPolicies: 'disabled'
  }
  {
    name: 'AzureBastionSubnet'
    addressPrefix: '10.20.0.96/27'
    privateEndpointNetworkPolicies: 'disabled'
    privateLinkServiceNetworkPolicies: 'disabled'
    nsgId: bastionNsg.outputs.id
  }
  {
    name: 'AzureWAFSubnet'
    addressPrefix: '10.20.0.128/28'
    privateEndpointNetworkPolicies: 'disabled'
    privateLinkServiceNetworkPolicies: 'disabled'
    nsgId: appGwNsg.outputs.id
  }
]
var vnetSpokeName = '${env}-${primaryLocationCode}-straightshooter-vnw'
var vnetSpokeAddressSpace = [
  '10.24.0.0/16'
]
var vnetSpokeSubnets = [
  {
    name: 'AksNodes'
    addressPrefix: '10.24.0.0/22'
    privateEndpointNetworkPolicies: 'disabled'
    privateLinkServiceNetworkPolicies: 'enabled'
    nsgId: aksNodesNsg.outputs.id
    udrId: defaultUdr.outputs.id
  }
  {
    name: 'AksIngressServices'
    addressPrefix: '10.24.4.0/28'
    privateEndpointNetworkPolicies: 'disabled'
    privateLinkServiceNetworkPolicies: 'disabled'
    nsgId: aksIngressNsg.outputs.id
    udrId: defaultUdr.outputs.id
  }
]

param vnetHubDeploymentName string = 'vnetHub${utcNow()}'
param vnetSpokeDeploymentName string = 'vnetSpoke${utcNow()}'

module vnetHub '../../../modules/networking/vnet/vnet.bicep' = {
  name: vnetHubDeploymentName
  scope: resourceGroup(networkHubRG.name)
  params: {
    vnetName: vnetHubName
    location: location
    vnetAddressSpace: vnetHubAddressSpace
    subnets: vnetHubSubnets
    enableDiagnostics: true
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
  }
}

module vnetSpoke '../../../modules/networking/vnet/vnet.bicep' = {
  name: vnetSpokeDeploymentName
  scope: resourceGroup(networkSpokeRG.name)
  params: {
    vnetName: vnetSpokeName
    location: location
    vnetAddressSpace: vnetSpokeAddressSpace
    subnets: vnetSpokeSubnets
    enableDiagnostics: true
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
  }
}
/*======================================================================
VIRTUAL NETWORK PEERINGS
======================================================================*/
param hubPeerDeploymentName string = 'hubpeer${utcNow()}'
param spokePeerDeploymentName string = 'spokepeer${utcNow()}'

module hubPeering '../../../modules/networking/vnet-peering/vnetpeering.bicep' = {
  name: hubPeerDeploymentName
  scope: resourceGroup(networkHubRG.name)
  params: {
    vnetName: vnetHub.outputs.name
    peerName: toLower('${vnetHub.outputs.name}-to-${vnetSpoke.outputs.name}')
    allowForwardedTraffic: false
    allowGatewayTransit: false
    allowVirtualNetworkAccess: true
    useRemoteGateways: false
    remoteVirtualNetworkId: vnetSpoke.outputs.id
  }
}

module spokePeering '../../../modules/networking/vnet-peering/vnetpeering.bicep' = {
  name: spokePeerDeploymentName
  scope: resourceGroup(networkSpokeRG.name)
  params: {
    vnetName: vnetSpoke.outputs.name
    peerName: toLower('${vnetSpoke.outputs.name}-to-${vnetHub.outputs.name}')
    allowForwardedTraffic: false
    allowGatewayTransit: false
    allowVirtualNetworkAccess: true
    useRemoteGateways: false
    remoteVirtualNetworkId: vnetHub.outputs.id
  }
}
/*======================================================================
PRIVATE DNS ZONES
======================================================================*/
param acrDnsDeploymentName string = 'acrDnsZone${utcNow()}'
param kvDnsDeploymentName string = 'kvDnsZone${utcNow()}'

var acrPrivateDnsName = 'privatelink.azurecr.io'
var kvPrivateDnsName = 'privatelink.vaultcore.azure.net'

module acrPrivateDnsZone '../../../modules/networking/private-dns-zone/private-dns-zone.bicep' = {
  name: acrDnsDeploymentName
  scope: resourceGroup(networkHubRG.name)
  params: {
    privateDnsZoneName: acrPrivateDnsName
    enableVnetLink: true
    vnetResourceId: vnetHub.outputs.id
  }
}

module kvPrivateDnsZone '../../../modules/networking/private-dns-zone/private-dns-zone.bicep' = {
  name: kvDnsDeploymentName
  scope: resourceGroup(networkHubRG.name)
  params: {
    privateDnsZoneName: kvPrivateDnsName
    enableVnetLink: true
    vnetResourceId: vnetHub.outputs.id
  }
}
