// =============================================================================
// main.bicep
// Subscription-scoped orchestrator for the Teamcenter on Azure deployment.
// Creates the resource group and invokes the tier modules.
// Target cloud: Azure Government.
// =============================================================================

targetScope = 'subscription'

// ----------------------------- Parameters ------------------------------------

@description('3-char organization code, e.g. "ntc".')
@minLength(3)
@maxLength(3)
param org string = 'ntc'

@description('3-4 char workload label, e.g. "plm".')
@minLength(3)
@maxLength(4)
param label string = 'plm'

@description('Environment name (dev, tst, prd). Used in resource names and tags.')
@allowed([
  'dev'
  'tst'
  'prd'
])
param environmentName string

@description('Azure Government region for all resources.')
param location string = 'usgovvirginia'

@description('Additional tags merged onto every resource.')
param tags object = {}

// ----------------------------- Network mode ----------------------------------

@description('When true, create the VNet/subnets/NSGs. When false, reference an existing VNet (bring-your-own).')
param deployVnet bool = true

@description('BYO mode: name of the existing VNet to reference. Required when deployVnet = false.')
param existingVnetName string = ''

@description('BYO mode: resource group of the existing VNet (same subscription). Defaults to the deployment resource group when blank.')
param existingVnetResourceGroup string = ''

@description('BYO mode: name of the existing subnet for the web tier.')
param existingWebTierSubnetName string = 'web-tier-sn'

@description('BYO mode: name of the existing subnet for the enterprise tier.')
param existingEnterpriseTierSubnetName string = 'enterprise-tier-sn'

@description('BYO mode: name of the existing subnet for the resource tier.')
param existingResourceTierSubnetName string = 'resource-tier-sn'

// ----------------------------- Security / DR ---------------------------------

@description('Enable purge protection on the Key Vault. Once enabled it cannot be disabled.')
param keyVaultPurgeProtection bool = false

@description('Enable soft-delete / enhanced security (purge protection) on the Recovery Services Vault.')
param recoveryVaultPurgeProtection bool = false

@description('When true and zone IDs are supplied, link private endpoints to their private DNS zones. When false, DNS is client-managed (BYO).')
param deployPrivateDns bool = false

@description('BYO: resource ID of the privatelink.vaultcore.usgovcloudapi.net private DNS zone (Key Vault).')
param keyVaultPrivateDnsZoneId string = ''

@description('BYO: resource ID of the AzureBackup private DNS zone (Recovery Services Vault).')
param recoveryVaultPrivateDnsZoneId string = ''

@description('BYO: resource ID of the privatelink.file.core.usgovcloudapi.net private DNS zone (Azure Files).')
param filesPrivateDnsZoneId string = ''

@description('Admin username for Teamcenter compute VMs.')
param computeAdminUsername string = 'tcadmin'

@description('Admin password for Teamcenter compute VMs.')
@secure()
param computeAdminPassword string

@description('Admin username for Oracle VMs.')
param oracleAdminUsername string = 'oracleadmin'

@description('Admin password for Oracle VMs.')
@secure()
param oracleAdminPassword string

@description('Web server + AWC gateway role settings.')
param webServer object = {
  enabled: true
  count: 1
  vmSize: 'Standard_D8ds_v5'
  osType: 'Windows'
  image: {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2022-datacenter-azure-edition'
    version: 'latest'
  }
  osDiskSizeGb: 128
  dataDisks: []
  availabilityZones: []
}

@description('Teamcenter Security Services (TCSS) settings.')
param tcss object = {
  enabled: true
  count: 1
  vmSize: 'Standard_D4ds_v5'
  osType: 'Windows'
  image: {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2022-datacenter-azure-edition'
    version: 'latest'
  }
  osDiskSizeGb: 128
  dataDisks: []
  availabilityZones: []
}

@description('Enterprise/foundation server settings.')
param enterprise object = {
  enabled: true
  count: 1
  vmSize: 'Standard_F16s_v2'
  osType: 'Windows'
  image: {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2022-datacenter-azure-edition'
    version: 'latest'
  }
  osDiskSizeGb: 128
  dataDisks: []
  availabilityZones: []
}

@description('Pool manager role settings.')
param poolManager object = {
  enabled: true
  count: 1
  vmSize: 'Standard_D4_v4'
  osType: 'Windows'
  image: {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2022-datacenter-azure-edition'
    version: 'latest'
  }
  osDiskSizeGb: 128
  dataDisks: []
  availabilityZones: []
}

@description('Active Workspace portal role settings.')
param awcPortal object = {
  enabled: true
  count: 1
  vmSize: 'Standard_D8ds_v5'
  osType: 'Windows'
  image: {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2022-datacenter-azure-edition'
    version: 'latest'
  }
  osDiskSizeGb: 128
  dataDisks: []
  availabilityZones: []
}

