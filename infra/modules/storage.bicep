// =============================================================================
// modules/storage.bicep
// Storage account(s) for the Teamcenter deployment (e.g. FMS volumes, backups).
// Starter configuration — harden and expand as needed.
// =============================================================================

@description('Compact name base in the form {org}{label}{env}{region} (no special chars).')
param nameBaseCompact string

@description('Azure Government region.')
param location string

@description('Tags applied to all resources.')
param tags object

@description('Storage account SKU.')
@allowed([
  'Standard_LRS'
  'Standard_ZRS'
  'Standard_GRS'
  'Premium_LRS'
])
param skuName string = 'Standard_LRS'

@description('Instance number for this storage account.')
param instance int = 1

@description('Resource ID of the user-assigned managed identity used for customer-managed key access.')
param userAssignedIdentityId string

@description('Vault URI of the Key Vault that holds the customer-managed key.')
param keyVaultUri string

@description('Name of the Key Vault key used for storage encryption.')
param keyName string

// Storage account names: lowercase, alphanumeric, 3-24 chars, globally unique.
// Deterministic per the naming convention: {baseCompact}st{instance}.
var storageAccountName = toLower('${nameBaseCompact}st${instance}')

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: length(storageAccountName) > 24 ? substring(storageAccountName, 0, 24) : storageAccountName
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityId}': {}
    }
  }
  sku: {
    name: skuName
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
    encryption: {
      identity: {
        userAssignedIdentity: userAssignedIdentityId
      }
      keySource: 'Microsoft.Keyvault'
      keyvaultproperties: {
        keyname: keyName
        keyvaulturi: keyVaultUri
      }
      services: {
        blob: {
          enabled: true
          keyType: 'Account'
        }
        file: {
          enabled: true
          keyType: 'Account'
        }
      }
    }
  }
}

output storageAccountId string = storageAccount.id
output storageAccountName string = storageAccount.name
