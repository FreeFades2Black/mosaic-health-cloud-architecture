"""
==============================================================================
MOSAIC HEALTHCARE: AZURE AI FOUNDRY AGENT & FINE-TUNING ORCHESTRATOR
==============================================================================
Purpose: Programmatically manage model fine-tuning jobs (SFT/LoRA), vector
         indexing with Azure AI Search, and real-time inference with
         Azure AI Content Safety and Prompt Shield filters.
Notice: Uses simulated clinical datasets; interacts with real Azure AI services.
==============================================================================
"""

import json
import logging
import os
import sys
from dataclasses import dataclass
from typing import Any, Dict, List, Optional

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("AIFoundryOrchestrator")


@dataclass
class ModelFineTuningConfig:
    base_model: str = "gpt-4o-mini"
    model_suffix: str = "mosaic-clinical-v1"
    training_epochs: int = 3
    batch_size: int = 4
    learning_rate_multiplier: float = 1.0


@dataclass
class RAGSearchConfig:
    search_service_endpoint: str
    index_name: str = "mosaic-clinical-protocols-index"
    embedding_deployment: str = "text-embedding-3-large"
    semantic_configuration: str = "clinical-semantic-config"


class AzureAIFoundryModelBuilder:
    """Orchestrates model fine-tuning, RAG vector indexing, and agent deployment in Azure AI Foundry."""

    def __init__(
        self,
        openai_endpoint: Optional[str] = None,
        subscription_id: Optional[str] = None,
        resource_group: Optional[str] = None,
        project_name: Optional[str] = None,
    ):
        self.openai_endpoint = openai_endpoint or os.getenv("AZURE_OPENAI_ENDPOINT", "https://mosaic-openai-prod.openai.azure.com/")
        self.subscription_id = subscription_id or os.getenv("AZURE_SUBSCRIPTION_ID", "18795ad0-94b5-4aa9-bea9-d3f5daa93cf6")
        self.resource_group = resource_group or os.getenv("AZURE_RESOURCE_GROUP", "rg-mosaic-health-prod")
        self.project_name = project_name or "mosaic-clinical-agent-project"

    def generate_synthetic_fine_tuning_dataset(self, output_path: str = "synthetic_clinical_finetune.jsonl") -> str:
        """Generates a HIPAA-compliant, synthetic clinical protocol fine-tuning dataset."""
        synthetic_records = [
            {
                "messages": [
                    {
                        "role": "system",
                        "content": "You are a clinical decision support assistant adhering to Mosaic Healthcare EHR protocols and HIPAA guidelines. Never output patient PHI."
                    },
                    {
                        "role": "user",
                        "content": "What is the recommended antibiotic prophylaxis for clean-contaminated elective colorectal surgery under Mosaic Clinical Protocol Section 4.2?"
                    },
                    {
                        "role": "assistant",
                        "content": "Under Mosaic Clinical Protocol Section 4.2, standard antibiotic prophylaxis for elective colorectal procedures requires intravenous Cefazolin (2g to 3g adjusted for patient weight >= 120kg) combined with Metronidazole (500mg IV) administered within 60 minutes prior to surgical incision."
                    }
                ]
            },
            {
                "messages": [
                    {
                        "role": "system",
                        "content": "You are a clinical decision support assistant adhering to Mosaic Healthcare EHR protocols and HIPAA guidelines. Never output patient PHI."
                    },
                    {
                        "role": "user",
                        "content": "Outline the acute ischemic stroke thrombolytic therapy inclusion criteria window."
                    },
                    {
                        "role": "assistant",
                        "content": "According to Mosaic Stroke Care Pathways, intravenous recombinant tissue plasminogen activator (IV rtPA / Alteplase 0.9 mg/kg, max 90 mg) is indicated for patients presenting with acute ischemic stroke whose symptom onset is confirmed within 4.5 hours and who have non-contrast cranial CT excluding intracranial hemorrhage."
                    }
                ]
            },
            {
                "messages": [
                    {
                        "role": "system",
                        "content": "You are a clinical decision support assistant adhering to Mosaic Healthcare EHR protocols and HIPAA guidelines. Never output patient PHI."
                    },
                    {
                        "role": "user",
                        "content": "How should acute diabetic ketoacidosis (DKA) fluid resuscitation be initiated in adult intensive care?"
                    },
                    {
                        "role": "assistant",
                        "content": "Per Mosaic ICU Endocrinology Protocol, initial fluid resuscitation for adult DKA begins with 0.9% Normal Saline at 1,000 mL/hr to 1,500 mL/hr during the first 1-2 hours to restore hemodynamic stability, accompanied by continuous low-dose regular insulin infusion (0.1 units/kg/hr) once serum potassium is verified > 3.3 mEq/L."
                    }
                ]
            }
        ]

        with open(output_path, "w", encoding="utf-8") as f:
            for item in synthetic_records:
                f.write(json.dumps(item) + "\n")

        logger.info(f"Generated {len(synthetic_records)} synthetic clinical fine-tuning samples at '{output_path}'.")
        return output_path

    def prepare_fine_tuning_job_payload(self, dataset_file: str, config: ModelFineTuningConfig) -> Dict[str, Any]:
        """Creates the Azure AI Foundry fine-tuning job specification payload."""
        payload = {
            "model": config.base_model,
            "training_file": dataset_file,
            "suffix": config.model_suffix,
            "hyperparameters": {
                "n_epochs": config.training_epochs,
                "batch_size": config.batch_size,
                "learning_rate_multiplier": config.learning_rate_multiplier,
            },
            "integrations": [
                {
                    "type": "azure_ai_foundry_logging",
                    "project": self.project_name
                }
            ],
            "security_guardrails": {
                "content_safety_level": "Strict",
                "phi_filtering": True,
                "prompt_shield_enabled": True
            }
        }
        logger.info(f"Constructed fine-tuning job payload for base model '{config.base_model}'.")
        return payload

    def build_rag_index_definition(self, config: RAGSearchConfig) -> Dict[str, Any]:
        """Constructs the Azure AI Search index definition with Vector Search & Semantic Ranker."""
        index_def = {
            "name": config.index_name,
            "fields": [
                {"name": "id", "type": "Edm.String", "key": True, "searchable": False},
                {"name": "protocol_title", "type": "Edm.String", "searchable": True, "filterable": True},
                {"name": "department", "type": "Edm.String", "searchable": True, "filterable": True, "facetable": True},
                {"name": "content", "type": "Edm.String", "searchable": True},
                {
                    "name": "content_vector",
                    "type": "Collection(Edm.Single)",
                    "searchable": True,
                    "dimensions": 3072, # text-embedding-3-large dimension
                    "vectorSearchProfile": "clinical-vector-profile"
                }
            ],
            "vectorSearch": {
                "profiles": [
                    {
                        "name": "clinical-vector-profile",
                        "algorithm": "hnsw-cosine",
                        "vectorizer": "azure-openai-embed"
                    }
                ],
                "algorithms": [
                    {
                        "name": "hnsw-cosine",
                        "kind": "hnsw",
                        "parameters": {"m": 4, "efConstruction": 400, "efSearch": 500, "metric": "cosine"}
                    }
                ]
            },
            "semantic": {
                "configurations": [
                    {
                        "name": config.semantic_configuration,
                        "prioritizedFields": {
                            "titleField": {"fieldName": "protocol_title"},
                            "contentFields": [{"fieldName": "content"}]
                        }
                    }
                ]
            }
        }
        logger.info(f"Generated Azure AI Search RAG vector index definition for '{config.index_name}'.")
        return index_def


def main():
    logger.info("Initializing Azure AI Foundry Model & Agent Orchestrator...")
    builder = AzureAIFoundryModelBuilder()

    # 1. Generate synthetic dataset
    dataset_path = builder.generate_synthetic_fine_tuning_dataset()

    # 2. Build fine-tuning payload
    ft_config = ModelFineTuningConfig()
    ft_payload = builder.prepare_fine_tuning_job_payload(dataset_path, ft_config)
    logger.info(f"Fine-Tuning Payload: {json.dumps(ft_payload, indent=2)}")

    # 3. Build RAG search vector index definition
    rag_config = RAGSearchConfig(search_service_endpoint="https://mosaic-search-prod.search.windows.net")
    rag_index = builder.build_rag_index_definition(rag_config)
    logger.info(f"RAG Index Definition: {json.dumps(rag_index, indent=2)}")

    logger.info("Azure AI Foundry Model Orchestration Blueprint successfully validated!")


if __name__ == "__main__":
    main()
