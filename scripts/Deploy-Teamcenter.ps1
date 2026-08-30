#Requires -Version 5.1
<#
.SYNOPSIS
    Logs in to Azure Government and deploys the Teamcenter infrastructure.

.DESCRIPTION
    Switches the Azure CLI active cloud to AzureUSGovernment, authenticates,
    selects the target subscription, and runs a subscription-scoped Bicep
    deployment using the environment-specific .bicepparam file.

.PARAMETER Environment
    Target environment. One of: dev, tst, prd. Selects the matching
    infra/environments/<env>.bicepparam file.

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

.PARAMETER WhatIf
    Runs `az deployment sub what-if` instead of creating the deployment.

.EXAMPLE
    ./Deploy-Teamcenter.ps1 -Environment dev -SubscriptionId <guid>

.EXAMPLE
    ./Deploy-Teamcenter.ps1 -Environment prd -WhatIf
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('dev', 'tst', 'prd')]
    [string]$Environment,

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

# Resolve paths relative to this script.
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$infraRoot = Resolve-Path (Join-Path (Join-Path $scriptRoot '..') 'infra')
$templateFile = Join-Path $infraRoot 'main.bicep'
$paramFile = Join-Path $infraRoot "environments/$Environment.bicepparam"

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

# 4. Deploy (or what-if).
$deploymentName = "teamcenter-$Environment-$(Get-Date -Format 'yyyyMMddHHmmss')"
$action = if ($WhatIf) { 'what-if' } else { 'create' }

Write-Host "Running subscription deployment ($action) '$deploymentName' in $Location..." -ForegroundColor Cyan
$deployArgs = @(
    'deployment', 'sub', $action,
    '--name', $deploymentName,
    '--location', $Location,
    '--template-file', $templateFile,
    '--parameters', $paramFile
)
Invoke-AzCli $deployArgs

Write-Host "Done." -ForegroundColor Green
