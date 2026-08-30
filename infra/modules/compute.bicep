// =============================================================================
// modules/compute.bicep
// Teamcenter compute tiers (web + enterprise) with parameter-driven scaling.
// Default OS is Windows Server 2022; each role can switch to Linux by params.
// =============================================================================

@description('Hyphenated name base in the form {org}-{label}-{env}-{region}.')
param nameBase string

@description('Azure Government region.')
param location string

@description('Tags applied to all resources.')
param tags object

@description('Resource ID of the web tier subnet.')
param webSubnetId string

@description('Resource ID of the enterprise tier subnet.')
param enterpriseSubnetId string

@description('Admin username for compute VMs.')
param adminUsername string = 'tcadmin'

@description('Admin password for compute VMs.')
@secure()
param adminPassword string

@description('Optional disk encryption set ID for OS/data disks.')
param diskEncryptionSetId string = ''

@description('Optional user-assigned managed identity ID for all VMs.')
param managedIdentityId string = ''

@description('Optional boot diagnostics storage URI.')
param bootDiagnosticsStorageUri string = ''

@description('Optional FMS Azure Files UNC path (for documentation/output).')
param fmsShareUncPath string = ''

@description('Web server + AWC gateway role settings.')
param webServer object = {
  enabled: true
  count: 2
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
  availabilityZones: [
    1
    2
  ]
  ppgKey: 'web-ent'
}

@description('Teamcenter Security Services (TCSS) role settings.')
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
  availabilityZones: [
    1
    2
  ]
  ppgKey: 'web-ent'
}

@description('Enterprise/foundation role settings.')
param enterprise object = {
  enabled: true
  count: 2
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
  availabilityZones: [
    1
    2
  ]
  ppgKey: 'web-ent'
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
  availabilityZones: [
    1
    2
  ]
  ppgKey: 'web-ent'
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
  availabilityZones: [
    1
    2
  ]
  ppgKey: 'web-ent'
}

@description('FMS volume server role settings.')
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
  availabilityZones: [
    1
    2
  ]
  ppgKey: 'web-ent'
}

@description('FSC cache role settings.')
param fscCache object = {
  enabled: true
  count: 2
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
  availabilityZones: [
    1
    2
  ]
  ppgKey: 'web-ent'
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
  availabilityZones: [
    1
    2
  ]
  ppgKey: 'web-ent'
}

@description('Dispatcher workers role settings.')
param dispatcher object = {
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
  availabilityZones: [
    1
    2
  ]
  ppgKey: 'web-ent'
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
  ppgKey: 'web-ent'
}

@description('Flex license server role settings.')
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
  availabilityZones: [
    1
    2
  ]
  ppgKey: 'web-ent'
}

var ppgName = '${nameBase}-ppg1-web-ent'

module webEntPpg 'compute/ppg.bicep' = if ((contains(webServer, 'enabled') ? bool(webServer.enabled) : false) || (contains(tcss, 'enabled') ? bool(tcss.enabled) : false) || (contains(enterprise, 'enabled') ? bool(enterprise.enabled) : false)) {
  name: 'deploy-web-ent-ppg'
  params: {
    name: ppgName
    location: location
    tags: tags
  }
}

var deployWebEntPpg = (contains(webServer, 'enabled') ? bool(webServer.enabled) : false) || (contains(tcss, 'enabled') ? bool(tcss.enabled) : false) || (contains(enterprise, 'enabled') ? bool(enterprise.enabled) : false)
var ppgId = deployWebEntPpg ? resourceId('Microsoft.Compute/proximityPlacementGroups', ppgName) : ''

module webRole 'compute/vm-role.bicep' = if ((contains(webServer, 'enabled') ? bool(webServer.enabled) : false) && (contains(webServer, 'count') ? int(webServer.count) : 0) > 0) {
  name: 'deploy-role-web'
  params: {
    nameBase: nameBase
    roleCode: 'web'
    location: location
    tags: tags
    subnetId: webSubnetId
    count: int(webServer.count)
    vmSize: string(webServer.vmSize)
    osType: contains(webServer, 'osType') ? string(webServer.osType) : 'Windows'
    image: webServer.image
    adminUsername: adminUsername
    adminPassword: adminPassword
    osDiskSizeGb: contains(webServer, 'osDiskSizeGb') ? int(webServer.osDiskSizeGb) : 128
    dataDisks: contains(webServer, 'dataDisks') ? webServer.dataDisks : []
    availabilityZones: contains(webServer, 'availabilityZones') ? webServer.availabilityZones : []
    proximityPlacementGroupId: ppgId
    diskEncryptionSetId: diskEncryptionSetId
    managedIdentityId: managedIdentityId
    bootDiagnosticsStorageUri: bootDiagnosticsStorageUri
  }
}

