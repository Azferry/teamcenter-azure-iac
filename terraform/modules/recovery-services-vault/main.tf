variable "name_base" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "tags" { type = map(string) }
variable "subnet_id" { type = string }
variable "enable_purge_protection" {
  type    = bool
  default = false
}
variable "deploy_private_dns" {
  type    = bool
  default = false
}
variable "private_dns_zone_id" {
  type    = string
  default = ""
}
variable "default_policy_name" {
  type    = string
  default = "default-daily-vm-policy"
}
variable "instance" {
  type    = number
  default = 1
}

locals {
  recovery_vault_name = "${var.name_base}-rsv${var.instance}"
  private_ep_name     = "${local.recovery_vault_name}-pe"
  link_private_dns    = var.deploy_private_dns && var.private_dns_zone_id != ""
}

resource "azurerm_recovery_services_vault" "this" {
  name                = local.recovery_vault_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"
  public_network_access_enabled = false
  soft_delete_enabled = var.enable_purge_protection
  tags                = var.tags

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_backup_policy_vm" "default" {
  name                = var.default_policy_name
  resource_group_name = var.resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.this.name
  timezone            = "UTC"

  backup {
    frequency = "Daily"
    time      = "23:00"
  }

  retention_daily {
    count = 30
  }
}

resource "azurerm_private_endpoint" "this" {
  name                = local.private_ep_name
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = local.private_ep_name
    private_connection_resource_id = azurerm_recovery_services_vault.this.id
    subresource_names              = ["AzureBackup"]
    is_manual_connection           = false
  }

  dynamic "private_dns_zone_group" {
    for_each = local.link_private_dns ? [1] : []
    content {
      name                 = "default"
      private_dns_zone_ids = [var.private_dns_zone_id]
    }
  }
}

output "recovery_services_vault_id" { value = azurerm_recovery_services_vault.this.id }
output "recovery_services_vault_name" { value = azurerm_recovery_services_vault.this.name }
output "default_policy_name" { value = azurerm_backup_policy_vm.default.name }
