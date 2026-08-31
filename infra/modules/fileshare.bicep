// =============================================================================
// modules/fileshare.bicep
// Premium Azure Files share for Teamcenter FMS volumes.
//
// Note: Alternative design is an FMS VM with striped Premium SSD data disks.
// This module keeps FMS storage on managed Azure Files (SMB) for now.
// =============================================================================

@description('Compact name base in the form {org}{label}{env}{region} (no special chars).')
param nameBaseCompact string

@description('Azure region.')
param location string

@description('Tags applied to all resources.')
param tags object

@description('Subnet resource ID for the private endpoint.')
param subnetId string

@description('Azure Files share name for Teamcenter FMS.')
param shareName string = 'teamcenter-fms'

@description('Provisioned quota for the share in GiB (Premium billing basis).')
@minValue(100)
param shareQuotaGiB int = 1024

@description('Storage account instance number.')
param instance int = 2

@description('When true and a zone ID is supplied, link the private endpoint to the private DNS zone.')
param deployPrivateDns bool = false

@description('BYO: resource ID of the privatelink.file.core.usgovcloudapi.net private DNS zone.')
param privateDnsZoneId string = ''

var fileStorageAccountName = take(toLower('${nameBaseCompact}st${instance}f'), 24)
var privateEndpointName = '${fileStorageAccountName}-pe'
var linkPrivateDns = deployPrivateDns && !empty(privateDnsZoneId)

resource fileStorageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: fileStorageAccountName
  location: location
  tags: tags
  sku: {
    name: 'Premium_LRS'
  }
  kind: 'FileStorage'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
  }
}

resource fileService 'Microsoft.Storage/storageAccounts/fileServices@2023-05-01' = {
  parent: fileStorageAccount
  name: 'default'
}

resource fmsShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-05-01' = {
  parent: fileService
  name: shareName
  properties: {
    enabledProtocols: 'SMB'
    shareQuota: shareQuotaGiB
    accessTier: 'Premium'
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
          privateLinkServiceId: fileStorageAccount.id
          groupIds: [
            'file'
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
        name: 'file'
        properties: {
          privateDnsZoneId: privateDnsZoneId
        }
      }
    ]
  }
}

output storageAccountId string = fileStorageAccount.id
output storageAccountName string = fileStorageAccount.name
output shareResourceId string = fmsShare.id
output shareNameOut string = shareName
output uncPath string = '\\\\${fileStorageAccount.name}.file.core.usgovcloudapi.net\\${shareName}'
