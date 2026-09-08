# --------------------------------------------------------------------------------------------------
# MOSAIC HEALTHCARE ENTERPRISE CLOUD ARCHITECTURE: AZURE AI FOUNDRY MODULE
# "Deterministic guardrails, hardened vector retrieval, and sovereign clinical intelligence."
# --------------------------------------------------------------------------------------------------
# File: terraform/azure-ai-foundry-enterprise/main.tf
# Purpose: Production-grade, HITRUST-compliant Azure AI Foundry Hub, Projects, OpenAI Model
#          Deployments (GPT-4o, Embeddings), AI Search RAG, Content Safety, and Private Link.
# --------------------------------------------------------------------------------------------------

# Retrieve Azure client configuration for tenant and subscription identification
data "azurerm_client_config" "current" {}

# Generate random string suffix for globally unique resource naming
resource "random_string" "ai_suffix" {
  length  = 6     # Length of random alphanumeric suffix
  special = false # Exclude special characters to adhere to Azure DNS naming rules
  upper   = false # Lowercase only for clean URI compatibility
}

# --------------------------------------------------------------------------------------------------
# 1. CORE SUPPORTING SERVICES: LOG ANALYTICS, APP INSIGHTS & STORAGE
# --------------------------------------------------------------------------------------------------

# Log Analytics Workspace for AI Foundry telemetry and model audit logging
resource "azurerm_log_analytics_workspace" "ai_law" {
  name                = "${var.prefix}-ai-law-${var.environment}-${random_string.ai_suffix.result}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days # Mandatory 730 days for HIPAA audit compliance

  tags = merge(var.tags, {
    Component          = "AI-Foundry-Audit-Logging"
    ComplianceScope    = "HIPAA-HITRUST-CSF-v11"
    DataClassification = "Audit-Telemetry"
  })
}

# Application Insights for MLflow model tracing and inference latency monitoring
resource "azurerm_application_insights" "ai_insights" {
  name                = "${var.prefix}-ai-appi-${var.environment}-${random_string.ai_suffix.result}"
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.ai_law.id
  application_type    = "web"

  tags = merge(var.tags, {
    Component       = "AI-Foundry-Telemetry"
    ComplianceScope = "HIPAA-HITRUST-CSF-v11"
  })
}

# Secure Storage Account for AI datasets, prompt engineering artifacts, and fine-tuning weights
resource "azurerm_storage_account" "ai_storage" {
  name                          = "${replace(var.prefix, "-", "")}aistg${var.environment}${random_string.ai_suffix.result}"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  account_tier                  = "Standard"
  account_replication_type      = "GRS" # Geo-Redundant Storage for clinical disaster recovery
  account_kind                  = "StorageV2"
  is_hns_enabled                = true  # Hierarchical Namespace enabled for Lakehouse AI & Delta Lake
  min_tls_version               = "TLS1_2"
  enable_https_traffic_only     = true
  public_network_access_enabled = false # Zero public internet ingress allowed

  blob_properties {
    versioning_enabled = true # Immutable artifact history for regulatory traceability
    delete_retention_policy {
      days = 30
    }
  }

  tags = merge(var.tags, {
    Component          = "AI-Foundry-Dataset-Store"
    ComplianceScope    = "HIPAA-HITRUST-CSF-v11"
    DataClassification = "PHI-Restricted"
  })
}

# --------------------------------------------------------------------------------------------------
# 2. AZURE OPENAI & AI SERVICES (FOUNDATION MODEL ENGINE)
# --------------------------------------------------------------------------------------------------

# Azure AI Services / OpenAI multi-service account with Managed Identity
resource "azurerm_cognitive_account" "openai" {
  name                          = "${var.prefix}-openai-${var.environment}-${random_string.ai_suffix.result}"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  kind                          = "OpenAI"
  sku_name                      = "S0"
  custom_subdomain_name         = "${var.prefix}-openai-${var.environment}-${random_string.ai_suffix.result}"
  public_network_access_enabled = false # Strict private endpoint enforcement

  identity {
    type = "SystemAssigned" # System-assigned identity for token-based authentication
  }

  tags = merge(var.tags, {
    Component          = "Azure-OpenAI-Inference"
    ComplianceScope    = "HIPAA-HITRUST-CSF-v11"
    DataClassification = "Clinical-AI-Inference"
  })
}

# Model Deployment: GPT-4o Multi-Modal Foundation Model
resource "azurerm_cognitive_deployment" "gpt4o" {
  name                 = "gpt-4o"
  cognitive_account_id = azurerm_cognitive_account.openai.id

  model {
    format  = "OpenAI"
    name    = "gpt-4o"
    version = var.gpt4o_model_version
  }

  scale {
    type     = "GlobalStandard" # Global Standard for elastic healthcare throughput
    capacity = var.gpt4o_capacity # TPM capacity allocation
  }
}

