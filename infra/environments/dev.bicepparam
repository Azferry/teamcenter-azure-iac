using '../main.bicep'

param org = 'ntc'
param label = 'plm'
param environmentName = 'dev'
param location = 'usgovvirginia'
param tags = {
  costCenter: 'REPLACE-ME'
  owner: 'REPLACE-ME'
}

// ---------------------------------------------------------------------------
// Security / DR
// Purge protection is off by default in non-prod. Private DNS is BYO: set
// deployPrivateDns = true and supply the zone IDs to auto-register PEs.
// ---------------------------------------------------------------------------
param keyVaultPurgeProtection = false
param recoveryVaultPurgeProtection = false
param deployPrivateDns = false
// param keyVaultPrivateDnsZoneId = 'REPLACE-ME'
// param recoveryVaultPrivateDnsZoneId = 'REPLACE-ME'

