# Infrastructure-as-Code (Bicep) for deploying **Teamcenter** on **Azure Government**.

## Overview

This repository deploys a baseline Teamcenter platform using modular Bicep templates.
It is designed for a **parameter-driven** rollout so each environment can control:

- the number of servers per Teamcenter role,
- the VM SKU (`vmSize`) per role,
- Windows-by-default or Linux override for supported roles,
- Oracle on IaaS (BYOL on RHEL), and
- internal-only networking with private endpoints.

The deployment currently implements:

- **Web tier**: Teamcenter web and TCSS roles
- **Enterprise tier**: application/service roles (enterprise, pool manager, AWC, FMS/FSC, Solr, dispatcher, license)
- **Resource tier**: Oracle VM infrastructure and Premium Azure Files for FMS volumes

Client/AVD and public ingress components are intentionally excluded in this baseline.

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
terraform/
  infra/                     # Terraform working directory (provider/module cache present)
scripts/
  Deploy-Teamcenter.ps1      # az cloud set -> login -> deploy
```

## Deployment details

### Deployment scope and flow

- `infra/main.bicep` is **subscription-scoped**.
- It creates the target resource group, then deploys modules into that group.
- Core module order is:
  1. network
  2. identity
  3. key vault + keys
  4. storage encryption role assignment
  5. disk encryption set
  6. storage + fileshare
  7. compute + database
  8. recovery services vault

### Network model

By default, the deployment creates a VNet with three subnets:

- `web-tier-sn`
- `enterprise-tier-sn`
- `resource-tier-sn`

Bring-your-own VNet is supported through `deployVnet = false` and existing subnet parameters.

NSGs are included with starter rules to allow tier-to-tier traffic and deny inbound internet.

### Compute and scale model

Compute is deployed by role via reusable VM modules. Each role object is parameter-driven.
Common controls:

- `enabled`
- `count`
- `vmSize`
- `osType`
- `image`
- `availabilityZones`

To scale a role, update `count` in the environment parameter file.
To change server SKU, update `vmSize` for that role.

### Database model (Oracle IaaS)

Oracle infrastructure is provisioned as VMs (BYOL) on RHEL defaults.

- Primary role: `oraclePrimary`
- Optional HA/DR roles: `oracleStandby`, `oracleObserver`

Disk and VM sizing are parameter-driven in environment files.

### FMS storage model

FMS volumes use **Premium Azure Files (SMB)** with private endpoint.
The deployment outputs the share UNC path as `fmsFilesShareUnc`.

Alternative supported design (future): FMS VM with attached/striped Premium managed disks.

### Environment parameter files

Use environment files under `infra/environments/` to control topology:

- `dev.bicepparam`
- `tst.bicepparam`
- `prd.bicepparam`

These files define per-role server count, per-role SKU, Oracle role toggles, and FMS share sizing.

### Server roles table

| Server role parameter | Tier | Purpose |
|---|---|---|
| `webServer` | Web | Hosts Teamcenter web services and Active Workspace gateway endpoint. |
| `tcss` | Web | Runs Teamcenter Security Services (SSO/SAML integration path). |
| `enterprise` | Enterprise | Runs Teamcenter core enterprise/business logic services. |
| `poolManager` | Enterprise | Manages server pools and session distribution for 4-tier components. |
| `awcPortal` | Enterprise | Hosts Active Workspace portal/application services. |
| `fmsVolumeServer` | Enterprise | Owns Teamcenter FMS volume service integration point. |
| `fscCache` | Enterprise | Provides Teamcenter file cache services (FSC) for performance. |
| `solr` | Enterprise | Hosts Apache Solr for Teamcenter search/index functions. |
| `dispatcher` | Enterprise | Runs Teamcenter dispatcher/processing jobs. |
| `visualization` | Enterprise | Optional visualization workload host (GPU-capable SKU). |
| `licenseServer` | Enterprise | Hosts Teamcenter/Flex license service. |
| `oraclePrimary` | Resource | Oracle database primary VM (IaaS, BYOL on RHEL). |
| `oracleStandby` | Resource | Optional Oracle Data Guard standby VM for HA/DR. |
| `oracleObserver` | Resource | Optional Oracle Data Guard observer VM for failover orchestration. |
| `fmsFilesShareUnc` (output) | Resource | Premium Azure Files SMB share path used for FMS volume storage. |

### Security controls in baseline

- Managed identity for service access
- CMK-backed encryption (Key Vault + Disk Encryption Set)
- Private endpoints for vault/backup/fileshare modules (with optional private DNS linking)
- Internal-only server topology (no public IPs in compute/database roles)

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

## Terraform implementation

Current implementation status in this repository:

- The deployable baseline is implemented with **Bicep** under `infra/`.
- A `terraform/infra/` working directory exists for Terraform usage.
- At this time, Terraform source files (`.tf`) are not committed in this repo.
- Target parity for Terraform should align with the same baseline tiers used by Bicep: web, enterprise, resource, private networking, and secure-by-default controls.

If Terraform source is added later, use Azure Government endpoints and keep naming, role model, and environment parameterization aligned with `infra/environments/*.bicepparam`.

## Reference architecture (quick overview)

Reference: [Siemens Teamcenter baseline architecture on Azure](https://learn.microsoft.com/en-us/azure/architecture/example-scenario/manufacturing/teamcenter-baseline)

```mermaid
flowchart LR
  U[Teamcenter users<br/>Rich Client / AWC Client] --> ID[Microsoft Entra ID<br/>SSO (SAML)]
  A[Admins / Support<br/>On-premises] --> ER[ExpressRoute / VPN]

  subgraph Hub[Hub Virtual Network]
    FW[Azure Firewall]
    AGW[Azure Application Gateway]
  end

  subgraph Spoke[Spoke Virtual Network]
    subgraph WebTier[Web Tier]
      TCSS[TCSS]
      WEB[Teamcenter Web Servers]
      AWCGW[AWC Gateway]
    end

    subgraph EnterpriseTier[Enterprise Tier]
      CORE[Teamcenter Foundation / Services]
      DISPATCH[Dispatcher]
      AWC[AWC Portal]
      FMS[FMS / FSC]
      SOLR[Apache Solr]
      LIC[License Server]
    end

    subgraph ResourceTier[Resource Tier]
      DB[Oracle or SQL Database]
      STORAGE[Azure Files Premium / ANF]
    end

    KV[Azure Key Vault]
    MON[Azure Monitor]
    BAK[Azure Backup]
  end

  ID --> FW
  ER --> FW
  FW --> AGW
  AGW --> TCSS
  AGW --> WEB
  AGW --> AWCGW

  TCSS --> CORE
  WEB --> CORE
  AWCGW --> AWC
  CORE --> DB
  CORE --> STORAGE
  FMS --> STORAGE

  KV -. secrets/certs .-> WebTier
  KV -. secrets/certs .-> EnterpriseTier
  MON -. telemetry .-> WebTier
  MON -. telemetry .-> EnterpriseTier
  MON -. telemetry .-> ResourceTier
  BAK -. protection .-> DB
  BAK -. protection .-> STORAGE
```

- Diagram above is a simplified rendering of the Microsoft reference architecture for documentation purposes.

- Uses a **hub-spoke** network: internet/on-prem traffic enters hub controls, then routes to a spoke hosting Teamcenter tiers.
- Defines **four tiers**: client, web, enterprise, and resource.
- Web tier commonly includes **TCSS**, Teamcenter web servers, and Active Workspace gateway behind load balancing.
- Enterprise tier hosts Teamcenter business services (for example foundation/services, dispatcher, AWC portal, FMS/FSC, Solr, and license roles).
- Resource tier provides database and storage services (for example Oracle/SQL options and Azure Files Premium or Azure NetApp Files patterns).
- Security and operations patterns include SSO with Microsoft Entra ID (SAML), NSG segmentation, Azure Firewall in hub designs, Key Vault for secrets/certs, and Azure Monitor/Azure Backup for observability and protection.

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

