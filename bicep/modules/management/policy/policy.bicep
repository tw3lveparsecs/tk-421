@maxLength(64)
@description('Name of the policy assignment. Maximum length is 64 characters for resource group scope')
param policyAssignmentName string

@description('Policy assignment location')
param location string = resourceGroup().location

@description('Policy assignment description')
param policyAssignmentDescription string = ''

@description('Policy assignment display name. Maximum length is 128 characters')
@maxLength(128)
param displayName string = ''

@description('ID of the policy definition or policy set definition being assigned')
param policyDefinitionId string

@description('Parameters for the policy assignment if needed')
param parameters object = {}

@description('Managed identity associated with the policy assignment')
@allowed([
  'SystemAssigned'
  'None'
])
param identity string = 'SystemAssigned'

@description('The IDs of the Azure Role Definition list that is used to assign permissions to the identity. You need to provide either the fully qualified ID in the following format: \'/providers/Microsoft.Authorization/roleDefinitions/c2f4ef07-c644-48eb-af81-4b1b4947fb11\'.. See https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles for the list IDs for built-in Roles. They must match on what is on the policy definition')
param roleDefinitionIds array = []

@description('The message that describe why a resource is non-compliant with the policy')
param nonComplianceMessage string = ''

@description('The policy assignment enforcement mode')
@allowed([
  'Default'
  'DoNotEnforce'
])
param enforcementMode string = 'Default'

@description('The policy excluded scopes')
param notScopes array = []

@description('The subscription ID of the subscription for the policy assignment')
param subscriptionId string = subscription().subscriptionId

@description('The name of the resource group for the policy assignment')
param resourceGroupName string = resourceGroup().name

var nonCompliantMessage = {
  message: !empty(nonComplianceMessage) ? nonComplianceMessage : null
}

var managedIdentity = identity == 'SystemAssigned' ? {
  type: identity
} : null

resource policyAssignment 'Microsoft.Authorization/policyAssignments@2021-06-01' = {
  name: policyAssignmentName
  location: location
  properties: {
    displayName: !empty(displayName) ? displayName : null
    description: !empty(policyAssignmentDescription) ? policyAssignmentDescription : null
    policyDefinitionId: policyDefinitionId
    parameters: parameters
    nonComplianceMessages: !empty(nonComplianceMessage) ? array(nonCompliantMessage) : []
    enforcementMode: enforcementMode
    notScopes: !empty(notScopes) ? notScopes : []
  }
  identity: managedIdentity
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = [for roleDefinitionId in roleDefinitionIds: if (!empty(roleDefinitionIds) && identity != 'None') {
  name: guid(subscriptionId, resourceGroupName, roleDefinitionId, location, policyAssignmentName)
  properties: {
    roleDefinitionId: roleDefinitionId
    principalId: policyAssignment.identity.principalId
    principalType: 'ServicePrincipal'
  }
}]

output name string = policyAssignment.name
output id string = policyAssignment.id
output managedIdentityId string = identity == 'SystemAssigned' ? policyAssignment.identity.principalId : ''
