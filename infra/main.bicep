// =============================================================================
// main.bicep
// Subscription-scoped orchestrator for the Teamcenter on Azure deployment.
// Creates the resource group and invokes the tier modules.
// Target cloud: Azure Government.
// =============================================================================

targetScope = 'subscription'

// ----------------------------- Parameters ------------------------------------

@description('Short prefix used to compose resource names, e.g. "tc".')
@minLength(2)
@maxLength(10)
param namePrefix string = 'tc'

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

// Consistent naming convention: <prefix>-<env>-<resource>
var namePrefixEnv = '${namePrefix}-${environmentName}'
var resourceGroupName = '${namePrefixEnv}-rg'

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
    namePrefixEnv: namePrefixEnv
    location: location
    tags: allTags
  }
}

module storage 'modules/storage/storage.bicep' = {
  name: 'deploy-storage'
  scope: rg
  params: {
    namePrefixEnv: namePrefixEnv
    location: location
    tags: allTags
  }
}

module database 'modules/database/database.bicep' = {
  name: 'deploy-database'
  scope: rg
  params: {
    namePrefixEnv: namePrefixEnv
    location: location
    tags: allTags
    subnetId: network.outputs.databaseSubnetId
  }
}

module compute 'modules/compute/compute.bicep' = {
  name: 'deploy-compute'
  scope: rg
  params: {
    namePrefixEnv: namePrefixEnv
    location: location
    tags: allTags
    subnetId: network.outputs.computeSubnetId
  }
}

// ----------------------------- Outputs ---------------------------------------

output resourceGroupNameOut string = rg.name
output vnetId string = network.outputs.vnetId
