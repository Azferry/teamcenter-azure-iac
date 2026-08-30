// =============================================================================
// modules/network.bicep
// Virtual network, subnets and NSGs for the Teamcenter tiers.
//
// Supports two modes:
//   * Create mode  (deployVnet = true, default): this module provisions the
//     VNet, subnets and NSGs.
//   * Bring-your-own (deployVnet = false): this module references an existing
//     VNet/subnets (in this subscription, optionally a different resource
//     group). No VNet/NSG resources are created; NSGs are assumed to be
//     managed by the client.
//
// NOTE: Address space and subnet layout below are starter defaults — adjust
// to match your Teamcenter network design.
// =============================================================================

@description('Hyphenated name base in the form {org}-{label}-{env}-{region}.')
param nameBase string

@description('Azure Government region.')
param location string

@description('Tags applied to all resources.')
param tags object

@description('When true, create the VNet/subnets/NSGs. When false, reference an existing VNet (bring-your-own).')
param deployVnet bool = true

@description('BYO mode: name of the existing VNet to reference. Required when deployVnet = false.')
param existingVnetName string = ''

@description('BYO mode: resource group of the existing VNet. Defaults to the current resource group when blank.')
param existingVnetResourceGroup string = ''

@description('BYO mode: name of the existing subnet for the web tier.')
param existingWebTierSubnetName string = 'web-tier-sn'

@description('BYO mode: name of the existing subnet for the enterprise tier.')
param existingEnterpriseTierSubnetName string = 'enterprise-tier-sn'

@description('BYO mode: name of the existing subnet for the resource tier.')
param existingResourceTierSubnetName string = 'resource-tier-sn'

@description('VNet address space.')
param vnetAddressPrefix string = '10.50.0.0/16'

@description('Subnet address prefix for the web tier.')
param webTierSubnetPrefix string = '10.50.1.0/24'

@description('Subnet address prefix for the enterprise tier.')
param enterpriseTierSubnetPrefix string = '10.50.2.0/24'

@description('Subnet address prefix for the resource tier.')
param resourceTierSubnetPrefix string = '10.50.3.0/24'

var vnetName = '${nameBase}-vnet1'
var webNsgName = '${nameBase}-web-nsg1'
var enterpriseNsgName = '${nameBase}-enterprise-nsg1'
var resourceNsgName = '${nameBase}-resource-nsg1'

// Resolve the resource group that holds the existing VNet in BYO mode.
var existingVnetRg = empty(existingVnetResourceGroup) ? resourceGroup().name : existingVnetResourceGroup

resource webNsg 'Microsoft.Network/networkSecurityGroups@2023-11-01' = if (deployVnet) {
  name: webNsgName
  location: location
  tags: tags
  properties: {
    // TODO: add Teamcenter web-tier security rules.
    securityRules: []
  }
}

resource enterpriseNsg 'Microsoft.Network/networkSecurityGroups@2023-11-01' = if (deployVnet) {
  name: enterpriseNsgName
  location: location
  tags: tags
  properties: {
    // TODO: add Teamcenter enterprise-tier security rules.
    securityRules: []
  }
}

resource resourceNsg 'Microsoft.Network/networkSecurityGroups@2023-11-01' = if (deployVnet) {
  name: resourceNsgName
  location: location
  tags: tags
  properties: {
    // TODO: add Teamcenter resource-tier security rules.
    securityRules: []
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = if (deployVnet) {
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

// BYO mode: reference the existing VNet (same subscription, any resource group).
resource existingVnet 'Microsoft.Network/virtualNetworks@2023-11-01' existing = if (!deployVnet) {
  name: existingVnetName
  scope: resourceGroup(existingVnetRg)
}

// Deterministic resource IDs for the existing subnets (valid whether or not the
// existing VNet lives in the current resource group).
var existingWebTierSubnetId = resourceId(existingVnetRg, 'Microsoft.Network/virtualNetworks/subnets', existingVnetName, existingWebTierSubnetName)
var existingEnterpriseTierSubnetId = resourceId(existingVnetRg, 'Microsoft.Network/virtualNetworks/subnets', existingVnetName, existingEnterpriseTierSubnetName)
var existingResourceTierSubnetId = resourceId(existingVnetRg, 'Microsoft.Network/virtualNetworks/subnets', existingVnetName, existingResourceTierSubnetName)

output vnetId string = deployVnet ? vnet!.id : existingVnet!.id
output vnetName string = deployVnet ? vnet!.name : existingVnetName
output webTierSubnetId string = deployVnet ? vnet!.properties.subnets[0].id : existingWebTierSubnetId
output enterpriseTierSubnetId string = deployVnet ? vnet!.properties.subnets[1].id : existingEnterpriseTierSubnetId
output resourceTierSubnetId string = deployVnet ? vnet!.properties.subnets[2].id : existingResourceTierSubnetId

