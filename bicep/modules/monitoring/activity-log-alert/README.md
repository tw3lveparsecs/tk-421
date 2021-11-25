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

### Example 2 - Activity Log alert scoped to subscription with multiple conditions
``` bicep
param deploymentName string = 'activitylogalert${utcNow()}'

module activityLogAlert 'activitylogalert.bicep' = {
  name: deploymentName  
  params: {
    alertName: 'MyAlert'
    conditions: [
      {
        field: 'category'
        equals: 'ServiceHealth'
      }
      anyOf: [
        {
          field: 'properties.incidentType'
          equals: 'Incident'
        }
                {
          field: 'properties.incidentType'
          equals: 'Maintenance'
        }
      ]
      {
        field: 'properties.impactedServices[*].ServiceName'
        containsAny: [
          'Action Groups'
          'Activity Logs & Alerts'
        ]
      } 
    ]
  }
}
```

### Example 3 - Activity Log alert scoped to resource group
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