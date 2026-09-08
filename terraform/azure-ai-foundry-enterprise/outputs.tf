# --------------------------------------------------------------------------------------------------
# MOSAIC HEALTHCARE ENTERPRISE CLOUD ARCHITECTURE: AZURE AI FOUNDRY MODULE
# Output Values for Downstream Application & Pipeline Integration
# --------------------------------------------------------------------------------------------------
# File: terraform/azure-ai-foundry-enterprise/outputs.tf
# Purpose: Expose critical endpoints, resource IDs, and identity principals for AI SDK pipelines.
# --------------------------------------------------------------------------------------------------

output "ai_foundry_hub_id" {
  value       = azurerm_ai_foundry.hub.id
  description = "Fully qualified Resource ID of the Azure AI Foundry Hub."
}

output "ai_foundry_hub_name" {
  value       = azurerm_ai_foundry.hub.name
  description = "Name of the provisioned Azure AI Foundry Hub workspace."
}

output "ai_foundry_project_id" {
  value       = azurerm_ai_foundry_project.clinical_project.id
  description = "Resource ID of the Clinical Agent AI Foundry Project."
}

output "openai_account_id" {
  value       = azurerm_cognitive_account.openai.id
  description = "Resource ID of the Azure OpenAI cognitive account."
}

output "openai_endpoint" {
  value       = azurerm_cognitive_account.openai.endpoint
  description = "Primary HTTPS endpoint URI for Azure OpenAI model inferencing."
}

output "openai_principal_id" {
  value       = azurerm_cognitive_account.openai.identity[0].principal_id
  description = "Managed Service Identity (MSI) Principal ID for Azure OpenAI account."
}

output "gpt4o_deployment_name" {
  value       = azurerm_cognitive_deployment.gpt4o.name
  description = "Deployment name for the GPT-4o multi-modal foundation model."
}

output "embedding_deployment_name" {
  value       = azurerm_cognitive_deployment.embedding.name
  description = "Deployment name for the text-embedding-3-large vectorization model."
}

output "ai_search_service_name" {
  value       = azurerm_search_service.rag_search.name
  description = "Name of the provisioned Azure AI Search Service."
}

output "ai_search_endpoint" {
  value       = "https://${azurerm_search_service.rag_search.name}.search.windows.net"
  description = "HTTPS endpoint URI for the Azure AI Search RAG vector index."
}

output "content_safety_endpoint" {
  value       = azurerm_cognitive_account.content_safety.endpoint
  description = "HTTPS endpoint for Azure AI Content Safety real-time harm evaluation."
}

output "ai_storage_account_name" {
  value       = azurerm_storage_account.ai_storage.name
  description = "Name of the storage account used for AI datasets and fine-tuning weights."
}
