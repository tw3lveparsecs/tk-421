@description('Name of the Alert')
param alertName string

@description('Description of the alert.')
param alertDescription string = ''

@description('Location of the alert.')
param location string = 'global'

@description('Enable alert')
param enabled bool = true

@description('Severity of the alert')
@allowed([
  0
  1
  2
  3
  4
])
param severity int = 3

@description('How often the metric alert is evaluated represented in ISO 8601 duration format')
@allowed([
  'PT1M'
  'PT5M'
  'PT15M'
  'PT30M'
  'PT1H'
])
param evaluationFrequency string = 'PT5M'

@description('The period of time (in ISO 8601 duration format) that is used to monitor alert activity based on the threshold')
@allowed([
  'PT1M'
  'PT5M'
  'PT15M'
  'PT30M'
  'PT1H'
  'PT6H'
  'PT12H'
  'P1D'
])
param windowSize string = 'PT15M'

@description('The list of resource id(s) that this metric alert is scoped to')
param scopes array = [
  subscription().id
]

@description('The resource type of the target resource(s) on which the alert is created/updated. Mandatory for MultipleResourceMultipleMetricCriteria')
param targetResourceType string = ''

@description('The region of the target resource(s) on which the alert is created/updated. Mandatory for MultipleResourceMultipleMetricCriteria')
param targetResourceRegion string = ''

@description('The flag that indicates whether the alert should be auto resolved or not')
param autoMitigate bool = true

@description('The list of actions to take when alert triggers')
param actions array = []

@description('The type of the alert criteria')
@allowed([
  'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
  'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
  'Microsoft.Azure.Monitor.WebtestLocationAvailabilityCriteria'
])
param alertCriteriaType string = 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'

@description('Criterias to trigger the alert')
param criterias array

var actionGroups = [for action in actions: {
  actionGroupId: contains(action, 'actionGroupId') ? action.actionGroupId : action
  webHookProperties: contains(action, 'webHookProperties') ? action.webHookProperties : null
}]

var criteria = alertCriteriaType == 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria' ? {
  'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
  allOf: criterias
} : alertCriteriaType == 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria' ? {
  'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
  allOf: criterias
} : {
  'odata.type': 'Microsoft.Azure.Monitor.WebtestLocationAvailabilityCriteria'
  allOf: criterias
}

resource metricAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: alertName
  location: location
  properties: {
    description: alertDescription
    severity: severity
    enabled: enabled
    scopes: scopes
    evaluationFrequency: evaluationFrequency
    windowSize: windowSize
    targetResourceType: targetResourceType
    targetResourceRegion: targetResourceRegion
    criteria: criteria
    autoMitigate: autoMitigate
    actions: actionGroups
  }
}

output name string = metricAlert.name
output id string = metricAlert.id
