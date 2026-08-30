// =============================================================================
// modules/recoveryservicesvault.bicep
// Recovery Services Vault for Teamcenter VM backup. Ships a default daily VM
// backup policy and is reached over a private endpoint on the resource-tier
// subnet.
//
// Private DNS follows the same BYO pattern as the VNet: when deployPrivateDns is
// true AND a zone ID is supplied, the private endpoint is linked to that zone.
//
// NOTE: A fully private RSV in Azure Government requires DNS registration across
// several zones (privatelink.<geo>.backup.windowsazure.us, siterecovery, and the
// blob/queue storage zones). This module accepts the primary AzureBackup zone
// ID; the remaining zones are expected to be BYO / client-managed.
// =============================================================================

@description('Hyphenated name base in the form {org}-{label}-{env}-{region}.')
param nameBase string

@description('Azure Government region.')
param location string

@description('Tags applied to all resources.')
param tags object

@description('Resource ID of the subnet the private endpoint attaches to (resource tier).')
param subnetId string

@description('Enable soft-delete / enhanced security (purge protection). When false, soft delete is disabled.')
param enablePurgeProtection bool = false

@description('When true and a zone ID is supplied, link the private endpoint to the private DNS zone. When false, DNS is client-managed (BYO).')
param deployPrivateDns bool = false

@description('BYO: resource ID of the primary AzureBackup private DNS zone (privatelink.<geo>.backup.windowsazure.us).')
param privateDnsZoneId string = ''

@description('Name of the default backup policy.')
param defaultPolicyName string = 'default-daily-vm-policy'

@description('Instance number for this recovery services vault.')
param instance int = 1

// Naming convention: {nameBase}-rsv{instance} e.g. ntc-plm-prd-usgv-rsv1
var recoveryVaultName = '${nameBase}-rsv${instance}'
var privateEndpointName = '${recoveryVaultName}-pe'
var linkPrivateDns = deployPrivateDns && !empty(privateDnsZoneId)

resource recoveryVault 'Microsoft.RecoveryServices/vaults@2024-04-01' = {
  name: recoveryVaultName
  location: location
  tags: tags
  sku: {
    name: 'RS0'
    tier: 'Standard'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publicNetworkAccess: 'Disabled'
    securitySettings: {
      softDeleteSettings: {
        softDeleteState: enablePurgeProtection ? 'Enabled' : 'Disabled'
        enhancedSecurityState: enablePurgeProtection ? 'Enabled' : 'Disabled'
      }
    }
  }
}

// Default daily VM backup policy: daily backup at 23:00 UTC, 30-day retention.
resource defaultPolicy 'Microsoft.RecoveryServices/vaults/backupPolicies@2024-04-01' = {
  parent: recoveryVault
  name: defaultPolicyName
  properties: {
    backupManagementType: 'AzureIaasVM'
    policyType: 'V2'
    instantRpRetentionRangeInDays: 2
    timeZone: 'UTC'
    schedulePolicy: {
      schedulePolicyType: 'SimpleSchedulePolicyV2'
      scheduleRunFrequency: 'Daily'
      dailySchedule: {
        scheduleRunTimes: [
          '2024-01-01T23:00:00Z'
        ]
      }
    }
    retentionPolicy: {
      retentionPolicyType: 'LongTermRetentionPolicy'
      dailySchedule: {
        retentionTimes: [
          '2024-01-01T23:00:00Z'
        ]
        retentionDuration: {
          count: 30
          durationType: 'Days'
        }
      }
    }
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-11-01' = {
  name: privateEndpointName
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        properties: {
          privateLinkServiceId: recoveryVault.id
          groupIds: [
            'AzureBackup'
          ]
        }
      }
    ]
  }
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-11-01' = if (linkPrivateDns) {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'backup'
        properties: {
          privateDnsZoneId: privateDnsZoneId
        }
      }
    ]
  }
}

output recoveryServicesVaultId string = recoveryVault.id
output recoveryServicesVaultName string = recoveryVault.name
output defaultPolicyName string = defaultPolicy.name
