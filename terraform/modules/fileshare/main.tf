variable "name_base_compact" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "tags" { type = map(string) }
variable "subnet_id" { type = string }
variable "share_name" {
  type    = string
  default = "teamcenter-fms"
}
variable "share_quota_gib" {
  type    = number
  default = 1024
}
variable "instance" {
  type    = number
  default = 2
}
variable "deploy_private_dns" {
  type    = bool
  default = false
}
variable "private_dns_zone_id" {
  type    = string
  default = ""
}

locals {
  file_storage_account_name = substr(lower("${var.name_base_compact}st${var.instance}f"), 0, 24)
  private_endpoint_name     = "${local.file_storage_account_name}-pe"
  link_private_dns          = var.deploy_private_dns && var.private_dns_zone_id != ""
}

resource "azurerm_storage_account" "this" {
  name                            = local.file_storage_account_name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  account_tier                    = "Premium"
  account_replication_type        = "LRS"
  account_kind                    = "FileStorage"
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = false
  tags                            = var.tags

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }
}

resource "azurerm_storage_share" "fms" {
  name               = var.share_name
  storage_account_id = azurerm_storage_account.this.id
  quota              = var.share_quota_gib
  enabled_protocol   = "SMB"
}

resource "azurerm_private_endpoint" "this" {
  name                = local.private_endpoint_name
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = local.private_endpoint_name
    private_connection_resource_id = azurerm_storage_account.this.id
    subresource_names              = ["file"]
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

output "storage_account_id" { value = azurerm_storage_account.this.id }
output "storage_account_name" { value = azurerm_storage_account.this.name }
output "share_resource_id" { value = azurerm_storage_share.fms.id }
output "share_name_out" { value = azurerm_storage_share.fms.name }
output "unc_path" {
  value = "\\\\${azurerm_storage_account.this.name}.file.core.usgovcloudapi.net\\${azurerm_storage_share.fms.name}"
}
