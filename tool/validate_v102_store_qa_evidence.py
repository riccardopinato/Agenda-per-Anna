#!/usr/bin/env python3
"""Validate real Google Play / RevenueCat Store QA evidence fail-closed."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
from pathlib import Path


REQUIRED_SCENARIOS = {
    "STORE-01",  # installed from Internal Testing + runtime catalog ready
    "STORE-02",  # monthly purchase grants entitlement
    "STORE-03",  # monthly survives restart
    "STORE-04",  # monthly reinstall + restore
    "STORE-05",  # lifetime purchase grants entitlement
    "STORE-06",  # lifetime survives restart
    "STORE-07",  # lifetime reinstall + restore
    "STORE-08",  # cancelled/pending/failed path grants nothing
    "STORE-09",  # repeated delivery/restore remains idempotent
}

HEX64 = re.compile(r"^[0-9a-fA-F]{64}$")


def fail(message: str) -> None:
    raise SystemExit(message)


def load_json(path: Path, label: str) -> dict:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        fail(f"Unable to read {label}: {exc}")
    if not isinstance(value, dict):
        fail(f"{label} must contain a JSON object")
    return value


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def nonempty(value: object) -> bool:
    return isinstance(value, str) and bool(value.strip())


def digest(value: object, field: str) -> str:
    if not nonempty(value):
        fail(f"Missing {field}")
    normalized = str(value).replace(":", "").replace(" ", "")
    if not HEX64.fullmatch(normalized):
        fail(f"{field} must be a SHA-256 digest")
    return normalized.lower()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("evidence")
    parser.add_argument("--release-reality", required=True)
    parser.add_argument("--artifact", required=True)
    args = parser.parse_args()

    evidence = load_json(Path(args.evidence), "Store QA evidence")
    reality = load_json(Path(args.release_reality), "Release Reality")
    artifact = Path(args.artifact)

    if evidence.get("schemaVersion") != 1:
        fail("Unsupported Store QA evidence schemaVersion")
    if reality.get("schemaVersion") != 1:
        fail("Unsupported Release Reality schemaVersion")
    if reality.get("evidenceType") != "release_reality":
        fail("Unexpected Release Reality evidenceType")
    if reality.get("validationLevel") != "ARTIFACT_BUILT":
        fail("Store QA candidate must start from ARTIFACT_BUILT")
    if not artifact.is_file():
        fail(f"Artifact not found: {artifact}")

    actual_artifact = sha256_file(artifact)
    reality_artifact = digest(reality.get("artifactSha256"), "Release Reality artifactSha256")
    evidence_artifact = digest(evidence.get("artifactSha256"), "evidence artifactSha256")
    if actual_artifact != reality_artifact:
        fail("Release Reality does not match supplied AAB bytes")
    if evidence_artifact != reality_artifact:
        fail("Store QA evidence does not match Release Reality artifact")

    identity = {
        "repository": "repository",
        "sourceSha": "sourceSha",
        "version": "version",
        "buildNumber": "buildNumber",
        "packageId": "packageId",
        "artifactName": "artifactName",
        "workflowRun": "workflowRun",
        "distributionChannel": "distributionChannel",
    }
    for evidence_key, reality_key in identity.items():
        if evidence.get(evidence_key) != reality.get(reality_key):
            fail(f"Store QA identity mismatch: {evidence_key}")

    evidence_signing = digest(
        evidence.get("signingFingerprint"),
        "evidence signingFingerprint",
    )
    reality_signing = digest(
        reality.get("signingFingerprint"),
        "Release Reality signingFingerprint",
    )
    if evidence_signing != reality_signing:
        fail("Store QA signing fingerprint mismatch")

    if evidence.get("distributionChannel") != "google-play-internal-testing-candidate":
        fail("Store QA must use the Internal Testing candidate channel")
    if evidence.get("playTrack") != "internal-testing":
        fail("Store QA evidence must identify the Internal Testing track")
    if evidence.get("installSource") != "google-play":
        fail("Sideloaded builds cannot certify billing")
    if not nonempty(evidence.get("testerRef")):
        fail("Store QA evidence requires a non-secret tester reference")
    if evidence.get("status") != "PASS":
        fail("Store QA evidence is not PASS")

    scenarios = evidence.get("scenarios")
    if not isinstance(scenarios, list):
        fail("Missing Store QA scenarios")

    by_id: dict[str, dict] = {}
    for raw in scenarios:
        if not isinstance(raw, dict) or not nonempty(raw.get("id")):
            fail("Invalid Store QA scenario")
        scenario_id = str(raw["id"]).strip()
        if scenario_id in by_id:
            fail(f"Duplicate Store QA scenario: {scenario_id}")
        by_id[scenario_id] = raw

    missing = REQUIRED_SCENARIOS.difference(by_id)
    if missing:
        fail("Missing Store QA scenarios: " + ", ".join(sorted(missing)))

    for scenario_id in sorted(REQUIRED_SCENARIOS):
        scenario = by_id[scenario_id]
        if scenario.get("status") != "PASS":
            fail(f"{scenario_id} is not PASS")
        if not nonempty(scenario.get("expected")):
            fail(f"{scenario_id} missing expected result")
        if not nonempty(scenario.get("observed")):
            fail(f"{scenario_id} missing observed result")
        refs = scenario.get("evidenceRefs")
        if not isinstance(refs, list) or not refs:
            fail(f"{scenario_id} requires evidenceRefs")
        if any(not nonempty(ref) for ref in refs):
            fail(f"{scenario_id} has invalid evidenceRefs")

    print("v1.02-C Google Play / RevenueCat Store QA evidence: PASS")


if __name__ == "__main__":
    main()
