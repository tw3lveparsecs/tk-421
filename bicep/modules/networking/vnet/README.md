# Virtual Network
This module will create a virtual network.

You can optionally configure subnets with delegation, service endpoints, private endpoints, NSGs, route table and enable diagnostics logs and a delete lock.

## Usage

### Example 1 - Virtual network with diagnostic logs and delete lock enabled
``` bicep
param deploymentName string = 'vnet${utcNow()}'

module vnet './main.bicep' = {
  name: vnetDeploymentName
  params: {
    vnetName: 'MyVnetName'
    location: resourceGroup().location
    vnetAddressSpace: [
      '10.0.0.0/16'
      '192.168.0.0/24'
    ]
    dnsServers: [
      '10.0.0.1'
      '10.0.0.2'
    ]
    subnets: [
      {
        name: 'subnet1'
        addressPrefix: '10.0.1.0/24'
        privateEndpointNetworkPolicies: 'disabled'
        privateLinkServiceNetworkPolicies: 'disabled'
        delegation: null
        natgatewayId: null
        nsgId: null
        udrId: null
        serviceEndpoints: null
      }
    ]
    enableDeleteLock: true
    enableDiagnostics: true
    logAnalyticsWorkspaceId: 'MyLogAnalyticsWorkspaceResourceId'
    diagnosticStorageAccountId: 'MyStorageAccountResourceId'
  }
}
```

### Example 2 - Virtual Network with Azure DNS, NSGs, Route Table, Nat Gateway, Service Endpoints and delegation.
``` bicep
param deploymentName string = 'vnet${utcNow()}'

module recoveryServices './main.bicep' = {
  name: vnetDeploymentName
  params: {
    vnetName: 'MyVnetName'
    location: resourceGroup().location
    vnetAddressSpace: [
      '10.0.0.0/16'  
    ]
    subnets: [
      {
        name: 'subnet1'
        addressPrefix: '10.0.1.0/24'
        privateEndpointNetworkPolicies: 'enabled'
        privateLinkServiceNetworkPolicies: 'disabled'
        delegation: 'Microsoft.Web/serverFarms'
        natgatewayId: 'MyNatgatewayResourceId'
        nsgId: 'MyNetworkSecurityGroupResourceId'
        udrId: 'MyRouteTableResourceId'
        serviceEndpoints: [
          {
            service: 'Microsoft.Web'
          }
          {
            service: 'Microsoft.Storage'
          }
        ]
      }
    ]
  }
}
```