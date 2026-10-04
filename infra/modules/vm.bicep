@description('Azure region.')
param location string

@description('Name suffix shared by all resources: <workload>-<environment>-<region code>.')
param suffix string

@description('Tags applied to every resource.')
param tags object

@description('Resource ID of the subnet the VM is placed in.')
param subnetId string

@description('Virtual machine size. Must support generation 2 images and the NVMe disk controller.')
param vmSize string

@description('Name of the administrator account.')
param adminUsername string

@description('SSH public key for the administrator account.')
@minLength(60)
param adminSshPublicKey string

// Private address only: there is no public IP configuration on this interface.
resource nic 'Microsoft.Network/networkInterfaces@2025-05-01' = {
  name: 'nic-${suffix}'
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetId
          }
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2025-04-01' = {
  name: 'vm-${suffix}'
  location: location
  tags: tags
  // Identity for future use; no role is assigned to it.
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'ubuntu-24_04-lts'
        sku: 'server'
        version: 'latest'
      }
      osDisk: {
        name: 'osdisk-${suffix}'
        createOption: 'FromImage'
        diskSizeGB: 30
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
        // The disk is removed with the VM so a deleted test leaves nothing billable behind.
        deleteOption: 'Delete'
      }
      // The v7 sizes support only the NVMe disk controller.
      diskControllerType: 'NVMe'
    }
    osProfile: {
      computerName: 'vm-${suffix}'
      adminUsername: adminUsername
      linuxConfiguration: {
        // SSH key only; there is no password to leak or guess.
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: adminSshPublicKey
            }
          ]
        }
      }
    }
    securityProfile: {
      // Trusted Launch: secure boot and a virtual TPM.
      securityType: 'TrustedLaunch'
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
          properties: {
            deleteOption: 'Delete'
          }
        }
      ]
    }
    diagnosticsProfile: {
      // Azure-managed storage; this is also what the serial console needs.
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}

@description('Resource ID of the virtual machine.')
output vmId string = vm.id

@description('Private IP address of the virtual machine.')
output privateIp string = nic.properties.ipConfigurations[0].properties.privateIPAddress
