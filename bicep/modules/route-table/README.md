# Route Table
This module will deploy a Route Table with routes and optionally a delete lock. 

## Usage

### Example 1 - Route table with delete lock
``` bicep
param deploymentName string = 'udr${utcNow()}'

module udr './main.bicep' = {
  name: deploymentName
  params: {
    routeTableName: 'MyRouteTable'
    routes: [
      {
        name: 'rule1'
        addressPrefix: '0.0.0.0/0'
        nextHopType: 'VnetLocal'
      }
    ]
    enableDeleteLock: true
  }
}
```

### Example 2 - Route table without delete lock
``` bicep
param deploymentName string = 'udr${utcNow()}'

module udr './main.bicep' = {
  name: deploymentName
  params: {
    routeTableName: 'MyRouteTable'
    routes: [
      {
        name: 'rule1'
        addressPrefix: '0.0.0.0/0'
        nextHopType: 'VnetLocal'
      }
     {
        name: 'rule2'
        addressPrefix: '192.168.0.0/24'
        nextHopType: 'VirtualAppliance'
        nextHopIpAddress: '10.0.1.4'
      }
    ]    
  }
}
```