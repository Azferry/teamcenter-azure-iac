// =============================================================================
// modules/database.bicep
// Oracle database tier (IaaS BYOL on RHEL) for Teamcenter.
// =============================================================================

@description('Hyphenated name base in the form {org}-{label}-{env}-{region}.')
param nameBase string

@description('Azure Government region.')
param location string

@description('Tags applied to all resources.')
param tags object

@description('Resource ID of the subnet the database tier attaches to.')
param subnetId string

@description('Admin username for Oracle Linux VMs.')
param adminUsername string = 'oracleadmin'

@description('Admin password for Oracle Linux VMs.')
@secure()
param adminPassword string

@description('Optional disk encryption set ID for OS/data disks.')
param diskEncryptionSetId string = ''

@description('Optional user-assigned managed identity ID for all DB VMs.')
param managedIdentityId string = ''

@description('Optional boot diagnostics storage URI.')
param bootDiagnosticsStorageUri string = ''

@description('Oracle primary role settings.')
param oraclePrimary object = {
  enabled: true
  count: 1
  vmSize: 'Standard_E32-16ds_v4'
  osDiskSizeGb: 128
  availabilityZones: []
  dataDisks: [
    {
      lun: 0
      sizeGb: 1024
      sku: 'PremiumV2_LRS'
    }
    {
      lun: 1
      sizeGb: 1024
      sku: 'PremiumV2_LRS'
    }
    {
      lun: 2
      sizeGb: 1024
      sku: 'PremiumV2_LRS'
    }
    {
      lun: 3
      sizeGb: 1024
      sku: 'PremiumV2_LRS'
    }
    {
      lun: 4
      sizeGb: 512
      sku: 'PremiumV2_LRS'
    }
    {
      lun: 5
      sizeGb: 512
      sku: 'PremiumV2_LRS'
    }
    {
      lun: 6
      sizeGb: 128
      sku: 'PremiumV2_LRS'
    }
    {
      lun: 7
      sizeGb: 128
      sku: 'PremiumV2_LRS'
    }
  ]
}

@description('Oracle Data Guard standby role settings.')
param oracleStandby object = {
  enabled: false
  count: 0
  vmSize: 'Standard_E32-16ds_v4'
  osDiskSizeGb: 128
  availabilityZones: []
  dataDisks: []
}

@description('Oracle FSFO observer role settings.')
param oracleObserver object = {
  enabled: false
  count: 0
  vmSize: 'Standard_D2s_v5'
  osDiskSizeGb: 64
  availabilityZones: []
  dataDisks: []
}

@description('Oracle Linux image reference.')
param oracleImage object = {
  publisher: 'RedHat'
  offer: 'RHEL'
  sku: '8-lvm-gen2'
  version: 'latest'
}

var primaryEnabled = contains(oraclePrimary, 'enabled') ? bool(oraclePrimary.enabled) : false
var primaryCount = contains(oraclePrimary, 'count') ? int(oraclePrimary.count) : 0

module oraclePrimaryRole 'database/oracle-vm.bicep' = if (primaryEnabled && primaryCount > 0) {
  name: 'deploy-oracle-primary'
  params: {
    nameBase: nameBase
    roleCode: 'orap'
    location: location
    tags: tags
    subnetId: subnetId
    count: primaryCount
    vmSize: contains(oraclePrimary, 'vmSize') ? string(oraclePrimary.vmSize) : 'Standard_E32-16ds_v4'
    image: oracleImage
    adminUsername: adminUsername
    adminPassword: adminPassword
    osDiskSizeGb: contains(oraclePrimary, 'osDiskSizeGb') ? int(oraclePrimary.osDiskSizeGb) : 128
    dataDisks: contains(oraclePrimary, 'dataDisks') ? oraclePrimary.dataDisks : []
    availabilityZones: contains(oraclePrimary, 'availabilityZones') ? oraclePrimary.availabilityZones : []
    proximityPlacementGroupId: contains(oraclePrimary, 'proximityPlacementGroupId') ? string(oraclePrimary.proximityPlacementGroupId) : ''
    diskEncryptionSetId: diskEncryptionSetId
    managedIdentityId: managedIdentityId
    bootDiagnosticsStorageUri: bootDiagnosticsStorageUri
  }
}

module oracleDataGuard 'database/oracle-dataguard.bicep' = if ((contains(oracleStandby, 'enabled') ? bool(oracleStandby.enabled) : false) || (contains(oracleObserver, 'enabled') ? bool(oracleObserver.enabled) : false)) {
  name: 'deploy-oracle-dataguard'
  params: {
    nameBase: nameBase
    location: location
    tags: tags
    subnetId: subnetId
    standby: oracleStandby
    observer: oracleObserver
    image: oracleImage
    adminUsername: adminUsername
    adminPassword: adminPassword
    diskEncryptionSetId: diskEncryptionSetId
    managedIdentityId: managedIdentityId
    bootDiagnosticsStorageUri: bootDiagnosticsStorageUri
  }
}

output primaryVmNames array = primaryEnabled && primaryCount > 0 ? oraclePrimaryRole.outputs.vmNames : []
output standbyVmNames array = ((contains(oracleStandby, 'enabled') ? bool(oracleStandby.enabled) : false) || (contains(oracleObserver, 'enabled') ? bool(oracleObserver.enabled) : false)) ? oracleDataGuard.outputs.standbyVmNames : []
output observerVmNames array = ((contains(oracleStandby, 'enabled') ? bool(oracleStandby.enabled) : false) || (contains(oracleObserver, 'enabled') ? bool(oracleObserver.enabled) : false)) ? oracleDataGuard.outputs.observerVmNames : []
