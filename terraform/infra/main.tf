resource "azurerm_resource_group" "this" {
  name     = "${local.name_base}-rg1"
  location = var.location
  tags     = local.all_tags
}

module "network" {
  source                               = "../modules/network"
  name_base                            = local.name_base
  resource_group_name                  = azurerm_resource_group.this.name
  location                             = var.location
  tags                                 = local.all_tags
  deploy_vnet                          = var.deploy_vnet
  existing_vnet_name                   = var.existing_vnet_name
  existing_vnet_resource_group         = var.existing_vnet_resource_group
  existing_web_tier_subnet_name        = var.existing_web_tier_subnet_name
  existing_enterprise_tier_subnet_name = var.existing_enterprise_tier_subnet_name
  existing_resource_tier_subnet_name   = var.existing_resource_tier_subnet_name
}

module "identity" {
  source              = "../modules/identity"
  name_base           = local.name_base
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  tags                = local.all_tags
}

module "keyvault" {
  source                  = "../modules/keyvault"
  name_base_compact       = local.name_base_compact
  resource_group_name     = azurerm_resource_group.this.name
  location                = var.location
  tags                    = local.all_tags
  tenant_id               = data.azurerm_client_config.current.tenant_id
  subnet_id               = module.network.resource_tier_subnet_id
  enable_purge_protection = var.key_vault_purge_protection
  deploy_private_dns      = var.deploy_private_dns
  private_dns_zone_id     = var.key_vault_private_dns_zone_id
}

module "storage_encryption" {
  source       = "../modules/storage-encryption"
  key_vault_id = module.keyvault.key_vault_id
  principal_id = module.identity.principal_id
}

module "encryption_set" {
  source              = "../modules/encryption-set"
  name_base           = local.name_base
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  tags                = local.all_tags
  key_vault_id        = module.keyvault.key_vault_id
  key_url             = module.keyvault.des_key_uri_with_version
}

module "storage" {
  source                    = "../modules/storage"
  name_base_compact         = local.name_base_compact
  resource_group_name       = azurerm_resource_group.this.name
  location                  = var.location
  tags                      = local.all_tags
  user_assigned_identity_id = module.identity.managed_identity_id
  key_vault_key_id          = module.keyvault.storage_key_uri

  depends_on = [module.storage_encryption]
}

module "fileshare" {
  source              = "../modules/fileshare"
  name_base_compact   = local.name_base_compact
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  tags                = local.all_tags
  subnet_id           = module.network.resource_tier_subnet_id
  share_name          = var.fms_share_name
  share_quota_gib     = var.fms_share_quota_gib
  deploy_private_dns  = var.deploy_private_dns
  private_dns_zone_id = var.files_private_dns_zone_id
}

locals {
  boot_diagnostics_storage_uri = "https://${module.storage.storage_account_name}.blob.core.usgovcloudapi.net/"
}

module "database" {
  source                       = "../modules/database"
  name_base                    = local.name_base
  resource_group_name          = azurerm_resource_group.this.name
  location                     = var.location
  tags                         = local.all_tags
  subnet_id                    = module.network.resource_tier_subnet_id
  admin_username               = var.oracle_admin_username
  admin_password               = var.oracle_admin_password
  disk_encryption_set_id       = module.encryption_set.disk_encryption_set_id
  managed_identity_id          = module.identity.managed_identity_id
  boot_diagnostics_storage_uri = local.boot_diagnostics_storage_uri
  oracle_primary               = var.oracle_primary
  oracle_standby               = var.oracle_standby
  oracle_observer              = var.oracle_observer
  oracle_image                 = var.oracle_image
}

module "compute" {
  source                       = "../modules/compute"
  name_base                    = local.name_base
  resource_group_name          = azurerm_resource_group.this.name
  location                     = var.location
  tags                         = local.all_tags
  web_subnet_id                = module.network.web_tier_subnet_id
  enterprise_subnet_id         = module.network.enterprise_tier_subnet_id
  admin_username               = var.compute_admin_username
  admin_password               = var.compute_admin_password
  disk_encryption_set_id       = module.encryption_set.disk_encryption_set_id
  managed_identity_id          = module.identity.managed_identity_id
  boot_diagnostics_storage_uri = local.boot_diagnostics_storage_uri
  fms_share_unc_path           = module.fileshare.unc_path
  web_server                   = var.web_server
  tcss                         = var.tcss
  enterprise                   = var.enterprise
  pool_manager                 = var.pool_manager
  awc_portal                   = var.awc_portal
  fms_volume_server            = var.fms_volume_server
  fsc_cache                    = var.fsc_cache
  solr                         = var.solr
  dispatcher                   = var.dispatcher
  visualization                = var.visualization
  license_server               = var.license_server
}

module "backup" {
  source                  = "../modules/recovery-services-vault"
  name_base               = local.name_base
  resource_group_name     = azurerm_resource_group.this.name
  location                = var.location
  tags                    = local.all_tags
  subnet_id               = module.network.resource_tier_subnet_id
  enable_purge_protection = var.recovery_vault_purge_protection
  deploy_private_dns      = var.deploy_private_dns
  private_dns_zone_id     = var.recovery_vault_private_dns_zone_id
}