module tcssRole 'compute/vm-role.bicep' = if ((contains(tcss, 'enabled') ? bool(tcss.enabled) : false) && (contains(tcss, 'count') ? int(tcss.count) : 0) > 0) {
  name: 'deploy-role-tcss'
  params: {
    nameBase: nameBase
    roleCode: 'tcss'
    location: location
    tags: tags
    subnetId: webSubnetId
    count: int(tcss.count)
    vmSize: string(tcss.vmSize)
    osType: contains(tcss, 'osType') ? string(tcss.osType) : 'Windows'
    image: tcss.image
    adminUsername: adminUsername
    adminPassword: adminPassword
    osDiskSizeGb: contains(tcss, 'osDiskSizeGb') ? int(tcss.osDiskSizeGb) : 128
    dataDisks: contains(tcss, 'dataDisks') ? tcss.dataDisks : []
    availabilityZones: contains(tcss, 'availabilityZones') ? tcss.availabilityZones : []
    proximityPlacementGroupId: ppgId
    diskEncryptionSetId: diskEncryptionSetId
    managedIdentityId: managedIdentityId
    bootDiagnosticsStorageUri: bootDiagnosticsStorageUri
  }
}

module entRole 'compute/vm-role.bicep' = if ((contains(enterprise, 'enabled') ? bool(enterprise.enabled) : false) && (contains(enterprise, 'count') ? int(enterprise.count) : 0) > 0) {
  name: 'deploy-role-ent'
  params: {
    nameBase: nameBase
    roleCode: 'ent'
    location: location
    tags: tags
    subnetId: enterpriseSubnetId
    count: int(enterprise.count)
    vmSize: string(enterprise.vmSize)
    osType: contains(enterprise, 'osType') ? string(enterprise.osType) : 'Windows'
    image: enterprise.image
    adminUsername: adminUsername
    adminPassword: adminPassword
    osDiskSizeGb: contains(enterprise, 'osDiskSizeGb') ? int(enterprise.osDiskSizeGb) : 128
    dataDisks: contains(enterprise, 'dataDisks') ? enterprise.dataDisks : []
    availabilityZones: contains(enterprise, 'availabilityZones') ? enterprise.availabilityZones : []
    proximityPlacementGroupId: ppgId
    diskEncryptionSetId: diskEncryptionSetId
    managedIdentityId: managedIdentityId
    bootDiagnosticsStorageUri: bootDiagnosticsStorageUri
  }
}

module poolRole 'compute/vm-role.bicep' = if ((contains(poolManager, 'enabled') ? bool(poolManager.enabled) : false) && (contains(poolManager, 'count') ? int(poolManager.count) : 0) > 0) {
  name: 'deploy-role-pool'
  params: {
    nameBase: nameBase
    roleCode: 'pool'
    location: location
    tags: tags
    subnetId: enterpriseSubnetId
    count: int(poolManager.count)
    vmSize: string(poolManager.vmSize)
    osType: contains(poolManager, 'osType') ? string(poolManager.osType) : 'Windows'
    image: poolManager.image
    adminUsername: adminUsername
    adminPassword: adminPassword
    osDiskSizeGb: contains(poolManager, 'osDiskSizeGb') ? int(poolManager.osDiskSizeGb) : 128
    dataDisks: contains(poolManager, 'dataDisks') ? poolManager.dataDisks : []
    availabilityZones: contains(poolManager, 'availabilityZones') ? poolManager.availabilityZones : []
    proximityPlacementGroupId: ppgId
    diskEncryptionSetId: diskEncryptionSetId
    managedIdentityId: managedIdentityId
    bootDiagnosticsStorageUri: bootDiagnosticsStorageUri
  }
}

