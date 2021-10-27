@description('Managed Identity name')
param managedIdentityName string

@description('Managed Identity location')
param location string = resourceGroup().location

resource userManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: managedIdentityName
  location: location
}
