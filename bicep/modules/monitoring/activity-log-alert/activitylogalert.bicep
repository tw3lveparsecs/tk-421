@description('Name of the alert')
param alertName string

@description('Description of the alert.')
param alertDescription string = ''

@description('Location of the alert')
param location string = 'global'

@description('The list of action groups for the alert')
@metadata({
  actionGroupId: 'The resource ID of the Action Group'
  webhookProperties: 'Object containing the dictionary of custom properties to include with the post operation'
})
param actionGroups array = []

@description('The condition that will cause this alert to activate, schema can be found here: https://docs.microsoft.com/en-us/azure/templates/microsoft.insights/2020-10-01/activitylogalerts?tabs=bicep#alertruleallofcondition')
param conditions array

@description('The list of resource id(s) that this alert is scoped to')
param scopes array = [
  subscription().id
]

@description('Enable Alert')
param enableAlert bool = true

var actionGroupConfig = [for action in actionGroups: {
  actionGroupId: contains(action, 'actionGroupId') ? action.actionGroupId : action
  webhookProperties: contains(action, 'webhookProperties') ? action.webhookProperties : null
}]

resource activityLogAlert 'Microsoft.Insights/activityLogAlerts@2020-10-01' = {
  name: alertName
  location: location
  properties: {
    actions: {
      actionGroups: actionGroupConfig
    }
    condition: {
      allOf: conditions
    }
    description: alertDescription
    enabled: enableAlert
    scopes: scopes
  }
}
