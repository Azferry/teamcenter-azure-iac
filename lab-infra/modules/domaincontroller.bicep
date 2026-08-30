// =============================================================================
// modules/domaincontroller.bicep
// Windows Server 2022 VM that is auto-promoted to an Active Directory domain
// controller (new forest) via a Custom Script Extension running
// Install-ADDSForest. No public IP - access is via Azure Bastion only.
// The NIC uses a static private IP so the DC can serve DNS reliably.
// =============================================================================

@description('Resource name prefix in the form <prefix>-lab.')
param namePrefixEnv string

@description('Azure Government region.')
param location string

@description('Tags applied to all resources.')
param tags object

@description('Resource ID of the subnet the domain controller attaches to.')
param subnetId string

@description('Static private IP address for the domain controller.')
param dcPrivateIp string = '10.60.1.4'

@description('Fully qualified Active Directory domain name to create, e.g. lab.local.')
param domainName string = 'lab.local'

@description('Local administrator username for the VM.')
param adminUsername string

@description('Local administrator password for the VM.')
@secure()
param adminPassword string

@description('Directory Services Restore Mode (safe-mode) password.')
@secure()
param dsrmPassword string

@description('VM size for the domain controller.')
param vmSize string = 'Standard_D2s_v3'

var vmName = '${namePrefixEnv}-dc'
// Windows computer names are limited to 15 characters.
var computerName = take(replace('${namePrefixEnv}dc', '-', ''), 15)
var nicName = '${vmName}-nic'

// Inline PowerShell that installs the AD DS role and promotes a new forest.
// The DSRM password is passed via a protected setting so it is not logged.
var installScript = 'powershell -ExecutionPolicy Unrestricted -Command "Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools; Import-Module ADDSDeployment; $sp = ConvertTo-SecureString -String \'DSRM_PLACEHOLDER\' -AsPlainText -Force; Install-ADDSForest -DomainName \'${domainName}\' -SafeModeAdministratorPassword $sp -InstallDns -Force -NoRebootOnCompletion:$false"'

resource nic 'Microsoft.Network/networkInterfaces@2023-11-01' = {
  name: nicName
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: dcPrivateIp
          subnet: {
            id: subnetId
          }
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: vmName
  location: location
  tags: tags
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: computerName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter-azure-edition'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}

// Promote to a domain controller. The DSRM password is injected into the
// command through protectedSettings so it never appears in plain text.
resource promote 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = {
  parent: vm
  name: 'PromoteToDC'
  location: location
  tags: tags
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    protectedSettings: {
      commandToExecute: replace(installScript, 'DSRM_PLACEHOLDER', dsrmPassword)
    }
  }
}

output vmName string = vm.name
output dcPrivateIp string = dcPrivateIp
