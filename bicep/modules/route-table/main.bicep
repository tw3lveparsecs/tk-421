@description('Route table name')
param routeTableName string

@description('Route table location')
param location string = resourceGroup().location

@description('Disable the routes learned by BGP on the route table')
param disableBgpRoutePropagation bool = false

@description('Array containing routes')
@metadata({
  name: 'Rule name'
  addressPrefix: 'The destination CIDR to which the route applies'
  hasBgpOverride: 'A value indicating whether this route overrides overlapping BGP routes regardless of LPM'
  nextHopIpAddress: 'The IP address packets should be forwarded to. Next hop values are only allowed in routes where the next hop type is VirtualAppliance'
  nextHopType: 'The type of Azure hop the packet should be sent to. Valid values are Internet, None, VirtualAppliance, VirtualNetworkGateway or VnetLocal'
})
param routes array = []

@description('Enable delete lock')
param enableDeleteLock bool = false

var lockName = '${routeTable.name}-lck'

resource routeTable 'Microsoft.Network/routeTables@2021-02-01' = {
  name: routeTableName
  location: location
  properties: {
    disableBgpRoutePropagation: disableBgpRoutePropagation
    routes: [for route in routes: {
      name: route.name
      properties: {
        addressPrefix: route.addressPrefix
        hasBgpOverride: contains(route, 'hasBgpOverride') ? route.hasBgpOverride : null
        nextHopIpAddress: contains(route, 'nextHopIpAddress') ? route.nextHopIpAddress : null
        nextHopType: route.nextHopType
      }
    }]
  }
}

resource lock 'Microsoft.Authorization/locks@2017-04-01' = if (enableDeleteLock) {
  scope: routeTable
  name: lockName
  properties: {
    level: 'CanNotDelete'
  }
}

output name string = routeTable.name
output id string = routeTable.id
