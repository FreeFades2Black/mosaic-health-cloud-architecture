# Audit Evidence & Centralized Logging Pipeline

<span class="badge badge-hitrust">Audit & Accountability</span>
<span class="badge badge-hipaa">7-Year Immutable WORM</span>

---

## 1. Enterprise Diagnostic Logging Pipeline

To satisfy **HIPAA § 164.312(b)** and **HITRUST Domain 09.0**, all system events, network flows, database queries, and identity authentications must be captured in real time, protected from tampering, and retained in an auditable immutable state for a minimum of **7 years**.

```mermaid
graph TD
    subgraph "Event & Telemetry Sources"
        EntraLogs["Entra ID Audit & Sign-In Logs"]
        ActivityLogs["Azure Subscription Activity Logs"]
        ResourceLogs["Resource Diagnostics<br/>(Key Vault, SQL, Storage, AKS)"]
        NetworkLogs["Azure Firewall & NSG Flow Logs"]
    end

    subgraph "Ingestion & Security Analytics Tier"
        DiagnosticSettings["Azure Diagnostic Settings<br/>(Enforced via Azure Policy)"]
        EventHub["Azure Event Hubs<br/>(High-Throughput Streaming Buffer)"]
        LogAnalytics["Log Analytics Central Workspace<br/><code>law-mosaic-mgmt-prod-01</code><br/>(Hot Tier: 730 Days Active Search)"]
        Sentinel["Microsoft Sentinel SIEM<br/>(Threat Intelligence & SOAR Playbooks)"]
    end

    subgraph "Long-Term Compliance Archive"
        ImmutableStorage["Azure Blob Immutable Storage<br/>(Time-Based Retention: 2,555 Days / 7 Years)<br/>WORM Policy + Legal Hold Capability"]
    end

    EntraLogs --> DiagnosticSettings
    ActivityLogs --> DiagnosticSettings
    ResourceLogs --> DiagnosticSettings
    NetworkLogs --> DiagnosticSettings

    DiagnosticSettings --> LogAnalytics
    DiagnosticSettings --> EventHub
    EventHub --> ImmutableStorage

    LogAnalytics --> Sentinel
    Sentinel -->|Automated Incident Alert| SOC["24/7 Healthcare SOC & Clinical Incident Lead"]
```

---

## 2. Retention Tiers & Lifecycle Management

| Storage Tier | Target Store | Retention Duration | Purpose & Access Pattern | Cost Optimization |
| :--- | :--- | :--- | :--- | :--- |
| **Hot Analytics Tier** | Azure Log Analytics Workspace | **730 Days (2 Years)** | Real-time threat hunting, KQL queries, incident investigation, interactive dashboards. | High performance indexing with daily ingestion commitment tiers. |
| **Archive Compliance Tier** | Azure Immutable Blob Storage | **2,555 Days (7 Years)** | Legal hold, OCR regulatory audits, forensic historical re-construction. | Cold / Archive blob tier with WORM policy locking. |

---

## 3. High-Priority Healthcare Threat Detection Rules (Sentinel)

Microsoft Sentinel is configured with custom healthcare analytics rules detecting anomalous activities on clinical endpoints and cryptographic keys:

### Rule 1: Mass ePHI Data Exfiltration Detection

```kusto
// Detect anomalous bulk download of patient files or database export
StorageBlobLogs
| where TimeGenerated > ago(1h)
| where OperationName == "GetBlob" or OperationName == "CopyBlob"
| summarize TotalBytes = sum(ResponseObjectSize), DownloadCount = count() by CallerIpAddress, AuthenticationType, UserAgent
| where TotalBytes > 10737418240 // > 10 GB in 1 hour
| order by TotalBytes desc
```

### Rule 2: Key Vault Secret Download Outside Maintenance Window

```kusto
// Alert on cryptographic key or secret extraction outside change window
AzureDiagnostics
| where TimeGenerated > ago(15m)
| where ResourceProvider == "MICROSOFT.KEYVAULT"
| where OperationName in ("SecretGet", "KeyDecrypt", "VaultGet")
| extend HourOfDay = hourofday(TimeGenerated)
| where HourOfDay < 6 or HourOfDay > 22 // Outside 06:00 - 22:00
| project TimeGenerated, OperationName, CallerIPAddress, identity_claim_upn_s, ResultSignature
```

### Rule 3: Unapproved PIM Elevation on Clinical Workload

```kusto
// Alert when administrative elevation occurs without linked Jira/ServiceNow change ticket
AuditLogs
| where TimeGenerated > ago(30m)
| where OperationName == "Add member to role in PIM completed"
| extend TargetRole = tostring(TargetResources[0].displayName)
| extend Initiator = tostring(InitiatedBy.user.userPrincipalName)
| where TargetRole in ("Owner", "User Access Administrator", "Key Vault Administrator")
| project TimeGenerated, OperationName, TargetRole, Initiator, Result
```
