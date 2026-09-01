variable "org" {
  type        = string
  description = "3-char organization code."
  default     = "ntc"
}

variable "label" {
  type        = string
  description = "3-4 char workload label."
  default     = "plm"
}

variable "environment_name" {
  type        = string
  description = "Environment name."
}

variable "location" {
  type        = string
  description = "Azure Government region."
  default     = "usgovvirginia"
}

variable "tags" {
  type        = map(string)
  description = "Additional tags."
  default     = {}
}

variable "deploy_vnet" {
  type    = bool
  default = true
}

variable "existing_vnet_name" {
  type    = string
  default = ""
}

variable "existing_vnet_resource_group" {
  type    = string
  default = ""
}

variable "existing_web_tier_subnet_name" {
  type    = string
  default = "web-tier-sn"
}

variable "existing_enterprise_tier_subnet_name" {
  type    = string
  default = "enterprise-tier-sn"
}

variable "existing_resource_tier_subnet_name" {
  type    = string
  default = "resource-tier-sn"
}

variable "key_vault_purge_protection" {
  type    = bool
  default = false
}

variable "recovery_vault_purge_protection" {
  type    = bool
  default = false
}

variable "deploy_private_dns" {
  type    = bool
  default = false
}

variable "key_vault_private_dns_zone_id" {
  type    = string
  default = ""
}

variable "recovery_vault_private_dns_zone_id" {
  type    = string
  default = ""
}

variable "files_private_dns_zone_id" {
  type    = string
  default = ""
}

variable "compute_admin_username" {
  type    = string
  default = "tcadmin"
}

variable "compute_admin_password" {
  type      = string
  sensitive = true
}

variable "oracle_admin_username" {
  type    = string
  default = "oracleadmin"
}

variable "oracle_admin_password" {
  type      = string
  sensitive = true
}

variable "fms_share_name" {
  type    = string
  default = "teamcenter-fms"
}

variable "fms_share_quota_gib" {
  type    = number
  default = 1024
}

variable "web_server" {
  type = any
  default = {
    enabled = true
    count   = 2
    vmSize  = "Standard_D8ds_v5"
    osType  = "Windows"
    image = {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2022-datacenter-azure-edition"
      version   = "latest"
    }
    osDiskSizeGb      = 128
    dataDisks         = []
    availabilityZones = [1, 2]
  }
}

variable "tcss" {
  type = any
  default = {
    enabled = true
    count   = 1
    vmSize  = "Standard_D4ds_v5"
    osType  = "Windows"
    image = {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2022-datacenter-azure-edition"
      version   = "latest"
    }
    osDiskSizeGb      = 128
    dataDisks         = []
    availabilityZones = [1, 2]
  }
}

variable "enterprise" {
  type = any
  default = {
    enabled = true
    count   = 1
    vmSize  = "Standard_F16s_v2"
    osType  = "Windows"
    image = {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2022-datacenter-azure-edition"
      version   = "latest"
    }
    osDiskSizeGb      = 128
    dataDisks         = []
    availabilityZones = []
  }
}

variable "pool_manager" {
  type = any
  default = {
    enabled = true
    count   = 1
    vmSize  = "Standard_D4_v4"
    osType  = "Windows"
    image = {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2022-datacenter-azure-edition"
      version   = "latest"
    }
    osDiskSizeGb      = 128
    dataDisks         = []
    availabilityZones = [1, 2]
  }
}

variable "awc_portal" {
  type = any
  default = {
    enabled = true
    count   = 1
    vmSize  = "Standard_D8ds_v5"
    osType  = "Windows"
    image = {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2022-datacenter-azure-edition"
      version   = "latest"
    }
    osDiskSizeGb      = 128
    dataDisks         = []
    availabilityZones = []
  }
}

variable "fms_volume_server" {
  type = any
  default = {
    enabled = true
    count   = 1
    vmSize  = "Standard_F16s_v2"
    osType  = "Windows"
    image = {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2022-datacenter-azure-edition"
      version   = "latest"
    }
    osDiskSizeGb      = 128
    dataDisks         = []
    availabilityZones = []
  }
}

variable "fsc_cache" {
  type = any
  default = {
    enabled = true
    count   = 1
    vmSize  = "Standard_D8ds_v5"
    osType  = "Windows"
    image = {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2022-datacenter-azure-edition"
      version   = "latest"
    }
    osDiskSizeGb      = 128
    dataDisks         = []
    availabilityZones = []
  }
}

variable "solr" {
  type = any
  default = {
    enabled = true
    count   = 1
    vmSize  = "Standard_D8ds_v5"
    osType  = "Windows"
    image = {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2022-datacenter-azure-edition"
      version   = "latest"
    }
    osDiskSizeGb      = 128
    dataDisks         = []
    availabilityZones = []
  }
}

variable "dispatcher" {
  type = any
  default = {
    enabled = false
    count   = 0
    vmSize  = "Standard_F16s_v2"
    osType  = "Windows"
    image = {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2022-datacenter-azure-edition"
      version   = "latest"
    }
    osDiskSizeGb      = 128
    dataDisks         = []
    availabilityZones = []
  }
}

variable "visualization" {
  type = any
  default = {
    enabled = false
    count   = 0
    vmSize  = "Standard_NV36ads_A10_v5"
    osType  = "Windows"
    image = {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2022-datacenter-azure-edition"
      version   = "latest"
    }
    osDiskSizeGb      = 128
    dataDisks         = []
    availabilityZones = []
  }
}

variable "license_server" {
  type = any
  default = {
    enabled = true
    count   = 1
    vmSize  = "Standard_D2s_v5"
    osType  = "Windows"
    image = {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2022-datacenter-azure-edition"
      version   = "latest"
    }
    osDiskSizeGb      = 128
    dataDisks         = []
    availabilityZones = [1, 2]
  }
}

variable "oracle_primary" {
  type = any
  default = {
    enabled           = true
    count             = 1
    vmSize            = "Standard_E32-16ds_v4"
    osDiskSizeGb      = 128
    availabilityZones = []
    dataDisks = [
      { lun = 0, sizeGb = 1024, sku = "PremiumV2_LRS" },
      { lun = 1, sizeGb = 1024, sku = "PremiumV2_LRS" },
      { lun = 2, sizeGb = 1024, sku = "PremiumV2_LRS" },
      { lun = 3, sizeGb = 1024, sku = "PremiumV2_LRS" },
      { lun = 4, sizeGb = 512, sku = "PremiumV2_LRS" },
      { lun = 5, sizeGb = 512, sku = "PremiumV2_LRS" },
      { lun = 6, sizeGb = 128, sku = "PremiumV2_LRS" },
      { lun = 7, sizeGb = 128, sku = "PremiumV2_LRS" }
    ]
  }
}

variable "oracle_standby" {
  type = any
  default = {
    enabled           = false
    count             = 0
    vmSize            = "Standard_E32-16ds_v4"
    osDiskSizeGb      = 128
    availabilityZones = []
    dataDisks         = []
  }
}

variable "oracle_observer" {
  type = any
  default = {
    enabled           = false
    count             = 0
    vmSize            = "Standard_D2s_v5"
    osDiskSizeGb      = 64
    availabilityZones = []
    dataDisks         = []
  }
}

variable "oracle_image" {
  type = any
  default = {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "8-lvm-gen2"
    version   = "latest"
  }
}
