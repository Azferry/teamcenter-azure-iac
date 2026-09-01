variable "key_vault_id" {
  type = string
}

variable "principal_id" {
  type = string
}

resource "azurerm_role_assignment" "storage_kv_crypto" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = var.principal_id
  principal_type       = "ServicePrincipal"
}

output "role_assignment_id" {
  value = azurerm_role_assignment.storage_kv_crypto.id
}
