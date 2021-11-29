# Metric Alert
This module will deploy a metric alert.

## Usage

### Example 1 - Metric Alert - MultipleResourceMultipleMetricCriteria
``` bicep
param deploymentName string = 'metricAlert${utcNow()}'

module metricAlert 'metricAlert.bicep' = {
  name: deploymentName
  params: {
    alertName: 'VM CPU'
    alertDescription: 'This alert monitors VM CPU have than 90 percent'
    evaluationFrequency: 'PT1M'
    severity: 3
    targetResourceType: 'Microsoft.Compute/virtualmachines'
    windowSize: 'PT1M'
    scopes: [
      'myResourceGroupResourceId'
    ]
    targetResourceRegion: 'australiaeast'
    alertCriteriaType: 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
    criterias: [
      {
        criterionType: 'StaticThresholdCriterion'
        metricName: 'Percentage CPU'
        metricNamespace: 'Microsoft.Compute/virtualmachines'
        name: 'HighCPU'
        operator: 'GreaterThan'
        threshold: '90'
        timeAggregation: 'Average'
      }
    ]
  }
}
```

### Example 2 - Metric Alert - SingleResourceMultipleMetricCriteria
``` bicep
param deploymentName string = 'metricAlert${utcNow()}'

module metricAlert 'metricAlert.bicep' = {
  name: deploymentName
  params: {
    alertName: 'Restarting cluster container count'
    alertDescription: 'This alert monitors number of containers restarting across the cluster'
    evaluationFrequency: 'PT1M'
    severity: 3
    targetResourceType: 'Microsoft.ContainerService/managedClusters'
    windowSize: 'PT1M'
    scopes: [
      'MyClusterResoucrceId'
    ]    
    alertCriteriaType: 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
    criterias: [
      {
        criterionType: 'StaticThresholdCriterion'
        dimensions: [
          {
            name: 'kubernetes namespace'
            operator: 'Include'
            values: [
              '*'
            ]
          }
          {
            name: 'controllerName'
            operator: 'Include'
            values: [
              '*'
            ]
          }
        ]
        metricName: 'restartingContainerCount'
        metricNamespace: 'Insights.Container/pods'
        name: 'Metric1'
        operator: 'GreaterThan'
        threshold: 0
        timeAggregation: 'Average'
        skipMetricValidation: true
      }
    ]
  }
}
```