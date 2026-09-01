#Requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('dev', 'tst', 'prd')]
    [string]$Environment,

    [Parameter()]
    [ValidateSet('AzureCloud', 'AzureUSGovernment')]
    [string]$Cloud = 'AzureUSGovernment',

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

function Invoke-Terraform {
    param([Parameter(Mandatory = $true)][string[]]$Arguments)
    Write-Host "> terraform $($Arguments -join ' ')" -ForegroundColor DarkGray
    & terraform @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Terraform command failed (exit $LASTEXITCODE): terraform $($Arguments -join ' ')"
    }
}

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptRoot '..')
$tfRoot = Join-Path $repoRoot 'terraform/infra'
$backendFile = Join-Path $tfRoot "environments/backend.$Environment.hcl"
$tfvarsFile = Join-Path $tfRoot "environments/$Environment.tfvars"

if (-not (Test-Path $tfRoot)) { throw "Terraform root not found: $tfRoot" }
if (-not (Test-Path $backendFile)) { throw "Backend file not found: $backendFile" }
if (-not (Test-Path $tfvarsFile)) { throw "TFVars file not found: $tfvarsFile" }

Write-Host "Switching Azure CLI cloud to $Cloud..." -ForegroundColor Cyan
Invoke-AzCli @('cloud', 'set', '--name', $Cloud)

Write-Host "Logging in to $Cloud..." -ForegroundColor Cyan
$loginArgs = @('login')
if ($TenantId) { $loginArgs += @('--tenant', $TenantId) }
Invoke-AzCli $loginArgs

if ($SubscriptionId) {
    Write-Host "Setting active subscription to $SubscriptionId..." -ForegroundColor Cyan
    Invoke-AzCli @('account', 'set', '--subscription', $SubscriptionId)
}

Push-Location $tfRoot
try {
    Invoke-Terraform @('init', "-backend-config=$backendFile")

    if ($WhatIf) {
        Invoke-Terraform @('plan', "-var-file=$tfvarsFile")
    }
    else {
        Invoke-Terraform @('apply', "-var-file=$tfvarsFile")
    }
}
finally {
    Pop-Location
}

Write-Host "Done." -ForegroundColor Green
