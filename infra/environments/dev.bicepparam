using '../main.bicep'

param org = 'ntc'
param label = 'plm'
param environmentName = 'dev'
param location = 'eastus'
param tags = {
  costCenter: 'REPLACE-ME'
  owner: 'REPLACE-ME'
}

// ---------------------------------------------------------------------------
// Network mode
// Default is create-mode: the deployment provisions the VNet, subnets and NSGs.
//
// To use an EXISTING VNet (same subscription, optionally a different resource
// group), uncomment and fill in the block below:
//
// param deployVnet = false
// param existingVnetName = 'REPLACE-ME-vnet'
// param existingVnetResourceGroup = 'REPLACE-ME-networking-rg'  // omit/blank = deployment RG
// param existingWebTierSubnetName = 'web-tier-sn'
// param existingEnterpriseTierSubnetName = 'enterprise-tier-sn'
// param existingResourceTierSubnetName = 'resource-tier-sn'
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Security / DR
// Purge protection is off by default in non-prod. Private DNS is BYO: set
// deployPrivateDns = true and supply the zone IDs to auto-register the private
// endpoints for the Key Vault and Recovery Services Vault.
// ---------------------------------------------------------------------------
param keyVaultPurgeProtection = false
param recoveryVaultPurgeProtection = false
param deployPrivateDns = false
// param keyVaultPrivateDnsZoneId = 'REPLACE-ME'
// param recoveryVaultPrivateDnsZoneId = 'REPLACE-ME'
