@description('Azure region.')
param location string

@description('Name suffix shared by all resources: <workload>-<environment>-<region code>.')
param suffix string

@description('Tags applied to every resource.')
param tags object

@description('Address space of the virtual network, in CIDR notation.')
param vnetAddressPrefix string

@description('Address range of the VM subnet, in CIDR notation.')
param subnetAddressPrefix string

// No custom rules on purpose: Azure's default rules deny all inbound traffic from the
// internet and allow traffic inside the virtual network.
resource nsg 'Microsoft.Network/networkSecurityGroups@2025-05-01' = {
  name: 'nsg-${suffix}'
  location: location
  tags: tags
  properties: {
    securityRules: []
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2025-05-01' = {
  name: 'vnet-${suffix}'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [vnetAddressPrefix]
    }
    subnets: [
      {
        name: 'snet-vm'
        properties: {
          addressPrefix: subnetAddressPrefix
          networkSecurityGroup: {
            id: nsg.id
          }
          // Private subnet: no implicit outbound internet access. Outbound access needs
          // an explicit NAT gateway, which this deployment deliberately does not have.
          defaultOutboundAccess: false
        }
      }
    ]
  }
}

@description('Resource ID of the VM subnet.')
output subnetId string = vnet.properties.subnets[0].id
