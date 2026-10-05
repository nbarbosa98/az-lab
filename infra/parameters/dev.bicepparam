using '../main.bicep'

param location = 'francecentral'
param environment = 'dev'
param workload = 'vmtest'
param regionCode = 'frc'
param tags = {
  environment: 'dev'
  workload: 'vmtest'
  owner: 'nelson'
}
param vnetAddressPrefix = '10.50.0.0/24'
param subnetAddressPrefix = '10.50.0.0/27'
param vmSize = 'Standard_F1als_v7'
param adminUsername = 'azureuser'
// Set IAC_VM_SSH_PUBLIC_KEY to the public key before deploying. It is not stored here.
param adminSshPublicKey = readEnvironmentVariable('IAC_VM_SSH_PUBLIC_KEY', '')
