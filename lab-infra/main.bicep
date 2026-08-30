// =============================================================================
// lab-infra/main.bicep
// Subscription-scoped orchestrator for the DEMO lab landing zone.
// Stands up a self-contained environment: Key Vault (secret storage), a VNet
// with Azure Bastion, and a Windows Server domain controller (auto-promoted to
// a new AD forest). Kept separate from the production Teamcenter stack.
// Target cloud: Azure Government.
// =============================================================================

targetScope = 'subscription'

// ----------------------------- Parameters ------------------------------------

@description('Short prefix used to compose resource names, e.g. "tclab".')
@minLength(2)
@maxLength(10)
param namePrefix string = 'tclab'

@description('Azure Government region for all resources.')
param location string = 'usgovvirginia'

@description('Additional tags merged onto every resource.')
param tags object = {}

@description('Object ID of the principal (user/SP) granted secret access on Key Vault.')
param deployerObjectId string

@description('Fully qualified Active Directory domain name to create, e.g. lab.local.')
param domainName string = 'lab.local'

@description('Static private IP address for the domain controller.')
param dcPrivateIp string = '10.60.1.4'

@description('Local administrator username for the domain controller VM.')
param adminUsername string = 'labadmin'

@description('Local administrator password for the domain controller VM.')
@secure()
param adminPassword string

@description('Directory Services Restore Mode (safe-mode) password.')
@secure()
param dsrmPassword string

// ----------------------------- Variables -------------------------------------

// Consistent naming convention: <prefix>-lab-<resource>
var namePrefixEnv = '${namePrefix}-lab'
var resourceGroupName = '${namePrefixEnv}-rg'

var defaultTags = {
  application: 'Teamcenter'
  environment: 'lab'
  purpose: 'demo-landing-zone'
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

// 1. Key Vault + secrets (durable storage of the DC passwords).
module keyvault 'modules/keyvault.bicep' = {
  name: 'deploy-keyvault'
  scope: rg
  params: {
    namePrefixEnv: namePrefixEnv
    location: location
    tags: allTags
    deployerObjectId: deployerObjectId
    adminPassword: adminPassword
    dsrmPassword: dsrmPassword
  }
}

// 2. Network (VNet + AzureBastionSubnet + dc subnet + NSG).
module network 'modules/network.bicep' = {
  name: 'deploy-network'
  scope: rg
  params: {
    namePrefixEnv: namePrefixEnv
    location: location
    tags: allTags
  }
}

// 3. Azure Bastion.
module bastion 'modules/bastion.bicep' = {
  name: 'deploy-bastion'
  scope: rg
  params: {
    namePrefixEnv: namePrefixEnv
    location: location
    tags: allTags
    bastionSubnetId: network.outputs.bastionSubnetId
  }
}

// 4. Domain controller VM (auto-promoted to a new AD forest).
module dc 'modules/domaincontroller.bicep' = {
  name: 'deploy-dc'
  scope: rg
  params: {
    namePrefixEnv: namePrefixEnv
    location: location
    tags: allTags
    subnetId: network.outputs.dcSubnetId
    dcPrivateIp: dcPrivateIp
    domainName: domainName
    adminUsername: adminUsername
    adminPassword: adminPassword
    dsrmPassword: dsrmPassword
  }
}

// 5. Second-pass DNS repoint: set the VNet DNS to the domain controller so
//    other lab VMs resolve the new AD domain. Runs after the DC is promoted.
module networkDns 'modules/network.bicep' = {
  name: 'deploy-network-dns'
  scope: rg
  params: {
    namePrefixEnv: namePrefixEnv
    location: location
    tags: allTags
    dnsServers: [
      dc.outputs.dcPrivateIp
    ]
  }
}

// ----------------------------- Outputs ---------------------------------------

output resourceGroupNameOut string = rg.name
output vnetId string = network.outputs.vnetId
output keyVaultName string = keyvault.outputs.keyVaultName
output bastionName string = bastion.outputs.bastionName
output domainControllerName string = dc.outputs.vmName
output domainControllerPrivateIp string = dc.outputs.dcPrivateIp
