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

// ----------------------------- Variables -------------------------------------

// location -> short region code. Single source of truth; extend as needed.
var regionCodeMap = {
  usgovvirginia: 'usgv'
  usgovarizona: 'usga'
  usgovtexas: 'usgt'
  eastus: 'eus'
  eastus2: 'eus2'
  westus: 'wus'
  centralus: 'cus'
}
var regionCode = regionCodeMap[location]

// Hyphenated base for hyphen-friendly resource types.
var base = toLower('${org}-${label}-${env}-${regionCode}')
// Compact base (no special chars) for storage accounts, key vaults, etc.
var baseCompact = toLower('${org}${label}${env}${regionCode}')

// ----------------------------- Outputs ---------------------------------------

@description('Hyphenated name base, e.g. "ntc-plm-prd-usgv". Append "-{type}{instance}".')
output base string = base

@description('Compact name base, e.g. "ntcplmprdusgv". Append "{type}{instance}".')
output baseCompact string = baseCompact

@description('Resolved short region code, e.g. "usgv".')
output regionCode string = regionCode
