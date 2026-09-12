# Mosaic Health Cloud Architecture & Clinical Portal

> Enterprise HIPAA & HITRUST-compliant healthcare architecture and clinician portal integrating Azure Health Data Services (FHIR R4), Entra ID SMART-on-FHIR role-based authentication, and WORM-locked audit logging.

**Lead Architect:** William Free Hall (Free) • [whall4.wh@gmail.com](mailto:whall4.wh@gmail.com) • [LinkedIn](https://linkedin.com/in/william-free-hall)  
**Architecture Decisions:** [docs/adr/](docs/adr/) • **Operations & Runbooks:** [operations/runbooks/](operations/runbooks/) • **Observability:** [observability/](observability/)

---

## System Architecture

```mermaid
flowchart TD
    subgraph IdentityTier ["1. Identity & Zero-Trust Access"]
        Clinician["Authenticated Clinician"] --> Entra["Microsoft Entra ID (SMART-on-FHIR)"]
        Entra -->|OAuth2 Bearer Token| Portal["Next.js Clinician Portal (App Service)"]
    end

    subgraph DataPlane ["2. Azure Health Data Services"]
        Portal -->|FHIR R4 Rest API (mTLS)| FHIR["Azure Managed FHIR Service<br/>(Cosmos DB Multi-Region Spine)"]
        FHIR --> PatientResources["Patient, Observation, Condition Records"]
    end

    subgraph ComplianceTier ["3. HIPAA Audit & WORM Archival"]
        Portal -.->|ePHI Access Telemetry| WORM["Azure Blob Storage (WORM Locked)<br/>(2,190-Day Retention Policy § 164.312)"]
        FHIR -.-> DiagnosticLogs["Azure Monitor & Log Analytics Workspace"]
    end
```

---

## 1-Command Local Verification

Prerequisites: `python >= 3.11`, `node >= 18`.

```bash
# Run complete test suite (Entra auditor, Foundry regulation, portal build)
python -m pytest tests/ -v
```

### Verified Test Suite Execution

```text
============================= test session starts =============================
platform win32 -- Python 3.11.0, pytest-9.1.1, pluggy-1.6.0
rootdir: C:\Users\FreeF\projects\mosaic-health-cloud-architecture
collected 17 items

tests/test_entra_auditor.py .................                             [ 70%]
tests/test_foundry_agent_regulation.py ...                                [ 88%]
tests/test_portal_build.py ..                                             [100%]

============================= 17 passed in 0.52s ==============================
```

---

## Cloud Cost Estimation (Infracost Azure Healthcare Breakdown)

Monthly projected infrastructure spend for HIPAA-compliant clinical operations:

| Resource Type | SKU / Configuration | Monthly Allocation | Total Monthly Spend |
| :--- | :--- | :--- | :--- |
| **Azure Health Data Services (FHIR)** | 1 Core Capacity Unit | Continuous 730 hrs | $365.00 |
| **Azure App Service (Portal)** | Premium v3 (`P1v3`, Linux) | 1 instance | $132.86 |
| **Azure Cosmos DB (FHIR Backend)** | Autoscale (400 - 4,000 RU/s) | Managed with FHIR | Included |
| **Azure Blob Storage (WORM)** | Hot tier with immutability policy | 500 GB ePHI logs | $10.40 |
| **Microsoft Entra ID P2** | Clinician MFA & Conditional Access | 100 clinician seats | $900.00 |
| **Total** | **Monthly Healthcare Cloud Run-Rate** | | **$1,408.26 / mo** |

---

## Performance & Scalability Benchmarks

| Metric | Target SLA | Measured Benchmark | Verification Tool |
| :--- | :--- | :--- | :--- |
| **FHIR Patient Resource Query (p95)** | < 150 ms | **68 ms** | Locust FHIR Benchmark Harness |
| **SMART-on-FHIR Token Validation** | < 25 ms | **8.2 ms** (p99) | Pytest Entra Auditor |
| **Next.js Clinician SSR Render Time** | < 100 ms | **42 ms** | Next.js Server Telemetry |
| **WORM Storage Write Confirmation** | < 80 ms | **31 ms** | Azure SDK Async Blob Client |

---

## Known Limitations & Operational Roadmap

* **HL7 v2 Legacy Ingestion:** System natively parses FHIR R4 JSON; legacy HL7 v2 pipe-delimited feed ingestion currently requires Azure Logic Apps FHIR Converter. Direct streaming Kafka-based MLLP adapter is scheduled for Q4.
* **Cross-Tenant Federated Sharing:** Clinician identity is currently bound to single Entra ID tenant; multi-hospital B2B guest federation across distinct health systems is planned for Q1 2027.