@description('FMS volume server settings.')
param fmsVolumeServer object = {
  enabled: true
  count: 1
  vmSize: 'Standard_F16s_v2'
  osType: 'Windows'
  image: {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2022-datacenter-azure-edition'
    version: 'latest'
  }
  osDiskSizeGb: 128
  dataDisks: []
  availabilityZones: []
}

@description('FSC cache server settings.')
param fscCache object = {
  enabled: true
  count: 1
  vmSize: 'Standard_D8ds_v5'
  osType: 'Windows'
  image: {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2022-datacenter-azure-edition'
    version: 'latest'
  }
  osDiskSizeGb: 128
  dataDisks: []
  availabilityZones: []
}

@description('Apache Solr role settings.')
param solr object = {
  enabled: true
  count: 1
  vmSize: 'Standard_D8ds_v5'
  osType: 'Windows'
  image: {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2022-datacenter-azure-edition'
    version: 'latest'
  }
  osDiskSizeGb: 128
  dataDisks: []
  availabilityZones: []
}

@description('Dispatcher role settings.')
param dispatcher object = {
  enabled: false
  count: 0
  vmSize: 'Standard_F16s_v2'
  osType: 'Windows'
  image: {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2022-datacenter-azure-edition'
    version: 'latest'
  }
  osDiskSizeGb: 128
  dataDisks: []
  availabilityZones: []
}

@description('Visualization role settings.')
param visualization object = {
  enabled: false
  count: 0
  vmSize: 'Standard_NV36ads_A10_v5'
  osType: 'Windows'
  image: {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2022-datacenter-azure-edition'
    version: 'latest'
  }
  osDiskSizeGb: 128
  dataDisks: []
  availabilityZones: []
}

@description('Flex license server settings.')
param licenseServer object = {
  enabled: true
  count: 1
  vmSize: 'Standard_D2s_v5'
  osType: 'Windows'
  image: {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2022-datacenter-azure-edition'
    version: 'latest'
  }
  osDiskSizeGb: 128
  dataDisks: []
  availabilityZones: []
}

@description('Oracle primary role settings (RHEL BYOL on IaaS).')
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

@description('Oracle standby Data Guard role settings.')
param oracleStandby object = {
  enabled: false
  count: 0
  vmSize: 'Standard_E32-16ds_v4'
  osDiskSizeGb: 128
  availabilityZones: []
  dataDisks: []
}

@description('Oracle observer role settings.')
param oracleObserver object = {
  enabled: false
  count: 0
  vmSize: 'Standard_D2s_v5'
  osDiskSizeGb: 64
  availabilityZones: []
  dataDisks: []
}

@description('Oracle image settings (RHEL BYOL).')
param oracleImage object = {
  publisher: 'RedHat'
  offer: 'RHEL'
  sku: '8-lvm-gen2'
  version: 'latest'
}

@description('Azure Files share name for FMS volumes.')
param fmsShareName string = 'teamcenter-fms'

@description('Azure Files Premium quota in GiB for FMS.')
@minValue(100)
param fmsShareQuotaGiB int = 1024


// ----------------------------- Variables -------------------------------------

// Naming: the convention is owned by the shared naming module and consumed here
// via compile-time imported functions, so names resolve at the start of the
// deployment (required for the subscription-scope resource group name).
import { makeBase, makeBaseCompact } from '../modules/naming.bicep'

var nameBase = makeBase(org, label, environmentName, location)
var nameBaseCompact = makeBaseCompact(org, label, environmentName, location)
var resourceGroupName = '${nameBase}-rg1'

// Emit the resolved names via the shared naming module for downstream reuse.
module naming '../modules/naming.bicep' = {
  name: 'compute-naming'
  params: {
    org: org
    label: label
    env: environmentName
    location: location
  }
}

var defaultTags = {
  application: 'Teamcenter'
  environment: environmentName
  managedBy: 'bicep'
}
var allTags = union(defaultTags, tags)

// ----------------------------- Resource Group --------------------------------

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: allTags
}

// ----------------------------- Modules ---------------------------------------

module network 'modules/network.bicep' = {
  name: 'deploy-network'
  scope: rg
  params: {
    nameBase: nameBase
    location: location
    tags: allTags
    deployVnet: deployVnet
    existingVnetName: existingVnetName
    existingVnetResourceGroup: existingVnetResourceGroup
    existingWebTierSubnetName: existingWebTierSubnetName
    existingEnterpriseTierSubnetName: existingEnterpriseTierSubnetName
    existingResourceTierSubnetName: existingResourceTierSubnetName
  }
}

module storage 'modules/storage.bicep' = {
  name: 'deploy-storage'
  scope: rg
  params: {
    nameBaseCompact: nameBaseCompact
    location: location
    tags: allTags
    userAssignedIdentityId: identity.outputs.managedIdentityId
    keyVaultUri: keyvault.outputs.keyVaultUri
    keyName: keyvault.outputs.storageKeyName
  }
  dependsOn: [
    storageencryption
  ]
}

