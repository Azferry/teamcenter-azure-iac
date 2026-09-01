variable "org" {
  type        = string
  description = "3-char organization code."
}

variable "label" {
  type        = string
  description = "3-4 char workload label."
}

variable "env" {
  type        = string
  description = "Environment code."
}

variable "location" {
  type        = string
  description = "Azure region."
}

locals {
  region_code_map = {
    usgovvirginia = "usgv"
    usgovarizona  = "usga"
    usgovtexas    = "usgt"
    eastus        = "eus"
    eastus2       = "eus2"
    westus        = "wus"
    centralus     = "cus"
  }

  region_code = lookup(local.region_code_map, lower(var.location), "usgv")
  base        = lower("${var.org}-${var.label}-${var.env}-${local.region_code}")
  base_compact = lower(
    "${var.org}${var.label}${var.env}${local.region_code}"
  )
}

output "region_code" {
  value = local.region_code
}

output "base" {
  value = local.base
}

output "base_compact" {
  value = local.base_compact
}
