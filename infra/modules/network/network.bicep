// =============================================================================
// modules/network/network.bicep
// Virtual network, subnets and NSGs for the Teamcenter tiers.
// NOTE: Address space and subnet layout below are starter defaults — adjust
// to match your Teamcenter network design.
// =============================================================================

@description('Resource name prefix in the form <prefix>-<env>.')
param namePrefixEnv string

@description('Azure Government region.')
param location string

@description('Tags applied to all resources.')
param tags object

@description('VNet address space.')
param vnetAddressPrefix string = '10.50.0.0/16'

@description('Subnet address prefix for the compute (application/web) tier.')
param computeSubnetPrefix string = '10.50.1.0/24'

@description('Subnet address prefix for the database tier.')
param databaseSubnetPrefix string = '10.50.2.0/24'

var vnetName = '${namePrefixEnv}-vnet'
var computeNsgName = '${namePrefixEnv}-compute-nsg'
var databaseNsgName = '${namePrefixEnv}-database-nsg'

resource computeNsg 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: computeNsgName
  location: location
  tags: tags
  properties: {
    // TODO: add Teamcenter compute-tier security rules.
    securityRules: []
  }
}

resource databaseNsg 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: databaseNsgName
  location: location
  tags: tags
  properties: {
    // TODO: add Teamcenter database-tier security rules.
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
    subnets: [
      {
        name: 'compute'
        properties: {
          addressPrefix: computeSubnetPrefix
          networkSecurityGroup: {
            id: computeNsg.id
          }
        }
      }
      {
        name: 'database'
        properties: {
          addressPrefix: databaseSubnetPrefix
          networkSecurityGroup: {
            id: databaseNsg.id
          }
        }
      }
    ]
  }
}

output vnetId string = vnet.id
output vnetName string = vnet.name
output computeSubnetId string = vnet.properties.subnets[0].id
output databaseSubnetId string = vnet.properties.subnets[1].id
