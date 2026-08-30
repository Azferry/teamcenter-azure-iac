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
}
param tcss = {
  enabled: true
  count: 1
  vmSize: 'Standard_D4ds_v5'
}
param enterprise = {
  enabled: true
  count: 2
  vmSize: 'Standard_F16s_v2'
}
param poolManager = {
  enabled: true
  count: 1
  vmSize: 'Standard_D4_v4'
}
param awcPortal = {
  enabled: true
  count: 1
  vmSize: 'Standard_D8ds_v5'
}
param fmsVolumeServer = {
  enabled: true
  count: 1
  vmSize: 'Standard_F16s_v2'
}
param fscCache = {
  enabled: true
  count: 2
  vmSize: 'Standard_D8ds_v5'
}
param solr = {
  enabled: true
  count: 1
  vmSize: 'Standard_D8ds_v5'
}
param dispatcher = {
  enabled: true
  count: 1
  vmSize: 'Standard_F16s_v2'
}
param visualization = {
  enabled: false
  count: 0
  vmSize: 'Standard_NV36ads_A10_v5'
}
param licenseServer = {
  enabled: true
  count: 1
  vmSize: 'Standard_D2s_v5'
}

// Oracle BYOL on RHEL (IaaS)
param oraclePrimary = {
  enabled: true
  count: 1
  vmSize: 'Standard_E32-16ds_v4'
}
param oracleStandby = {
  enabled: false
  count: 0
  vmSize: 'Standard_E32-16ds_v4'
}
param oracleObserver = {
  enabled: false
  count: 0
  vmSize: 'Standard_D2s_v5'
}

// Azure Files share for Teamcenter FMS
param fmsShareName = 'teamcenter-fms'
param fmsShareQuotaGiB = 2048

