// =============================================================================
// modules/compute/ppg.bicep
// Proximity Placement Group helper for low-latency Teamcenter tier placement.
// =============================================================================

@description('PPG name.')
param name string

@description('Azure region.')
param location string

@description('Tags applied to the PPG.')
param tags object = {}

resource ppg 'Microsoft.Compute/proximityPlacementGroups@2023-09-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    proximityPlacementGroupType: 'Standard'
  }
}

output id string = ppg.id
output ppgName string = ppg.name
