# NSG Flow Log
This module will create a NSG flow log for an existing Network Security Group. 

You can optionally enable traffic analytics.  

## Usage

### Example 1 - NSG Flow Log
``` bicep
param deploymentName string = 'nsgflowlog${utcNow()}'

module flowlog 'main.bicep' = {
  name: deploymentName
  scope: resourceGroup('MyNetworkWatcherRG')
  params: {
    flowlogName: 'MyFlowLogName'
    networkWatcherName: 'MyExistingNetworkWatcherName'    
    flowLogStorageAccountId: 'StorageAccountResourceId'
    nsgId: 'NsgResourceId'
  }
}
```

### Example 2 - NSG Flow Log with traffic analytics
``` bicep
param deploymentName string = 'nsgflowlog${utcNow()}'

module flowlog 'main.bicep' = {
  name: deploymentName
  scope: resourceGroup('MyNetworkWatcherRG')
  params: {
    flowlogName: 'MyFlowLogName'
    networkWatcherName: 'MyExistingNetworkWatcherName'    
    flowLogStorageAccountId: 'StorageAccountResourceId'
    nsgId: 'NsgResourceId'
    logAnalyticsWorkspaceId: 'logAnalyticsResourceId'
  }
}
```