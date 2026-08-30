// =============================================================================
// modules/keyvault.bicep
// Key Vault for the lab landing zone. Stores the domain controller local admin
// and DSRM (safe-mode) passwords as secrets. Secrets are supplied as secure
// parameters at deploy time, so nothing sensitive is committed to source.
// =============================================================================

@description('Resource name prefix in the form <prefix>-lab.')
param namePrefixEnv string

@description('Azure Government region.')
param location string

@description('Tags applied to all resources.')
param tags object

@description('Object ID of the principal granted secret management on the vault.')
param deployerObjectId string

@description('Azure AD tenant ID for the Key Vault.')
param tenantId string = subscription().tenantId

@description('Domain controller local administrator password.')
@secure()
param adminPassword string

@description('Directory Services Restore Mode (safe-mode) password.')
@secure()
param dsrmPassword string

// Key Vault names must be globally unique, 3-24 chars, alphanumeric + hyphens.
var keyVaultName = take('${replace(namePrefixEnv, '-', '')}kv${uniqueString(resourceGroup().id)}', 24)

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
    enableRbacAuthorization: false
    enabledForTemplateDeployment: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    accessPolicies: [
      {
        tenantId: tenantId
        objectId: deployerObjectId
        permissions: {
          secrets: [
            'get'
            'list'
            'set'
            'delete'
          ]
        }
      }
    ]
  }
}

resource adminSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'dc-admin-password'
  properties: {
    value: adminPassword
  }
}

resource dsrmSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'dc-dsrm-password'
  properties: {
    value: dsrmPassword
  }
}

output keyVaultId string = keyVault.id
output keyVaultName string = keyVault.name
