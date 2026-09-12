# Incident Post-Mortem: Overnight FHIR API Rate-Limiting During Bulk Patient Sync

**Incident Date:** 2026-06-28  
**Impact Duration:** 28 minutes  
**Severity:** SEV-2  
**Root Cause:** Nightly ETL batch ingestion script dispatched 500 concurrent HTTP POST requests to Azure Health Data Services without client-side token bucket throttling, exhausting the provisioned 1,000 requests/sec limit and causing clinical dashboard sync failures.

## Timeline
* **02:00 UTC:** Nightly cron launched bulk patient intake pipeline.
* **02:03 UTC:** Azure FHIR API returned HTTP 429 (`TooManyRequests`) on 64% of inbound requests.
* **02:11 UTC:** Clinician night-shift triage reported portal sync latency exceeding 45 seconds.
* **02:18 UTC:** On-call engineer temporarily increased FHIR capacity units from 1 to 4 via Azure CLI.
* **02:28 UTC:** Bulk sync completed; capacity throttles returned to baseline.

## Corrective Actions
1. Implemented client-side exponential backoff with randomized jitter in `src/etl/fhir_sync.py`.
2. Added Azure Monitor alert `FHIRServiceThrottledRequests` triggering when 429 responses exceed 1% of total requests over a 5-minute window.
