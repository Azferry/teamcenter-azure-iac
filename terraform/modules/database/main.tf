variable "name_base" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "tags" { type = map(string) }
variable "subnet_id" { type = string }
variable "admin_username" {
  type    = string
  default = "oracleadmin"
}
variable "admin_password" {
  type      = string
  sensitive = true
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
variable "oracle_primary" { type = any }
variable "oracle_standby" { type = any }
variable "oracle_observer" { type = any }
variable "oracle_image" { type = any }

module "oracle_primary_role" {
  count                        = try(var.oracle_primary.enabled, false) && try(var.oracle_primary.count, 0) > 0 ? 1 : 0
  source                       = "./oracle-vm"
  name_base                    = var.name_base
  resource_group_name          = var.resource_group_name
  role_code                    = "orap"
  location                     = var.location
  tags                         = var.tags
  subnet_id                    = var.subnet_id
  vm_count                     = try(var.oracle_primary.count, 0)
  vm_size                      = try(var.oracle_primary.vm_size, try(var.oracle_primary.vmSize, "Standard_E32-16ds_v4"))
  image                        = var.oracle_image
  admin_username               = var.admin_username
  admin_password               = var.admin_password
  os_disk_size_gb              = try(var.oracle_primary.os_disk_size_gb, try(var.oracle_primary.osDiskSizeGb, 128))
  data_disks                   = try(var.oracle_primary.data_disks, try(var.oracle_primary.dataDisks, []))
  availability_zones           = try(var.oracle_primary.availability_zones, try(var.oracle_primary.availabilityZones, []))
  proximity_placement_group_id = try(var.oracle_primary.proximity_placement_group_id, try(var.oracle_primary.proximityPlacementGroupId, ""))
  disk_encryption_set_id       = var.disk_encryption_set_id
  managed_identity_id          = var.managed_identity_id
  boot_diagnostics_storage_uri = var.boot_diagnostics_storage_uri
}

module "oracle_dataguard" {
  count                        = (try(var.oracle_standby.enabled, false) && try(var.oracle_standby.count, 0) > 0) || (try(var.oracle_observer.enabled, false) && try(var.oracle_observer.count, 0) > 0) ? 1 : 0
  source                       = "./oracle-dataguard"
  name_base                    = var.name_base
  resource_group_name          = var.resource_group_name
  location                     = var.location
  tags                         = var.tags
  subnet_id                    = var.subnet_id
  standby                      = var.oracle_standby
  observer                     = var.oracle_observer
  image                        = var.oracle_image
  admin_username               = var.admin_username
  admin_password               = var.admin_password
  disk_encryption_set_id       = var.disk_encryption_set_id
  managed_identity_id          = var.managed_identity_id
  boot_diagnostics_storage_uri = var.boot_diagnostics_storage_uri
}

output "primary_vm_names" {
  value = length(module.oracle_primary_role) > 0 ? module.oracle_primary_role[0].vm_names : []
}

output "standby_vm_names" {
  value = length(module.oracle_dataguard) > 0 ? module.oracle_dataguard[0].standby_vm_names : []
}

output "observer_vm_names" {
  value = length(module.oracle_dataguard) > 0 ? module.oracle_dataguard[0].observer_vm_names : []
}
