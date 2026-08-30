using 'main.bicep'

// Non-secret defaults for the demo lab landing zone.
// SECRETS ARE NOT STORED HERE: adminPassword and dsrmPassword are supplied at
// deploy time by scripts/Deploy-Lab.ps1 (generated if not provided) and stored
// in the lab Key Vault. deployerObjectId is also supplied at deploy time.
param deployerObjectId = readEnvironmentVariable('DEPLOYER_OBJECT_ID')
param adminPassword = readEnvironmentVariable('ADMIN_PASSWORD')
param dsrmPassword = readEnvironmentVariable('DSRM_PASSWORD')

param org = 'ntc'
param label = 'plm'
param location = 'usgovvirginia'
param domainName = 'lab.local'
param dcPrivateIp = '10.60.1.4'
param adminUsername = 'labadmin'
param tags = {
  costCenter: 'REPLACE-ME'
  owner: 'REPLACE-ME'
}
