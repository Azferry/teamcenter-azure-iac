// =============================================================================
// modules/database/oracle-vm.bicep
// Oracle IaaS VM role wrapper (RHEL BYOL image with parameter-driven scaling).
// =============================================================================

@description('Hyphenated name base in the form {org}-{label}-{env}-{region}.')
param nameBase string

@description('Role code token used in VM names.')
param roleCode string

@description('Azure region.')
param location string

@description('Tags applied to role resources.')
param tags object

@description('Subnet resource ID for Oracle VM NICs.')
param subnetId string

@description('VM count for this Oracle role.')
@minValue(0)
param count int = 1

@description('Oracle VM SKU.')
param vmSize string = 'Standard_E32-16ds_v4'

@description('Linux image object (publisher, offer, sku, version).')
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

@description('OS disk size in GB.')
@minValue(64)
param osDiskSizeGb int = 128

@description('Optional Oracle data disks list.')
param dataDisks array = [
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

@description('Availability zones for role VM distribution. Empty means no zonal placement.')
param availabilityZones array = []

@description('Optional proximity placement group resource ID.')
param proximityPlacementGroupId string = ''

@description('Optional disk encryption set ID for OS/data disks.')
param diskEncryptionSetId string = ''

@description('Optional managed identity ID to attach.')
param managedIdentityId string = ''

@description('Optional boot diagnostics storage URI.')
param bootDiagnosticsStorageUri string = ''

module oracleRole '../compute/vm-role.bicep' = {
  name: 'deploy-oracle-role-${roleCode}'
  params: {
    nameBase: nameBase
    roleCode: roleCode
    location: location
    tags: tags
    subnetId: subnetId
    count: count
    vmSize: vmSize
    osType: 'Linux'
    image: image
    adminUsername: adminUsername
    adminPassword: adminPassword
    osDiskSizeGb: osDiskSizeGb
    dataDisks: dataDisks
    availabilityZones: availabilityZones
    proximityPlacementGroupId: proximityPlacementGroupId
    diskEncryptionSetId: diskEncryptionSetId
    managedIdentityId: managedIdentityId
    bootDiagnosticsStorageUri: bootDiagnosticsStorageUri
  }
}

output vmNames array = oracleRole.outputs.vmNames
output vmIds array = oracleRole.outputs.vmIds
