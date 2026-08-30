// =============================================================================
// modules/network.bicep
// Virtual network for the lab landing zone. Contains the mandatory
// AzureBastionSubnet (for Azure Bastion) and a subnet for the domain
// controller. Optionally sets custom DNS servers so the VNet resolves against
// the domain controller after it is promoted (second-pass DNS repoint).
// =============================================================================

@description('Hyphenated name base in the form {org}-{label}-{env}-{region}.')
param nameBase string

@description('Azure Government region.')
param location string

@description('Tags applied to all resources.')
param tags object

@description('VNet address space.')
param vnetAddressPrefix string = '10.60.0.0/16'

@description('Address prefix for the Azure Bastion subnet (must be /26 or larger).')
param bastionSubnetPrefix string = '10.60.0.0/26'

@description('Address prefix for the domain controller subnet.')
param dcSubnetPrefix string = '10.60.1.0/24'

@description('Subnet address prefix for the web tier.')
param webTierSubnetPrefix string = '10.60.2.0/24'

@description('Subnet address prefix for the enterprise tier.')
param enterpriseTierSubnetPrefix string = '10.60.3.0/24'

@description('Subnet address prefix for the resource tier.')
param resourceTierSubnetPrefix string = '10.60.4.0/24'

@description('Custom DNS servers for the VNet. Leave empty to use Azure-provided DNS.')
param dnsServers array = []

var vnetName = '${nameBase}-vnet1'
var dcNsgName = '${nameBase}-dc-nsg1'
var webNsgName = '${nameBase}-web-nsg1'
var enterpriseNsgName = '${nameBase}-enterprise-nsg1'
var resourceNsgName = '${nameBase}-resource-nsg1'

resource dcNsg 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: dcNsgName
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'Allow-RDP-From-VNet'
        properties: {
          priority: 1000
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
        }
      }
    ]
  }
}

resource webNsg 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: webNsgName
  location: location
  tags: tags
  properties: {
    // TODO: add Teamcenter web-tier security rules.
    securityRules: []
  }
}

resource enterpriseNsg 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: enterpriseNsgName
  location: location
  tags: tags
  properties: {
    // TODO: add Teamcenter enterprise-tier security rules.
    securityRules: []
  }
}

resource resourceNsg 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: resourceNsgName
  location: location
  tags: tags
  properties: {
    // TODO: add Teamcenter resource-tier security rules.
    securityRules: []
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    dhcpOptions: empty(dnsServers) ? null : {
      dnsServers: dnsServers
    }
    subnets: [
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: bastionSubnetPrefix
        }
      }
      {
        name: 'dc'
        properties: {
          addressPrefix: dcSubnetPrefix
          networkSecurityGroup: {
            id: dcNsg.id
          }
        }
      }
      {
        name: 'web-tier-sn'
        properties: {
          addressPrefix: webTierSubnetPrefix
          networkSecurityGroup: {
            id: webNsg.id
          }
        }
      }
      {
        name: 'enterprise-tier-sn'
        properties: {
          addressPrefix: enterpriseTierSubnetPrefix
          networkSecurityGroup: {
            id: enterpriseNsg.id
          }
        }
      }
      {
        name: 'resource-tier-sn'
        properties: {
          addressPrefix: resourceTierSubnetPrefix
          networkSecurityGroup: {
            id: resourceNsg.id
          }
        }
      }
    ]
  }
}

output vnetId string = vnet.id
output vnetName string = vnet.name
output bastionSubnetId string = vnet.properties.subnets[0].id
output dcSubnetId string = vnet.properties.subnets[1].id
output webTierSubnetId string = vnet.properties.subnets[2].id
output enterpriseTierSubnetId string = vnet.properties.subnets[3].id
output resourceTierSubnetId string = vnet.properties.subnets[4].id
