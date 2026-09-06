# Compliance & HITRUST CSF Governance

<span class="badge badge-hitrust">HITRUST CSF v11</span>
<span class="badge badge-hipaa">HIPAA Security Rule</span>

---

## 1. Healthcare Regulatory Landscape

Operating cloud infrastructure hosting electronic Protected Health Information (ePHI) requires continuous compliance with federal mandates and cybersecurity frameworks. Mosaic Healthcare maps every cloud resource, network route, and identity token to the **HITRUST Common Security Framework (CSF) v11** and the **HIPAA Security & Privacy Rules (45 CFR Part 160 and Part 164)**.

```mermaid
graph TD
    subgraph "Federal & Industry Mandates"
        HIPAA["HIPAA Security & Privacy Rules<br/>(45 CFR Part 164 Subparts C & E)"]
        HITECH["HITECH Act<br/>(Breach Notification & Audit)"]
        HITRUST["HITRUST CSF v11.0<br/>(19 Control Domains / 156 Control Specs)"]
    end

    subgraph "Mosaic Governance & Policy Layer"
        AzPolicy["Azure Policy Built-in HITRUST Initiatives<br/>(Continuous Audit & Automated Deny)"]
        SentinelSIEM["Microsoft Sentinel SIEM<br/>(Audit Evidence & Threat Hunting)"]
        CryptoVault["Gunslinger Key Vault<br/>(FIPS 140-2 Level 3 HSM CMK)"]
    end

    subgraph "Technical Enforcement"
        T1["Encryption at Rest (RSA 4096 / AES-256-GCM)"]
        T2["Zero-Trust Microsegmentation (Azure FW IDPS)"]
        T3["Immutable Audit Logs (7-Year Legal Hold Blob)"]
        T4["Privileged JIT Elevation (Entra ID PIM)"]
    end

    HIPAA --> AzPolicy
    HITECH --> SentinelSIEM
    HITRUST --> AzPolicy

    AzPolicy --> T1
    AzPolicy --> T2
    SentinelSIEM --> T3
    AzPolicy --> T4
    CryptoVault --> T1
```

---

## 2. Core Compliance Artifacts

- **[HITRUST & HIPAA Control Mapping Matrix](control-mapping-matrix.md)**  
  Comprehensive, searchable matrix mapping HITRUST CSF v11 domains directly to Azure technical implementations, Azure Policy IDs, and evidence verification mechanisms.
- **[Audit Evidence & Centralized Logging Pipeline](audit-evidence-logging.md)**  
  Architecture and deployment patterns for real-time diagnostic log ingestion, Microsoft Sentinel analytics rules, and WORM (Write Once, Read Many) compliant long-term audit storage.
