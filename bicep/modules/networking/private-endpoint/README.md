# Private Endpoint 
This module creates a Private Endpoint for an existing resource with a private dns zone group configured.

## Usage

### Example - Private Endpoint for a storage account

```bicep
param deploymentName string = 'privateEndpoint${utcNow()}'

module privateEndpoint 'private-endpoint.bicep' = {
  name: deploymentName
  params: {
    privateEndpointName: 'myStorageAccount-pep'
    privateEndpointSubnetId: 'MyPrivateEndpointSubnetId'
    targetResourceId: 'myStorageAccountId'
    groupIds: [
      'blob'
    ]
    privateDnsZoneId: 'myPrivateDnsZoneId'
  }
}
```