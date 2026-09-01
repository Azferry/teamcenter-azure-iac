output "resource_group_name_out" {
  value = azurerm_resource_group.this.name
}

output "vnet_id" {
  value = module.network.vnet_id
}

output "managed_identity_id" {
  value = module.identity.managed_identity_id
}

output "key_vault_id" {
  value = module.keyvault.key_vault_id
}

output "disk_encryption_set_id" {
  value = module.encryption_set.disk_encryption_set_id
}

output "recovery_services_vault_id" {
  value = module.backup.recovery_services_vault_id
}

output "fms_files_share_unc" {
  value = module.fileshare.unc_path
}
