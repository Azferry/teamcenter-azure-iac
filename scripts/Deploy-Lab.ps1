#Requires -Version 5.1
<#
.SYNOPSIS
    Logs in to Azure Government and deploys the DEMO lab landing zone
    (VNet + Azure Bastion + auto-promoted domain controller) with Key Vault.

.DESCRIPTION
    Switches the Azure CLI active cloud to AzureUSGovernment, authenticates,
    optionally selects the target subscription, and runs a subscription-scoped
    Bicep deployment of lab-infra/main.bicep using lab-infra/lab.bicepparam.

    Secrets (the domain controller local admin password and the DSRM/safe-mode
    password) are NEVER committed to source. If they are not supplied, strong
    random values are generated at deploy time and stored in the lab Key Vault.

.PARAMETER Cloud
    Target Azure cloud. One of: AzureCloud (commercial) or AzureUSGovernment
    (US Gov). Defaults to AzureUSGovernment.

.PARAMETER Location
    Azure region for the deployment. If omitted, a per-cloud default is used
    (eastus for AzureCloud, usgovvirginia for AzureUSGovernment).

.PARAMETER SubscriptionId
    Subscription to deploy into. If omitted, the current default is used.

.PARAMETER TenantId
    Optional tenant ID for login.

.PARAMETER DeployerObjectId
    Object ID granted secret access on the Key Vault. If omitted, the signed-in
    principal's object ID is resolved automatically.

.PARAMETER AdminPassword
    Optional secure local admin password. Generated if not supplied.

.PARAMETER DsrmPassword
    Optional secure DSRM (safe-mode) password. Generated if not supplied.

.PARAMETER WhatIf
    Runs `az deployment sub what-if` instead of creating the deployment.

.EXAMPLE
    ./Deploy-Lab.ps1 -SubscriptionId <guid>

.EXAMPLE
    ./Deploy-Lab.ps1 -SubscriptionId <guid> -WhatIf
#>
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('AzureCloud', 'AzureUSGovernment')]
    [string]$Cloud = 'AzureUSGovernment',

    [Parameter()]
    [string]$Location,

    [Parameter()]
    [string]$SubscriptionId,

    [Parameter()]
    [string]$TenantId,

    [Parameter()]
    [string]$DeployerObjectId,

    [Parameter()]
    [securestring]$AdminPassword,

    [Parameter()]
    [securestring]$DsrmPassword,

    [Parameter()]
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'

function Invoke-AzCli {
    param([Parameter(Mandatory = $true)][string[]]$Arguments)
    Write-Host "> az $($Arguments -join ' ')" -ForegroundColor DarkGray
    & az @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Azure CLI command failed (exit $LASTEXITCODE): az $($Arguments -join ' ')"
    }
}

function New-RandomPassword {
    # 24 chars mixing categories to satisfy Windows complexity requirements.
    $upper = 'ABCDEFGHJKLMNPQRSTUVWXYZ'
    $lower = 'abcdefghijkmnpqrstuvwxyz'
    $digit = '23456789'
    $special = '!@#$%^&*()-_=+'
    $all = $upper + $lower + $digit + $special
    $chars = @()
    $chars += ($upper.ToCharArray() | Get-Random)
    $chars += ($lower.ToCharArray() | Get-Random)
    $chars += ($digit.ToCharArray() | Get-Random)
    $chars += ($special.ToCharArray() | Get-Random)
    for ($i = 0; $i -lt 20; $i++) { $chars += ($all.ToCharArray() | Get-Random) }
    return (($chars | Sort-Object { Get-Random }) -join '')
}

function ConvertTo-Plain {
    param([securestring]$Secure)
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Secure)
    try { return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
}

# Resolve paths relative to this script.
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$labRoot = Resolve-Path (Join-Path (Join-Path $scriptRoot '..') 'lab-infra')
$templateFile = Join-Path $labRoot 'main.bicep'
$paramFile = Join-Path $labRoot 'lab.bicepparam'

if (-not (Test-Path $templateFile)) { throw "Template not found: $templateFile" }
if (-not (Test-Path $paramFile)) { throw "Parameter file not found: $paramFile" }

# Verify Azure CLI is available.
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    throw 'Azure CLI (az) is not installed or not on PATH.'
}

# Default the region based on the selected cloud if not explicitly provided.
if (-not $Location) {
    $Location = if ($Cloud -eq 'AzureUSGovernment') { 'usgovvirginia' } else { 'eastus' }
}

# 1. Switch to the target Azure cloud.
Write-Host "Switching Azure CLI cloud to $Cloud..." -ForegroundColor Cyan
Invoke-AzCli @('cloud', 'set', '--name', $Cloud)

# 2. Login.
Write-Host "Logging in to $Cloud..." -ForegroundColor Cyan
$loginArgs = @('login')
if ($TenantId) { $loginArgs += @('--tenant', $TenantId) }
Invoke-AzCli $loginArgs

# 3. Select subscription (optional).
if ($SubscriptionId) {
    Write-Host "Setting active subscription to $SubscriptionId..." -ForegroundColor Cyan
    Invoke-AzCli @('account', 'set', '--subscription', $SubscriptionId)
}

# 4. Resolve deployer object ID if not provided.
if (-not $DeployerObjectId) {
    Write-Host "Resolving signed-in principal object ID..." -ForegroundColor Cyan
    $DeployerObjectId = (& az ad signed-in-user show --query id -o tsv)
    if ($LASTEXITCODE -ne 0 -or -not $DeployerObjectId) {
        throw 'Could not resolve DeployerObjectId. Pass it explicitly with -DeployerObjectId.'
    }
}

# 5. Generate secrets if not supplied.
$adminPwPlain = if ($AdminPassword) { ConvertTo-Plain $AdminPassword } else { New-RandomPassword }
$dsrmPwPlain = if ($DsrmPassword) { ConvertTo-Plain $DsrmPassword } else { New-RandomPassword }

# 6. Deploy (or what-if).
$deploymentName = "teamcenter-lab-$(Get-Date -Format 'yyyyMMddHHmmss')"
$action = if ($WhatIf) { 'what-if' } else { 'create' }

Write-Host "Running subscription deployment ($action) '$deploymentName' in $Location..." -ForegroundColor Cyan
$deployArgs = @(
    'deployment', 'sub', $action,
    '--name', $deploymentName,
    '--location', $Location,
    '--template-file', $templateFile,
    '--parameters', $paramFile,
    '--parameters', "deployerObjectId=$DeployerObjectId",
    '--parameters', "adminPassword=$adminPwPlain",
    '--parameters', "dsrmPassword=$dsrmPwPlain"
)
Invoke-AzCli $deployArgs

Write-Host "Done. Passwords are stored in the lab Key Vault (secrets: dc-admin-password, dc-dsrm-password)." -ForegroundColor Green
