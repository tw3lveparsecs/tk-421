# Log Analytics
This module will deploy a Log Analytics Workspace with solutions, data sources and linked to an automation account.

## Usage

### Example 1 - Log Analytics Workspace with solutions and data sources
``` bicep
param deploymentName string = 'logAnalytics${utcNow()}'

module logAnalytics './main.bicep' = {
  name: deploymentName
  params: {
    name: 'myLogAnalyticsWorkspace'
    sku: 'PerGB2018'
    retentionInDays: 30
    solutions: [
      {
        name: 'AzureActivity'
        product: 'OMSGallery/AzureActivity'
        publisher: 'Microsoft'
        promotionCode: ''
      }
    ]
    dataSources: [
      {
        name: 'Application'
        kind: 'WindowsEvent'
        properties: {
          eventLogName: 'Application'
          eventTypes: [
            {
              eventType: 'Error'
            }
            {
              eventType: 'Warning'
            }
          ]
        }
      }
      {
        name: 'LogicalDisk1'
        kind: 'WindowsPerformanceCounter'
        properties: {
          objectName: 'LogicalDisk'
          instanceName: '*'
          intervalSeconds: 360
          counterName: 'Avg Disk sec/Read'
        }
      }
    ]
  }
}
```

### Example 2 - Log Analytics Workspace with solutions, data sources and linked to an automation account
``` bicep
param deploymentName string = 'logAnalytics${utcNow()}'

module logAnalytics './main.bicep' = {
  name: deploymentName
  params: {
    name: 'myLogAnalyticsWorkspace'
    sku: 'PerGB2018'
    retentionInDays: 30
    automationAccountID: 'myAutomationAccountResourceId'
    solutions: [
      {
        name: 'AzureActivity'
        product: 'OMSGallery/AzureActivity'
        publisher: 'Microsoft'
        promotionCode: ''
      }
    ]
    dataSources: [
      {
        name: 'Application'
        kind: 'WindowsEvent'
        properties: {
          eventLogName: 'Application'
          eventTypes: [
            {
              eventType: 'Error'
            }
            {
              eventType: 'Warning'
            }
          ]
        }
      }
      {
        name: 'LogicalDisk1'
        kind: 'WindowsPerformanceCounter'
        properties: {
          objectName: 'LogicalDisk'
          instanceName: '*'
          intervalSeconds: 360
          counterName: 'Avg Disk sec/Read'
        }
      }
    ]
  }
}
```

### Example 3 - Log Analytics Workspace with solutions, data sources, delete lock and diagnostic logs enabled
``` bicep
param deploymentName string = 'logAnalytics${utcNow()}'

module logAnalytics './main.bicep' = {
  name: deploymentName
  params: {
    name: 'myLogAnalyticsWorkspace'
    sku: 'PerGB2018'
    retentionInDays: 30
    enableDeleteLock: true
    enableDiagnostics: true
    diagnosticStorageAccountId: 'myStorageAccountResourceId'
    solutions: [
      {
        name: 'AzureActivity'
        product: 'OMSGallery/AzureActivity'
        publisher: 'Microsoft'
        promotionCode: ''
      }
    ]
    dataSources: [
      {
        name: 'Application'
        kind: 'WindowsEvent'
        properties: {
          eventLogName: 'Application'
          eventTypes: [
            {
              eventType: 'Error'
            }
            {
              eventType: 'Warning'
            }
          ]
        }
      }
      {
        name: 'LogicalDisk1'
        kind: 'WindowsPerformanceCounter'
        properties: {
          objectName: 'LogicalDisk'
          instanceName: '*'
          intervalSeconds: 360
          counterName: 'Avg Disk sec/Read'
        }
      }
    ]
  }
}
```

### Example 4 - Log Analytics Workspace with saved search
``` bicep
param deploymentName string = 'logAnalytics${utcNow()}'

module logAnalytics './main.bicep' = {
  name: deploymentName
  params: {
    name: 'myLogAnalyticsWorkspace'
    sku: 'PerGB2018'
    retentionInDays: 30
    savedSearches: [
      {
        name: 'MySearchQuery'
        etag: '*'
        category: 'Other'
        displayName: 'Example search query'
        query: 'My search query expression'
      }
    ]    
  }
}
```