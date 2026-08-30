// =============================================================================
// modules/identity.bicep
// User-assigned managed identity (UMI) for the Teamcenter deployment. Created
// up front so downstream resources (VMs, storage access, Key Vault RBAC, etc.)
// can be granted access to a single, stable identity for later use.
// =============================================================================

@description('Hyphenated name base in the form {org}-{label}-{env}-{region}.')
param nameBase string

@description('Azure Government region.')
param location string

@description('Tags applied to all resources.')
param tags object

@description('Instance number for this managed identity.')
param instance int = 1

// Naming convention: {nameBase}-umi{instance} e.g. ntc-plm-prd-usgv-umi1
var managedIdentityName = '${nameBase}-umi${instance}'

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: managedIdentityName
  location: location
  tags: tags
}

output managedIdentityId string = managedIdentity.id
output managedIdentityName string = managedIdentity.name
output principalId string = managedIdentity.properties.principalId
output clientId string = managedIdentity.properties.clientId