module fileshare 'modules/fileshare.bicep' = {
  name: 'deploy-fms-fileshare'
  scope: rg
  params: {
    nameBaseCompact: nameBaseCompact
    location: location
    tags: allTags
    subnetId: network.outputs.resourceTierSubnetId
    shareName: fmsShareName
    shareQuotaGiB: fmsShareQuotaGiB
    deployPrivateDns: deployPrivateDns
    privateDnsZoneId: filesPrivateDnsZoneId
  }
}

module database 'modules/database.bicep' = {
  name: 'deploy-database'
  scope: rg
  params: {
    nameBase: nameBase
    location: location
    tags: allTags
    subnetId: network.outputs.resourceTierSubnetId
    adminUsername: oracleAdminUsername
    adminPassword: oracleAdminPassword
    diskEncryptionSetId: encryptionset.outputs.diskEncryptionSetId
    managedIdentityId: identity.outputs.managedIdentityId
    bootDiagnosticsStorageUri: storage.outputs.storageAccountName == '' ? '' : 'https://${storage.outputs.storageAccountName}.blob.core.usgovcloudapi.net/'
    oraclePrimary: oraclePrimary
    oracleStandby: oracleStandby
    oracleObserver: oracleObserver
    oracleImage: oracleImage
  }
}

module compute 'modules/compute.bicep' = {
  name: 'deploy-compute'
  scope: rg
  params: {
    nameBase: nameBase
    location: location
    tags: allTags
    webSubnetId: network.outputs.webTierSubnetId
    enterpriseSubnetId: network.outputs.enterpriseTierSubnetId
    adminUsername: computeAdminUsername
    adminPassword: computeAdminPassword
    diskEncryptionSetId: encryptionset.outputs.diskEncryptionSetId
    managedIdentityId: identity.outputs.managedIdentityId
    bootDiagnosticsStorageUri: storage.outputs.storageAccountName == '' ? '' : 'https://${storage.outputs.storageAccountName}.blob.core.usgovcloudapi.net/'
    fmsShareUncPath: fileshare.outputs.uncPath
    webServer: webServer
    tcss: tcss
    enterprise: enterprise
    poolManager: poolManager
    awcPortal: awcPortal
    fmsVolumeServer: fmsVolumeServer
    fscCache: fscCache
    solr: solr
    dispatcher: dispatcher
    visualization: visualization
    licenseServer: licenseServer
  }
}

module identity 'modules/identity.bicep' = {
  name: 'deploy-identity'
  scope: rg
  params: {
    nameBase: nameBase
    location: location
    tags: allTags
  }
}

module keyvault 'modules/keyvault.bicep' = {
  name: 'deploy-keyvault'
  scope: rg
  params: {
    nameBaseCompact: nameBaseCompact
    location: location
    tags: allTags
    subnetId: network.outputs.resourceTierSubnetId
    enablePurgeProtection: keyVaultPurgeProtection
    deployPrivateDns: deployPrivateDns
    privateDnsZoneId: keyVaultPrivateDnsZoneId
  }
}

module storageencryption 'modules/storageencryption.bicep' = {
  name: 'deploy-storageencryption'
  scope: rg
  params: {
    keyVaultName: keyvault.outputs.keyVaultName
    principalId: identity.outputs.principalId
  }
}

module encryptionset 'modules/encryptionset.bicep' = {
  name: 'deploy-encryptionset'
  scope: rg
  params: {
    nameBase: nameBase
    location: location
    tags: allTags
    keyVaultId: keyvault.outputs.keyVaultId
    keyVaultName: keyvault.outputs.keyVaultName
    keyUrl: keyvault.outputs.desKeyUriWithVersion
  }
}

module backup 'modules/recoveryservicesvault.bicep' = {
  name: 'deploy-backup'
  scope: rg
  params: {
    nameBase: nameBase
    location: location
    tags: allTags
    subnetId: network.outputs.resourceTierSubnetId
    enablePurgeProtection: recoveryVaultPurgeProtection
    deployPrivateDns: deployPrivateDns
    privateDnsZoneId: recoveryVaultPrivateDnsZoneId
  }
}

// ----------------------------- Outputs ---------------------------------------

output resourceGroupNameOut string = rg.name
output vnetId string = network.outputs.vnetId
output managedIdentityId string = identity.outputs.managedIdentityId
output keyVaultId string = keyvault.outputs.keyVaultId
output diskEncryptionSetId string = encryptionset.outputs.diskEncryptionSetId
output recoveryServicesVaultId string = backup.outputs.recoveryServicesVaultId
output fmsFilesShareUnc string = fileshare.outputs.uncPath

