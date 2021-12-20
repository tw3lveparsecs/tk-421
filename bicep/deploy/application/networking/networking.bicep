targetScope = 'subscription'

@description('Deployment environment')
param env string

@description('Application Gateway resource group')
param appGwResourceGroup string

@description('Hub subscription id')
param hubSubscriptionId string

@description('Name of existing Application Gateway')
param appGwName string

@description('Object containing existing Application Gateway settings')
@metadata({
  sku: 'Application Gateway sku'
  tier: 'Application Gateway tier'
  enableWebApplicationFirewall: 'Bool to enable web application firewall'
  firewallPolicyName: 'Application Gateway firewall policy name'
  publicIpAddressName: 'Application Gateway public ip address name'
  vNetSubscriptionId: 'Application Gateway virtual network subscription id'
  vNetResourceGroup: 'Application Gateway virtual network resource group'
  vNetName: 'Application Gateway virtual network name'
  subnetName: 'Application Gateway subnet name'
  managedIdentityResourceId: 'Application Gateway managed identity resource id'
  firewallPolicySettings: {
    requestBodyCheck: 'Bool to enable request body check'
    maxRequestBodySizeInKb: 'Integer containing max request body size in kb'
    fileUploadLimitInMb: 'Integer containing file upload limit in mb'
    state: 'Enabled/Disabled. Configures firewall policy settings'
    mode: 'Sets the detection mode'
  }
  firewallPolicyManagedRuleSets: {
    ruleSetType: 'Rule set type'
    ruleSetVersion: 'Rule set version'
  }
})
param appGwSettings object

@description('Application Gateway SSL certificates')
@metadata({
  sslCertificates: [
    {
      name: 'Name of SSL certificate'
      keyVaultResourceId: 'Key vault resource id containing certificate'
      secretName: 'Name of certificate secret within key vault'
    }
  ]
  trustedRootCertificates: [
    {
      name: 'Name of trusted root certificate'
      keyVaultResourceId: 'Key vault resource id containing certificate'
      secretName: 'Name of certificate secret within key vault'
    }
  ]
})
param appGwCertificates object

// @description('Log Analytics Workspace resource id')
// param logAnalyticsWorkspaceId string

// @description('Diagnostic logs storage account resource id')
// param diagnosticLogsStorageId string

/*======================================================================
APPLICATION GATEWAY
======================================================================*/
param appGwDeploymentName string = 'appGw${utcNow()}'

var appGwCustomProbes = [
  {
    name: '${env}-https-aksbaseline-prb'
    protocol: 'Https'
    host: null
    path: '/favicon.ico'
    interval: 30
    timeout: 30
    unhealthyThreshold: 3
    pickHostNameFromBackendHttpSettings: true
    minServers: 0
    match: {}
  }
]
var appGwFrontEndPorts = [
  {
    name: 'port_443'
    port: 443
  }
]
var appGwHttpListeners = [
  {
    name: '${env}-https-443-lst'
    protocol: 'Https'
    frontEndPort: 'port_443'
    sslCertificate: appGwCertificates.sslCertificates[0].name
    hostName: 'tk421.aksbaseline.com'
    firewallPolicy: 'Enabled'
    requireServerNameIndication: true
  }
]
var appGwBackendAddressPools = [
  {
    name: '${env}-aksbaseline-bpl'
    backendAddresses: [
      {
        fqdn: 'tk421-ingress.aksbaseline.com'
      }
    ]
  }
]
var appGwBackendHttpSettings = [
  {
    name: '${env}-aksbaseline-bes'
    port: 443
    protocol: 'Https'
    cookieBasedAffinity: 'Disabled'
    requestTimeout: 20
    connectionDraining: {
      drainTimeoutInSec: 60
      enabled: true
    }
    trustedRootCertificate: appGwCertificates.trustedRootCertificates[0].name
    pickHostNameFromBackendAddress: true
    probeName: appGwCustomProbes[0].name
  }
]
var appGwRules = [
  {
    name: '${env}-https-443-aksbaseline-rle'
    ruleType: 'Basic'
    listener: appGwHttpListeners[0].name
    backendPool: appGwBackendAddressPools[0].name
    backendHttpSettings: appGwBackendHttpSettings[0].name
  }
]

module appGateway '../../../modules/networking/application-gateway/applicationgateway.bicep' = {
  name: appGwDeploymentName
  scope: resourceGroup(hubSubscriptionId, appGwResourceGroup)
  params: {
    applicationGatewayName: appGwName
    sku: appGwSettings.sku
    tier: appGwSettings.tier
    enableWebApplicationFirewall: appGwSettings.enableWebApplicationFirewall
    firewallPolicyName: appGwSettings.firewallPolicyName
    publicIpAddressName: appGwSettings.publicIpAddressName
    vNetResourceGroup: appGwSettings.vNetResourceGroup
    vNetName: appGwSettings.vNetName
    vNetSubscriptionId: appGwSettings.vNetSubscriptionId
    subnetName: appGwSettings.subnetName
    managedIdentityResourceId: appGwSettings.managedIdentityResourceId
    sslCertificates: appGwCertificates.sslCertificates
    trustedRootCertificates: appGwCertificates.trustedRootCertificates
    customProbes: appGwCustomProbes
    frontEndPorts: appGwFrontEndPorts
    httpListeners: appGwHttpListeners
    backendAddressPools: appGwBackendAddressPools
    backendHttpSettings: appGwBackendHttpSettings
    rules: appGwRules
    firewallPolicyManagedRuleSets: appGwSettings.firewallPolicyManagedRuleSets
    firewallPolicySettings: appGwSettings.firewallPolicySettings
  }
}
