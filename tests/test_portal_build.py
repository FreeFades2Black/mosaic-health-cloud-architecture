"""
==============================================================================
MOSAIC HEALTHCARE ENTERPRISE CLOUD ARCHITECTURE PORTAL
Automated Test Suite & Architecture Governance Verification
==============================================================================
"""

import os
import subprocess
import yaml
import pytest
from pathlib import Path

# Project root path resolution
PROJECT_ROOT = Path(__file__).parent.parent.resolve()


class CustomYamlLoader(yaml.SafeLoader):
    """Custom YAML loader that ignores Python object tags like !!python/name."""
    pass


def _ignore_custom_tags(loader, tag_suffix, node):
    if isinstance(node, yaml.ScalarNode):
        return loader.construct_scalar(node)
    elif isinstance(node, yaml.SequenceNode):
        return loader.construct_sequence(node)
    elif isinstance(node, yaml.MappingNode):
        return loader.construct_mapping(node)
    return None


CustomYamlLoader.add_multi_constructor("tag:yaml.org,2002:python/", _ignore_custom_tags)
CustomYamlLoader.add_multi_constructor("!", _ignore_custom_tags)


@pytest.fixture
def mkdocs_config():
    """Load and parse mkdocs.yml configuration."""
    config_file = PROJECT_ROOT / "mkdocs.yml"
    assert config_file.exists(), f"mkdocs.yml not found at {config_file}"
    with open(config_file, "r", encoding="utf-8") as f:
        config = yaml.load(f, Loader=CustomYamlLoader)
    return config


def test_mkdocs_config_valid(mkdocs_config):
    """Validate critical mkdocs.yml settings and metadata."""
    assert "site_name" in mkdocs_config
    assert "Mosaic Health" in mkdocs_config["site_name"]
    assert mkdocs_config["theme"]["name"] == "material"
    assert "palette" in mkdocs_config["theme"]
    assert "nav" in mkdocs_config
    assert "plugins" in mkdocs_config
    assert "markdown_extensions" in mkdocs_config


def extract_nav_files(nav_item):
    """Recursively extract markdown files defined in mkdocs navigation."""
    files = []
    if isinstance(nav_item, dict):
        for key, value in nav_item.items():
            files.extend(extract_nav_files(value))
    elif isinstance(nav_item, list):
        for item in nav_item:
            files.extend(extract_nav_files(item))
    elif isinstance(nav_item, str):
        files.append(nav_item)
    return files


def test_all_documentation_pages_exist(mkdocs_config):
    """Verify that every page declared in navigation exists on disk."""
    nav_files = extract_nav_files(mkdocs_config["nav"])
    assert len(nav_files) >= 14, f"Expected at least 14 nav files, found {len(nav_files)}"

    docs_dir = PROJECT_ROOT / "docs"
    for rel_path in nav_files:
        # Check if the file is in docs/ or root
        target_in_docs = docs_dir / rel_path
        target_in_root = PROJECT_ROOT / rel_path
        assert target_in_docs.exists() or target_in_root.exists(), (
            f"Navigation target file missing: {rel_path}"
        )


def test_mermaid_diagrams_present_in_core_docs():
    """Verify that core architectural documents contain rendered Mermaid diagrams."""
    core_docs = [
        PROJECT_ROOT / "docs" / "index.md",
        PROJECT_ROOT / "docs" / "landing-zone" / "management-groups.md",
        PROJECT_ROOT / "docs" / "landing-zone" / "hybrid-networking.md",
        PROJECT_ROOT / "docs" / "landing-zone" / "identity-access.md",
        PROJECT_ROOT / "docs" / "ma-playbook" / "due-diligence-checklist.md",
        PROJECT_ROOT / "docs" / "ma-playbook" / "wave-migration-sequencer.md",
        PROJECT_ROOT / "docs" / "compliance-hitrust" / "audit-evidence-logging.md",
        PROJECT_ROOT / "docs" / "multicloud-matrix" / "aws-gcp-azure-mapping.md",
        PROJECT_ROOT / "docs" / "multicloud-matrix" / "migration-rationalization.md",
        PROJECT_ROOT / "docs" / "arb-adrs" / "adr-001-vwan-hub-spoke.md",
        PROJECT_ROOT / "docs" / "arb-adrs" / "adr-002-key-vault-cmk.md",
        PROJECT_ROOT / "docs" / "arb-adrs" / "adr-003-tenant-consolidation.md",
    ]

    for doc_path in core_docs:
        assert doc_path.exists(), f"Required core doc missing: {doc_path}"
        content = doc_path.read_text(encoding="utf-8")
        assert "```mermaid" in content, f"Doc missing Mermaid diagram: {doc_path.name}"


