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

// ----------------------------- Variables -------------------------------------

// Naming convention (single source of truth documented in modules/naming.bicep):
//   Hyphenated : {org}-{label}-{env}-{region}-{type}{instance}
//   Compact    : {org}{label}{env}{region}{type}{instance}
// Computed inline as compile-time vars so the resource group name (assigned at
// subscription scope, before modules run) resolves at the start of deployment.
var regionCodeMap = {
  usgovvirginia: 'usgv'
}
var regionCode = regionCodeMap[location]
var nameBase = toLower('${org}-${label}-${environmentName}-${regionCode}')
var nameBaseCompact = toLower('${org}${label}${environmentName}${regionCode}')
var resourceGroupName = '${nameBase}-rg1'

// Emit the resolved names via the shared naming module for downstream reuse and
// as the canonical definition of the convention.
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
    subnetId: network.outputs.databaseSubnetId
  }
}

module compute 'modules/compute/compute.bicep' = {
  name: 'deploy-compute'
  scope: rg
  params: {
    nameBase: nameBase
    location: location
    tags: allTags
    subnetId: network.outputs.computeSubnetId
  }
}

// ----------------------------- Outputs ---------------------------------------

output resourceGroupNameOut string = rg.name
output vnetId string = network.outputs.vnetId
