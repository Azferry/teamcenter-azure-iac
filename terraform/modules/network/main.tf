variable "name_base" {
  type        = string
  description = "Hyphenated base name."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "tags" {
  type        = map(string)
  description = "Tags for resources."
}

variable "deploy_vnet" {
  type        = bool
  description = "Create VNet and subnets when true."
  default     = true
}

variable "existing_vnet_name" {
  type        = string
  default     = ""
  description = "Existing VNet name for BYO mode."
}

variable "existing_vnet_resource_group" {
  type        = string
  default     = ""
  description = "Existing VNet resource group for BYO mode."
}

variable "existing_web_tier_subnet_name" {
  type        = string
  default     = "web-tier-sn"
}

variable "existing_enterprise_tier_subnet_name" {
  type        = string
  default     = "enterprise-tier-sn"
}

variable "existing_resource_tier_subnet_name" {
  type        = string
  default     = "resource-tier-sn"
}

variable "vnet_address_prefix" {
  type        = string
  default     = "10.50.0.0/16"
}

variable "web_tier_subnet_prefix" {
  type        = string
  default     = "10.50.1.0/24"
}

variable "enterprise_tier_subnet_prefix" {
  type        = string
  default     = "10.50.2.0/24"
}

variable "resource_tier_subnet_prefix" {
  type        = string
  default     = "10.50.3.0/24"
}

locals {
  vnet_name       = "${var.name_base}-vnet1"
  web_nsg_name    = "${var.name_base}-nsg1-web"
  ent_nsg_name    = "${var.name_base}-nsg1-enterprise"
  resource_nsg    = "${var.name_base}-nsg1-resource"
  existing_vnet_rg = var.existing_vnet_resource_group != "" ? var.existing_vnet_resource_group : var.resource_group_name
}

resource "azurerm_network_security_group" "web" {
  count               = var.deploy_vnet ? 1 : 0
  name                = local.web_nsg_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  security_rule {
    name                       = "allow-https-from-vnet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "deny-internet-inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "enterprise" {
  count               = var.deploy_vnet ? 1 : 0
  name                = local.ent_nsg_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  security_rule {
    name                       = "allow-web-to-enterprise"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["443", "7001", "7002", "8080"]
    source_address_prefix      = var.web_tier_subnet_prefix
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "deny-internet-inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "resource" {
  count               = var.deploy_vnet ? 1 : 0
  name                = local.resource_nsg
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  security_rule {
    name                       = "allow-oracle-from-enterprise"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["1521", "5500"]
    source_address_prefix      = var.enterprise_tier_subnet_prefix
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-resource-eastwest"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.resource_tier_subnet_prefix
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "deny-internet-inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

resource "azurerm_virtual_network" "this" {
  count               = var.deploy_vnet ? 1 : 0
  name                = local.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [var.vnet_address_prefix]
  tags                = var.tags
}

resource "azurerm_subnet" "web" {
  count                = var.deploy_vnet ? 1 : 0
  name                 = "web-tier-sn"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this[0].name
  address_prefixes     = [var.web_tier_subnet_prefix]
}

resource "azurerm_subnet_network_security_group_association" "web" {
  count                     = var.deploy_vnet ? 1 : 0
  subnet_id                 = azurerm_subnet.web[0].id
  network_security_group_id = azurerm_network_security_group.web[0].id
}

resource "azurerm_subnet" "enterprise" {
  count                = var.deploy_vnet ? 1 : 0
  name                 = "enterprise-tier-sn"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this[0].name
  address_prefixes     = [var.enterprise_tier_subnet_prefix]
}

resource "azurerm_subnet_network_security_group_association" "enterprise" {
  count                     = var.deploy_vnet ? 1 : 0
  subnet_id                 = azurerm_subnet.enterprise[0].id
  network_security_group_id = azurerm_network_security_group.enterprise[0].id
}

resource "azurerm_subnet" "resource" {
  count                = var.deploy_vnet ? 1 : 0
  name                 = "resource-tier-sn"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this[0].name
  address_prefixes     = [var.resource_tier_subnet_prefix]
}

resource "azurerm_subnet_network_security_group_association" "resource" {
  count                     = var.deploy_vnet ? 1 : 0
  subnet_id                 = azurerm_subnet.resource[0].id
  network_security_group_id = azurerm_network_security_group.resource[0].id
}

data "azurerm_virtual_network" "existing" {
  count               = var.deploy_vnet ? 0 : 1
  name                = var.existing_vnet_name
  resource_group_name = local.existing_vnet_rg
}

data "azurerm_subnet" "existing_web" {
  count                = var.deploy_vnet ? 0 : 1
  name                 = var.existing_web_tier_subnet_name
  virtual_network_name = var.existing_vnet_name
  resource_group_name  = local.existing_vnet_rg
}

data "azurerm_subnet" "existing_enterprise" {
  count                = var.deploy_vnet ? 0 : 1
  name                 = var.existing_enterprise_tier_subnet_name
  virtual_network_name = var.existing_vnet_name
  resource_group_name  = local.existing_vnet_rg
}

data "azurerm_subnet" "existing_resource" {
  count                = var.deploy_vnet ? 0 : 1
  name                 = var.existing_resource_tier_subnet_name
  virtual_network_name = var.existing_vnet_name
  resource_group_name  = local.existing_vnet_rg
}

output "vnet_id" {
  value = var.deploy_vnet ? azurerm_virtual_network.this[0].id : data.azurerm_virtual_network.existing[0].id
}

output "vnet_name" {
  value = var.deploy_vnet ? azurerm_virtual_network.this[0].name : var.existing_vnet_name
}

output "web_tier_subnet_id" {
  value = var.deploy_vnet ? azurerm_subnet.web[0].id : data.azurerm_subnet.existing_web[0].id
}

output "enterprise_tier_subnet_id" {
  value = var.deploy_vnet ? azurerm_subnet.enterprise[0].id : data.azurerm_subnet.existing_enterprise[0].id
}

output "resource_tier_subnet_id" {
  value = var.deploy_vnet ? azurerm_subnet.resource[0].id : data.azurerm_subnet.existing_resource[0].id
}
