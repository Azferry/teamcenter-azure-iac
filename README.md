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

## Lab landing zone (demo)

For demos, `lab-infra/` stands up a **self-contained** landing zone that is
independent of the production Teamcenter stack in `infra/`. It provisions:

- an **Azure Key Vault** that stores the domain controller passwords as secrets,
- a **VNet** with an **Azure Bastion** host (browser-based RDP/SSH, no public IPs
  on the VMs), and
- a **Windows Server 2022 domain controller** VM that is **auto-promoted** to a
  new Active Directory forest (`Install-ADDSForest`). After promotion the VNet
  DNS is repointed to the domain controller.

```text
lab-infra/
  main.bicep                 # Subscription-scoped orchestrator (creates <prefix>-lab-rg)
  lab.bicepparam             # Non-secret defaults (secrets supplied at deploy time)
  modules/
    keyvault.bicep           # Key Vault + secrets (dc-admin-password, dc-dsrm-password)
    network.bicep            # VNet, AzureBastionSubnet, dc subnet, NSG, DNS repoint
    bastion.bicep            # Public IP + Azure Bastion host
    domaincontroller.bicep   # Windows Server 2022 VM + auto-promote to AD forest
```

Secrets are **never committed**. `scripts/Deploy-Lab.ps1` generates strong
random passwords (unless supplied), stores them in the Key Vault, and passes
them securely into the deployment.

```powershell
# Preview changes (what-if)
./scripts/Deploy-Lab.ps1 -SubscriptionId <guid> -WhatIf

# Deploy
./scripts/Deploy-Lab.ps1 -SubscriptionId <guid>
```

Parameters: `-Location` (default `usgovvirginia`), `-SubscriptionId`,
`-TenantId`, `-DeployerObjectId` (auto-resolved if omitted), `-AdminPassword`,
`-DsrmPassword`, `-WhatIf`.

> Note: domain controller promotion reboots the VM to complete. Access the DC
> through the Bastion host; there is no public IP on the VM.

## Extending

- Add resources to the `compute` and `database` module stubs for each Teamcenter tier.
- Adjust network address spaces in `modules/network/network.bicep`.
- Tune per-environment settings in `infra/environments/*.bicepparam`.

