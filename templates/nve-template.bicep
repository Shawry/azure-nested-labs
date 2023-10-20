@maxLength(15)
@minLength(3)
param labName string
param org string
param location string
param loc string
param vmSize string
@secure()
param adminPassword string
param adminUsername string
param imageReferenceId string
param shutdownTime string
param timeZoneId string
param subnetName string
param vnetName string
param vnetRg string
param nicNsgName string
param nicNsgRg string
param imageName string
param imageVersion string
param roleAssignmentName string = newGuid()
param accessGroupId string

targetScope = 'subscription'

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'nve-${org}-${labName}-rg'
  location: location
  tags: {
    Lab: labName
    Org: org
  }
}

module vm 'nve-vm-template.bicep' = {
  name: '${org}-${labName}-${loc}-vm-deployment'
  scope: rg
  params: {
    labName:            labName
    org:                org
    location:           location
    vmSize:             vmSize
    timeZoneId:         timeZoneId
    adminUsername:      adminUsername
    adminPassword:      adminPassword
    imageReferenceId:   imageReferenceId
    nicNsgName:         nicNsgName
    nicNsgRg:           nicNsgRg
    vnetName:           vnetName
    vnetRg:             vnetRg
    subnetName:         subnetName
    shutdownTime:       shutdownTime
    imageVersion:       imageVersion
    imageName:          imageName
    roleAssignmentName: roleAssignmentName
    accessGroupId:      accessGroupId
  }
}

output ipAddress string = vm.outputs.ipAddress
output resourceId string = vm.outputs.resourceId
