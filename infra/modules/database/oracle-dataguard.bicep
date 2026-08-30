// =============================================================================
// modules/database/oracle-dataguard.bicep
// Optional Oracle Data Guard standby and observer roles.
// =============================================================================

@description('Hyphenated name base in the form {org}-{label}-{env}-{region}.')
param nameBase string

@description('Azure region.')
param location string

@description('Tags applied to role resources.')
param tags object

@description('Subnet resource ID for Oracle VM NICs.')
param subnetId string

@description('Standby role settings object.')
param standby object = {
  enabled: false
  count: 0
  vmSize: 'Standard_E32-16ds_v4'
  osDiskSizeGb: 128
  availabilityZones: []
}

@description('Observer role settings object.')
param observer object = {
  enabled: false
  count: 0
  vmSize: 'Standard_D2s_v5'
  osDiskSizeGb: 64
  availabilityZones: []
}

@description('Linux image object for Oracle hosts.')
param image object = {
  publisher: 'RedHat'
  offer: 'RHEL'
  sku: '8-lvm-gen2'
  version: 'latest'
}

@description('Linux admin username.')
param adminUsername string = 'oracleadmin'

@description('Linux admin password.')
@secure()
param adminPassword string

@description('Optional disk encryption set ID for OS/data disks.')
param diskEncryptionSetId string = ''

@description('Optional managed identity ID to attach.')
param managedIdentityId string = ''

@description('Optional boot diagnostics storage URI.')
param bootDiagnosticsStorageUri string = ''

var standbyEnabled = contains(standby, 'enabled') ? bool(standby.enabled) : false
var standbyCount = contains(standby, 'count') ? int(standby.count) : 0
var observerEnabled = contains(observer, 'enabled') ? bool(observer.enabled) : false
var observerCount = contains(observer, 'count') ? int(observer.count) : 0

module standbyRole './oracle-vm.bicep' = if (standbyEnabled && standbyCount > 0) {
  name: 'deploy-oracle-standby'
  params: {
    nameBase: nameBase
    roleCode: 'oras'
    location: location
    tags: tags
    subnetId: subnetId
    count: standbyCount
    vmSize: contains(standby, 'vmSize') ? string(standby.vmSize) : 'Standard_E32-16ds_v4'
    image: image
    adminUsername: adminUsername
    adminPassword: adminPassword
    osDiskSizeGb: contains(standby, 'osDiskSizeGb') ? int(standby.osDiskSizeGb) : 128
    dataDisks: contains(standby, 'dataDisks') ? standby.dataDisks : []
    availabilityZones: contains(standby, 'availabilityZones') ? standby.availabilityZones : []
    proximityPlacementGroupId: contains(standby, 'proximityPlacementGroupId') ? string(standby.proximityPlacementGroupId) : ''
    diskEncryptionSetId: diskEncryptionSetId
    managedIdentityId: managedIdentityId
    bootDiagnosticsStorageUri: bootDiagnosticsStorageUri
  }
}

module observerRole '../compute/vm-role.bicep' = if (observerEnabled && observerCount > 0) {
  name: 'deploy-oracle-observer'
  params: {
    nameBase: nameBase
    roleCode: 'orao'
    location: location
    tags: tags
    subnetId: subnetId
    count: observerCount
    vmSize: contains(observer, 'vmSize') ? string(observer.vmSize) : 'Standard_D2s_v5'
    osType: 'Linux'
    image: image
    adminUsername: adminUsername
    adminPassword: adminPassword
    osDiskSizeGb: contains(observer, 'osDiskSizeGb') ? int(observer.osDiskSizeGb) : 64
    dataDisks: contains(observer, 'dataDisks') ? observer.dataDisks : []
    availabilityZones: contains(observer, 'availabilityZones') ? observer.availabilityZones : []
    proximityPlacementGroupId: contains(observer, 'proximityPlacementGroupId') ? string(observer.proximityPlacementGroupId) : ''
    diskEncryptionSetId: diskEncryptionSetId
    managedIdentityId: managedIdentityId
    bootDiagnosticsStorageUri: bootDiagnosticsStorageUri
  }
}

output standbyVmNames array = standbyEnabled && standbyCount > 0 ? standbyRole.outputs.vmNames : []
output observerVmNames array = observerEnabled && observerCount > 0 ? observerRole.outputs.vmNames : []
