// =============================================================================
// modules/compute/compute.bicep
// Compute tier for Teamcenter (application/web/pool manager servers).
// STUB: intentionally minimal — add VMs / VMSS for each Teamcenter tier.
// =============================================================================

@description('Resource name prefix in the form <prefix>-<env>.')
param namePrefixEnv string

@description('Azure Government region.')
param location string

@description('Tags applied to all resources.')
param tags object

@description('Resource ID of the subnet the compute tier attaches to.')
param subnetId string

// Placeholder to keep the module valid until compute resources are implemented.
var computeNamePlaceholder = '${namePrefixEnv}-compute'

output computeName string = computeNamePlaceholder
output computeSubnetId string = subnetId
output computeLocation string = location
output computeTags object = tags
