# Terraform Teamcenter Infrastructure (Azure Government)

This folder contains the Terraform implementation of the **Teamcenter** infrastructure stack for **Azure Government**.

## Scope

- Includes only Teamcenter infrastructure from `infra/`.
- Excludes lab infrastructure (`lab-infra/`).

## Structure

- `infra/` root deployment
- `modules/` reusable Teamcenter modules
- `infra/environments/*.tfvars.example` environment variable examples

## Azure Government

- Provider is configured with `environment = "usgovernment"`.
- Gov endpoints are used for resource URIs (for example: `usgovcloudapi.net`).

## Deploy

From repository root:

1. Set secrets with environment variables:
   - `TF_VAR_compute_admin_password`
   - `TF_VAR_oracle_admin_password`
2. Copy an example tfvars file:
   - `terraform/infra/environments/dev.tfvars.example` -> `terraform/infra/environments/dev.tfvars`
3. Initialize and plan/apply:

```powershell
terraform -chdir=terraform/infra init -backend-config=environments/backend.dev.hcl
terraform -chdir=terraform/infra plan -var-file=environments/dev.tfvars
terraform -chdir=terraform/infra apply -var-file=environments/dev.tfvars
```

## Validation

```powershell
terraform fmt -recursive terraform
terraform -chdir=terraform/infra init -backend=false
terraform -chdir=terraform/infra validate
```
