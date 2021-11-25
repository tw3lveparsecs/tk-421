# Scheduled Query Rule
This module will deploy a schedule query rule within an existing Log Analytics workspace.

## Usage

### Example 1 - Scheduled query rule - AlertingAction
``` bicep
param deploymentName string = 'scheduledqueryrule${utcNow()}'

module scheduledQueryRule 'scheduledqueryrule.bicep' = {
  name: deploymentName
  params: {
    ruleName: 'MyRuleName'
    ruleDescription: 'My AlertingAction Rule'
    query: 'let endDateTime = now(); let startDateTime = ago(1h); let trendBinSize = 1m; TableNAme | where TimeGenerated < endDateTime | where TimeGenerated >= startDateTime'
    workspaceResourceId: 'MyLogAnalyticeWorkspaceId'
    evaluationFrequency: 5
    windowSize: 10
    odataType: 'AlertingAction'
    severity: '3'
    breachesThresholdOperator: 'GreaterThan'
    breachesThreshold: 3
    breachesTriggerType: 'Consecutive'
    metricResultCountThresholdOperator: 'GreaterThan'
    metricResultCountThreshold: 2
  }
}
```

### Example 2 - Scheduled query rule - LogToMetricAction
``` bicep
param deploymentName string = 'scheduledqueryrule${utcNow()}'

module scheduledQueryRule 'scheduledqueryrule.bicep' = {
  name: deploymentName
  params: {
    ruleName: 'MyRuleName'
    ruleDescription: 'My LogToMetricAction Rule'
    query: 'let endDateTime = now(); let startDateTime = ago(1h); let trendBinSize = 1m; TableNAme | where TimeGenerated < endDateTime | where TimeGenerated >= startDateTime'
    workspaceResourceId: 'MyLogAnalyticeWorkspaceId'
    evaluationFrequency: 5
    windowSize: 10
    odataType: 'LogToMetricAction'
    criterias:[
      {
        metricName: 'Average_% Idle Time"'
        dimensions: []
      }
    ]
  }
}
```