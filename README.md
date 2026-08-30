# teamcenter-azure-iac

Infrastructure-as-Code (Bicep) for deploying **Teamcenter** on **Azure Government**.

## Layout

```text
infra/
  main.bicep                 # Subscription-scoped orchestrator (creates RG + calls modules)
  environments/
    dev.bicepparam           # Per-environment parameters
    tst.bicepparam
    prd.bicepparam
  modules/
    network/network.bicep    # VNet, subnets, NSGs
    storage/storage.bicep    # Storage account(s)
    database/database.bicep  # Database tier (stub)
    compute/compute.bicep    # Compute tier (stub)
scripts/
  Deploy-Teamcenter.ps1      # az cloud set -> login -> deploy
```

## Prerequisites

- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) with the Bicep tooling (`az bicep install`)
- PowerShell 5.1+ (or PowerShell 7+)
- Access to an Azure **Government** subscription

## Deploy

The deploy script switches the Azure CLI to the Azure Government cloud, logs in,
optionally selects a subscription, and runs the Bicep deployment.

```powershell
# Preview changes (what-if)
./scripts/Deploy-Teamcenter.ps1 -Environment dev -SubscriptionId <guid> -WhatIf

# Deploy
./scripts/Deploy-Teamcenter.ps1 -Environment dev -SubscriptionId <guid>
```

Parameters: `-Environment` (dev|tst|prd), `-Location` (default `usgovvirginia`),
`-SubscriptionId`, `-TenantId`, `-WhatIf`.

## Extending

- Add resources to the `compute` and `database` module stubs for each Teamcenter tier.
- Adjust network address spaces in `modules/network/network.bicep`.
- Tune per-environment settings in `infra/environments/*.bicepparam`.

