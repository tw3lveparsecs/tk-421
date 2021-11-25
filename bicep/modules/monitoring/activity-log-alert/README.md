# Activity Log Alert
This module will deploy an Activity Log alert.

## Usage

### Example 1 - Activity Log alert scoped to subscription
``` bicep
param deploymentName string = 'activitylogalert${utcNow()}'

module activityLogAlert 'activitylogalert.bicep' = {
  name: deploymentName  
  params: {
    alertName: 'MyAlert'
    conditions: [
      {
        field: 'category'
        equals: 'Recommendation'
      }
      {
        field: 'operationName'
        equals: 'Microsoft.Advisor/recommendations/available/action'
      }
    ]
  }
}
```

### Example 2 - Activity Log alert scoped to resource group
``` bicep
param deploymentName string = 'activitylogalert${utcNow()}'

module activityLogAlert 'activitylogalert.bicep' = {
  name: deploymentName  
  params: {
    alertName: 'MyAlert'
    conditions: [
      {
        field: 'category'
        equals: 'Recommendation'
      }
      {
        field: 'operationName'
        equals: 'Microsoft.Advisor/recommendations/available/action'
      }
    ]
    scopes:[
      'MyResourceGroupId'
    ]
  }
}
```