module awcRole 'compute/vm-role.bicep' = if ((contains(awcPortal, 'enabled') ? bool(awcPortal.enabled) : false) && (contains(awcPortal, 'count') ? int(awcPortal.count) : 0) > 0) {
  name: 'deploy-role-awc'
  params: {
    nameBase: nameBase
    roleCode: 'awc'
    location: location
    tags: tags
    subnetId: enterpriseSubnetId
    count: int(awcPortal.count)
    vmSize: string(awcPortal.vmSize)
    osType: contains(awcPortal, 'osType') ? string(awcPortal.osType) : 'Windows'
    image: awcPortal.image
    adminUsername: adminUsername
    adminPassword: adminPassword
    osDiskSizeGb: contains(awcPortal, 'osDiskSizeGb') ? int(awcPortal.osDiskSizeGb) : 128
    dataDisks: contains(awcPortal, 'dataDisks') ? awcPortal.dataDisks : []
    availabilityZones: contains(awcPortal, 'availabilityZones') ? awcPortal.availabilityZones : []
    proximityPlacementGroupId: ppgId
    diskEncryptionSetId: diskEncryptionSetId
    managedIdentityId: managedIdentityId
    bootDiagnosticsStorageUri: bootDiagnosticsStorageUri
  }
}

module fmsRole 'compute/vm-role.bicep' = if ((contains(fmsVolumeServer, 'enabled') ? bool(fmsVolumeServer.enabled) : false) && (contains(fmsVolumeServer, 'count') ? int(fmsVolumeServer.count) : 0) > 0) {
  name: 'deploy-role-fms'
  params: {
    nameBase: nameBase
    roleCode: 'fms'
    location: location
    tags: tags
    subnetId: enterpriseSubnetId
    count: int(fmsVolumeServer.count)
    vmSize: string(fmsVolumeServer.vmSize)
    osType: contains(fmsVolumeServer, 'osType') ? string(fmsVolumeServer.osType) : 'Windows'
    image: fmsVolumeServer.image
    adminUsername: adminUsername
    adminPassword: adminPassword
    osDiskSizeGb: contains(fmsVolumeServer, 'osDiskSizeGb') ? int(fmsVolumeServer.osDiskSizeGb) : 128
    dataDisks: contains(fmsVolumeServer, 'dataDisks') ? fmsVolumeServer.dataDisks : []
    availabilityZones: contains(fmsVolumeServer, 'availabilityZones') ? fmsVolumeServer.availabilityZones : []
    proximityPlacementGroupId: ppgId
    diskEncryptionSetId: diskEncryptionSetId
    managedIdentityId: managedIdentityId
    bootDiagnosticsStorageUri: bootDiagnosticsStorageUri
  }
}

module fscRole 'compute/vm-role.bicep' = if ((contains(fscCache, 'enabled') ? bool(fscCache.enabled) : false) && (contains(fscCache, 'count') ? int(fscCache.count) : 0) > 0) {
  name: 'deploy-role-fsc'
  params: {
    nameBase: nameBase
    roleCode: 'fsc'
    location: location
    tags: tags
    subnetId: enterpriseSubnetId
    count: int(fscCache.count)
    vmSize: string(fscCache.vmSize)
    osType: contains(fscCache, 'osType') ? string(fscCache.osType) : 'Windows'
    image: fscCache.image
    adminUsername: adminUsername
    adminPassword: adminPassword
    osDiskSizeGb: contains(fscCache, 'osDiskSizeGb') ? int(fscCache.osDiskSizeGb) : 128
    dataDisks: contains(fscCache, 'dataDisks') ? fscCache.dataDisks : []
    availabilityZones: contains(fscCache, 'availabilityZones') ? fscCache.availabilityZones : []
    proximityPlacementGroupId: ppgId
    diskEncryptionSetId: diskEncryptionSetId
    managedIdentityId: managedIdentityId
    bootDiagnosticsStorageUri: bootDiagnosticsStorageUri
  }
}

module solrRole 'compute/vm-role.bicep' = if ((contains(solr, 'enabled') ? bool(solr.enabled) : false) && (contains(solr, 'count') ? int(solr.count) : 0) > 0) {
  name: 'deploy-role-solr'
  params: {
    nameBase: nameBase
    roleCode: 'solr'
    location: location
    tags: tags
    subnetId: enterpriseSubnetId
    count: int(solr.count)
    vmSize: string(solr.vmSize)
    osType: contains(solr, 'osType') ? string(solr.osType) : 'Windows'
    image: solr.image
    adminUsername: adminUsername
    adminPassword: adminPassword
    osDiskSizeGb: contains(solr, 'osDiskSizeGb') ? int(solr.osDiskSizeGb) : 128
    dataDisks: contains(solr, 'dataDisks') ? solr.dataDisks : []
    availabilityZones: contains(solr, 'availabilityZones') ? solr.availabilityZones : []
    proximityPlacementGroupId: ppgId
    diskEncryptionSetId: diskEncryptionSetId
    managedIdentityId: managedIdentityId
    bootDiagnosticsStorageUri: bootDiagnosticsStorageUri
  }
}

