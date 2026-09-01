variable "name_base" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "tags" { type = map(string) }
variable "web_subnet_id" { type = string }
variable "enterprise_subnet_id" { type = string }
variable "admin_username" {
  type    = string
  default = "tcadmin"
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
variable "fms_share_unc_path" {
  type    = string
  default = ""
}
variable "web_server" { type = any }
variable "tcss" { type = any }
variable "enterprise" { type = any }
variable "pool_manager" { type = any }
variable "awc_portal" { type = any }
variable "fms_volume_server" { type = any }
variable "fsc_cache" { type = any }
variable "solr" { type = any }
variable "dispatcher" { type = any }
variable "visualization" { type = any }
variable "license_server" { type = any }

locals {
  deploy_web_ent_ppg = (
    try(var.web_server.enabled, false) ||
    try(var.tcss.enabled, false) ||
    try(var.enterprise.enabled, false)
  )
  ppg_name = "${var.name_base}-ppg1-web-ent"
}

module "web_ent_ppg" {
  count               = local.deploy_web_ent_ppg ? 1 : 0
  source              = "./ppg"
  name                = local.ppg_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

locals {
  ppg_id = local.deploy_web_ent_ppg ? module.web_ent_ppg[0].id : ""
}

module "web_role" {
  count                         = try(var.web_server.enabled, false) && try(var.web_server.count, 0) > 0 ? 1 : 0
  source                        = "./vm-role"
  name_base                     = var.name_base
  resource_group_name           = var.resource_group_name
  role_code                     = "web"
  location                      = var.location
  tags                          = var.tags
  subnet_id                     = var.web_subnet_id
  role                          = var.web_server
  admin_username                = var.admin_username
  admin_password                = var.admin_password
  proximity_placement_group_id  = local.ppg_id
  disk_encryption_set_id        = var.disk_encryption_set_id
  managed_identity_id           = var.managed_identity_id
  boot_diagnostics_storage_uri  = var.boot_diagnostics_storage_uri
}

module "tcss_role" {
  count                         = try(var.tcss.enabled, false) && try(var.tcss.count, 0) > 0 ? 1 : 0
  source                        = "./vm-role"
  name_base                     = var.name_base
  resource_group_name           = var.resource_group_name
  role_code                     = "tcss"
  location                      = var.location
  tags                          = var.tags
  subnet_id                     = var.web_subnet_id
  role                          = var.tcss
  admin_username                = var.admin_username
  admin_password                = var.admin_password
  proximity_placement_group_id  = local.ppg_id
  disk_encryption_set_id        = var.disk_encryption_set_id
  managed_identity_id           = var.managed_identity_id
  boot_diagnostics_storage_uri  = var.boot_diagnostics_storage_uri
}

module "ent_role" {
  count                         = try(var.enterprise.enabled, false) && try(var.enterprise.count, 0) > 0 ? 1 : 0
  source                        = "./vm-role"
  name_base                     = var.name_base
  resource_group_name           = var.resource_group_name
  role_code                     = "ent"
  location                      = var.location
  tags                          = var.tags
  subnet_id                     = var.enterprise_subnet_id
  role                          = var.enterprise
  admin_username                = var.admin_username
  admin_password                = var.admin_password
  proximity_placement_group_id  = local.ppg_id
  disk_encryption_set_id        = var.disk_encryption_set_id
  managed_identity_id           = var.managed_identity_id
  boot_diagnostics_storage_uri  = var.boot_diagnostics_storage_uri
}

module "pool_role" {
  count                         = try(var.pool_manager.enabled, false) && try(var.pool_manager.count, 0) > 0 ? 1 : 0
  source                        = "./vm-role"
  name_base                     = var.name_base
  resource_group_name           = var.resource_group_name
  role_code                     = "pool"
  location                      = var.location
  tags                          = var.tags
  subnet_id                     = var.enterprise_subnet_id
  role                          = var.pool_manager
  admin_username                = var.admin_username
  admin_password                = var.admin_password
  proximity_placement_group_id  = local.ppg_id
  disk_encryption_set_id        = var.disk_encryption_set_id
  managed_identity_id           = var.managed_identity_id
  boot_diagnostics_storage_uri  = var.boot_diagnostics_storage_uri
}

module "awc_role" {
  count                         = try(var.awc_portal.enabled, false) && try(var.awc_portal.count, 0) > 0 ? 1 : 0
  source                        = "./vm-role"
  name_base                     = var.name_base
  resource_group_name           = var.resource_group_name
  role_code                     = "awc"
  location                      = var.location
  tags                          = var.tags
  subnet_id                     = var.enterprise_subnet_id
  role                          = var.awc_portal
  admin_username                = var.admin_username
  admin_password                = var.admin_password
  proximity_placement_group_id  = local.ppg_id
  disk_encryption_set_id        = var.disk_encryption_set_id
  managed_identity_id           = var.managed_identity_id
  boot_diagnostics_storage_uri  = var.boot_diagnostics_storage_uri
}

module "fms_role" {
  count                         = try(var.fms_volume_server.enabled, false) && try(var.fms_volume_server.count, 0) > 0 ? 1 : 0
  source                        = "./vm-role"
  name_base                     = var.name_base
  resource_group_name           = var.resource_group_name
  role_code                     = "fms"
  location                      = var.location
  tags                          = var.tags
  subnet_id                     = var.enterprise_subnet_id
  role                          = var.fms_volume_server
  admin_username                = var.admin_username
  admin_password                = var.admin_password
  proximity_placement_group_id  = local.ppg_id
  disk_encryption_set_id        = var.disk_encryption_set_id
  managed_identity_id           = var.managed_identity_id
  boot_diagnostics_storage_uri  = var.boot_diagnostics_storage_uri
}

module "fsc_role" {
  count                         = try(var.fsc_cache.enabled, false) && try(var.fsc_cache.count, 0) > 0 ? 1 : 0
  source                        = "./vm-role"
  name_base                     = var.name_base
  resource_group_name           = var.resource_group_name
  role_code                     = "fsc"
  location                      = var.location
  tags                          = var.tags
  subnet_id                     = var.enterprise_subnet_id
  role                          = var.fsc_cache
  admin_username                = var.admin_username
  admin_password                = var.admin_password
  proximity_placement_group_id  = local.ppg_id
  disk_encryption_set_id        = var.disk_encryption_set_id
  managed_identity_id           = var.managed_identity_id
  boot_diagnostics_storage_uri  = var.boot_diagnostics_storage_uri
}

module "solr_role" {
  count                         = try(var.solr.enabled, false) && try(var.solr.count, 0) > 0 ? 1 : 0
  source                        = "./vm-role"
  name_base                     = var.name_base
  resource_group_name           = var.resource_group_name
  role_code                     = "solr"
  location                      = var.location
  tags                          = var.tags
  subnet_id                     = var.enterprise_subnet_id
  role                          = var.solr
  admin_username                = var.admin_username
  admin_password                = var.admin_password
  proximity_placement_group_id  = local.ppg_id
  disk_encryption_set_id        = var.disk_encryption_set_id
  managed_identity_id           = var.managed_identity_id
  boot_diagnostics_storage_uri  = var.boot_diagnostics_storage_uri
}

module "disp_role" {
  count                         = try(var.dispatcher.enabled, false) && try(var.dispatcher.count, 0) > 0 ? 1 : 0
  source                        = "./vm-role"
  name_base                     = var.name_base
  resource_group_name           = var.resource_group_name
  role_code                     = "disp"
  location                      = var.location
  tags                          = var.tags
  subnet_id                     = var.enterprise_subnet_id
  role                          = var.dispatcher
  admin_username                = var.admin_username
  admin_password                = var.admin_password
  proximity_placement_group_id  = local.ppg_id
  disk_encryption_set_id        = var.disk_encryption_set_id
  managed_identity_id           = var.managed_identity_id
  boot_diagnostics_storage_uri  = var.boot_diagnostics_storage_uri
}

module "vis_role" {
  count                         = try(var.visualization.enabled, false) && try(var.visualization.count, 0) > 0 ? 1 : 0
  source                        = "./vm-role"
  name_base                     = var.name_base
  resource_group_name           = var.resource_group_name
  role_code                     = "vis"
  location                      = var.location
  tags                          = var.tags
  subnet_id                     = var.enterprise_subnet_id
  role                          = var.visualization
  admin_username                = var.admin_username
  admin_password                = var.admin_password
  proximity_placement_group_id  = local.ppg_id
  disk_encryption_set_id        = var.disk_encryption_set_id
  managed_identity_id           = var.managed_identity_id
  boot_diagnostics_storage_uri  = var.boot_diagnostics_storage_uri
}

module "lic_role" {
  count                         = try(var.license_server.enabled, false) && try(var.license_server.count, 0) > 0 ? 1 : 0
  source                        = "./vm-role"
  name_base                     = var.name_base
  resource_group_name           = var.resource_group_name
  role_code                     = "lic"
  location                      = var.location
  tags                          = var.tags
  subnet_id                     = var.enterprise_subnet_id
  role                          = var.license_server
  admin_username                = var.admin_username
  admin_password                = var.admin_password
  proximity_placement_group_id  = local.ppg_id
  disk_encryption_set_id        = var.disk_encryption_set_id
  managed_identity_id           = var.managed_identity_id
  boot_diagnostics_storage_uri  = var.boot_diagnostics_storage_uri
}

output "proximity_placement_group_id" {
  value = local.ppg_id
}

output "fms_share_unc_path_out" {
  value = var.fms_share_unc_path
}
