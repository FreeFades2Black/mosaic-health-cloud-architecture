# --------------------------------------------------------------------------------------------------
# GUNSLINGER DISPATCH: AZURE KEY VAULT ENTERPRISE HEALTHCARE MODULE
# "In cold iron and cryptographic stone, the patient record is sealed beyond reach."
# --------------------------------------------------------------------------------------------------
# File: terraform/gunslinger-secure-vault/main.tf
# Purpose: Production-grade, HITRUST-compliant Azure Key Vault with Private Link & CMK Encryption.
# --------------------------------------------------------------------------------------------------

# Retrieve Azure client configuration for tenant and subscription identification
data "azurerm_client_config" "current" {}

# Generate random string suffix for globally unique resource naming
resource "random_string" "vault_suffix" {
  length  = 6     # Length of random alphanumeric suffix
  special = false # Exclude special characters to adhere to Key Vault naming rules
  upper   = false # Lowercase only for clean DNS compatibility
}

# Provision the Enterprise Azure Key Vault instance
resource "azurerm_key_vault" "vault" {
  name                            = "${var.vault_prefix}-${var.environment}-${random_string.vault_suffix.result}" # Globally unique Key Vault name (max 24 chars)
  location                        = var.location                                                                   # Target Azure region (e.g., eastus2)
  resource_group_name             = var.resource_group_name                                                        # Host Resource Group name
  tenant_id                       = data.azurerm_client_config.current.tenant_id                                   # Entra ID Tenant ID for token validation
  sku_name                        = var.sku_name                                                                   # SKU tier: 'premium' for FIPS 140-2 Level 3 HSM backing
  soft_delete_retention_days      = var.soft_delete_retention_days                                                 # Retention window (90 days) for disaster recovery
  purge_protection_enabled        = var.purge_protection_enabled                                                   # Prevent forced deletion even by root tenant admins
  enabled_for_disk_encryption     = var.enabled_for_disk_encryption                                                # Authorize Azure Disk Encryption subsystem
  enabled_for_deployment          = false                                                                          # Disallow Azure Resource Manager VM template cleartext secret injection
  enabled_for_template_deployment = false                                                                          # Disallow ARM template direct secret extraction
  enable_rbac_authorization       = true                                                                           # Enforce Azure RBAC over legacy Access Policies (HITRUST 01.0)
  public_network_access_enabled   = false                                                                          # Deny 100% of public internet ingress (Private Endpoint mandatory)

  # Network ACL default action to block all non-private endpoint traffic
  network_acls {
    bypass         = "AzureServices" # Allow trusted first-party Azure services (e.g., Azure Backup)
    default_action = "Deny"          # Explicit default deny for all unapproved network routes
    ip_rules       = []              # Zero public CIDRs permitted in production healthcare tier
  }

  # Enterprise resource tags for cost center allocation and compliance auditing
  tags = merge(var.tags, {
    ComplianceScope    = "HIPAA-HITRUST-CSF-v11"                     # Regulatory compliance tag
    DataClassification = "PHI-Restricted"                            # Protected Health Information classification
    ManagedBy          = "Terraform-Gunslinger-Engine"               # IaC ownership tag
    ProvisionedAt      = timestamp()                                 # Provisioning audit timestamp
  })

  # Ensure lifecycle ignore for timestamp updates on re-apply
  lifecycle {
    ignore_changes = [
      tags["ProvisionedAt"],
    ]
  }
}

# Customer-Managed Master Key (CMK) for ePHI Data Store Encryption
resource "azurerm_key_vault_key" "master_cmk" {
  name         = "${var.vault_prefix}-master-kek-01" # Master Key Encryption Key (KEK) identifier
  key_vault_id = azurerm_key_vault.vault.id          # Reference parent Key Vault instance
  key_type     = "RSA-HSM"                           # Hardware Security Module backed RSA key type
  key_size     = 4096                                # 4096-bit RSA key length meeting HITRUST cryptographic requirements

  # Cryptographic operation permissions granted on the master key
  key_opts = [
    "decrypt", # Permit DEK decryption for authorized clinical workloads
    "encrypt", # Permit DEK encryption for authorized clinical workloads
    "sign",    # Permit cryptographic signature verification
    "verify",  # Permit signature validation
    "wrapKey", # Permit Data Encryption Key wrapping
    "unwrapKey"# Permit Data Encryption Key unwrapping
  ]

  # Automated 365-day rotation policy configuration
  rotation_policy {
    automatic {
      time_after_creation = "P365D" # Automatically rotate master key every 365 days
    }
    expire_after         = "P730D" # Set key expiration threshold to 730 days
    notify_before_expiry = "P30D"  # Trigger Event Grid notification 30 days prior to expiry
  }

  depends_on = [azurerm_key_vault.vault] # Ensure vault is provisioned before key creation
}

# Private Endpoint for Zero-Trust Private Network Connectivity
resource "azurerm_private_endpoint" "vault_pe" {
  name                = "pe-${azurerm_key_vault.vault.name}" # Name of the private endpoint resource
  location            = var.location                         # Target Azure region
  resource_group_name = var.resource_group_name              # Host Resource Group
  subnet_id           = var.private_endpoint_subnet_id       # Target isolated Spoke subnet ID

  # Private Link Service Connection specification
  private_service_connection {
    name                           = "psc-${azurerm_key_vault.vault.name}" # Connection link identifier
    private_connection_resource_id = azurerm_key_vault.vault.id           # Target Key Vault Resource ID
    is_manual_connection           = false                                # Automated approval for same-tenant resources
    subresource_names              = ["vault"]                             # Target sub-resource for Key Vault
  }

  # DNS Zone Group integration for automated private DNS record registration
  private_dns_zone_group {
    name                 = "pdz-group-vault"                               # DNS zone group identifier
    private_dns_zone_ids = [var.private_dns_zone_id]                       # Target *.privatelink.vaultcore.azure.net zone ID
  }

  tags = var.tags # Inherit standard resource tags
}

# Diagnostic Settings for Centralized Audit & SIEM Ingestion
resource "azurerm_monitor_diagnostic_setting" "vault_diagnostics" {
  name                       = "diag-${azurerm_key_vault.vault.name}" # Diagnostic setting identifier
  target_resource_id         = azurerm_key_vault.vault.id             # Target Key Vault resource to monitor
  log_analytics_workspace_id = var.log_analytics_workspace_id         # Central Log Analytics Workspace ID

  # Ingest 100% of audit event logs (AuditEvents category)
  enabled_log {
    category = "AuditEvent" # Key Vault access logs, key operations, secret queries
  }

  # Ingest Azure Key Vault performance metrics
  metric {
    category = "AllMetrics" # Ingestion latency, throughput, and error rate metrics
    enabled  = true         # Enable metric forwarding
  }
}
