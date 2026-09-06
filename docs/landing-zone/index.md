# Azure Landing Zone & Hybrid Backbone Architecture

<span class="badge badge-prod">Enterprise Landing Zone</span>
<span class="badge badge-hitrust">HITRUST CSF v11</span>

---

## Strategic Blueprint Overview

The **Mosaic Healthcare Azure Landing Zone** is architected in alignment with the **Microsoft Cloud Adoption Framework (CAF)** and custom tailored for high-acuity healthcare workloads, HIPAA compliance, and multi-facility operational resilience.

The architecture enforces strict operational separation across **Management**, **Connectivity**, **Identity**, and **Workload** domains, ensuring that compromised developer credentials or experimental sandbox failures cannot penetrate clinical environments containing Protected Health Information (PHI).

```mermaid
graph TB
    subgraph "Mosaic Enterprise Tenant Root"
        RootMG["Mosaic Healthcare Root Management Group<br/>(Policy: Deny Public IPs, Enforce CMK, Require TLS 1.3)"]
        
        subgraph "Platform Services Domain"
            PlatformMG["Platform Management Group"]
            MgmtSub["Management Subscription<br/>• Log Analytics Central<br/>• Sentinel SIEM<br/>• Azure Monitor / Automation"]
            ConnSub["Connectivity Subscription<br/>• Azure Virtual WAN Hub<br/>• Azure Firewall Premium<br/>• ExpressRoute Gateway<br/>• Private DNS Zones"]
            IdSub["Identity Subscription<br/>• Entra ID Domain Services<br/>• Domain Controllers (PaaS/IaaS)<br/>• Conditional Access Policies"]
        end
        
        subgraph "Landing Zones Domain"
            LandingMG["Landing Zones Management Group"]
            ClinicalSub["Clinical Core Subscription<br/>• Epic / Cerner EHR Clusters<br/>• FHIR / HL7 Ingestion Services<br/>• Private Endpoint Key Vault"]
            LakehouseSub["Healthcare Lakehouse Subscription<br/>• Databricks Unity Catalog<br/>• Azure Data Lake Gen2 (ADLS)<br/>• TimesFM-3 Capacity Forecasters"]
            CorpSub["Corporate & Shared Services<br/>• Billing & Revenue Cycle<br/>• HR & Supply Chain ERP"]
        end
        
        subgraph "Sandboxes & Decommissioned"
            SandboxMG["Sandbox & Quarantine Management Group<br/>(Isolated, Strict Budget Caps, No Clinical Data)"]
        end
    end

    RootMG --> PlatformMG
    RootMG --> LandingMG
    RootMG --> SandboxMG

    PlatformMG --> MgmtSub
    PlatformMG --> ConnSub
    PlatformMG --> IdSub

    LandingMG --> ClinicalSub
    LandingMG --> LakehouseSub
    LandingMG --> CorpSub
```

---

## Core Landing Zone Sub-Sections

- **[Management Group Hierarchy & Policy Governance](management-groups.md)**  
  Detailed taxonomy of management groups, hierarchical subscription placement, Azure Policy initiatives, and automated guardrails enforcing HITRUST CSF standards.
- **[Hybrid Networking & Virtual WAN Backbone](hybrid-networking.md)**  
  Virtual WAN architecture, Secured Hub design with Azure Firewall Premium, ExpressRoute 10Gbps circuits, dual IPsec VPN fallback, and zero-trust private link endpoints.
- **[Identity, Entra ID & Privileged Access Management](identity-access.md)**  
  Hybrid identity synchronization, phishing-resistant FIDO2 MFA, Just-in-Time (JIT) Privileged Identity Management (PIM), and role-based access control (RBAC) tiers.
