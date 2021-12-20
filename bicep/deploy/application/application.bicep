targetScope = 'subscription'
/*======================================================================
COMMON VARIABLES
======================================================================*/
var orgShortName = 'tk421'
var location = 'AustraliaEast'
var primaryLocationCode = 'syd'
var env = 'dev'
var tags = {
  project: 'tk-421'
  environment: env
  application: 'aksbaseline'
}
var appName = 'aksbaseline'
/*======================================================================
RESOURCE GROUPS
======================================================================*/
var appMonitorResourceGroup = '${env}-spoke-monitoring2-rgp'
var appResourceGroup = '${env}-spoke-straightshooter2-rgp'

resource appMonitorRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: appMonitorResourceGroup
  location: location
  tags: tags
}

resource applicationRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: appResourceGroup
  location: location
  tags: tags
}

/*======================================================================
MONITORING
======================================================================*/
param monitorDeploymentName string = 'monitoring${utcNow()}'

module monitoring 'monitoring/monitoring.bicep' = {
  name: monitorDeploymentName
  params: {
    env: env
    orgShortName: orgShortName
    primaryLocationCode: primaryLocationCode
    appName: appName
    monitorResourceGroup: appMonitorRG.name
    clusterResourceGroup: applicationRG.name
  }
}
/*======================================================================
CLUSTER
======================================================================*/
param clusterDeploymentName string = 'cluster${utcNow()}'

var spokeVnetResourceGroup = '${env}-spoke-network-rgp'
var spokeVnetName = '${env}-${primaryLocationCode}-straightshooter-vnw'
var acrPrivateEndpointSubnetName = 'AksNodes'
var acrDnsZoneName = 'privatelink.azurecr.io'
var hubNetworkResourceGroup = '${env}-hub-network-rgp'
var hubSubscription = subscription().subscriptionId // replace with hub subscription id if hub exists in a different subscription to spoke

resource spokeVnet 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  name: spokeVnetName
  scope: resourceGroup(spokeVnetResourceGroup)
}

resource acrDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: acrDnsZoneName
  scope: resourceGroup(hubSubscription, hubNetworkResourceGroup)
}

module cluster 'cluster/cluster.bicep' = {
  name: clusterDeploymentName
  params: {
    env: env
    clusterResourceGroup: applicationRG.name
    acrPrivateEndpointSubnetId: '${spokeVnet.id}/subnets/${acrPrivateEndpointSubnetName}'
    acrPrivateDnsZoneId: acrDnsZone.id
  }
}

/*======================================================================
NETWORKING
======================================================================*/
param networkingDeploymentName string = 'appnetworking${utcNow()}'

var appGwName = '${env}-${primaryLocationCode}-hub-agw'
var appGwManagedIdentityName = '${appGwName}-umi'
var appGwFirewallPolicyName = '${appGwName}-pol'

resource appGw 'Microsoft.Network/applicationGateways@2021-03-01' existing = {
  name: appGwName
  scope: resourceGroup(hubSubscription, hubNetworkResourceGroup)
}

resource appGwManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = {
  name: appGwManagedIdentityName
  scope: resourceGroup(hubSubscription, hubNetworkResourceGroup)
}

resource appGwFirewallPolicy 'Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2021-03-01' existing = {
  name: appGwFirewallPolicyName
  scope: resourceGroup(hubSubscription, hubNetworkResourceGroup)
}

module networking 'networking/networking.bicep' = {
  name: networkingDeploymentName
  params: {
    env: env
    appGwName: appGw.name
    appGwResourceGroup: hubNetworkResourceGroup
    hubSubscriptionId: hubSubscription
    appGwSettings: {
      sku: appGw.properties.sku.name
      tier: appGw.properties.sku.tier
      enableWebApplicationFirewall: appGw.properties.webApplicationFirewallConfiguration.enabled
      firewallPolicyName: split(appGw.properties.firewallPolicy.id, '/')[8]
      publicIpAddressName: split(appGw.properties.frontendIPConfigurations[0].properties.publicIPAddress.id, '/')[8]
      vNetSubscriptionId: split(appGw.properties.gatewayIPConfigurations[0].properties.subnet.id, '/')[2]
      vNetResourceGroup: split(appGw.properties.gatewayIPConfigurations[0].properties.subnet.id, '/')[4]
      vNetName: split(appGw.properties.gatewayIPConfigurations[0].properties.subnet.id, '/')[8]
      subnetName: split(appGw.properties.gatewayIPConfigurations[0].properties.subnet.id, '/')[10]
      managedIdentityResourceId: appGwManagedIdentity.id
      firewallPolicySettings: appGwFirewallPolicy.properties.policySettings
      firewallPolicyManagedRuleSets: appGwFirewallPolicy.properties.managedRules.managedRuleSets
    }
    appGwCertificates: {
      sslCertificates: [
        {
          name: // update once key vault module added
          keyVaultResourceId: // update once key vault module added
          secretName: // update once key vault module added
        }
      ]
      trustedRootCertificates: [
        {
          name: // update once key vault module added
          keyVaultResourceId: // update once key vault module added
          secretName: // update once key vault module added
        }
      ]
    }
  }
}
