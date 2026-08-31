// =============================================================================
// modules/compute/vm-role.bicep
// Reusable Teamcenter VM role deployment module.
// =============================================================================

@description('Hyphenated name base in the form {org}-{label}-{env}-{region}.')
param nameBase string

@description('Friendly role token used in VM names (example: web, ent, fms).')
param roleCode string

@description('Azure region.')
param location string

@description('Tags applied to all role resources.')
param tags object

@description('Subnet resource ID for role NICs.')
param subnetId string

@description('Number of VMs to deploy for this role.')
@minValue(0)
param count int

@description('VM size for this role.')
param vmSize string

@description('Role OS type (Windows or Linux).')
param osType string = 'Windows'

@description('Image reference object: publisher, offer, sku, version.')
param image object

@description('Admin username for VMs.')
param adminUsername string

@description('Admin password for VMs.')
@secure()
param adminPassword string

@description('OS disk size in GB.')
@minValue(64)
param osDiskSizeGb int = 128

@description('Optional role data disks object array (sizeGb, optional sku and lun).')
param dataDisks array = []

@description('Availability zones for this role. Empty = no zonal placement.')
param availabilityZones array = []

@description('Optional proximity placement group resource ID.')
param proximityPlacementGroupId string = ''

@description('Optional disk encryption set ID for OS/data disks.')
param diskEncryptionSetId string = ''

@description('Optional user-assigned managed identity ID to attach.')
param managedIdentityId string = ''

@description('Optional boot diagnostics storage URI.')
param bootDiagnosticsStorageUri string = ''

var useDiskEncryptionSet = !empty(diskEncryptionSetId)
var useIdentity = !empty(managedIdentityId)
var usePpg = !empty(proximityPlacementGroupId)
var normalizedOsType = toLower(osType) == 'linux' ? 'Linux' : 'Windows'

resource roleNics 'Microsoft.Network/networkInterfaces@2023-11-01' = [for i in range(0, count): {
  name: '${nameBase}-nic-${roleCode}${padLeft(string(i + 1), 2, '0')}'
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetId
          }
        }
      }
    ]
  }
}]

resource roleVms 'Microsoft.Compute/virtualMachines@2024-03-01' = [for i in range(0, count): {
  name: '${nameBase}-vm-${roleCode}${padLeft(string(i + 1), 2, '0')}'
  location: location
  tags: tags
  zones: length(availabilityZones) > 0 ? [string(availabilityZones[i % length(availabilityZones)])] : null
  identity: useIdentity ? {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  } : null
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    proximityPlacementGroup: usePpg ? {
      id: proximityPlacementGroupId
    } : null
    storageProfile: {
      imageReference: {
        publisher: image.publisher
        offer: image.offer
        sku: image.sku
        version: image.version
      }
      osDisk: {
        createOption: 'FromImage'
        osType: normalizedOsType
        diskSizeGB: osDiskSizeGb
        managedDisk: {
          storageAccountType: 'Premium_LRS'
          diskEncryptionSet: useDiskEncryptionSet ? {
            id: diskEncryptionSetId
          } : null
        }
      }
      dataDisks: [for (disk, diskIndex) in dataDisks: {
        lun: contains(disk, 'lun') ? int(disk.lun) : diskIndex
        createOption: 'Empty'
        diskSizeGB: int(disk.sizeGb)
        managedDisk: {
          storageAccountType: contains(disk, 'sku') ? string(disk.sku) : 'Premium_LRS'
          diskEncryptionSet: useDiskEncryptionSet ? {
            id: diskEncryptionSetId
          } : null
        }
      }]
    }
    osProfile: {
      computerName: take('${roleCode}${padLeft(string(i + 1), 2, '0')}', 15)
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: normalizedOsType == 'Windows' ? {
        provisionVMAgent: true
        enableAutomaticUpdates: true
        patchSettings: {
          patchMode: 'AutomaticByOS'
          assessmentMode: 'ImageDefault'
        }
      } : null
      linuxConfiguration: normalizedOsType == 'Linux' ? {
        disablePasswordAuthentication: false
        patchSettings: {
          patchMode: 'ImageDefault'
          assessmentMode: 'ImageDefault'
        }
      } : null
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: roleNics[i].id
          properties: {
            primary: true
          }
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: empty(bootDiagnosticsStorageUri) ? {
        enabled: true
      } : {
        enabled: true
        storageUri: bootDiagnosticsStorageUri
      }
    }
  }
}]

output vmIds array = [for i in range(0, count): roleVms[i].id]
output vmNames array = [for i in range(0, count): roleVms[i].name]
output nicIds array = [for i in range(0, count): roleNics[i].id]
