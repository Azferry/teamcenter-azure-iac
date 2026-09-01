provider "azurerm" {
  environment = "usgovernment"
  features {}
}

data "azurerm_client_config" "current" {}
