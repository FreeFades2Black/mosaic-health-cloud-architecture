# ADR-0002: Immutable Audit Logging via Azure Blob WORM Storage for HIPAA § 164.312(b)

**Status:** Accepted  
**Date:** 2026-06-02  
**Lead Architect:** William Free Hall (Free) <whall4.wh@gmail.com>

## 1. Context & Operational Challenge
HIPAA Security Rule § 164.312(b) mandates that electronic protected health information (ePHI) access logs must be immutable and retained for a minimum of 6 years, tamper-proof against deletion even by global subscription administrators.

## 2. Options Considered
* **Option A: Log Analytics Workspace with Data Export Rules**
  - *Evaluation:* Standard querying in KQL, but retention caps at 2 years without archival, and storage administrators can delete or truncate historical tables.
* **Option B: Azure Blob Storage with Time-Based Immutability (WORM) Legal Hold Policies**
  - *Evaluation:* Write-Once-Read-Many (WORM) compliant storage locks blob versions; neither root users nor automated scripts can delete objects before the 2,190-day retention lock expires.

## 3. Decision & Trade-Off Accepted
We adopted **Option B (Azure Blob WORM Storage)**.  
**Trade-Off Accepted:** Objects written to the audit container cannot be purged or compressed retrospectively; lifecycle tiering rules must be carefully defined to archive blobs to Cold/Archive storage without violating WORM retention locks.