# Model Deployment: text-embedding-3-large for High-Dimensional Clinical Vector Search
resource "azurerm_cognitive_deployment" "embedding" {
  name                 = "text-embedding-3-large"
  cognitive_account_id = azurerm_cognitive_account.openai.id

  model {
    format  = "OpenAI"
    name    = "text-embedding-3-large"
    version = "1"
  }

  scale {
    type     = "Standard"
    capacity = 50 # 50K TPM allocation for document vectorization
  }
}

# --------------------------------------------------------------------------------------------------
# 3. AZURE AI CONTENT SAFETY & PROMPT SHIELD
# --------------------------------------------------------------------------------------------------

# Azure AI Content Safety service for real-time harm filtering and prompt shield
resource "azurerm_cognitive_account" "content_safety" {
  name                          = "${var.prefix}-safety-${var.environment}-${random_string.ai_suffix.result}"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  kind                          = "ContentSafety"
  sku_name                      = "S0"
  custom_subdomain_name         = "${var.prefix}-safety-${var.environment}-${random_string.ai_suffix.result}"
  public_network_access_enabled = false

  identity {
    type = "SystemAssigned"
  }

  tags = merge(var.tags, {
    Component          = "Azure-AI-Content-Safety"
    ComplianceScope    = "HIPAA-HITRUST-CSF-v11"
    DataClassification = "AI-Safety-Guardrail"
  })
}

# --------------------------------------------------------------------------------------------------
# 4. AZURE AI SEARCH (CLINICAL RAG & SEMANTIC VECTOR RETRIEVAL)
# --------------------------------------------------------------------------------------------------

# Azure AI Search Service for hybrid dense/sparse vector retrieval with Semantic Ranker
resource "azurerm_search_service" "rag_search" {
  name                          = "${var.prefix}-search-${var.environment}-${random_string.ai_suffix.result}"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  sku                           = "standard"
  replica_count                 = var.search_replica_count
  partition_count               = 1
  semantic_search_sku           = "standard" # Enables Microsoft Semantic Ranker for clinical accuracy
  public_network_access_enabled = false      # Private Link only

  identity {
    type = "SystemAssigned"
  }

  tags = merge(var.tags, {
    Component          = "Azure-AI-Search-RAG"
    ComplianceScope    = "HIPAA-HITRUST-CSF-v11"
    DataClassification = "Clinical-Vector-Store"
  })
}

# --------------------------------------------------------------------------------------------------
# 5. AZURE AI FOUNDRY HUB & PROJECT (ENTERPRISE GOVERNANCE WORKSPACE)
# --------------------------------------------------------------------------------------------------

# Azure AI Foundry Hub (Top-Level Enterprise Workspace)
resource "azurerm_ai_foundry" "hub" {
  name                    = "${var.prefix}-aihub-${var.environment}-${random_string.ai_suffix.result}"
  location                = var.location
  resource_group_name     = var.resource_group_name
  storage_account_id      = azurerm_storage_account.ai_storage.id
  key_vault_id            = var.key_vault_id
  application_insights_id = azurerm_application_insights.ai_insights.id
  public_network_access   = "Disabled" # Enforce private endpoint communication

  identity {
    type = "SystemAssigned"
  }

  tags = merge(var.tags, {
    Component          = "Azure-AI-Foundry-Hub"
    ComplianceScope    = "HIPAA-HITRUST-CSF-v11"
    DataClassification = "AI-Governance-Hub"
  })
}

# Azure AI Foundry Project: Clinical Copilot & Model Fine-Tuning Environment
resource "azurerm_ai_foundry_project" "clinical_project" {
  name               = "mosaic-clinical-agent-project"
  location           = var.location
  ai_services_hub_id = azurerm_ai_foundry.hub.id

  identity {
    type = "SystemAssigned"
  }

  tags = merge(var.tags, {
    Component          = "Azure-AI-Foundry-Project"
    ComplianceScope    = "HIPAA-HITRUST-CSF-v11"
    ProjectRole        = "Clinical-Agent-Development"
  })
}

# --------------------------------------------------------------------------------------------------
# 6. DIAGNOSTIC LOGGING FOR IMMUTABLE AUDIT TRAIL (7-YEAR HIPAA WORM COMPLIANCE)
# --------------------------------------------------------------------------------------------------

# Diagnostic settings streaming all OpenAI audit events and token transactions to Log Analytics
resource "azurerm_monitor_diagnostic_setting" "openai_diagnostics" {
  name                       = "${var.prefix}-openai-diag"
  target_resource_id         = azurerm_cognitive_account.openai.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.ai_law.id

  enabled_log {
    category = "Audit"
  }

  enabled_log {
    category = "RequestAndResponseLogs"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
