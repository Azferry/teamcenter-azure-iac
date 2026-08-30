// =============================================================================
// modules/keyvault/keyvault.bicep
// Key Vault for the Teamcenter deployment. RBAC-authorized, public network
// access disabled, reached over a private endpoint on the resource-tier subnet.
//
// Also hosts an RSA key used by the disk encryption set (see encryption module).
//
// Private DNS follows the same BYO pattern as the VNet: when deployPrivateDns is
// true AND a zone ID is supplied, the private endpoint is linked to that zone.
// Otherwise DNS registration is assumed to be client-managed.
// =============================================================================

@description('Compact name base in the form {org}{label}{env}{region} (no special chars).')
param nameBaseCompact string

@description('Azure Government region.')
param location string

@description('Tags applied to all resources.')
param tags object

@description('Azure AD tenant ID for the Key Vault.')
param tenantId string = subscription().tenantId

@description('Resource ID of the subnet the private endpoint attaches to (resource tier).')
param subnetId string

@description('Enable purge protection. Once enabled it cannot be disabled. Azure only accepts true or unset.')
param enablePurgeProtection bool = false

@description('When true and a zone ID is supplied, link the private endpoint to the private DNS zone. When false, DNS is client-managed (BYO).')
param deployPrivateDns bool = false

@description('BYO: resource ID of the privatelink.vaultcore.usgovcloudapi.net private DNS zone.')
param privateDnsZoneId string = ''

@description('Name of the RSA key created for the disk encryption set.')
param desKeyName string = 'des-key'

@description('Instance number for this key vault.')
param instance int = 1

// Key Vault names: 3-24 chars, alphanumeric + hyphens, globally unique.
// Deterministic per the naming convention: {baseCompact}kv{instance}.
var keyVaultName = take('${nameBaseCompact}kv${instance}', 24)
var privateEndpointName = '${keyVaultName}-pe'
var linkPrivateDns = deployPrivateDns && !empty(privateDnsZoneId)

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenantId
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    // Azure rejects enablePurgeProtection: false; emit true or leave unset.
    enablePurgeProtection: enablePurgeProtection ? true : null
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
  }
}

// RSA key consumed by the disk encryption set.
resource desKey 'Microsoft.KeyVault/vaults/keys@2023-07-01' = {
  parent: keyVault
  name: desKeyName
  properties: {
    kty: 'RSA'
    keySize: 3072
    keyOps: [
      'wrapKey'
      'unwrapKey'
    ]
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-11-01' = {
  name: privateEndpointName
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        properties: {
          privateLinkServiceId: keyVault.id
          groupIds: [
            'vault'
          ]
        }
      }
    ]
  }
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-11-01' = if (linkPrivateDns) {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'vaultcore'
        properties: {
          privateDnsZoneId: privateDnsZoneId
        }
      }
    ]
  }
}

output keyVaultId string = keyVault.id
output keyVaultName string = keyVault.name
output keyVaultUri string = keyVault.properties.vaultUri
output desKeyName string = desKey.name
output desKeyUri string = desKey.properties.keyUri
output desKeyUriWithVersion string = desKey.properties.keyUriWithVersion
