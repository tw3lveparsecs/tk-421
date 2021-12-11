/*
TODO
- update param desc with metadata and desc/spell check
- test deployment types
- add readme with examples
*/
@description('Application gateway network name.')
param applicationGatewayName string

@description('Application gateway location.')
param location string = resourceGroup().location

@description('Application gateway tier.')
@allowed([
  'Standard'
  'WAF'
  'Standard_v2'
  'WAF_v2'
])
param tier string

@description('Application gateway SKU.')
@allowed([
  'Standard_Small'
  'Standard_Medium'
  'Standard_Large'
  'WAF_Medium'
  'WAF_Large'
  'Standard_v2'
  'WAF_v2'
])
param sku string

@description('Enables HTTP/2 support')
param http2Enabled bool = true

@description('Capacity (instance count) of application gateway.')
@minValue(1)
@maxValue(32)
param capacity int

@description('Capacity (instance count) of application gateway.')
@minValue(1)
@maxValue(32)
param autoScaleMaxCapacity int

@description('Public ip address name.')
param publicIpAddressName string

@description('Virutal network name.')
param vnetResourceId string

@description('Application gateway subnet name.')
param subnetName string

@description('Array containing the ssl certificates.')
param sslCertificates array

@description('Array containing the trusted root certificates.')
param trustedRootCertificates array

@description('Array containing the http listeners.')
param httpListeners array

@description('Array containing the backend address pools.')
param backendAddressPools array

@description('Array containing the backend http settings.')
param backendHttpSettings array

@description('Array containing the routing rules.')
param rules array

@description('Array containing the rules redirect configurations.')
param redirectConfigurations array

@description('Array containing the front end ports.')
param frontEndPorts array

@description('Array containing the custom probes.')
param customProbes array

@description('Resource Id of an User assigned managed identity which will be associated with the App Gateway.')
param managedIdentityResourceId string = ''

@description('Enables web application firewall')
param enableWebApplicationFirewall bool = false

@description('Name of the firewall policy. Only required if enableWebApplicationFirewall is set to true')
param firewallPolicyName string

@description('Array containing the firewall policy settings. Only required if enableWebApplicationFirewall is set to true')
param firewallPolicySettings object = {}

@description('Array containing the firewall policy custom rules. Only required if enableWebApplicationFirewall is set to true')
param firewallPolicyCustomRules array = []

@description('Array containing the firewall policy managed rule sets. Only required if enableWebApplicationFirewall is set to true')
param firewallPolicyManagedRuleSets array = []

@description('Array containing the firewall policy managed rule exclusions. Only required if enableWebApplicationFirewall is set to true')
param firewallPolicyManagedRuleExclusions array = []

@description('Enable delete lock')
param enableDeleteLock bool = false

@description('Enable diagnostic logs')
param enableDiagnostics bool = false

@description('Storage account resource id. Only required if enableDiagnostics is set to true.')
param diagnosticStorageAccountId string = ''

@description('Log analytics workspace resource id. Only required if enableDiagnostics is set to true.')
param logAnalyticsWorkspaceId string = ''

var publicIpLockName = '${publicIpAddress.name}-lck'
var publicIpDiagnosticsName = '${publicIpAddress.name}-dgs'
var appGatewayLockName = '${applicationGateway.name}-lck'
var appGatewayDiagnosticsName = '${applicationGateway.name}-dgs'
var gatewayIpConfigurationName = 'appGatewayIpConfig'
var frontendIpConfigurationName = 'appGwPublicFrontendIp'

