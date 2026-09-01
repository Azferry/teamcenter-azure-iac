variable "name_base" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "tags" { type = map(string) }
variable "subnet_id" { type = string }
variable "standby" { type = any }
variable "observer" { type = any }
variable "image" { type = any }
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

module "standby_role" {
  count                        = try(var.standby.enabled, false) && try(var.standby.count, 0) > 0 ? 1 : 0
  source                       = "../oracle-vm"
  name_base                    = var.name_base
  resource_group_name          = var.resource_group_name
  role_code                    = "oras"
  location                     = var.location
  tags                         = var.tags
  subnet_id                    = var.subnet_id
  vm_count                     = try(var.standby.count, 0)
  vm_size                      = try(var.standby.vm_size, try(var.standby.vmSize, "Standard_E32-16ds_v4"))
  image                        = var.image
  admin_username               = var.admin_username
  admin_password               = var.admin_password
  os_disk_size_gb              = try(var.standby.os_disk_size_gb, try(var.standby.osDiskSizeGb, 128))
  data_disks                   = try(var.standby.data_disks, try(var.standby.dataDisks, []))
  availability_zones           = try(var.standby.availability_zones, try(var.standby.availabilityZones, []))
  proximity_placement_group_id = try(var.standby.proximity_placement_group_id, try(var.standby.proximityPlacementGroupId, ""))
  disk_encryption_set_id       = var.disk_encryption_set_id
  managed_identity_id          = var.managed_identity_id
  boot_diagnostics_storage_uri = var.boot_diagnostics_storage_uri
}

module "observer_role" {
  count                       = try(var.observer.enabled, false) && try(var.observer.count, 0) > 0 ? 1 : 0
  source                      = "../../compute/vm-role"
  name_base                   = var.name_base
  resource_group_name         = var.resource_group_name
  role_code                   = "orao"
  location                    = var.location
  tags                        = var.tags
  subnet_id                   = var.subnet_id
  admin_username              = var.admin_username
  admin_password              = var.admin_password
  disk_encryption_set_id      = var.disk_encryption_set_id
  managed_identity_id         = var.managed_identity_id
  boot_diagnostics_storage_uri = var.boot_diagnostics_storage_uri
  proximity_placement_group_id = try(var.observer.proximity_placement_group_id, try(var.observer.proximityPlacementGroupId, ""))
  role = {
    enabled            = try(var.observer.enabled, false)
    count              = try(var.observer.count, 0)
    vm_size            = try(var.observer.vm_size, try(var.observer.vmSize, "Standard_D2s_v5"))
    os_type            = "Linux"
    image              = var.image
    os_disk_size_gb    = try(var.observer.os_disk_size_gb, try(var.observer.osDiskSizeGb, 64))
    data_disks         = try(var.observer.data_disks, try(var.observer.dataDisks, []))
    availability_zones = try(var.observer.availability_zones, try(var.observer.availabilityZones, []))
  }
}

output "standby_vm_names" {
  value = length(module.standby_role) > 0 ? module.standby_role[0].vm_names : []
}

output "observer_vm_names" {
  value = length(module.observer_role) > 0 ? module.observer_role[0].vm_names : []
}
