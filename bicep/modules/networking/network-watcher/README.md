# Network Watcher
This module will create network watcher.

You can optionally configure network watcher with a delete lock.

## Usage

### Example 1 - Network Watcher with delete lock
``` bicep
param nwDeploymentName string = 'networkWatcher${utcNow()}'

module networkWatcher './main.bicep' = {
  name: nwDeploymentName  
  params: {
    networkWatcherName: networkWatcherName
    enableDeleteLock: true
    location: location
  }
}
```

### Example 2 - Network Watcher without delete lock
``` bicep
param nwDeploymentName string = 'networkWatcher${utcNow()}'

module networkWatcher './main.bicep' = {
  name: nwDeploymentName  
  params: {
    networkWatcherName: networkWatcherName   
    location: location
  }
}
```