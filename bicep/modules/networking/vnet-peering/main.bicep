@description('Peering name')
param peerName string

@description('Name of the existing virtual network to create the peer on')
param vnetName string

@description('Whether the forwarded traffic from the VMs in the local virtual network will be allowed/disallowed in remote virtual network')
param allowForwardedTraffic bool

@description('If gateway links can be used in remote virtual networking to link to this virtual network')
param allowGatewayTransit bool

@description('Whether the VMs in the local virtual network space would be able to access the VMs in remote virtual network space')
param allowVirtualNetworkAccess bool

@description('Do not verify the provisioning state of the remote gateway.')
param doNotVerifyRemoteGateways bool = false

@description('Resource id of the remote virtual network to peer with')
param remoteVirtualNetworkId string

@description('Resource id of the remote virtual network to peer with')
param useRemoteGateways bool

resource peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-02-01' = {
  name: '${vnetName}/${peerName}'
  properties: {
    allowForwardedTraffic: allowForwardedTraffic
    allowGatewayTransit: allowGatewayTransit
    allowVirtualNetworkAccess: allowVirtualNetworkAccess
    doNotVerifyRemoteGateways: doNotVerifyRemoteGateways
    remoteVirtualNetwork: {
      id: remoteVirtualNetworkId
    }
    useRemoteGateways: useRemoteGateways
  }
}

output name string = peering.name
output id string = peering.id
