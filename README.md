# teamcenter-azure-iac

Infrastructure-as-Code (Bicep) for deploying **Teamcenter** on **Azure Government**.

## Layout

```text
modules/
  naming.bicep               # Shared naming convention (region map + name bases)
infra/
  main.bicep                 # Subscription-scoped orchestrator (creates RG + calls modules)
  environments/
    dev.bicepparam           # Per-environment parameters
    tst.bicepparam
    prd.bicepparam
  modules/
    network.bicep            # VNet, subnets, NSGs
    storage.bicep            # Storage account(s)
    database.bicep           # Oracle DB tier (IaaS BYOL on RHEL)
    compute.bicep            # Teamcenter compute tiers (parameter-driven)
    fileshare.bicep          # Premium Azure Files share for FMS volumes
    compute/
      vm-role.bicep          # Reusable role VM module
      ppg.bicep              # Proximity placement group helper
    database/
      oracle-vm.bicep        # Oracle primary/standby VM wrapper
      oracle-dataguard.bicep # Optional Data Guard observer + standby
scripts/
  Deploy-Teamcenter.ps1      # az cloud set -> login -> deploy
```

## Naming convention

All resources follow a consistent, reusable naming standard. The canonical
definition lives in `modules/naming.bicep`; each stack computes the same name
bases inline (as compile-time vars, so the resource group name resolves before
any module runs).

| Token | Meaning | This deployment |
|-------|---------|-----------------|
| `org` | 3-char organization code | `ntc` |
| `label` | 3-4 char workload label | `plm` |
| `env` | environment | `dev` / `tst` / `prd` / `lab` |
| `region` | short region code | `usgv` (usgovvirginia) |
| `type` | CAF resource-type code | see below |
| `instance` | instance number, starts at 1 | `1` |

**Patterns**

- Hyphenated (default): `{org}-{label}-{env}-{region}-{type}{instance}`
  e.g. `ntc-plm-prd-usgv-rg1`
- Compact (for resources that disallow special chars, e.g. storage accounts and
  key vaults): `{org}{label}{env}{region}{type}{instance}`
  e.g. `ntcplmprdusgvst1`

**Resource-type codes (Microsoft CAF)**

| Resource | Code | Resource | Code |
|----------|------|----------|------|
| Resource group | `rg` | Storage account | `st` |
| Virtual network | `vnet` | Key vault | `kv` |
| Subnet | `snet` | Virtual machine | `vm` |
| Network security group | `nsg` | Network interface | `nic` |
| Public IP | `pip` | Bastion | `bas` |

**Region codes**

| Azure region | Code |
|--------------|------|
| `usgovvirginia` | `usgv` |

To onboard a new region, add it to `regionCodeMap` in `modules/naming.bicep`
(and the inline map in each `main.bicep`).

## Prerequisites

- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) with the Bicep tooling (`az bicep install`) - Version 0.46 or greater
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
  main.bicep                 # Subscription-scoped orchestrator (creates ntc-plm-lab-usgv-rg1)
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

## Teamcenter server roles and scaling

Deployment is parameter-driven per role. Each role object supports at least:
`enabled`, `count`, `vmSize`, `osType`, and `image`.

- Set `enabled: false` or `count: 0` to skip a role.
- Change `count` to scale out/in.
- Default OS is **Windows Server 2022**, but each role can be switched to Linux by updating `osType` and `image`.

Implemented roles:

- Web tier: `webServer`, `tcss`
- Enterprise tier: `enterprise`, `poolManager`, `awcPortal`, `fmsVolumeServer`, `fscCache`, `solr`, `dispatcher`, `visualization`, `licenseServer`
- Resource tier (Oracle): `oraclePrimary`, `oracleStandby`, `oracleObserver`

## Oracle on IaaS (BYOL)

The database tier deploys Oracle VM infrastructure on RHEL BYOL defaults:

- Image: `RedHat:RHEL:8-lvm-gen2:latest`
- Primary SKU default: `Standard_E32-16ds_v4`
- Data Guard standby and observer are optional and parameter-driven.

## FMS storage

Current implementation uses **Premium Azure Files (SMB)** with private endpoint.
The deployment outputs the UNC path as `fmsFilesShareUnc`.

Alternative noted for future use: FMS volume server VMs with attached/striped Premium managed disks.

## Extending

- Adjust subnet CIDRs and NSG rules in `infra/modules/network.bicep`.
- Tune role objects in `infra/environments/*.bicepparam`.

