// =============================================================================
// modules/encryption/encryptionset.bicep
// Disk Encryption Set (customer-managed key) backed by the Key Vault key. Uses a
// system-assigned identity that is granted "Key Vault Crypto Service Encryption
// User" on the vault so managed-disk encryption can wrap/unwrap the DES key.
//
// Ordering: Key Vault + key (keyvault module) -> DES -> role assignment.
// =============================================================================

@description('Hyphenated name base in the form {org}-{label}-{env}-{region}.')
param nameBase string

@description('Azure Government region.')
param location string

@description('Tags applied to all resources.')
param tags object

@description('Resource ID of the Key Vault that holds the encryption key.')
param keyVaultId string

@description('Name of the Key Vault (used to scope the RBAC role assignment).')
param keyVaultName string

@description('Key URI (versionless) of the RSA key used for disk encryption.')
param keyUrl string

@description('Instance number for this disk encryption set.')
param instance int = 1

// Naming convention: {nameBase}-des{instance} e.g. ntc-plm-prd-usgv-des1
var diskEncryptionSetName = '${nameBase}-des${instance}'

// Built-in role: Key Vault Crypto Service Encryption User.
var cryptoServiceEncryptionUserRoleId = 'e147488a-f6f5-4113-8e2d-b22465e65bf6'

resource diskEncryptionSet 'Microsoft.Compute/diskEncryptionSets@2023-10-02' = {
  name: diskEncryptionSetName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    encryptionType: 'EncryptionAtRestWithCustomerKey'
    rotationToLatestKeyVersionEnabled: true
    activeKey: {
      sourceVault: {
        id: keyVaultId
      }
      keyUrl: keyUrl
    }
  }
}

// Reference the vault to scope the role assignment.
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

// Grant the DES identity crypto access on the vault.
resource desKeyVaultRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, diskEncryptionSet.id, cryptoServiceEncryptionUserRoleId)
  scope: keyVault
  properties: {
    principalId: diskEncryptionSet.identity.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', cryptoServiceEncryptionUserRoleId)
    principalType: 'ServicePrincipal'
  }
}

output diskEncryptionSetId string = diskEncryptionSet.id
output diskEncryptionSetName string = diskEncryptionSet.name
output principalId string = diskEncryptionSet.identity.principalId
