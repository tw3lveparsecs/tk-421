@description('Location of the scheduled query rule')
param location string = resourceGroup().location

@description('Name of the scheduled query rule')
param ruleName string

@description('Description of the scheduled query rule')
param ruleDescription string = ''

@description('Enable the scheduled query rule')
param enabled string = 'true'

@description('Resource id of the Log Analytics workspace where the query needs to be executed')
param workspaceResourceId string

@description('The severity of the alert')
@allowed([
  '0'
  '1'
  '2'
  '3'
  '4'
])
param severity string = '3'

@description('How often the metric alert is evaluated (in minutes)')
@allowed([
  5
  10
  15
  30
  45
  60
  120
  180
  240
  300
  360
  1440
])
param evaluationFrequency int = 5

@description('The period of time (in minutes) that is used to monitor alert activity based on the threshold')
@allowed([
  5
  10
  15
  30
  45
  60
  120
  180
  240
  300
  360
  1440
  2880
])
param windowSize int = 60

@description('The list of resource id(s) referenced in the query')
param authorizedResources array = []

@description('The query to execute')
param query string = ''

@description('Operator of threshold breaches to trigger the alert')
@allowed([
  'GreaterThan'
  'Equal'
  'LessThan'
])
param metricResultCountThresholdOperator string = 'GreaterThan'

@description('Operator for metric or number of result evaluation')
@minValue(0)
@maxValue(10000)
param metricResultCountThreshold int = 0

@description('Variable (column) on which the query result will be grouped and then evaluated for trigger condition. Use comma to specify more than one. Leave empty to use "Number of results" type of alert logic')
param metricColumn string = ''

@description('If `metricColumn` is specified, operator for the breaches count evaluation to trigger the alert. Not used if using result count trigger')
@allowed([
  'GreaterThan'
  'Equal'
  'LessThan'
])
param breachesThresholdOperator string = 'GreaterThan'

@description('Type of aggregation of threadshold violation')
@allowed([
  'Consecutive'
  'Total'
])
param breachesTriggerType string = 'Consecutive'

@description('Number of threadshold violation to trigger the alert')
@minValue(0)
@maxValue(10000)
param breachesThreshold int = 3

@description('The list of actions to take when alert triggers')
param actions array = []

@description('The list of action alert creterias')
param criterias array = []

@description('Type of the alert criteria')
@allowed([
  'AlertingAction'
  'LogToMetricAction'
])
param odataType string = 'AlertingAction'

@description('Suppress Alert for (in minutes)')
param suppressForMinutes int = 0

var metricTrigger = {
  metricColumn: metricColumn
  metricTriggerType: breachesTriggerType
  threshold: breachesThreshold
  thresholdOperator: breachesThresholdOperator
}

var action = odataType == 'AlertingAction' ? {
  severity: severity
  aznsAction: {
    actionGroup: actions
  }
  throttlingInMin: suppressForMinutes
  trigger: {
    thresholdOperator: metricResultCountThresholdOperator
    threshold: metricResultCountThreshold
    metricTrigger: (empty(metricColumn) ? null : metricTrigger)
  }
  'odata.type': 'Microsoft.WindowsAzure.Management.Monitoring.Alerts.Models.Microsoft.AppInsights.Nexus.DataContracts.Resources.ScheduledQueryRules.AlertingAction'
} : {
  'odata.type': 'Microsoft.WindowsAzure.Management.Monitoring.Alerts.Models.Microsoft.AppInsights.Nexus.DataContracts.Resources.ScheduledQueryRules.LogToMetricAction'
  criteria: criterias
}

resource scheduledQueryRule 'Microsoft.Insights/scheduledQueryRules@2018-04-16' = {
  name: ruleName
  location: location
  properties: {
    description: ruleDescription
    enabled: enabled
    source: {
      query: query
      authorizedResources: authorizedResources
      dataSourceId: workspaceResourceId
      queryType: 'ResultCount'
    }
    schedule: {
      frequencyInMinutes: evaluationFrequency
      timeWindowInMinutes: windowSize
    }
    action: action
  }
}
