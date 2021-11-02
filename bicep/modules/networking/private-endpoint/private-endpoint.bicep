@description('Private endpoint name')
param privateEndpointName string

@description('Private endpoint location')
param location string = resourceGroup().location

@description('Private endpoint subnet resource id')
param privateEndpointSubnetId string

@description('Resource id of the target resource requiring private endpoint')
param targetResourceId string

@description('Private endpoint group id(s)/sub resource type(s). Use "az network private-link-resource list" to find group id of a resource')
param groupIds array

@description('Resource id of the existing private dns zone for the private endpoint')
param privateDnsZoneId string

var privateDnsZoneGroupSuffix = '-grp'
var privateDnsZoneConfigSuffix = '-config'
var privateDnsZoneName = split(privateDnsZoneId, '/')[8]

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-03-01' = {
  name: privateEndpointName
  location: location
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        properties: {
          privateLinkServiceId: targetResourceId
          groupIds: groupIds
        }
      }
    ]
  }
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-03-01' = {
  parent: privateEndpoint
  name: '${privateDnsZoneName}${privateDnsZoneGroupSuffix}'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: '${privateEndpointName}${privateDnsZoneConfigSuffix}'
        properties: {
          privateDnsZoneId: privateDnsZoneId
        }
      }
    ]
  }
}

output name string = privateEndpoint.name
output id string = privateEndpoint.id
