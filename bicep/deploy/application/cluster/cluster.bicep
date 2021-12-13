/* TODO
- ROLE ASSIGNMENTS
- AKS
- IDENTITIES
- KV
- EVENT GRID
- POLICY ASSIGMENTS
*/

targetScope = 'subscription'

@description('Deployment environment')
param env string

@description('Subnet resource id for ACR private endpoint')
param acrPrivateEndpointSubnetId string

@description('ACR private dns zone resource id')
param acrPrivateDnsZoneId string

@description('Object containing the cluster resource group')
param clusterResourceGroup string
/*======================================================================
ACR
======================================================================*/
param acrDeploymentName string = 'acr${utcNow()}'

var acrName = '${env}tk421straightshooteracr'
var acrSku = 'Premium'
var acrIpRules = {
  defaultAction: 'Deny'
  ipRules: []
}
var acrPolicies = {
  exportPolicy: {
    status: 'disabled'
  }
  quarantinePolicy: {
    status: 'disabled'
  }
  retentionPolicy: {
    status: 'enabled'
    days: 15
  }
  trustPolicy: {
    status: 'disabled'
  }
}
var acrPublicNetworkAccess = 'Disabled'
var acrNetworkRuleBypassOptions = 'AzureServices'
var acrZoneRedundancy = 'Enabled'

module acr '../../../modules/containerisation/azure-container-registry/acr.bicep' = {
  name: acrDeploymentName
  scope: resourceGroup(clusterResourceGroup)
  params: {
    acrName: acrName
    acrSku: acrSku
    ipRules: acrIpRules
    policies: acrPolicies
    publicNetworkAccess: acrPublicNetworkAccess
    networkRuleBypassOptions: acrNetworkRuleBypassOptions
    zoneRedundancy: acrZoneRedundancy
  }
}
/*======================================================================
PRIVATE ENDPOINTS
======================================================================*/
param acrPepDeploymentName string = 'acrPep${utcNow()}'

var acrPepName = '${acr.outputs.name}-pep'

module acrPep '../../../modules/networking/private-endpoint/private-endpoint.bicep' = {
  name: acrPepDeploymentName
  scope: resourceGroup(clusterResourceGroup)
  params: {
    privateEndpointName: acrPepName
    targetResourceId: acr.outputs.id
    groupIds: [
      'registry'
    ]
    privateEndpointSubnetId: acrPrivateEndpointSubnetId
    privateDnsZoneId: acrPrivateDnsZoneId
  }
}
/*======================================================================
ALERTS
======================================================================*/
param deploymentName string = 'metricAlert${utcNow()}'

