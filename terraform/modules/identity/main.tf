variable "name_base" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "tags" { type = map(string) }
variable "instance" {
  type    = number
  default = 1
}

resource "azurerm_user_assigned_identity" "this" {
  name                = "${var.name_base}-umi${var.instance}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

output "managed_identity_id" { value = azurerm_user_assigned_identity.this.id }
output "managed_identity_name" { value = azurerm_user_assigned_identity.this.name }
output "principal_id" { value = azurerm_user_assigned_identity.this.principal_id }
output "client_id" { value = azurerm_user_assigned_identity.this.client_id }
