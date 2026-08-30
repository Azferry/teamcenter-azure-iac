using '../main.bicep'

param org = 'ntc'
param label = 'plm'
param environmentName = 'tst'
param location = 'usgovvirginia'
param tags = {
  costCenter: 'REPLACE-ME'
  owner: 'REPLACE-ME'
}

// ---------------------------------------------------------------------------
// Security / DR
// ---------------------------------------------------------------------------
param keyVaultPurgeProtection = false
param recoveryVaultPurgeProtection = false
param deployPrivateDns = false
// param keyVaultPrivateDnsZoneId = 'REPLACE-ME'
// param recoveryVaultPrivateDnsZoneId = 'REPLACE-ME'

