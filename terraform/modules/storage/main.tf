variable "name_base_compact" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "tags" { type = map(string) }
variable "sku_name" {
  type    = string
  default = "Standard_LRS"
}
variable "instance" {
  type    = number
  default = 1
}
variable "user_assigned_identity_id" { type = string }
variable "key_vault_key_id" { type = string }

locals {
  storage_account_name = substr(lower("${var.name_base_compact}st${var.instance}"), 0, 24)
}

resource "azurerm_storage_account" "this" {
  name                     = local.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = split("_", var.sku_name)[0]
  account_replication_type = split("_", var.sku_name)[1]
  min_tls_version          = "TLS1_2"
  https_traffic_only_enabled = true
  allow_nested_items_to_be_public = false
  account_kind             = "StorageV2"
  shared_access_key_enabled = true
  public_network_access_enabled = true
  tags                     = var.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [var.user_assigned_identity_id]
  }
}

resource "azurerm_storage_account_customer_managed_key" "this" {
  storage_account_id           = azurerm_storage_account.this.id
  key_vault_key_id             = var.key_vault_key_id
  user_assigned_identity_id    = var.user_assigned_identity_id
}

output "storage_account_id" { value = azurerm_storage_account.this.id }
output "storage_account_name" { value = azurerm_storage_account.this.name }
