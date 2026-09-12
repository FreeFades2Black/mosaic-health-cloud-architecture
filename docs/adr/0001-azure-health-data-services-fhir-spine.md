# ADR-0001: Standardizing on Azure Health Data Services Managed FHIR API Spine

**Status:** Accepted  
**Date:** 2026-05-14  
**Lead Architect:** William Free Hall (Free) <whall4.wh@gmail.com>

## 1. Context & Operational Challenge
Our clinical portal integrates electronic health records (EHR) from regional hospital networks. We needed a FHIR R4-compliant data spine providing strict HIPAA compliance, HITRUST certification, and role-based clinician access control via Entra ID.

## 2. Options Considered
* **Option A: Self-Hosted HAPI FHIR Server on Azure Kubernetes Service (AKS)**
  - *Evaluation:* Lower raw compute cost, but requires maintaining custom database partitioning, manual HL7 schema upgrades, and managing HITRUST CSF assessment compliance boundaries independently.
* **Option B: Managed Azure Health Data Services (FHIR Service)**
  - *Evaluation:* Out-of-the-box HIPAA BAA coverage, native Entra ID SMART-on-FHIR OAuth2 scopes, automated Cosmos DB multi-region replication, and managed search parameter re-indexing.

## 3. Decision & Trade-Off Accepted
We adopted **Option B (Azure Health Data Services)**.  
**Trade-Off Accepted:** Azure charges per-structured-request ($0.0001 per request + $0.05/GB storage). We accept the usage-based operational cost in exchange for zero infrastructure compliance management overhead.
