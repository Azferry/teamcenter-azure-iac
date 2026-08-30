// =============================================================================
// modules/database/database.bicep
// Database tier for Teamcenter (Oracle / SQL Server on VM, or a managed DB).
// STUB: intentionally minimal — fill in the DB platform you standardize on.
// =============================================================================

@description('Resource name prefix in the form <prefix>-<env>.')
param namePrefixEnv string

@description('Azure Government region.')
param location string

@description('Tags applied to all resources.')
param tags object

@description('Resource ID of the subnet the database tier attaches to.')
param subnetId string

// Placeholder to keep the module valid until the DB platform is implemented.
// Reference params so the linter does not flag them as unused.
var dbNamePlaceholder = '${namePrefixEnv}-db'

output databaseName string = dbNamePlaceholder
output databaseSubnetId string = subnetId
output databaseLocation string = location
output databaseTags object = tags
