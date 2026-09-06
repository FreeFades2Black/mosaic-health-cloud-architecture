# --------------------------------------------------------------------------------------------------
# GUNSLINGER DISPATCH: AZURE KEY VAULT VARIABLES DECLARATION
# "Every parameter measured, every boundary enforced with precision."
# --------------------------------------------------------------------------------------------------
# File: terraform/gunslinger-secure-vault/variables.tf
# Purpose: Type-safe, validated input variables for production Key Vault deployment.
# --------------------------------------------------------------------------------------------------

# Prefix for Key Vault resource naming
variable "vault_prefix" {
  type        = string                          # String type for resource name prefix
  description = "Prefix for Azure Key Vault resource name (e.g. kv-mosaic)" # Explanation of variable purpose
  default     = "kv-mosaic"                     # Default prefix value

  # Validation ensuring prefix conforms to naming guidelines
  validation {
    condition     = length(var.vault_prefix) <= 12 && can(regex("^[a-z0-9-]+$", var.vault_prefix))
    error_message = "Vault prefix must be 12 characters or less, lowercase alphanumeric and hyphens only."
  }
}

# Environment identifier
variable "environment" {
  type        = string                          # String type for deployment environment
  description = "Target deployment tier (prod, staging, dr, nonprod)" # Tier description
  default     = "prod"                          # Default environment

  # Validation restricting environment to approved tiers
  validation {
    condition     = contains(["prod", "staging", "dr", "nonprod"], var.environment)
    error_message = "Environment must be one of: prod, staging, dr, nonprod."
  }
}

# Target Azure primary region
variable "location" {
  type        = string                          # String type for Azure region
  description = "Target Azure geographic region" # Region explanation
  default     = "eastus2"                       # Default region: East US 2 (Primary Healthcare Zone)
}

# Hosting Resource Group Name
variable "resource_group_name" {
  type        = string                          # String type for Resource Group name
  description = "Name of the target Azure Resource Group" # Description
  default     = "rg-mosaic-security-prod-01"    # Default resource group name
}

# Key Vault SKU Tier
variable "sku_name" {
  type        = string                          # String type for Key Vault SKU
  description = "Key Vault SKU tier: standard or premium (premium required for HSM CMK)" # Description
  default     = "premium"                       # Default SKU: premium (FIPS 140-2 Level 3 HSM)

  # Validation enforcing premium SKU for production HIPAA compliance
  validation {
    condition     = var.sku_name == "premium"
    error_message = "Production healthcare compliance requires SKU tier 'premium' for HSM backing."
  }
}

# Soft Delete Retention Window in Days
variable "soft_delete_retention_days" {
  type        = number                          # Number type for retention window
  description = "Number of days that items should be retained for once soft-deleted (7 to 90 days)" # Description
  default     = 90                              # Default: 90 days (Maximum disaster recovery window)

  # Validation ensuring retention is set to maximum 90 days for prod
  validation {
    condition     = var.soft_delete_retention_days >= 90
    error_message = "Production healthcare compliance requires soft_delete_retention_days to be at least 90."
  }
}

# Purge Protection Flag
variable "purge_protection_enabled" {
  type        = bool                            # Boolean flag for purge protection
  description = "Whether Purge Protection is enabled for this Key Vault (Mandatory for PHI protection)" # Description
  default     = true                            # Default: true (Permanent locking)

  # Validation enforcing true in production
  validation {
    condition     = var.purge_protection_enabled == true
    error_message = "Purge protection must be enabled in production to prevent ransomware key destruction."
  }
}

# Disk Encryption Subsystem Authorization Flag
variable "enabled_for_disk_encryption" {
  type        = bool                            # Boolean flag for Azure Disk Encryption
  description = "Whether Azure Disk Encryption is permitted to retrieve secrets and keys" # Description
  default     = true                            # Default: true
}

# Private Endpoint Target Subnet Resource ID
variable "private_endpoint_subnet_id" {
  type        = string                          # Resource ID string of Spoke subnet
  description = "The Resource ID of the subnet where the Private Endpoint will be provisioned" # Description
  default     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mosaic-network-prod-01/providers/Microsoft.Network/virtualNetworks/vnet-mosaic-clinical-prod-01/subnets/snet-private-endpoints"
}

# Private DNS Zone Resource ID
variable "private_dns_zone_id" {
  type        = string                          # Resource ID string of Private DNS Zone
  description = "The Resource ID of the privatelink.vaultcore.azure.net Private DNS Zone" # Description
  default     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mosaic-network-prod-01/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
}

# Log Analytics Workspace Resource ID for SIEM Ingestion
variable "log_analytics_workspace_id" {
  type        = string                          # Resource ID string of Log Analytics Workspace
  description = "The Resource ID of the Central Log Analytics Workspace for Sentinel SIEM ingestion" # Description
  default     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mosaic-mgmt-prod-01/providers/Microsoft.OperationalInsights/workspaces/law-mosaic-mgmt-prod-01"
}

# Resource Governance Tags
variable "tags" {
  type        = map(string)                     # Map of key-value string pairs
  description = "Metadata tags applied to all provisioned resources" # Tag description
  default = {
    CostCenter     = "CC-94102-SECURITY-INFRA" # Financial accounting cost center
    Owner          = "Cloud-Architecture-Board" # Squad ownership
    Environment    = "Production"               # Environment tier
    Criticality    = "Mission-Critical-Tier-0"  # Disaster recovery criticality tier
  }
}
