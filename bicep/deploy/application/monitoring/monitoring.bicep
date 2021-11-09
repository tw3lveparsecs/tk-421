targetScope = 'subscription'

@description('Organisation short name')
param orgShortName string

@description('Airport location code or alternative short location description')
param primaryLocationCode string

@description('Deployment environment')
param env string

@description('Azure resource location')
param location string

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
