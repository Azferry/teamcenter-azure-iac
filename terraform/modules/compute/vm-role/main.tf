variable "name_base" { type = string }
variable "resource_group_name" { type = string }
variable "role_code" { type = string }
variable "location" { type = string }
variable "tags" { type = map(string) }
variable "subnet_id" { type = string }
variable "admin_username" { type = string }
variable "admin_password" {
  type      = string
  sensitive = true
}
variable "role" { type = any }
variable "proximity_placement_group_id" {
  type    = string
  default = ""
}
variable "disk_encryption_set_id" {
  type    = string
  default = ""
}
variable "managed_identity_id" {
  type    = string
  default = ""
}
variable "boot_diagnostics_storage_uri" {
  type    = string
  default = ""
}

locals {
  vm_keys = (
    try(var.role.enabled, false) && try(var.role.count, 0) > 0
  ) ? {
    for i in range(try(var.role.count, 0)) : format("%s-%02d", var.role_code, i + 1) => i + 1
  } : {}

  normalized_os_type = lower(try(var.role.os_type, try(var.role.osType, "Windows"))) == "linux" ? "Linux" : "Windows"
  vm_size            = try(var.role.vm_size, try(var.role.vmSize, "Standard_D2s_v5"))
  os_disk_size_gb    = try(var.role.os_disk_size_gb, try(var.role.osDiskSizeGb, 128))
  data_disks         = try(var.role.data_disks, try(var.role.dataDisks, []))
  availability_zones = try(var.role.availability_zones, try(var.role.availabilityZones, []))

  disk_matrix_list = [
    for vm_key, vm_idx in local.vm_keys : {
      for disk_index, disk in local.data_disks : "${vm_key}-lun${try(disk.lun, disk_index)}" => {
        vm_key  = vm_key
        vm_idx  = vm_idx
        lun     = try(disk.lun, disk_index)
        size_gb = try(disk.size_gb, try(disk.sizeGb, 128))
        sku     = try(disk.sku, "Premium_LRS")
      }
    }
  ]

  disk_matrix = length(local.disk_matrix_list) > 0 ? merge(local.disk_matrix_list...) : {}
}

resource "azurerm_network_interface" "this" {
  for_each            = local.vm_keys
  name                = "${var.name_base}-nic-${var.role_code}${format("%02d", each.value)}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "this" {
  for_each            = local.normalized_os_type == "Windows" ? local.vm_keys : {}
  name                = "${var.name_base}-vm-${var.role_code}${format("%02d", each.value)}"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = local.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  network_interface_ids = [
    azurerm_network_interface.this[each.key].id
  ]
  provision_vm_agent         = true
  enable_automatic_updates   = true
  patch_mode                 = "AutomaticByOS"
  computer_name              = substr("${var.role_code}${format("%02d", each.value)}", 0, 15)
  zone                       = length(local.availability_zones) > 0 ? tostring(local.availability_zones[(each.value - 1) % length(local.availability_zones)]) : null
  proximity_placement_group_id = var.proximity_placement_group_id != "" ? var.proximity_placement_group_id : null
  tags                       = var.tags

  dynamic "identity" {
    for_each = var.managed_identity_id != "" ? [1] : []
    content {
      type         = "UserAssigned"
      identity_ids = [var.managed_identity_id]
    }
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = local.os_disk_size_gb
    disk_encryption_set_id = var.disk_encryption_set_id != "" ? var.disk_encryption_set_id : null
  }

  source_image_reference {
    publisher = try(var.role.image.publisher, "MicrosoftWindowsServer")
    offer     = try(var.role.image.offer, "WindowsServer")
    sku       = try(var.role.image.sku, "2022-datacenter-azure-edition")
    version   = try(var.role.image.version, "latest")
  }

  dynamic "boot_diagnostics" {
    for_each = var.boot_diagnostics_storage_uri != "" ? [1] : []
    content {
      storage_account_uri = var.boot_diagnostics_storage_uri
    }
  }
}

resource "azurerm_linux_virtual_machine" "this" {
  for_each            = local.normalized_os_type == "Linux" ? local.vm_keys : {}
  name                = "${var.name_base}-vm-${var.role_code}${format("%02d", each.value)}"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = local.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.this[each.key].id
  ]
  computer_name              = substr("${var.role_code}${format("%02d", each.value)}", 0, 15)
  zone                       = length(local.availability_zones) > 0 ? tostring(local.availability_zones[(each.value - 1) % length(local.availability_zones)]) : null
  proximity_placement_group_id = var.proximity_placement_group_id != "" ? var.proximity_placement_group_id : null
  tags                       = var.tags

  dynamic "identity" {
    for_each = var.managed_identity_id != "" ? [1] : []
    content {
      type         = "UserAssigned"
      identity_ids = [var.managed_identity_id]
    }
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = local.os_disk_size_gb
    disk_encryption_set_id = var.disk_encryption_set_id != "" ? var.disk_encryption_set_id : null
  }

  source_image_reference {
    publisher = try(var.role.image.publisher, "RedHat")
    offer     = try(var.role.image.offer, "RHEL")
    sku       = try(var.role.image.sku, "8-lvm-gen2")
    version   = try(var.role.image.version, "latest")
  }

  dynamic "boot_diagnostics" {
    for_each = var.boot_diagnostics_storage_uri != "" ? [1] : []
    content {
      storage_account_uri = var.boot_diagnostics_storage_uri
    }
  }
}

resource "azurerm_managed_disk" "data" {
  for_each             = local.disk_matrix
  name                 = "${var.name_base}-disk-${each.value.vm_key}-${format("%02d", each.value.lun)}"
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = each.value.sku
  create_option        = "Empty"
  disk_size_gb         = each.value.size_gb
  zone                 = length(local.availability_zones) > 0 ? tostring(local.availability_zones[(each.value.vm_idx - 1) % length(local.availability_zones)]) : null
  disk_encryption_set_id = var.disk_encryption_set_id != "" ? var.disk_encryption_set_id : null
  tags                 = var.tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "this" {
  for_each = local.disk_matrix

  managed_disk_id    = azurerm_managed_disk.data[each.key].id
  virtual_machine_id = local.normalized_os_type == "Windows" ? azurerm_windows_virtual_machine.this[each.value.vm_key].id : azurerm_linux_virtual_machine.this[each.value.vm_key].id
  lun                = each.value.lun
  caching            = "ReadWrite"
}

output "vm_ids" {
  value = local.normalized_os_type == "Windows" ? values(azurerm_windows_virtual_machine.this)[*].id : values(azurerm_linux_virtual_machine.this)[*].id
}

output "vm_names" {
  value = local.normalized_os_type == "Windows" ? values(azurerm_windows_virtual_machine.this)[*].name : values(azurerm_linux_virtual_machine.this)[*].name
}

output "nic_ids" {
  value = values(azurerm_network_interface.this)[*].id
}