module dispatcherRole 'compute/vm-role.bicep' = if ((contains(dispatcher, 'enabled') ? bool(dispatcher.enabled) : false) && (contains(dispatcher, 'count') ? int(dispatcher.count) : 0) > 0) {
  name: 'deploy-role-disp'
  params: {
    nameBase: nameBase
    roleCode: 'disp'
    location: location
    tags: tags
    subnetId: enterpriseSubnetId
    count: int(dispatcher.count)
    vmSize: string(dispatcher.vmSize)
    osType: contains(dispatcher, 'osType') ? string(dispatcher.osType) : 'Windows'
    image: dispatcher.image
    adminUsername: adminUsername
    adminPassword: adminPassword
    osDiskSizeGb: contains(dispatcher, 'osDiskSizeGb') ? int(dispatcher.osDiskSizeGb) : 128
    dataDisks: contains(dispatcher, 'dataDisks') ? dispatcher.dataDisks : []
    availabilityZones: contains(dispatcher, 'availabilityZones') ? dispatcher.availabilityZones : []
    proximityPlacementGroupId: ppgId
    diskEncryptionSetId: diskEncryptionSetId
    managedIdentityId: managedIdentityId
    bootDiagnosticsStorageUri: bootDiagnosticsStorageUri
  }
}

module visRole 'compute/vm-role.bicep' = if ((contains(visualization, 'enabled') ? bool(visualization.enabled) : false) && (contains(visualization, 'count') ? int(visualization.count) : 0) > 0) {
  name: 'deploy-role-vis'
  params: {
    nameBase: nameBase
    roleCode: 'vis'
    location: location
    tags: tags
    subnetId: enterpriseSubnetId
    count: int(visualization.count)
    vmSize: string(visualization.vmSize)
    osType: contains(visualization, 'osType') ? string(visualization.osType) : 'Windows'
    image: visualization.image
    adminUsername: adminUsername
    adminPassword: adminPassword
    osDiskSizeGb: contains(visualization, 'osDiskSizeGb') ? int(visualization.osDiskSizeGb) : 128
    dataDisks: contains(visualization, 'dataDisks') ? visualization.dataDisks : []
    availabilityZones: contains(visualization, 'availabilityZones') ? visualization.availabilityZones : []
    proximityPlacementGroupId: ppgId
    diskEncryptionSetId: diskEncryptionSetId
    managedIdentityId: managedIdentityId
    bootDiagnosticsStorageUri: bootDiagnosticsStorageUri
  }
}

module licRole 'compute/vm-role.bicep' = if ((contains(licenseServer, 'enabled') ? bool(licenseServer.enabled) : false) && (contains(licenseServer, 'count') ? int(licenseServer.count) : 0) > 0) {
  name: 'deploy-role-lic'
  params: {
    nameBase: nameBase
    roleCode: 'lic'
    location: location
    tags: tags
    subnetId: enterpriseSubnetId
    count: int(licenseServer.count)
    vmSize: string(licenseServer.vmSize)
    osType: contains(licenseServer, 'osType') ? string(licenseServer.osType) : 'Windows'
    image: licenseServer.image
    adminUsername: adminUsername
    adminPassword: adminPassword
    osDiskSizeGb: contains(licenseServer, 'osDiskSizeGb') ? int(licenseServer.osDiskSizeGb) : 128
    dataDisks: contains(licenseServer, 'dataDisks') ? licenseServer.dataDisks : []
    availabilityZones: contains(licenseServer, 'availabilityZones') ? licenseServer.availabilityZones : []
    proximityPlacementGroupId: ppgId
    diskEncryptionSetId: diskEncryptionSetId
    managedIdentityId: managedIdentityId
    bootDiagnosticsStorageUri: bootDiagnosticsStorageUri
  }
}

output proximityPlacementGroupId string = ppgId
output fmsShareUncPathOut string = fmsShareUncPath
