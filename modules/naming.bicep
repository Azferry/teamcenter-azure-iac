// =============================================================================
// modules/naming.bicep
// Shared, resource-free naming module. Single source of truth for the resource
// naming convention across every stack in this repo. Called ONCE per stack; the
// emitted base strings are then passed down to the tier modules, which append a
// CAF resource-type short code + instance number.
//
// Convention:
//   Hyphenated : {org}-{label}-{env}-{region}-{type}{instance}   e.g. ntc-plm-prd-usgv-rg1
//   Compact    : {org}{label}{env}{region}{type}{instance}       e.g. ntcplmprdusgvst1
//              (compact form is for resources that disallow special chars,
//               e.g. storage accounts and key vaults)
// =============================================================================

targetScope = 'subscription'

// ----------------------------- Functions -------------------------------------
// Exported, compile-time naming functions. These are the single source of truth
// for the convention and can be imported by any stack, e.g.:
//   import { makeBase, makeBaseCompact } from '../modules/naming.bicep'
// Being compile-time, their results are available at the start of a deployment,
// so they can safely name subscription-scope resources (e.g. resource groups).

@export()
@description('Maps an Azure region to its short region code. Extend as needed.')
func regionCodeOf(location string) string => ({
  usgovvirginia: 'usgv'
  usgovarizona: 'usga'
  usgovtexas: 'usgt'
  eastus: 'eus'
  eastus2: 'eus2'
  westus: 'wus'
  centralus: 'cus'
})[location]

@export()
@description('Hyphenated name base: {org}-{label}-{env}-{region}. Append "-{type}{instance}".')
func makeBase(org string, label string, env string, location string) string =>
  toLower('${org}-${label}-${env}-${regionCodeOf(location)}')

@export()
@description('Compact name base: {org}{label}{env}{region}. Append "{type}{instance}".')
func makeBaseCompact(org string, label string, env string, location string) string =>
  toLower('${org}${label}${env}${regionCodeOf(location)}')

// ----------------------------- Parameters ------------------------------------

@description('3-char organization code, e.g. "ntc".')
@minLength(3)
@maxLength(3)
param org string = 'ntc'

@description('3-4 char workload label, e.g. "plm".')
@minLength(3)
@maxLength(4)
param label string = 'plm'

@description('Environment code (dev, tst, prd, lab).')
@allowed([
  'dev'
  'tst'
  'prd'
  'lab'
])
param env string

@description('Azure region. Mapped to a short region code internally.')
param location string = 'usgovvirginia'

// ----------------------------- Outputs ---------------------------------------
// Retained for callers that prefer module outputs over the imported functions.
// Implemented via the exported functions so there is a single implementation.

@description('Hyphenated name base, e.g. "ntc-plm-prd-usgv". Append "-{type}{instance}".')
output base string = makeBase(org, label, env, location)

@description('Compact name base, e.g. "ntcplmprdusgv". Append "{type}{instance}".')
output baseCompact string = makeBaseCompact(org, label, env, location)

@description('Resolved short region code, e.g. "usgv".')
output regionCode string = regionCodeOf(location)
