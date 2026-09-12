# Operational Runbook: Clinician Portal Authentication & Entra ID SMART-on-FHIR Triage

**Severity:** P2 / Clinician Portal Authentication Interruption  
**Target Systems:** Entra ID, Azure Health Data Services, Clinician Next.js Portal

## Diagnostic Workflow

### 1. Check Entra ID Sign-in Logs for Failed Token Grants
```bash
az monitor activity-log list \
  --namespace Microsoft.AAD \
  --start-time $(date -u -d '1 hour ago' +%FT%TZ) \
  --query '[?contains(caller, "clinician")]'
```

### 2. Verify SMART-on-FHIR OAuth2 Token Scopes
Clinicians require explicit FHIR scopes (`launch/patient`, `patient/*.read`, `openid`).
Verify received JWT claims:
```bash
python -m src.entra_auditor --verify-jwt-payload /tmp/token.jwt
```

### 3. Diagnose 429 FHIR Throttling During Overnight Bulk Sync
```bash
az healthcareapis workspace fhir-service show \
  --name mosaic-fhir-prod \
  --resource-group mosaic-health-rg \
  --workspace-name mosaic-workspace
```
If throughput throttled, scale FHIR capacity units from 1 to 4 via CLI:
```bash
az healthcareapis workspace fhir-service update \
  --name mosaic-fhir-prod \
  --resource-group mosaic-health-rg \
  --workspace-name mosaic-workspace \
  --capacity 4
```
