# Managed Identity
This module will deploy a user managed identity.

## Usage

### Example 1 - User Managed Identity
``` bicep
param deploymentName string = 'umi${utcNow()}'

module identity 'main.bicep' = {
  name: deploymentName
  params: {
    managedIdentityName: 'myUserManagedIdentity-umi'
  }
}
```
