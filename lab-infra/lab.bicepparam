using 'main.bicep'

// Non-secret defaults for the demo lab landing zone.
// SECRETS ARE NOT STORED HERE: adminPassword and dsrmPassword are supplied at
// deploy time by scripts/Deploy-Lab.ps1 (generated if not provided) and stored
// in the lab Key Vault. deployerObjectId is also supplied at deploy time.
param namePrefix = 'tclab'
param location = 'usgovvirginia'
param domainName = 'lab.local'
param dcPrivateIp = '10.60.1.4'
param adminUsername = 'labadmin'
param tags = {
  costCenter: 'REPLACE-ME'
  owner: 'REPLACE-ME'
}
