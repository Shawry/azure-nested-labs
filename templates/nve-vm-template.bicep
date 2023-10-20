param labName string
param org string
@minLength(17)
@secure()
param adminPassword string
@minLength(3)
@maxLength(15)
param adminUsername string
param location string
param vmSize string
param imageReferenceId string
param vnetName string
param vnetRg string
param nicNsgName string
param nicNsgRg string
param shutdownTime string
param timeZoneId string
param subnetName string
param imageName string
param imageVersion string
param roleAssignmentName string
param accessGroupId string

resource roleGroupAccess 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: roleAssignmentName
  properties: {
    description: 'Lab Access Group'
    principalId: accessGroupId
    principalType: 'Group'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')
  }
}
resource nicNsg 'Microsoft.Network/networkSecurityGroups@2021-05-01' existing = {
  name:   nicNsgName
  scope:  resourceGroup(nicNsgRg)
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-08-01' existing = {
  name: '${vnetName}/${subnetName}'
  scope: resourceGroup(vnetRg)
}

resource nic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: 'vm-nve-${org}-${labName}_nic'
  location: location
  tags: {
    Lab: labName
    Org: org
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnet.id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nicNsg.id
    }
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2021-11-01' = {
  name: 'vm-nve-${org}-${labName}'
  location: location
  tags: {
    Lab: labName
    Org: org
    Image: imageName
    Version: imageVersion
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    licenseType: 'Windows_Server'
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
          properties: {
            primary: true
            deleteOption: 'Delete'
          }
        }
      ]
    }
    osProfile: {
      adminPassword: adminPassword
      adminUsername: adminUsername
      allowExtensionOperations: true
      computerName: 'NVE'
      windowsConfiguration: {
        enableAutomaticUpdates: false
        provisionVMAgent: true
        timeZone: timeZoneId
      }
    }
    priority: 'Regular'
    storageProfile: {
      imageReference: {
        id: imageReferenceId
      }
      osDisk: {
        createOption: 'FromImage'
        deleteOption: 'Delete'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
        name: 'vm-nve-${org}-${labName}_osdisk'
        osType: 'Windows'
        writeAcceleratorEnabled: false
      }
    }
  }
}

resource schedule 'Microsoft.DevTestLab/schedules@2018-09-15' = {
  name: 'shutdown-computevm-vm-nve-${org}-${labName}'
  location: location
  tags: {
    Lab: labName
    Org: org
  }
  properties: {
    dailyRecurrence: {
      time: shutdownTime
    }
    status: 'Enabled'
    targetResourceId: vm.id
    taskType: 'ComputeVmShutdownTask'
    timeZoneId: timeZoneId
  }
}
 output ipAddress string = nic.properties.ipConfigurations[0].properties.privateIPAddress
 output resourceId string = vm.id
