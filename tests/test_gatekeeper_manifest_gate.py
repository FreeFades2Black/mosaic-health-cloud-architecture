"""
Unit tests for the Manifest Gatekeeper Ingress Gate.
Validates that infrastructure resource declarations pass the gatekeeper,
duplicates are dropped, and malformed resource declarations cause non-zero rejection.
"""

import pytest
from scripts.validate_manifests_gatekeeper import ManifestGatekeeper, collect_manifest_records


def test_collect_manifest_records_finds_infrastructure():
    records = collect_manifest_records()
    assert len(records) > 0
    # Must include terraform and dashboard declarations
    ids = [r["id"] for r in records]
    assert any("tf-manifest" in r_id for r_id in ids)
    assert any("azure_portal_build_dashboard" in r_id for r_id in ids)


def test_all_existing_declarations_valid():
    records = collect_manifest_records()
    gatekeeper = ManifestGatekeeper()

    for rec in records:
        status, _, error = gatekeeper.evaluate(rec["id"], rec["timestamp"], rec["payload"])
        assert status == "processed", f"Resource declaration {rec['id']} failed: {error}"

    gatekeeper.close()


def test_gatekeeper_halts_on_invalid_manifest():
    gatekeeper = ManifestGatekeeper()

    # Empty ID
    status, _, error = gatekeeper.evaluate("", 1728100000, "valid payload")
    assert status == "invalid"
    assert "blank" in (error or "").lower()

    # Empty payload
    status, _, error = gatekeeper.evaluate("res-corrupted-tf", 1728100000, "")
    assert status == "invalid"
    assert "empty" in (error or "").lower()

    gatekeeper.close()


def test_gatekeeper_deduplicates_repeated_declarations():
    gatekeeper = ManifestGatekeeper()

    # First arrival
    s1, _, _ = gatekeeper.evaluate("res-state-1", 1728100000, '{"state":"active"}')
    assert s1 == "processed"

    # Second arrival of same ID
    s2, _, _ = gatekeeper.evaluate("res-state-1", 1728100005, '{"state":"active"}')
    assert s2 == "duplicate"

    gatekeeper.close()
