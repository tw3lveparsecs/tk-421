# Network Security Group
This module will create a Network Security group and optionally enable diagnostics logs and a delete lock.

## Usage

### Example 1 - NSG with diagnostic logs and delete lock enabled
``` bicep
param deploymentName string = 'nsg${utcNow()}'

module nsg './main.bicep' = {
  name: deploymentName
  params: {
    location: resourceGroup().location
    nsgName: 'MyNSG'
    securityRules: [
      {
        name: 'rule1'
        properties: {
          access: 'Allow'
          description: 'rule example'
          destinationAddressPrefix: '10.0.0.1'
          destinationPortRanges: [
            '80'
            '443'
          ]
          direction: 'Inbound'
          priority: 150
          protocol: 'tcp'
          sourceAddressPrefix: '192.168.1.5'
          sourcePortRanges: [
            '22'
            '3389'
          ]
        }
      }
    ]
    enableDeleteLock: true
    enableDiagnostics: true
    logAnalyticsWorkspaceId: 'MyLogAnalyticsWorkspaceResourceId'
    diagnosticStorageAccountId: 'MyStorageAccountResourceId'
  }
}
```

### Example 2 - NSG without diagnostic logs and delete lock enabled
``` bicep
param deploymentName string = 'nsg${utcNow()}'

module nsg './main.bicep' = {
  name: deploymentName
  params: {
    location: resourceGroup().location
    nsgName: 'MyNSG'
    securityRules: [
      {
        name: 'rule1'
        properties: {
          access: 'Allow'
          description: 'rule example'
          destinationAddressPrefix: '10.0.0.1'
          destinationPortRanges: [
            '80'
            '443'
          ]
          direction: 'Inbound'
          priority: 150
          protocol: 'tcp'
          sourceAddressPrefix: '192.168.1.5'
          sourcePortRanges: [
            '22'
            '3389'
          ]
        }
      }
    ]
  }
}
```