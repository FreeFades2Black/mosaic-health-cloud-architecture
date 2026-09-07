"""
==============================================================================
MICROSOFT ENTRA ID ZERO-TRUST AUDITOR TEST SUITE
Validates Tenant Posture, Role Assignments, and Workload Identity Federation
==============================================================================
"""

import pytest
from src.governance.entra_security_auditor import EntraSecurityAuditor, EntraAuditScorecard


@pytest.fixture
def auditor():
    """Instantiate Entra Security Auditor."""
    return EntraSecurityAuditor(max_global_admins=3, require_federation=True)


def test_clean_tenant_posture_passes_audit(auditor):
    """Verify that a compliant tenant snapshot achieves 100% compliance."""
    users = [
        {"displayName": "Free Hall", "userPrincipalName": "Gunslinger-19_outlook.com#EXT#@Gunslinger19outlook.onmicrosoft.com"}
    ]
    roles = [
        {"displayName": "Global Administrator", "id": "role-ga-01"}
    ]
    apps = [
        {
            "displayName": "app-mosaic-cloud-automation",
            "appId": "a722ef5f-7429-4db4-96aa-37075cac2d79",
            "federatedCredentials": [{"name": "github-actions-mosaic-main"}]
        }
    ]

    card = auditor.audit_tenant(
        tenant_id="18795ad0-94b5-4aa9-bea9-d3f5daa93cf6",
        tenant_name="Default Directory",
        users=users,
        directory_roles=roles,
        applications=apps
    )

    assert card.passed is True
    assert card.compliance_score == 100.0
    assert card.global_admin_count == 1
    assert card.guest_user_count == 1
    assert card.federated_credentials_count == 1
    assert len(card.findings) == 0


def test_excessive_global_admins_fails_or_deducts_score(auditor):
    """Verify that excessive Global Administrators trigger security finding."""
    users = [{"displayName": f"User {i}", "userPrincipalName": f"user{i}@mosaic.org"} for i in range(10)]
    roles = [{"displayName": "Global Administrator", "id": f"role-ga-{i}"} for i in range(6)]

    card = auditor.audit_tenant(
        tenant_id="18795ad0-94b5-4aa9-bea9-d3f5daa93cf6",
        tenant_name="Default Directory",
        users=users,
        directory_roles=roles,
        applications=[]
    )

    assert any("Excessive Global Administrators" in f for f in card.findings)
    assert card.compliance_score < 100.0
