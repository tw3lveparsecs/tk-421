//  TODO
//  - get working in pipeline

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
}
/*======================================================================
MANAGEMENT
======================================================================*/
param mgmtDeploymentName string = 'mgmt${utcNow()}'

module monitoring 'management/main.bicep' = {
  name: mgmtDeploymentName
  params: {
    orgShortName: orgShortName
    env: env
    location: location
    primaryLocationCode: primaryLocationCode
    tags: tags
  }
}
/*======================================================================
NETWORKING
======================================================================*/
param netwrkDeploymentName string = 'network${utcNow()}'

module networking 'networking/main.bicep' = {
  name: netwrkDeploymentName
  params: {
    env: env
    location: location
    primaryLocationCode: primaryLocationCode
    flowLogsStorageId: monitoring.outputs.flowlogsStorageId
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsId
    tags: tags
  }
}
