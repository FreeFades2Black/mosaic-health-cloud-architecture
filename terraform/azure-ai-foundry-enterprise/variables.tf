# --------------------------------------------------------------------------------------------------
# MOSAIC HEALTHCARE ENTERPRISE CLOUD ARCHITECTURE: AZURE AI FOUNDRY MODULE
# Variable Definitions with Type Constraints & Regex Validation
# --------------------------------------------------------------------------------------------------
# File: terraform/azure-ai-foundry-enterprise/variables.tf
# Purpose: Define strictly typed input variables for Azure AI Foundry, OpenAI, Search, and Hub.
# --------------------------------------------------------------------------------------------------

variable "prefix" {
  type        = string
  description = "Resource name prefix applied to all AI Foundry components (e.g., 'mosaic')."
  default     = "mosaic"

  validation {
    condition     = can(regex("^[a-z0-9-]{2,10}$", var.prefix))
    error_message = "Prefix must consist of 2-10 lowercase alphanumeric characters and hyphens."
  }
}

variable "environment" {
  type        = string
  description = "Target deployment lifecycle environment (prod, stage, dev, or sandbox)."
  default     = "prod"

  validation {
    condition     = contains(["prod", "stage", "dev", "sandbox"], var.environment)
    error_message = "Environment must be one of: 'prod', 'stage', 'dev', 'sandbox'."
  }
}

variable "location" {
  type        = string
  description = "Target Azure primary region for AI Foundry resources (must support GPT-4o & AI Search)."
  default     = "eastus2"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the parent Azure Resource Group housing the AI Foundry infrastructure."
}

variable "key_vault_id" {
  type        = string
  description = "Resource ID of the enterprise Azure Key Vault instance for CMK encryption and secrets."

  validation {
    condition     = can(regex("^/subscriptions/.+/resourceGroups/.+/providers/Microsoft.KeyVault/vaults/.+$", var.key_vault_id))
    error_message = "Key Vault ID must be a fully qualified Azure Resource ID."
  }
}

variable "log_retention_days" {
  type        = number
  description = "Diagnostic and audit log retention window in days (730 days for HIPAA § 164.312)."
  default     = 730

  validation {
    condition     = var.log_retention_days >= 365
    error_message = "Healthcare audit log retention must be at least 365 days (730 recommended for HIPAA)."
  }
}

variable "gpt4o_model_version" {
  type        = string
  description = "Target model version tag for GPT-4o foundation model in Azure AI Foundry."
  default     = "2024-11-20"
}

variable "gpt4o_capacity" {
  type        = number
  description = "Tokens-per-minute (TPM) capacity allocation in thousands for GPT-4o model deployment."
  default     = 100 # 100K TPM default allocation

  validation {
    condition     = var.gpt4o_capacity >= 10 && var.gpt4o_capacity <= 2000
    error_message = "GPT-4o capacity must be between 10K TPM and 2,000K TPM."
  }
}

variable "search_replica_count" {
  type        = number
  description = "Replica count for Azure AI Search Service for high availability and low latency query SLA."
  default     = 2

  validation {
    condition     = var.search_replica_count >= 1 && var.search_replica_count <= 12
    error_message = "Search replica count must be between 1 and 12."
  }
}

variable "tags" {
  type        = map(string)
  description = "Enterprise metadata tags attached to all provisioned AI Foundry resources."
  default = {
    Organization       = "Mosaic Healthcare System"
    ArchitecturePillar = "AI-Foundry-Model-Regulation"
    ComplianceStandard = "HITRUST-CSF-v11"
    SecurityTier       = "Tier-1-Clinical-Restricted"
  }
}
