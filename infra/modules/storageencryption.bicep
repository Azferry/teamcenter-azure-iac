// =============================================================================
// modules/storageencryption.bicep
// Grants the user-assigned managed identity (UMI) the "Key Vault Crypto Service
// Encryption User" role on the Key Vault so the storage account can wrap/unwrap
// its customer-managed key. This role assignment must exist before the storage
// account applies CMK encryption.
//
// Ordering: Key Vault + storage key (keyvault module) + UMI (identity module)
//   -> role assignment (this module) -> storage account (storage module).
// =============================================================================

@description('Name of the Key Vault (used to scope the RBAC role assignment).')
param keyVaultName string

@description('Principal ID of the user-assigned managed identity granted crypto access.')
param principalId string

// Built-in role: Key Vault Crypto Service Encryption User.
var cryptoServiceEncryptionUserRoleId = 'e147488a-f6f5-4113-8e2d-b22465e65bf6'

// Reference the vault to scope the role assignment.
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

// Grant the UMI crypto access on the vault for storage CMK.
resource storageKeyVaultRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, principalId, cryptoServiceEncryptionUserRoleId)
  scope: keyVault
  properties: {
    principalId: principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', cryptoServiceEncryptionUserRoleId)
    principalType: 'ServicePrincipal'
  }
}

output roleAssignmentId string = storageKeyVaultRoleAssignment.id