resource publicIpAddress 'Microsoft.Network/publicIPAddresses@2021-03-01' = {
  name: publicIpAddressName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource publicIpAddressDiagnostics 'microsoft.insights/diagnosticSettings@2021-05-01-preview' = if (enableDiagnostics) {
  scope: publicIpAddress
  name: publicIpDiagnosticsName
  properties: {
    workspaceId: empty(logAnalyticsWorkspaceId) ? null : logAnalyticsWorkspaceId
    storageAccountId: empty(diagnosticStorageAccountId) ? null : diagnosticStorageAccountId
    logs: [
      {
        category: 'DDoSProtectionNotifications'
        enabled: true
      }
      {
        category: 'DDoSMitigationFlowLogs'
        enabled: true
      }
      {
        category: 'DDoSMitigationReports'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

resource publicIpAddressLock 'Microsoft.Authorization/locks@2017-04-01' = if (enableDeleteLock) {
  scope: publicIpAddress
  name: publicIpLockName
  properties: {
    level: 'CanNotDelete'
  }
}

resource applicationGateway 'Microsoft.Network/applicationGateways@2021-03-01' = {
  name: applicationGatewayName
  location: location
  identity: !empty(managedIdentityResourceId) ? {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityResourceId}': {}
    }
  } : null
  properties: {
    sku: {
      name: sku
      tier: tier
    }
    autoscaleConfiguration: {
      minCapacity: capacity
      maxCapacity: autoScaleMaxCapacity
    }
    enableHttp2: http2Enabled
    webApplicationFirewallConfiguration: enableWebApplicationFirewall ? {
      enabled: true
      firewallMode: 'Detection'
      ruleSetType: 'OWASP'
      ruleSetVersion: '3.0'
    } : null
    gatewayIPConfigurations: [
      {
        name: gatewayIpConfigurationName
        properties: {
          subnet: {
            id: resourceId(vnetResourceId, '/subnets', subnetName)
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: frontendIpConfigurationName
        properties: {
          publicIPAddress: {
            id: publicIpAddress.id
          }
        }
      }
    ]
    frontendPorts: frontEndPorts
    probes: customProbes
    backendAddressPools: backendAddressPools
    firewallPolicy: enableWebApplicationFirewall ? {
      id: firewallPolicy.id
    } : null
    trustedRootCertificates: [for trustedRootCertificate in trustedRootCertificates: {
      name: trustedRootCertificate.name
      properties: {
        keyVaultSecretId: contains(trustedRootCertificate, 'subscriptionId') ? '${reference(resourceId(trustedRootCertificate.subscriptionId, 'Microsoft.KeyVault/vaults', trustedRootCertificate.keyVaultName), '2021-10-01').vaultUri}secrets/${trustedRootCertificate.secretName}' : '${reference(resourceId('Microsoft.KeyVault/vaults', trustedRootCertificate.keyVaultName), '2021-10-01').vaultUri}secrets/${trustedRootCertificate.secretName}'
      }
    }]
    sslCertificates: [for sslCertificate in sslCertificates: {
      name: sslCertificate.name
      properties: {
        keyVaultSecretId: contains(sslCertificate, 'subscriptionId') ? '${reference(resourceId(sslCertificate.subscriptionId, 'Microsoft.KeyVault/vaults', sslCertificate.keyVaultName), '2021-10-01').vaultUri}secrets/${sslCertificate.secretName}' : '${reference(resourceId('Microsoft.KeyVault/vaults', sslCertificate.keyVaultName), '2021-10-01').vaultUri}secrets/${sslCertificate.secretName}'
      }
    }]
    backendHttpSettingsCollection: [for backendHttpSetting in backendHttpSettings: {
      name: backendHttpSetting.name
      properties: {
        port: backendHttpSetting.port
        protocol: backendHttpSetting.protocol
        cookieBasedAffinity: backendHttpSetting.cookieBasedAffinity
        affinityCookieName: contains(backendHttpSetting, 'affinityCookieName') ? backendHttpSetting.affinityCookieName : null
        requestTimeout: backendHttpSetting.requestTimeout
        connectionDraining: backendHttpSetting.connectionDraining
        probe: contains(backendHttpSetting, 'probeName') ? json('{"id": "${resourceId('Microsoft.Network/applicationGateways/probes', applicationGatewayName, backendHttpSetting.probeName)}"}') : null
        trustedRootCertificates: contains(backendHttpSetting, 'trustedRootCertificate') ? json('[{"id": "${resourceId('Microsoft.Network/applicationGateways/trustedRootCertificates', applicationGatewayName, backendHttpSetting.trustedRootCertificate)}"}]') : null
        hostName: contains(backendHttpSetting, 'hostName') ? backendHttpSetting.hostName : null
      }
    }]
    httpListeners: [for httpListener in httpListeners: {
      name: httpListener.name
      properties: {
        frontendIPConfiguration: {
          id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGatewayName, frontendIpConfigurationName)
        }
        frontendPort: {
          id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGatewayName, httpListener.frontEndPort)
        }
        protocol: httpListener.protocol
        sslCertificate: contains(httpListener, 'sslCertificate') ? json('{"id": "${resourceId('Microsoft.Network/applicationGateways/sslCertificates', applicationGatewayName, httpListener.sslCertificate)}"}') : null
        hostNames: contains(httpListener, 'hostNames') ? httpListener.hostNames : null
        hostName: contains(httpListener, 'hostName') ? httpListener.hostName : null
        requireServerNameIndication: contains(httpListener, 'requireServerNameIndication') ? httpListener.requireServerNameIndication : false
        firewallPolicy: contains(httpListener, 'firewallPolicy') ? json('{"id": "${firewallPolicy.id}"}') : null
      }
    }]
    requestRoutingRules: [for rule in rules: {
      name: rule.name
      properties: {
        ruleType: rule.ruleType
        httpListener: contains(rule, 'listener') ? json('{"id": "${resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGatewayName, rule.listener)}"}') : null
        backendAddressPool: contains(rule, 'backendPool') ? json('{"id": "${resourceId('Microsoft.Network/applicationGateways/backendAddressPools', applicationGatewayName, rule.backendPool)}"}') : null
        backendHttpSettings: contains(rule, 'backendHttpSettings') ? json('{"id": "${resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGatewayName, rule.backendHttpSettings)}"}') : null
        redirectConfiguration: contains(rule, 'redirectConfiguration') ? json('{"id": "${resourceId('Microsoft.Network/applicationGateways/redirectConfigurations', applicationGatewayName, rule.redirectConfiguration)}"}') : null
      }
    }]
    redirectConfigurations: [for redirectConfiguration in redirectConfigurations: {
      name: redirectConfiguration.name
      properties: {
        redirectType: redirectConfiguration.redirectType
        targetUrl: redirectConfiguration.targetUrl
        targetListener: contains(redirectConfiguration, 'targetListener') ? json('{"id": "${resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGatewayName, redirectConfiguration.targetListener)}"}') : null
        includePath: redirectConfiguration.includePath
        includeQueryString: redirectConfiguration.includeQueryString
        requestRoutingRules: [
          {
            id: resourceId('Microsoft.Network/applicationGateways/requestRoutingRules', applicationGatewayName, redirectConfiguration.requestRoutingRule)
          }
        ]
      }
    }]
  }
}

resource applicationGatewayDiagnostics 'microsoft.insights/diagnosticSettings@2021-05-01-preview' = if (enableDiagnostics) {
  scope: applicationGateway
  name: appGatewayDiagnosticsName
  properties: {
    workspaceId: empty(logAnalyticsWorkspaceId) ? null : logAnalyticsWorkspaceId
    storageAccountId: empty(diagnosticStorageAccountId) ? null : diagnosticStorageAccountId
    logs: [
      {
        category: 'ApplicationGatewayAccessLog'
        enabled: true
      }
      {
        category: 'ApplicationGatewayPerformanceLog'
        enabled: true
      }
      {
        category: 'ApplicationGatewayFirewallLog'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

resource applicationGatewayLock 'Microsoft.Authorization/locks@2017-04-01' = if (enableDeleteLock) {
  scope: applicationGateway
  name: appGatewayLockName
  properties: {
    level: 'CanNotDelete'
  }
}

resource firewallPolicy 'Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2021-03-01' = if (enableWebApplicationFirewall) {
  name: firewallPolicyName
  location: location
  properties: {
    customRules: firewallPolicyCustomRules
    policySettings: firewallPolicySettings
    managedRules: {
      managedRuleSets: firewallPolicyManagedRuleSets
      exclusions: firewallPolicyManagedRuleExclusions
    }
  }
}

output name string = applicationGateway.name
output id string = applicationGateway.id
