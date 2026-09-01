variable "name_base" { type = string }
variable "resource_group_name" { type = string }
variable "role_code" { type = string }
variable "location" { type = string }
variable "tags" { type = map(string) }
variable "subnet_id" { type = string }
variable "vm_count" {
  type    = number
  default = 1
}
variable "vm_size" {
  type    = string
  default = "Standard_E32-16ds_v4"
}
variable "image" {
  type = any
}
variable "admin_username" {
  type    = string
  default = "oracleadmin"
}
variable "admin_password" {
  type      = string
  sensitive = true
}
variable "os_disk_size_gb" {
  type    = number
  default = 128
}
variable "data_disks" {
  type    = list(any)
  default = []
}
variable "availability_zones" {
  type    = list(any)
  default = []
}
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

module "oracle_role" {
  source                       = "../../compute/vm-role"
  name_base                    = var.name_base
  resource_group_name          = var.resource_group_name
  role_code                    = var.role_code
  location                     = var.location
  tags                         = var.tags
  subnet_id                    = var.subnet_id
  admin_username               = var.admin_username
  admin_password               = var.admin_password
  proximity_placement_group_id = var.proximity_placement_group_id
  disk_encryption_set_id       = var.disk_encryption_set_id
  managed_identity_id          = var.managed_identity_id
  boot_diagnostics_storage_uri = var.boot_diagnostics_storage_uri

  role = {
    enabled            = var.vm_count > 0
    count              = var.vm_count
    vm_size            = var.vm_size
    os_type            = "Linux"
    image              = var.image
    os_disk_size_gb    = var.os_disk_size_gb
    data_disks         = var.data_disks
    availability_zones = var.availability_zones
  }
}

output "vm_names" { value = module.oracle_role.vm_names }
output "vm_ids" { value = module.oracle_role.vm_ids }
