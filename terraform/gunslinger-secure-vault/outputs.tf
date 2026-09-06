# --------------------------------------------------------------------------------------------------
# GUNSLINGER DISPATCH: AZURE KEY VAULT OUTPUTS DECLARATION
# "The keys are forged, the endpoints secured; export the coordinates to the ledger."
# --------------------------------------------------------------------------------------------------
# File: terraform/gunslinger-secure-vault/outputs.tf
# Purpose: Resource identifiers and cryptographic endpoints exported for downstream modules.
# --------------------------------------------------------------------------------------------------

# Export the Azure Resource ID of the provisioned Key Vault
output "key_vault_id" {
  description = "The Azure Resource Manager ID of the provisioned Key Vault" # Output description
  value       = azurerm_key_vault.vault.id                                    # Resource ID reference
}

# Export the Key Vault Vault URI (FQDN)
output "key_vault_uri" {
  description = "The Vault URI endpoint for HTTPS cryptographic API calls"     # Output description
  value       = azurerm_key_vault.vault.vault_uri                             # Vault URI reference (e.g. https://kv-mosaic-prod-abc123.vault.azure.net/)
}

# Export the Key Vault Name
output "key_vault_name" {
  description = "The globally unique name of the Azure Key Vault instance"     # Output description
  value       = azurerm_key_vault.vault.name                                  # Key Vault resource name
}

# Export the Customer-Managed Key (CMK) Resource ID
output "master_cmk_key_id" {
  description = "The full Versioned Key ID of the Customer-Managed Master Key (RSA-4096)" # Output description
  value       = azurerm_key_vault_key.master_cmk.id                            # Key resource ID reference
}

# Export the Customer-Managed Key Versionless ID for Auto-Rotation Binding
output "master_cmk_versionless_id" {
  description = "The Versionless Key ID for binding storage accounts to automated rotation" # Output description
  value       = azurerm_key_vault_key.master_cmk.versionless_id                # Versionless ID reference
}

# Export the Private Endpoint IP Address
output "private_endpoint_ip" {
  description = "The private IP address assigned to the Key Vault Private Endpoint" # Output description
  value       = azurerm_private_endpoint.vault_pe.private_service_connection[0].private_ip_address # Private IP reference
}
