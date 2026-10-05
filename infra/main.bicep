targetScope = 'subscription'

@description('Azure region for the resource group and everything in it.')
param location string

@description('Environment name, used in resource names and tags.')
@allowed(['dev'])
param environment string

@description('Short workload name, used in resource names and tags.')
@minLength(2)
@maxLength(12)
param workload string

@description('Short code for the region, used in resource names (for example frc for France Central).')
@minLength(2)
@maxLength(5)
param regionCode string

@description('Tags applied to the resource group and every resource.')
param tags object

@description('Address space of the virtual network, in CIDR notation.')
param vnetAddressPrefix string

@description('Address range of the VM subnet, in CIDR notation. Must lie inside the virtual network address space.')
param subnetAddressPrefix string

@description('Virtual machine size.')
param vmSize string

@description('Name of the administrator account on the VM.')
param adminUsername string

@description('SSH public key for the administrator account. A public key is not a secret; it is still passed in at deployment time and not stored in the repository.')
@minLength(60)
param adminSshPublicKey string

var suffix = '${workload}-${environment}-${regionCode}'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: 'rg-${suffix}'
  location: location
  tags: tags
}

module network 'modules/network.bicep' = {
  name: 'network-${suffix}'
  scope: resourceGroup
  params: {
    location: location
    suffix: suffix
    tags: tags
    vnetAddressPrefix: vnetAddressPrefix
    subnetAddressPrefix: subnetAddressPrefix
  }
}

module vm 'modules/vm.bicep' = {
  name: 'vm-${suffix}'
  scope: resourceGroup
  params: {
    location: location
    suffix: suffix
    tags: tags
    subnetId: network.outputs.subnetId
    vmSize: vmSize
    adminUsername: adminUsername
    adminSshPublicKey: adminSshPublicKey
  }
}

@description('Name of the resource group that holds the deployment.')
output resourceGroupName string = resourceGroup.name

@description('Resource ID of the virtual machine.')
output vmId string = vm.outputs.vmId

@description('Private IP address of the virtual machine.')
output vmPrivateIp string = vm.outputs.privateIp
