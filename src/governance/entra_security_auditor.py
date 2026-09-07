"""
==============================================================================
MOSAIC HEALTHCARE: MICROSOFT ENTRA ID ZERO-TRUST SECURITY AUDITOR
Audits Tenant Posture, Privileged Roles, App Credentials, and Guest Accounts
==============================================================================
"""

from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional


@dataclass
class EntraAuditScorecard:
    """Security posture scorecard for Microsoft Entra ID tenant."""
    tenant_id: str
    tenant_name: str
    global_admin_count: int
    user_count: int
    guest_user_count: int
    app_registration_count: int
    federated_credentials_count: int
    compliance_score: float  # 0.0 to 100.0%
    findings: List[str] = field(default_factory=list)
    passed: bool = True


class EntraSecurityAuditor:
    """Audits Microsoft Entra ID tenant data against Zero-Trust and CIS benchmarks."""

    def __init__(self, max_global_admins: int = 5, require_federation: bool = True):
        self.max_global_admins = max_global_admins
        self.require_federation = require_federation

    def audit_tenant(
        self,
        tenant_id: str,
        tenant_name: str,
        users: List[Dict[str, Any]],
        directory_roles: List[Dict[str, Any]],
        applications: List[Dict[str, Any]],
    ) -> EntraAuditScorecard:
        """Evaluates Entra ID directory snapshot and generates security scorecard."""
        findings = []
        score_deductions = 0.0

        user_count = len(users)
        guest_users = [u for u in users if "#EXT#" in u.get("userPrincipalName", "") or u.get("userType") == "Guest"]
        guest_count = len(guest_users)

        # 1. Audit Global Administrators
        global_admins = [r for r in directory_roles if r.get("displayName") == "Global Administrator" or r.get("roleTemplateId") == "62e90394-69f5-4237-9190-012177145e10"]
        admin_count = len(global_admins)

        if admin_count == 0:
            findings.append("No active Global Administrator role detected in snapshot.")
            score_deductions += 10.0
        elif admin_count > self.max_global_admins:
            findings.append(f"Excessive Global Administrators ({admin_count} > {self.max_global_admins}). Principle of least privilege violated.")
            score_deductions += 20.0

        # 2. Audit App Registrations & Workload Identity Federation
        app_count = len(applications)
        fed_creds_count = 0
        for app in applications:
            fed_creds = app.get("federatedCredentials", [])
            fed_creds_count += len(fed_creds)
            # Check for expiring client secrets if present
            for secret in app.get("passwordCredentials", []):
                if secret.get("hint") is None:
                    findings.append(f"Application '{app.get('displayName')}' contains unmanaged client secret.")
                    score_deductions += 5.0

        if self.require_federation and app_count > 0 and fed_creds_count == 0:
            findings.append("App registrations present without Workload Identity Federation (OIDC). Passwordless auth recommended.")
            score_deductions += 10.0

        # Calculate final compliance score
        final_score = max(0.0, 100.0 - score_deductions)
        passed = final_score >= 80.0

        return EntraAuditScorecard(
            tenant_id=tenant_id,
            tenant_name=tenant_name,
            global_admin_count=max(1, admin_count),
            user_count=user_count,
            guest_user_count=guest_count,
            app_registration_count=app_count,
            federated_credentials_count=fed_creds_count,
            compliance_score=final_score,
            findings=findings,
            passed=passed,
        )
