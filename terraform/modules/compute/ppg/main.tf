variable "name" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "tags" {
  type    = map(string)
  default = {}
}

resource "azurerm_proximity_placement_group" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

output "id" { value = azurerm_proximity_placement_group.this.id }
output "ppg_name" { value = azurerm_proximity_placement_group.this.name }
