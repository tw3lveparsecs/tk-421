targetScope = 'subscription'

@description('Organisation short name')
param orgShortName string

@description('Airport location code or alternative short location description')
param primaryLocationCode string

@description('Deployment environment')
param env string

@description('Azure resource location')
param location string

@description('Application name')
param appName string

@description('Object containing tags')
param tags object
/*======================================================================
RESOURCE GROUPS
======================================================================*/
var appMonitorResourceGroup = '${env}-spoke-monitoring-rgp'

resource appMonitorRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: appMonitorResourceGroup
  location: location
  tags: tags
}
/*======================================================================
LOG ANALYTICS
======================================================================*/
var logAnalyticsName = '${env}-${orgShortName}-${primaryLocationCode}-straightshooter-law'
var lawSku = 'PerGB2018'
var lawRetention = 30
var lawSolutions = [
  {
    name: 'ContainerInsights'
    product: 'OMSGallery/ContainerInsights'
    publisher: 'Microsoft'
    promotionCode: ''
  }
]
var lawSavedSearches = [
  {
    name: 'AllPrometheus'
    etag: '*'
    category: 'Prometheus'
    displayName: 'All collected Prometheus information'
    query: 'InsightsMetrics | where Namespace == "prometheus"'
  }
  {
    name: 'ForbiddenReponsesOnIngress'
    etag: '*'
    category: 'Prometheus'
    displayName: 'Increase number of forbidden response on the Ingress Controller'
    query: 'let value = toscalar(InsightsMetrics | where Namespace == "prometheus" and Name == "traefik_entrypoint_requests_total" | where parse_json(Tags).code == 403 | summarize Value = avg(Val) by bin(TimeGenerated, 5m) | summarize min = min(Value)); InsightsMetrics | where Namespace == "prometheus" and Name == "traefik_entrypoint_requests_total" | where parse_json(Tags).code == 403 | summarize AggregatedValue = avg(Val)-value by bin(TimeGenerated, 5m) | order by TimeGenerated | render barchart"'
  }
  {
    name: 'NodeRebootRequested'
    etag: '*'
    category: 'Prometheus'
    displayName: 'Nodes reboot required by kured'
    query: 'InsightsMetrics | where Namespace == "prometheus" and Name == "kured_reboot_required" | where Val > 0'
  }
]

param lawDeploymentName string = 'logAnalytics${utcNow()}'

module logAnalytics '../../../modules/monitoring/log-analytics/loganalytics.bicep' = {
  name: lawDeploymentName
  scope: resourceGroup(appMonitorRG.name)
  params: {
    name: logAnalyticsName
    sku: lawSku
    retentionInDays: lawRetention
    solutions: lawSolutions
    savedSearches: lawSavedSearches
  }
}
/*======================================================================
SCHEDULED QUERY RULES
======================================================================*/
var clusterName = toLower('${env}-${primaryLocationCode}-${appName}-aks')
var ruleName = 'PodFailedScheduledQuery'
var ruleDescription = 'Alert on pod Failed phase'
var ruleQuery = 'let endDateTime = now(); let startDateTime = ago(1h); let trendBinSize = 1m; let clusterName = "${clusterName}"; KubePodInventory | where TimeGenerated < endDateTime | where TimeGenerated >= startDateTime | where ClusterName == clusterName | distinct ClusterName, TimeGenerated | summarize ClusterSnapshotCount = count() by bin(TimeGenerated, trendBinSize), ClusterName | join hint.strategy=broadcast ( KubePodInventory | where TimeGenerated < endDateTime | where TimeGenerated >= startDateTime | distinct ClusterName, Computer, PodUid, TimeGenerated, PodStatus | summarize TotalCount = count(), PendingCount = sumif(1, PodStatus =~ "Pending"), RunningCount = sumif(1, PodStatus =~ "Running"), SucceededCount = sumif(1, PodStatus =~ "Succeeded"), FailedCount = sumif(1, PodStatus =~ "Failed") by ClusterName, bin(TimeGenerated, trendBinSize) ) on ClusterName, TimeGenerated | extend UnknownCount = TotalCount - PendingCount - RunningCount - SucceededCount - FailedCount | project TimeGenerated, TotalCount = todouble(TotalCount) / ClusterSnapshotCount, PendingCount = todouble(PendingCount) / ClusterSnapshotCount, RunningCount = todouble(RunningCount) / ClusterSnapshotCount, SucceededCount = todouble(SucceededCount) / ClusterSnapshotCount, FailedCount = todouble(FailedCount) / ClusterSnapshotCount, UnknownCount = todouble(UnknownCount) / ClusterSnapshotCount| summarize AggregatedValue = avg(FailedCount) by bin(TimeGenerated, trendBinSize)'
var evaluationFrequency = 5
var windowSize = 10
var odataType = 'AlertingAction'
var severity = '3'
var breachesThresholdOperator = 'GreaterThan'
var breachesThreshold = 3
var breachesTriggerType = 'Consecutive'
var metricResultCountThresholdOperator = 'GreaterThan'
var metricResultCountThreshold = 2

param scheduleQueryRuleDeploymentName string = 'scheduledQueryRule${utcNow()}'

module scheduledQueryRule '../../../modules/monitoring/scheduled-query-rule/scheduledqueryrule.bicep' = {
  name: scheduleQueryRuleDeploymentName
  scope: resourceGroup(appMonitorRG.name)
  params: {
    ruleName: ruleName
    ruleDescription: ruleDescription
    query: ruleQuery
    workspaceResourceId: logAnalytics.outputs.id
    evaluationFrequency: evaluationFrequency
    windowSize: windowSize
    odataType: odataType
    severity: severity
    breachesThresholdOperator: breachesThresholdOperator
    breachesThreshold: breachesThreshold
    breachesTriggerType: breachesTriggerType
    metricResultCountThresholdOperator: metricResultCountThresholdOperator
    metricResultCountThreshold: metricResultCountThreshold
  }
}