def test_adr_structure_and_formatting():
    """Verify that all ADRs satisfy the standard Architectural Decision Record structure."""
    adr_dir = PROJECT_ROOT / "docs" / "arb-adrs"
    adr_files = list(adr_dir.glob("adr-*.md"))
    assert len(adr_files) >= 3, f"Expected at least 3 ADRs, found {len(adr_files)}"

    required_sections = [
        "Context & Problem Statement",
        "Decision Drivers",
        "Considered Options",
        "Decision Outcome",
        "Consequences",
        "Compliance & Security Mapping",
    ]

    for adr_path in adr_files:
        content = adr_path.read_text(encoding="utf-8")
        for section in required_sections:
            assert section in content, (
                f"ADR {adr_path.name} missing required section: '{section}'"
            )


def test_hitrust_control_mapping_completeness():
    """Verify that HITRUST control mapping matrix includes mandatory domains and HIPAA specs."""
    matrix_file = PROJECT_ROOT / "docs" / "compliance-hitrust" / "control-mapping-matrix.md"
    assert matrix_file.exists(), f"Matrix file missing at {matrix_file}"
    content = matrix_file.read_text(encoding="utf-8")

    mandatory_domains = ["01.0", "02.0", "03.0", "06.0", "07.0", "08.0", "09.0", "10.0"]
    for domain in mandatory_domains:
        assert domain in content, f"HITRUST Domain {domain} missing from control mapping matrix"

    assert "164.312" in content, "HIPAA § 164.312 citation missing from control matrix"


def test_terraform_gunslinger_module_integrity():
    """Verify Terraform module structure, resource definitions, and outputs."""
    tf_dir = PROJECT_ROOT / "terraform" / "gunslinger-secure-vault"
    assert tf_dir.exists(), f"Terraform module directory missing at {tf_dir}"

    main_tf = tf_dir / "main.tf"
    variables_tf = tf_dir / "variables.tf"
    outputs_tf = tf_dir / "outputs.tf"
    tfvars_example = tf_dir / "terraform.tfvars.example"

    for f in [main_tf, variables_tf, outputs_tf, tfvars_example]:
        assert f.exists(), f"Terraform file missing: {f.name}"
        assert f.stat().st_size > 200, f"Terraform file {f.name} is unexpectedly small"

    main_content = main_tf.read_text(encoding="utf-8")
    assert "azurerm_key_vault" in main_content
    assert "azurerm_key_vault_key" in main_content
    assert "azurerm_private_endpoint" in main_content
    assert "azurerm_monitor_diagnostic_setting" in main_content


def test_terraform_code_annotation_density():
    """Verify that Terraform HCL files contain thorough comments and line-by-line notes."""
    tf_dir = PROJECT_ROOT / "terraform" / "gunslinger-secure-vault"
    for tf_file in tf_dir.glob("*.tf"):
        lines = tf_file.read_text(encoding="utf-8").splitlines()
        comment_lines = [l for l in lines if "#" in l]
        assert len(comment_lines) >= len(lines) * 0.4, (
            f"File {tf_file.name} lacks sufficient line-by-line annotations "
            f"({len(comment_lines)} comment occurrences out of {len(lines)} lines)"
        )


def test_docker_and_ci_manifests():
    """Verify Dockerfile, docker-compose, and GitHub Actions workflow."""
    dockerfile = PROJECT_ROOT / "Dockerfile"
    compose = PROJECT_ROOT / "docker-compose.yml"
    ci_workflow = PROJECT_ROOT / ".github" / "workflows" / "deploy.yml"

    assert dockerfile.exists(), "Dockerfile missing"
    assert compose.exists(), "docker-compose.yml missing"
    assert ci_workflow.exists(), "CI workflow deploy.yml missing"

    docker_content = dockerfile.read_text(encoding="utf-8")
    assert "FROM python:3.11-slim AS builder" in docker_content
    assert "FROM nginx:1.27-alpine AS runner" in docker_content
    assert "USER nginx" in docker_content


def test_terraform_ai_foundry_module_integrity():
    """Verify Azure AI Foundry Terraform module structure, resource definitions, and outputs."""
    tf_dir = PROJECT_ROOT / "terraform" / "azure-ai-foundry-enterprise"
    assert tf_dir.exists(), f"AI Foundry module directory missing at {tf_dir}"

    main_tf = tf_dir / "main.tf"
    variables_tf = tf_dir / "variables.tf"
    outputs_tf = tf_dir / "outputs.tf"
    tfvars_example = tf_dir / "terraform.tfvars.example"

    for f in [main_tf, variables_tf, outputs_tf, tfvars_example]:
        assert f.exists(), f"Terraform file missing: {f.name}"
        assert f.stat().st_size > 200, f"Terraform file {f.name} is unexpectedly small"

    main_content = main_tf.read_text(encoding="utf-8")
    assert "azurerm_cognitive_account" in main_content
    assert "azurerm_cognitive_deployment" in main_content
    assert "azurerm_search_service" in main_content
    assert "azurerm_ai_foundry" in main_content
    assert "azurerm_ai_foundry_project" in main_content

