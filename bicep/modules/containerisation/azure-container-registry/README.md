# Azure Container Registry
This module will create an Azure Container Registry.

You can optionally configure system/user assigned identities, IP rules, polices, public access and zone redundancy.

## Usage

### Example 1 - Azure Container Registry with default settings
``` bicep
param deploymentName string = 'acr${utcNow()}'

module acr 'main.bicep' = {
  name: deploymentName
  params: {
    acrName: 'myacrname'
    acrSku: 'Basic'    
  }
}
```

### Example 2 - Azure Container Registry with IP rules, policies and user assigned identity
``` bicep
param deploymentName string = 'acr${utcNow()}'

module acr 'main.bicep' = {
  name: deploymentName
  params: {
    acrName: 'myacrname'
    acrSku: 'Premium'
    publicNetworkAccess: 'Enabled'
    networkRuleBypassOptions: 'AzureServices'
    networkRules: {
      defaultAction: 'Deny'
      ipRules: [
        {
          action: 'Allow'
          value: '72.0.0.0/24'
        }
        {
          action: 'Allow'
          value: '172.0.0.0/16'
        }
      ]
    }
    userAssignedIdentities: {
      'myUserAssignedIdentityResourceId': {}
    }
    policies: {
      exportPolicy: {
        status: 'enabled'
      }
      quarantinePolicy: {
        status: 'enabled'
      }
      retentionPolicy: {
        status: 'enabled'
        days: 30
      }
      trustPolicy: {
        status: 'enabled'
      }
    }
  }
}
```

### Example 3 - Azure Container Registry with diagnostic logs, delete lock and system assigned identity
``` bicep
param deploymentName string = 'acr${utcNow()}'

module acr 'main.bicep' = {
  name: deploymentName
  params: {
    acrName: 'myacrname'
    acrSku: 'Standard'
    enableSystemIdentity: true
    enableDeleteLock: true
    enableDiagnostics: true
    diagnosticStorageAccountId: 'MyStorageAccountResourceId'
    logAnalyticsWorkspaceId: 'MyLogAnalyticsWorkspaceId'    
  }
}