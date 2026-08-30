// =============================================================================
// modules/bastion.bicep
// Azure Bastion host for secure browser-based RDP/SSH into the lab VMs with no
// public IPs on the VMs themselves. Attaches to the AzureBastionSubnet.
// =============================================================================

@description('Hyphenated name base in the form {org}-{label}-{env}-{region}.')
param nameBase string

@description('Azure Government region.')
param location string

@description('Tags applied to all resources.')
param tags object

@description('Resource ID of the AzureBastionSubnet.')
param bastionSubnetId string

@description('Bastion SKU. Basic is sufficient for a demo lab.')
@allowed([
  'Basic'
  'Standard'
])
param bastionSku string = 'Basic'

var bastionName = '${nameBase}-bas1'
var bastionPipName = '${nameBase}-bas-pip1'

resource bastionPip 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: bastionPipName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2023-11-01' = {
  name: bastionName
  location: location
  tags: tags
  sku: {
    name: bastionSku
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          subnet: {
            id: bastionSubnetId
          }
          publicIPAddress: {
            id: bastionPip.id
          }
        }
      }
    ]
  }
}

output bastionId string = bastion.id
output bastionName string = bastion.name
