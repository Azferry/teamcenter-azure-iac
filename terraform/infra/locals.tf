module "naming" {
  source = "../modules/naming"

  org      = var.org
  label    = var.label
  env      = var.environment_name
  location = var.location
}

locals {
  name_base         = module.naming.base
  name_base_compact = module.naming.base_compact

  default_tags = {
    application = "Teamcenter"
    environment = var.environment_name
    managedBy   = "terraform"
  }

  all_tags = merge(local.default_tags, var.tags)
}
