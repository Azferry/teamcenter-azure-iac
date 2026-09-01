variable "name_base" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "tags" { type = map(string) }
variable "key_vault_id" { type = string }
variable "key_url" { type = string }
variable "instance" {
  type    = number
  default = 1
}

resource "azurerm_disk_encryption_set" "this" {
  name                = "${var.name_base}-des${var.instance}"
  location            = var.location
  resource_group_name = var.resource_group_name
  key_vault_key_id    = var.key_url
  auto_key_rotation_enabled = true
  tags                = var.tags

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "des_kv_crypto" {
  scope              = var.key_vault_id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id       = azurerm_disk_encryption_set.this.identity[0].principal_id
  principal_type     = "ServicePrincipal"

  depends_on = [azurerm_disk_encryption_set.this]
}

output "disk_encryption_set_id" { value = azurerm_disk_encryption_set.this.id }
output "disk_encryption_set_name" { value = azurerm_disk_encryption_set.this.name }
output "principal_id" { value = azurerm_disk_encryption_set.this.identity[0].principal_id }
