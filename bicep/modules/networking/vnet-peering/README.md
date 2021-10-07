# Virtual Network Peering
This module will create a virtual network peering on an existing virtual network.

## Usage

### Example 1 - Virtual network peering
``` bicep
param deploymentName string = 'peer${utcNow()}'

module peering './main.bicep' = {
  name: deploymentName
  params: {
    vnetName: 'vnet1'
    peerName: 'vnet1-to-vnet2'
    allowForwardedTraffic: false
    allowGatewayTransit: false
    allowVirtualNetworkAccess: true
    useRemoteGateways: false
    remoteVirtualNetworkId: 'RemoteVnetResourceId'
  }
}
```