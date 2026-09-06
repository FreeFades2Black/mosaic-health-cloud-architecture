# Enterprise Management Group Hierarchy & Governance

<span class="badge badge-prod">Governance Hierarchy</span>
<span class="badge badge-hitrust">HITRUST Control 01.0</span>

---

## 1. Hierarchy Design & Subscription Taxonomy

In an enterprise healthcare organization operating over 140+ clinics and medical centers, governance must be structured to prevent configuration drift, enforce strict regulatory controls at the root, and grant autonomous velocity to engineering squads within pre-approved boundary constraints.

```mermaid
graph TD
    TenantRoot["Tenant Root Group<br/>(Mosaic Healthcare Tenant: mosaic-healthcare.org)"]
    
    MosaicRoot["Mosaic Healthcare Enterprise Root<br/><code>/providers/Microsoft.Management/managementGroups/mg-mosaic-root</code>"]
    
    TenantRoot --> MosaicRoot

    Platform["Platform Management Group<br/><code>mg-mosaic-platform</code>"]
    LandingZones["Landing Zones Management Group<br/><code>mg-mosaic-landingzones</code>"]
    Sandbox["Sandboxes Management Group<br/><code>mg-mosaic-sandboxes</code>"]
    Decom["Decommissioned Management Group<br/><code>mg-mosaic-decom</code>"]

    MosaicRoot --> Platform
    MosaicRoot --> LandingZones
    MosaicRoot --> Sandbox
    MosaicRoot --> Decom

    MgmtSub["Management Sub<br/><code>sub-mosaic-mgmt-prod-01</code>"]
    ConnSub["Connectivity Sub<br/><code>sub-mosaic-conn-prod-01</code>"]
    IdSub["Identity Sub<br/><code>sub-mosaic-identity-prod-01</code>"]

    Platform --> MgmtSub
    Platform --> ConnSub
    Platform --> IdSub

    Clinical["Clinical Workloads<br/><code>mg-mosaic-clinical</code>"]
    Analytics["Lakehouse & AI Analytics<br/><code>mg-mosaic-analytics</code>"]
    Corporate["Corporate Services<br/><code>mg-mosaic-corporate</code>"]

    LandingZones --> Clinical
    LandingZones --> Analytics
    LandingZones --> Corporate

    EpicSub["Epic / Cerner EHR Sub<br/><code>sub-mosaic-clinical-prod-01</code>"]
    PACSsub["DICOM Imaging Sub<br/><code>sub-mosaic-pacs-prod-01</code>"]
    LakehouseSub["Databricks UC Sub<br/><code>sub-mosaic-lakehouse-prod-01</code>"]

    Clinical --> EpicSub
    Clinical --> PACSsub
    Analytics --> LakehouseSub
```

---

## 2. Management Group Guardrails & Azure Policy Initiatives

Each node in the hierarchy applies specific **Azure Policy Initiatives (Policy Sets)** enforcing zero-trust constraints:

### Root Level Policy Guardrails (`mg-mosaic-root`)

| Policy Definition / Initiative | Effect | Rationale & HITRUST Mapping |
| :--- | :--- | :--- |
| **Require Secure Transfer & TLS 1.3** | `Deny` | Prohibits unencrypted HTTP and TLS < 1.3 for all Azure Storage, App Services, and API Gateways (HITRUST 09.0). |
| **Deny Public Network Access on Data Stores** | `Deny` | Enforces Private Endpoints for all Key Vaults, SQL Databases, Cosmos DB, and Storage Accounts. |
| **Enforce Customer-Managed Keys (CMK)** | `Deny` | Requires all block/blob storage and managed disks to utilize CMK hosted in FIPS 140-2 Level 3 Key Vaults. |
| **Restrict Approved Azure Regions** | `Deny` | Limits provisioning strictly to `East US 2` (Primary) and `Central US` (Secondary DR) to satisfy geographic data residency. |
| **Require Mandatory Governance Resource Tags** | `Deny` | Enforces `Environment`, `Owner`, `CostCenter`, `DataClassification` (`PHI`, `Confidential`, `Public`), and `ComplianceScope`. |

### Platform Level Policy Guardrails (`mg-mosaic-platform`)

- **Diagnostic Setting Centralization:** Automatically assigns diagnostic settings via `DeployIfNotExists` sending all platform resource logs to the primary Log Analytics Workspace in `sub-mosaic-mgmt-prod-01`.
- **RBAC Role Assignment Lockdown:** Restricts owner permissions to PIM-activated security groups. Prevents manual service principal secret creation without secret lifecycle governance.

### Landing Zone Clinical Guardrails (`mg-mosaic-clinical`)

- **Subnet NSG Enforcement:** Enforces Network Security Groups on 100% of subnets.
- **Bastion / Jump Host Prohibition:** Prohibits direct RDP (3389) and SSH (22) from non-bastion IP space.
- **HIPAA CSF Benchmark:** Automatically applies the **Azure Security Benchmark v3** and **HITRUST CSF v11.0** compliance initiatives with real-time continuous evaluation.

---

## 3. Automated Subscription Vending Machine

To support rapid M&A integration and internal squad provisioning, Mosaic Healthcare utilizes a **Subscription Vending Machine (SVM)** pipeline driven by Terraform and GitHub Actions:

```mermaid
sequenceDiagram
    autonumber
    actor Architect as Enterprise Cloud Architect
    participant Portal as GitHub PR / ARB Review
    participant CI as Terraform GitHub Actions Runner
    participant Azure as Azure Resource Manager (ARM API)
    participant Sentinel as Microsoft Sentinel SIEM

    Architect->>Portal: Submit Subscription Request PR (JSON Manifest)
    Portal-->>Architect: Automated Linting & Policy Pre-Check
    Architect->>Portal: ARB Approval & Merge to Main
    CI->>Azure: Deploy Subscription via Azure Enterprise Agreement API
    Azure->>Azure: Move Subscription to Target Management Group
    Azure->>Azure: Apply Baseline Azure Policies & RBAC Roles
    Azure->>Azure: Peer VNet to Virtual WAN Hub & Deploy Private DNS Links
    Azure->>Sentinel: Emit Audit Event: Subscription Provisioned
    CI-->>Architect: Notification: Subscription Ready with Hardened Baseline
```

### Subscription Baseline Manifest Example

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "subscriptionName": "sub-mosaic-clinical-oncology-prod-01",
  "targetManagementGroup": "mg-mosaic-clinical",
  "primaryRegion": "eastus2",
  "secondaryRegion": "centralus",
  "costCenter": "CC-94102-CLINICAL-ONCOLOGY",
  "dataClassification": "PHI",
  "vnetCidrPrimary": "10.240.16.0/20",
  "vnetCidrSecondary": "10.241.16.0/20"
}
```
