//  TODO
//  - update deploy with peerings, udrs
//  - get working in pipeline

targetScope = 'subscription'
/*======================================================================
COMMON VARIABLES
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
NSGs
======================================================================*/
var bastionNsgName = 'dev-${primaryLocationCode}-bastion-nsg'
var AppGwNsgName = 'dev-${primaryLocationCode}-appgw-nsg'
var AksNodesNsgName = 'dev-${primaryLocationCode}-aksnodes-nsg'
var AksIngressNsgName = 'dev-${primaryLocationCode}-aksingress-nsg'

param nsgDeploymentName string = 'nsg${utcNow()}'

module bastionNsg '../../modules/nsgs/main.bicep' = {
  name: nsgDeploymentName
  scope: resourceGroup(networkRG.name)
  params: {
    nsgName: bastionNsgName
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

module AppGwNsg '../../modules/nsgs/main.bicep' = {
  name: nsgDeploymentName
  scope: resourceGroup(networkRG.name)
  params: {
    nsgName: AppGwNsgName
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

module AksNodesNsg '../../modules/nsgs/main.bicep' = {
  name: nsgDeploymentName
  scope: resourceGroup(networkRG.name)
  params: {
    nsgName: AksNodesNsgName
  }
}

module AksIngressNsg '../../modules/nsgs/main.bicep' = {
  name: nsgDeploymentName
  scope: resourceGroup(networkRG.name)
  params: {
    nsgName: AksIngressNsgName
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
    nsgId: null // add nsg
  }
  {
    name: 'AzureWAFSubnet'
    addressPrefix: '10.20.0.128/28'
    privateEndpointNetworkPolicies: 'disabled'
    privateLinkServiceNetworkPolicies: 'disabled'
    nsgId: null // add nsg
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
    nsgId: null //add nsg
    udrId: null //add udr
  }
  {
    name: 'AksIngressServices'
    addressPrefix: '10.24.4.0/28'
    privateEndpointNetworkPolicies: 'disabled'
    privateLinkServiceNetworkPolicies: 'disabled'
    nsgId: null // add nsg
    udrId: null // add udr  
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
