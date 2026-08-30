using '../main.bicep'

param org = 'ntc'
param label = 'plm'
param environmentName = 'prd'
param location = 'usgovvirginia'
param tags = {
  costCenter: 'REPLACE-ME'
  owner: 'REPLACE-ME'
}

// ---------------------------------------------------------------------------
// Security / DR
// Production: purge protection ON for both vaults. Supply DNS zone IDs to
// auto-register the private endpoints.
// ---------------------------------------------------------------------------
param keyVaultPurgeProtection = true
param recoveryVaultPurgeProtection = true
param deployPrivateDns = false
// param keyVaultPrivateDnsZoneId = 'REPLACE-ME'
// param recoveryVaultPrivateDnsZoneId = 'REPLACE-ME'

