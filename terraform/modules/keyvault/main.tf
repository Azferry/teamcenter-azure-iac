variable "name_base_compact" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "tags" { type = map(string) }
variable "tenant_id" { type = string }
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
variable "des_key_name" {
  type    = string
  default = "des-key"
}
variable "storage_key_name" {
  type    = string
  default = "storage-key"
}
variable "instance" {
  type    = number
  default = 1
}

locals {
  key_vault_name   = substr(lower("${var.name_base_compact}kv${var.instance}"), 0, 24)
  private_ep_name  = "${local.key_vault_name}-pe"
  link_private_dns = var.deploy_private_dns && var.private_dns_zone_id != ""
}

resource "azurerm_key_vault" "this" {
  name                            = local.key_vault_name
  location                        = var.location
  resource_group_name             = var.resource_group_name
  tenant_id                       = var.tenant_id
  sku_name                        = "standard"
  tags                            = var.tags
  enable_rbac_authorization       = true
  purge_protection_enabled        = var.enable_purge_protection
  soft_delete_retention_days      = 90
  public_network_access_enabled   = false

  network_acls {
    bypass         = "AzureServices"
    default_action = "Deny"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_key_vault_key" "des" {
  name         = var.des_key_name
  key_vault_id = azurerm_key_vault.this.id
  key_type     = "RSA"
  key_size     = 3072
  key_opts     = ["unwrapKey", "wrapKey"]
}

resource "azurerm_key_vault_key" "storage" {
  name         = var.storage_key_name
  key_vault_id = azurerm_key_vault.this.id
  key_type     = "RSA"
  key_size     = 3072
  key_opts     = ["unwrapKey", "wrapKey"]
}

resource "azurerm_private_endpoint" "this" {
  name                = local.private_ep_name
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = local.private_ep_name
    private_connection_resource_id = azurerm_key_vault.this.id
    subresource_names              = ["vault"]
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

output "key_vault_id" { value = azurerm_key_vault.this.id }
output "key_vault_name" { value = azurerm_key_vault.this.name }
output "key_vault_uri" { value = azurerm_key_vault.this.vault_uri }
output "des_key_name" { value = azurerm_key_vault_key.des.name }
output "des_key_uri" { value = azurerm_key_vault_key.des.versionless_id }
output "des_key_uri_with_version" { value = azurerm_key_vault_key.des.id }
output "storage_key_name" { value = azurerm_key_vault_key.storage.name }
output "storage_key_uri" { value = azurerm_key_vault_key.storage.versionless_id }
