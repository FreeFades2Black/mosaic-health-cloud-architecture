## Healthcare Portal Operational Overview
*Describe the clinical portal, FHIR integration, or HIPAA compliance change.*

- [ ] Clinician Portal Feature (Next.js / TypeScript)
- [ ] Entra ID / SMART-on-FHIR Authentication
- [ ] Azure Health Data Services (FHIR API) Schema
- [ ] HIPAA § 164.312 Audit Logging & WORM Storage

## HIPAA Security & Compliance Verification
- **PHI Impact Assessment:** Verified zero plaintext ePHI is logged to console or telemetry.
- **Audit Immutability:** Verified write-once-read-many (WORM) audit retention remains untouched.

## Verification Checklist
- [ ] Full test suite passed (17/17 tests): `python -m pytest tests/ -v`
- [ ] Entra ID auditor rules validated: `python -m pytest tests/test_entra_auditor.py`
- [ ] Next.js portal build verified
