# Wave Migration Sequencer & Rollback Triggers

<span class="badge badge-prod">Migration Sequencer</span>
<span class="badge badge-hitrust">High-Acuity Resilience</span>

---

## 1. 5-R Workload Rationalization Engine

When an acquisition is finalized, every discovered server, database, and clinical microservice is classified into one of five rationalization buckets:

```mermaid
graph TD
    App[Discovered Application / Workload] --> Evaluation{Architectural Assessment}

    Evaluation -->|Legacy Monolith / Fixed Vendor Support| Rehost["1. REHOST (Lift & Shift)<br/>Azure Migrate VM Replication"]
    Evaluation -->|Standardized Web/App / Containerizable| Replatform["2. REPLATFORM<br/>Azure App Service / AKS Microservices"]
    Evaluation -->|Monolithic EHR Replacement| Refactor["3. REFACTOR<br/>Migrate to Enterprise Core Epic SaaS/Azure PaaS"]
    Evaluation -->|Medical Modality Hardware Bound| Retain["4. RETAIN<br/>Isolate on Local Clinic Edge VLAN"]
    Evaluation -->|Redundant / Duplicate Capability| Retire["5. RETIRE<br/>Archive Data & Decommission VM"]
```

---

## 2. 4-Phase Wave Execution Sequencer

Workloads migrate in structured waves to eliminate blast radius and ensure emergency department and ICU clinical operations remain uninterrupted.

```mermaid
gantt
    title M&A 90-Day Wave Migration Timeline
    dateFormat  YYYY-MM-DD
    section Phase 0: Foundation
    Transit VNet & NAT Deployment      :done,    p0_1, 2026-09-01, 10d
    Azure Migrate Appliance Install    :done,    p0_2, 2026-09-05, 7d
    EDR Deployment & Sentinel Onboard  :active,  p0_3, 2026-09-08, 8d
    section Phase 1: Corporate Pilot
    Active Directory Sync & O365 Coex  :p1_1, 2026-09-15, 14d
    Corporate ERP & Intranet Migration :p1_2, 2026-09-20, 10d
    section Phase 2: Tier-2 Clinical
    PACS Archive Data Hydration        :p2_1, 2026-09-28, 20d
    Lab & Pharmacy Interface Testing   :p2_2, 2026-10-05, 15d
    section Phase 3: Tier-1 Core EHR
    Epic EHR Delta Sync & Validation   :p3_1, 2026-10-20, 7d
    Go-Live Final Cutover Window (4h)  :milestone, p3_cut, 2026-10-27, 0d
    Decommission Legacy Hardware       :p3_2, 2026-10-28, 14d
```

### Phase Details

1. **Phase 0: Foundation & Network Quarantine (Days 1–15)**
   - Deploy Transit VNet (`10.245.0.0/20`) with Azure Firewall inspection.
   - Establish Site-to-Site IPsec VPN to acquired datacenter.
   - Deploy Azure Migrate Hyper-V / VMware virtual appliance.
   - Install CrowdStrike / Defender for Endpoint agents on all endpoints.

2. **Phase 1: Pilot & Corporate Systems (Days 16–30)**
   - Synchronize Entra ID identities via Entra Cloud Sync.
   - Migrate file servers, payroll ERP, and internal intranet portals.
   - Verify identity federation and Conditional Access enforcement.

3. **Phase 2: Tier-2 Clinical Supporting Systems (Days 31–60)**
   - Pre-seed secondary PACS imaging archives (DICOM studies > 2 years old) to Azure Blob Storage (Cold Tier).
   - Replatform Lab Information Systems (LIS) and Pharmacy dispensing interfaces to containerized AKS clusters.

4. **Phase 3: Tier-1 EHR Core Cutover (Days 61–90)**
   - Initialize continuous database block-level replication (Azure Site Recovery / Always On Availability Groups).
   - Execute scheduled 4-hour weekend cutover window during low clinical census.

---

## 3. Pre-Flight Go/No-Go Gate Criteria

Prior to commencing any final production cutover, all six pre-flight criteria must be certified by the Incident Commander:

```
[ ] 1. Data Replication Lag: < 1.0 seconds across all database replicas.
[ ] 2. Identity Verification: 100% of clinicians authenticated successfully via Entra ID MFA.
[ ] 3. Network Latency: Round-trip time (RTT) from clinic edge to Azure Virtual WAN Hub < 18ms.
[ ] 4. Rollback Snapshots: Immutable SAN snapshot and Azure backup verified.
[ ] 5. ARB Sign-Off: Lead Clinical Informaticist and CISO formal sign-off recorded.
[ ] 6. Help Desk Preparedness: Dedicated high-priority triage queue active with 24/7 staffing.
```

---

## 4. Automated Rollback Triggers & Runbook

If any critical failure threshold is exceeded during the cutover window, the automated rollback trigger is engaged:

```mermaid
flowchart TD
    CutoverStart[Cutover Execution Window Initiated] --> Monitor{Continuous Metric Monitoring}

    Monitor -->|Condition A: Database Lag > 120s| EngageRollback[Engage Automated Rollback]
    Monitor -->|Condition B: Clinical Interface Error Rate > 0.5%| EngageRollback
    Monitor -->|Condition C: Network Packet Loss > 2% for 5 mins| EngageRollback
    Monitor -->|All Metrics Nominal| Validate[Clinical Workflow Validation Passed]

    Validate --> Finalize[Commit Cutover & Update DNS Records]

    EngageRollback --> R1[1. Revert BGP Route Announcement to Legacy DC]
    R1 --> R2[2. Power On Source Hypervisors from Quiesced State]
    R2 --> R3[3. Re-enable Legacy HL7 Interface Engines]
    R3 --> R4[4. Notify ARB & Incident Management Channel]
```

### Rollback Metric Thresholds

| Trigger Code | Metric Monitored | Critical Threshold | Automated Action |
| :--- | :--- | :--- | :--- |
| **TRG-01** | Database Replication Lag | > 120 seconds for > 3 minutes | Halt cutover; failback to primary on-prem cluster. |
| **TRG-02** | HL7 Interface Message Drops | > 10 unacknowledged messages | Revert MLLP DNS routes to on-prem interface engine. |
| **TRG-03** | End-to-End Synthetic Latency | RTT > 45ms for > 5 minutes | Re-route clinical traffic via backup MPLS circuit. |
| **TRG-04** | Clinician Login Failure Rate | > 2.0% failed authentications | Re-enable legacy AD federation endpoint temporarily. |