var metricAlerts = [
  {
    alertName: 'Node CPU utilisation high for ${clusterName}' // update variable with cluster name once cluster module added
    alertDescription: 'Node CPU utilisation across the cluster'
    evaluationFrequency: 'PT1M'
    severity: 3
    targetResourceType: 'Microsoft.ContainerService/managedclusters'
    windowSize: 'PT5M'
    scopes: [
      clusterId // update with cluster id once cluster module added
    ]
    alertCriteriaType: 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
    criterias: [
      {
        criterionType: 'StaticThresholdCriterion'
        dimensions: [
          {
            name: 'host'
            operator: 'Include'
            values: [
              '*'
            ]
          }
        ]
        metricName: 'cpuUsagePercentage'
        metricNamespace: 'Insights.Container/nodes'
        name: 'Metric1'
        operator: 'GreaterThan'
        threshold: 80
        timeAggregation: 'Average'
        skipMetricValidation: true
      }
    ]
    targetResourceRegion: ''
    actions: []
    autoMitigate: true
  }
  {
    alertName: 'Node working set memory utilisation high for ${clusterName}' // update variable with cluster name once cluster module added
    alertDescription: 'Node working set memory utilisation across the cluster'
    evaluationFrequency: 'PT1M'
    severity: 3
    targetResourceType: 'Microsoft.ContainerService/managedclusters'
    windowSize: 'PT5M'
    scopes: [
      clusterId // update with cluster id once cluster module added
    ]
    alertCriteriaType: 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
    criterias: [
      {
        criterionType: 'StaticThresholdCriterion'
        dimensions: [
          {
            name: 'host'
            operator: 'Include'
            values: [
              '*'
            ]
          }
        ]
        metricName: 'memoryWorkingSetPercentage'
        metricNamespace: 'Insights.Container/nodes'
        name: 'Metric1'
        operator: 'GreaterThan'
        threshold: 80
        timeAggregation: 'Average'
        skipMetricValidation: true
      }
    ]
    targetResourceRegion: ''
    actions: []
    autoMitigate: true
  }
  {
    alertName: 'Jobs completed more than 6 hours ago for ${clusterName}' // update variable with cluster name once cluster module added
    alertDescription: 'This alert monitors completed jobs (more than 6 hours ago)'
    evaluationFrequency: 'PT1M'
    severity: 3
    targetResourceType: 'Microsoft.ContainerService/managedclusters'
    windowSize: 'PT1M'
    scopes: [
      clusterId // update with cluster id once cluster module added
    ]
    alertCriteriaType: 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
    criterias: [
      {
        criterionType: 'StaticThresholdCriterion'
        dimensions: [
          {
            name: 'controllerName'
            operator: 'Include'
            values: [
              '*'
            ]
          }
          {
            name: 'kubernetes namespace'
            operator: 'Include'
            values: [
              '*'
            ]
          }
        ]
        metricName: 'completedJobsCount'
        metricNamespace: 'Insights.Container/pods'
        name: 'Metric1'
        operator: 'GreaterThan'
        threshold: 0
        timeAggregation: 'Average'
        skipMetricValidation: true
      }
    ]
    targetResourceRegion: ''
    actions: []
    autoMitigate: true
  }
  {
    alertName: 'Container CPU usage high for ${clusterName}' // update variable with cluster name once cluster module added
    alertDescription: 'This alert monitors container CPU utilisation'
    evaluationFrequency: 'PT1M'
    severity: 3
    targetResourceType: 'Microsoft.ContainerService/managedclusters'
    windowSize: 'PT5M'
    scopes: [
      clusterId // update with cluster id once cluster module added
    ]
    alertCriteriaType: 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
    criterias: [
      {
        criterionType: 'StaticThresholdCriterion'
        dimensions: [
          {
            name: 'controllerName'
            operator: 'Include'
            values: [
              '*'
            ]
          }
          {
            name: 'kubernetes namespace'
            operator: 'Include'
            values: [
              '*'
            ]
          }
        ]
        metricName: 'cpuExceededPercentage'
        metricNamespace: 'Insights.Container/containers'
        name: 'Metric1'
        operator: 'GreaterThan'
        threshold: 90
        timeAggregation: 'Average'
        skipMetricValidation: true
      }
    ]
    targetResourceRegion: ''
    actions: []
    autoMitigate: true
  }
  {
    alertName: 'Container working set memory usage high for ${clusterName}' // update variable with cluster name once cluster module added
    alertDescription: 'This alert monitors container working set memory utilisation'
    evaluationFrequency: 'PT1M'
    severity: 3
    targetResourceType: 'Microsoft.ContainerService/managedclusters'
    windowSize: 'PT5M'
    scopes: [
      clusterId // update with cluster id once cluster module added
    ]
    alertCriteriaType: 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
    criterias: [
      {
        criterionType: 'StaticThresholdCriterion'
        dimensions: [
          {
            name: 'controllerName'
            operator: 'Include'
            values: [
              '*'
            ]
          }
          {
            name: 'kubernetes namespace'
            operator: 'Include'
            values: [
              '*'
            ]
          }
        ]
        metricName: 'memoryWorkingSetExceededPercentage'
        metricNamespace: 'Insights.Container/containers'
        name: 'Metric1'
        operator: 'GreaterThan'
        threshold: 90
        timeAggregation: 'Average'
        skipMetricValidation: true
      }
    ]
    targetResourceRegion: ''
    actions: []
    autoMitigate: true
  }
  {
    alertName: 'Pods in failed state for ${clusterName}' // update variable with cluster name once cluster module added
    alertDescription: 'Pod status monitoring'
    evaluationFrequency: 'PT1M'
    severity: 3
    targetResourceType: 'Microsoft.ContainerService/managedclusters'
    windowSize: 'PT5M'
    scopes: [
      clusterId // update with cluster id once cluster module added
    ]
    alertCriteriaType: 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
    criterias: [
      {
        criterionType: 'StaticThresholdCriterion'
        dimensions: [
          {
            name: 'phase'
            operator: 'Include'
            values: [
              'Failed'
            ]
          }
        ]
        metricName: 'podCount'
        metricNamespace: 'Insights.Container/pods'
        name: 'Metric1'
        operator: 'GreaterThan'
        threshold: 0
        timeAggregation: 'Average'
        skipMetricValidation: true
      }
    ]
    targetResourceRegion: ''
    actions: []
    autoMitigate: true
  }
  {
    alertName: 'Disk usage high for ${clusterName}' // update variable with cluster name once cluster module added
    alertDescription: 'This alert monitors disk usage for all nodes and storage devices'
    evaluationFrequency: 'PT1M'
    severity: 3
    targetResourceType: 'Microsoft.ContainerService/managedclusters'
    windowSize: 'PT5M'
    scopes: [
      clusterId // update with cluster id once cluster module added
    ]
    alertCriteriaType: 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
    criterias: [
      {
        criterionType: 'StaticThresholdCriterion'
        dimensions: [
          {
            name: 'host'
            operator: 'Include'
            values: [
              '*'
            ]
          }
          {
            name: 'device'
            operator: 'Include'
            values: [
              '*'
            ]
          }
        ]
        metricName: 'DiskUsedPercentage'
        metricNamespace: 'Insights.Container/nodes'
        name: 'Metric1'
        operator: 'GreaterThan'
        threshold: 80
        timeAggregation: 'Average'
        skipMetricValidation: true
      }
    ]
    targetResourceRegion: ''
    actions: []
    autoMitigate: true
  }
  {
    alertName: 'Nodes in not ready status for ${clusterName}' // update variable with cluster name once cluster module added
    alertDescription: 'Node status monitoring'
    evaluationFrequency: 'PT1M'
    severity: 3
    targetResourceType: 'Microsoft.ContainerService/managedclusters'
    windowSize: 'PT5M'
    scopes: [
      clusterId // update with cluster id once cluster module added
    ]
    alertCriteriaType: 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
    criterias: [
      {
        criterionType: 'StaticThresholdCriterion'
        dimensions: [
          {
            name: 'status'
            operator: 'Include'
            values: [
              'NotReady'
            ]
          }
        ]
        metricName: 'nodesCount'
        metricNamespace: 'Insights.Container/nodes'
        name: 'Metric1'
        operator: 'GreaterThan'
        threshold: 0
        timeAggregation: 'Average'
        skipMetricValidation: true
      }
    ]
    targetResourceRegion: ''
    actions: []
    autoMitigate: true
  }
  {
    alertName: 'Containers getting OOM killed for ${clusterName}' // update variable with cluster name once cluster module added
    alertDescription: 'This alert monitors number of containers killed due to out of memory (OOM) error'
    evaluationFrequency: 'PT1M'
    severity: 3
    targetResourceType: 'Microsoft.ContainerService/managedclusters'
    windowSize: 'PT1M'
    scopes: [
      clusterId // update with cluster id once cluster module added
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
        metricName: 'oomKilledContainerCount'
        metricNamespace: 'Insights.Container/pods'
        name: 'Metric1'
        operator: 'GreaterThan'
        threshold: 0
        timeAggregation: 'Average'
        skipMetricValidation: true
      }
    ]
    targetResourceRegion: ''
    actions: []
    autoMitigate: true
  }
  {
    alertName: 'Persistent volume usage high for ${clusterName}' // update variable with cluster name once cluster module added
    alertDescription: 'This alert monitors persistent volume utilisation'
    evaluationFrequency: 'PT1M'
    severity: 3
    targetResourceType: 'Microsoft.ContainerService/managedclusters'
    windowSize: 'PT5M'
    scopes: [
      clusterId // update with cluster id once cluster module added
    ]
    alertCriteriaType: 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
    criterias: [
      {
        criterionType: 'StaticThresholdCriterion'
        dimensions: [
          {
            name: 'podName'
            operator: 'Include'
            values: [
              '*'
            ]
          }
          {
            name: 'kubernetesNamespace'
            operator: 'Include'
            values: [
              '*'
            ]
          }
        ]
        metricName: 'pvUsageExceededPercentage'
        metricNamespace: 'Insights.Container/persistentvolumes'
        name: 'Metric1'
        operator: 'GreaterThan'
        threshold: 80
        timeAggregation: 'Average'
        skipMetricValidation: true
      }
    ]
    targetResourceRegion: ''
    actions: []
    autoMitigate: true
  }
  {
    alertName: 'Pods not in ready state for ${clusterName}' // update variable with cluster name once cluster module added
    alertDescription: 'This alert monitors for excessive pods not in the ready state'
    evaluationFrequency: 'PT1M'
    severity: 3
    targetResourceType: 'Microsoft.ContainerService/managedclusters'
    windowSize: 'PT5M'
    scopes: [
      clusterId // update with cluster id once cluster module added
    ]
    alertCriteriaType: 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
    criterias: [
      {
        criterionType: 'StaticThresholdCriterion'
        dimensions: [
          {
            name: 'controllerName'
            operator: 'Include'
            values: [
              '*'
            ]
          }
          {
            name: 'kubernetes namespace'
            operator: 'Include'
            values: [
              '*'
            ]
          }
        ]
        metricName: 'PodReadyPercentage'
        metricNamespace: 'Insights.Container/pods'
        name: 'Metric1'
        operator: 'LessThan'
        threshold: 80
        timeAggregation: 'Average'
        skipMetricValidation: true
      }
    ]
    targetResourceRegion: ''
    actions: []
    autoMitigate: true
  }
  {
    alertName: 'Restarting container count for ${clusterName}' // update variable with cluster name once cluster module added
    alertDescription: 'This alert monitors number of containers restarting across the cluster'
    evaluationFrequency: 'PT1M'
    severity: 3
    targetResourceType: 'Microsoft.ContainerService/managedclusters'
    windowSize: 'PT1M'
    scopes: [
      clusterId // update with cluster id once cluster module added
    ]
    alertCriteriaType: 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
    criterias: [
      {
        criterionType: 'StaticThresholdCriterion'
        dimensions: [
          {
            name: 'controllerName'
            operator: 'Include'
            values: [
              '*'
            ]
          }
          {
            name: 'kubernetes namespace'
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
    targetResourceRegion: ''
    actions: []
    autoMitigate: true
  }
]

module metricAlert '../../../modules/monitoring/metric-alert/metricalert.bicep' = [for alert in metricAlerts: {
  name: '${deploymentName}${uniqueString(alert.alertName)}'
  scope: resourceGroup(clusterResourceGroup)
  params: {
    alertName: alert.alertName
    alertDescription: alert.alertDescription
    evaluationFrequency: alert.evaluationFrequency
    severity: alert.severity
    targetResourceType: alert.targetResourceType
    windowSize: alert.windowSize
    scopes: alert.scopes
    targetResourceRegion: alert.targetResourceRegion
    alertCriteriaType: alert.alertCriteriaType
    criterias: alert.criterias
    actions: alert.actions
    autoMitigate: alert.autoMitigate
  }
}]
