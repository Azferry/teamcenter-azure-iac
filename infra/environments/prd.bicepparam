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

// ---------------------------------------------------------------------------
// Admin credentials (replace for real deployments; prefer Key Vault references)
// ---------------------------------------------------------------------------
param computeAdminPassword = 'REPLACE-ME-COMPUTE-PASSWORD'
param oracleAdminPassword = 'REPLACE-ME-ORACLE-PASSWORD'

// ---------------------------------------------------------------------------
// Compute scaling by role
// ---------------------------------------------------------------------------
param webServer = {
  enabled: true
  count: 2
  vmSize: 'Standard_D8ds_v5'
  availabilityZones: [1, 2]
}
param tcss = {
  enabled: true
  count: 2
  vmSize: 'Standard_D4ds_v5'
  availabilityZones: [1, 2]
}
param enterprise = {
  enabled: true
  count: 4
  vmSize: 'Standard_F16s_v2'
  availabilityZones: [1, 2]
}
param poolManager = {
  enabled: true
  count: 2
  vmSize: 'Standard_D4_v4'
  availabilityZones: [1, 2]
}
param awcPortal = {
  enabled: true
  count: 2
  vmSize: 'Standard_D8ds_v5'
  availabilityZones: [1, 2]
}
param fmsVolumeServer = {
  enabled: true
  count: 2
  vmSize: 'Standard_F16s_v2'
  availabilityZones: [1, 2]
}
param fscCache = {
  enabled: true
  count: 2
  vmSize: 'Standard_D8ds_v5'
  availabilityZones: [1, 2]
}
param solr = {
  enabled: true
  count: 2
  vmSize: 'Standard_D8ds_v5'
  availabilityZones: [1, 2]
}
param dispatcher = {
  enabled: true
  count: 2
  vmSize: 'Standard_F16s_v2'
  availabilityZones: [1, 2]
}
param visualization = {
  enabled: false
  count: 0
  vmSize: 'Standard_NV36ads_A10_v5'
}
param licenseServer = {
  enabled: true
  count: 2
  vmSize: 'Standard_D2s_v5'
  availabilityZones: [1, 2]
}

// Oracle BYOL on RHEL (IaaS)
param oraclePrimary = {
  enabled: true
  count: 1
  vmSize: 'Standard_E32-16ds_v4'
  availabilityZones: [1]
}
param oracleStandby = {
  enabled: true
  count: 1
  vmSize: 'Standard_E32-16ds_v4'
  availabilityZones: [2]
}
param oracleObserver = {
  enabled: true
  count: 1
  vmSize: 'Standard_D2s_v5'
  availabilityZones: [3]
}

// Azure Files share for Teamcenter FMS
param fmsShareName = 'teamcenter-fms'
param fmsShareQuotaGiB = 4096

