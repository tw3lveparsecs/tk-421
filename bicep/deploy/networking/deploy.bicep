//  TODO
//  - add hub/spoke
//  - add peerings
//  - fix example below for aks networks
//  - add resource groups
//  - add network watcher
//  - get working in pipeline

param vnetDeploymentName string = 'vnet${utcNow()}'

module vnet '../../modules/vnet/main.bicep' = {
  name: vnetDeploymentName
  params: {
    vnetName: 'test-vnet-05'
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
        delegation: 'Microsoft.Web/serverFarms'
        natgatewayId: '/subscriptions/200ef0b6-6c4f-4c21-a331-f8301096bac9/resourceGroups/network/providers/Microsoft.Network/natGateways/nat1'
        nsgId: '/subscriptions/200ef0b6-6c4f-4c21-a331-f8301096bac9/resourceGroups/network/providers/Microsoft.Network/networkSecurityGroups/nsg1'
        udrId: '/subscriptions/200ef0b6-6c4f-4c21-a331-f8301096bac9/resourceGroups/network/providers/Microsoft.Network/routeTables/udr1'
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
    enableDeleteLock: true
    enableDiagnostics: true
    logAnalyticsWorkspaceId: '/subscriptions/200ef0b6-6c4f-4c21-a331-f8301096bac9/resourcegroups/temp/providers/microsoft.operationalinsights/workspaces/law1'
    diagnosticStorageAccountId: '/subscriptions/200ef0b6-6c4f-4c21-a331-f8301096bac9/resourceGroups/temp/providers/Microsoft.Storage/storageAccounts/ajbdiags01'
  }
}
