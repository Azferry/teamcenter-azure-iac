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

module network 'modules/network/network.bicep' = {
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

module storage 'modules/storage/storage.bicep' = {
  name: 'deploy-storage'
  scope: rg
  params: {
    nameBaseCompact: nameBaseCompact
    location: location
    tags: allTags
  }
}

module database 'modules/database/database.bicep' = {
  name: 'deploy-database'
  scope: rg
  params: {
    nameBase: nameBase
    location: location
    tags: allTags
    subnetId: network.outputs.resourceTierSubnetId
  }
}

module compute 'modules/compute/compute.bicep' = {
  name: 'deploy-compute'
  scope: rg
  params: {
    nameBase: nameBase
    location: location
    tags: allTags
    subnetId: network.outputs.enterpriseTierSubnetId
  }
}

module identity 'modules/identity/identity.bicep' = {
  name: 'deploy-identity'
  scope: rg
  params: {
    nameBase: nameBase
    location: location
    tags: allTags
  }
}

module keyvault 'modules/keyvault/keyvault.bicep' = {
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

module encryptionset 'modules/encryption/encryptionset.bicep' = {
  name: 'deploy-encryptionset'
  scope: rg
  params: {
    nameBase: nameBase
    location: location
    tags: allTags
    keyVaultId: keyvault.outputs.keyVaultId
    keyVaultName: keyvault.outputs.keyVaultName
    keyUrl: keyvault.outputs.desKeyUri
  }
}

module backup 'modules/backup/recoveryservicesvault.bicep' = {
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

