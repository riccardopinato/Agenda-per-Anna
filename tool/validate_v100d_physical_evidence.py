#!/usr/bin/env python3
"""Validate v1.00-D physical certification evidence without inventing PASS."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
from pathlib import Path

REQUIRED_SCENARIOS = {
    "DS-01", "DS-02", "DS-03", "DS-04", "DS-05", "DS-06",
    "VAULT-01", "VAULT-02", "VAULT-03", "VAULT-04",
    "NOI-01", "NOI-02", "NOI-03",
    "NATIVE-01", "NATIVE-02", "NATIVE-03",
}

IDENTITY_FIELDS = (
    "repository",
    "commit",
    "appVersion",
    "artifactFile",
    "workflowRunId",
    "channel",
)

HEX64 = re.compile(r"^[0-9a-fA-F]{64}$")


def fail(message: str) -> None:
    raise SystemExit(message)


def nonempty(value: object) -> bool:
    return isinstance(value, str) and bool(value.strip())


def normalized_digest(value: object, field: str) -> str:
    if not nonempty(value):
        fail(f"Missing evidence field: {field}")
    digest = str(value).replace(":", "").replace(" ", "")
    if not HEX64.fullmatch(digest):
        fail(f"{field} must be a 64-character hexadecimal SHA-256 digest")
    return digest.lower()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def load_json(path: Path, label: str) -> dict:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        fail(f"Unable to read {label}: {exc}")
    if not isinstance(value, dict):
        fail(f"{label} must contain a JSON object")
    return value


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("evidence")
    parser.add_argument("--manifest", required=True)
    parser.add_argument("--artifact", required=True)
    args = parser.parse_args()

    evidence_path = Path(args.evidence)
    manifest_path = Path(args.manifest)
    artifact_path = Path(args.artifact)

    data = load_json(evidence_path, "evidence")
    manifest = load_json(manifest_path, "candidate manifest")

    if data.get("schemaVersion") != 1:
        fail("Unsupported evidence schemaVersion")
    if manifest.get("schemaVersion") != 1:
        fail("Unsupported candidate manifest schemaVersion")
    if manifest.get("evidenceType") != "physical_certification_candidate":
        fail("Candidate manifest has unexpected evidenceType")
    if not artifact_path.is_file():
        fail(f"Candidate artifact not found: {artifact_path}")

    for key in IDENTITY_FIELDS:
        if not nonempty(data.get(key)):
            fail(f"Missing evidence field: {key}")
        if not nonempty(manifest.get(key)):
            fail(f"Missing candidate manifest field: {key}")
        if str(data[key]).strip() != str(manifest[key]).strip():
            fail(f"Evidence identity mismatch for {key}")

    evidence_artifact_sha = normalized_digest(
        data.get("artifactSha256"),
        "artifactSha256",
    )
    manifest_artifact_sha = normalized_digest(
        manifest.get("artifactSha256"),
        "candidate artifactSha256",
    )
    actual_artifact_sha = sha256_file(artifact_path)
    if manifest_artifact_sha != actual_artifact_sha:
        fail("Candidate artifact SHA-256 does not match the artifact bytes")
    if evidence_artifact_sha != manifest_artifact_sha:
        fail("Evidence artifact SHA-256 does not match the candidate manifest")

    evidence_signing_sha = normalized_digest(
        data.get("signingCertificateSha256"),
        "signingCertificateSha256",
    )
    manifest_signing_sha = normalized_digest(
        manifest.get("signingCertificateSha256"),
        "candidate signingCertificateSha256",
    )
    if evidence_signing_sha != manifest_signing_sha:
        fail("Evidence signing certificate does not match the candidate manifest")

    if Path(str(data["artifactFile"])).name != artifact_path.name:
        fail("artifactFile does not identify the supplied artifact")

    devices = data.get("devices")
    if not isinstance(devices, list) or len(devices) < 2:
        fail("Two physical devices are required for the Noi shared-password gate")

    device_ids: set[str] = set()
    role_devices: dict[str, set[str]] = {"owner": set(), "member": set()}
    for device in devices:
        if not isinstance(device, dict):
            fail("Invalid device record")
        for key in ("id", "model", "osVersion", "accountRole"):
            if not nonempty(device.get(key)):
                fail(f"Incomplete device field: {key}")
        device_id = str(device["id"]).strip()
        if device_id in device_ids:
            fail(f"Duplicate physical device id: {device_id}")
        device_ids.add(device_id)
        role = str(device["accountRole"]).strip().lower()
        if role not in role_devices:
            fail(f"Unsupported accountRole for {device_id}: {role}")
        role_devices[role].add(device_id)

    if not role_devices["owner"] or not role_devices["member"]:
        fail("Physical evidence requires distinct owner and member accounts")
    if role_devices["owner"].intersection(role_devices["member"]):
        fail("The same device cannot be both owner and member in this evidence")

    scenarios = data.get("scenarios")
    if not isinstance(scenarios, list):
        fail("Missing scenarios")

    by_id: dict[str, dict] = {}
    for scenario in scenarios:
        if not isinstance(scenario, dict) or not nonempty(scenario.get("id")):
            fail("Invalid scenario record")
        scenario_id = str(scenario["id"]).strip()
        if scenario_id in by_id:
            fail(f"Duplicate scenario id: {scenario_id}")
        by_id[scenario_id] = scenario

    missing = REQUIRED_SCENARIOS.difference(by_id)
    if missing:
        fail("Missing mandatory scenarios: " + ", ".join(sorted(missing)))

    for scenario_id in sorted(REQUIRED_SCENARIOS):
        scenario = by_id[scenario_id]
        if scenario.get("status") != "PASS":
            fail(f"{scenario_id} is not PASS")
        if not nonempty(scenario.get("expected")):
            fail(f"{scenario_id} missing expected result")
        if not nonempty(scenario.get("observed")):
            fail(f"{scenario_id} missing observed result")

        ids = scenario.get("deviceIds")
        if not isinstance(ids, list) or not ids:
            fail(f"{scenario_id} missing deviceIds")
        if len(ids) != len(set(ids)):
            fail(f"{scenario_id} repeats a physical device id")
        unknown = set(ids).difference(device_ids)
        if unknown:
            fail(f"{scenario_id} references unknown devices: {sorted(unknown)}")

        evidence_refs = scenario.get("evidenceRefs")
        if not isinstance(evidence_refs, list):
            fail(f"{scenario_id} evidenceRefs must be a list")
        if any(not nonempty(ref) for ref in evidence_refs):
            fail(f"{scenario_id} contains an invalid evidence reference")

    for scenario_id in ("NOI-01", "NOI-02", "NOI-03"):
        ids = set(by_id[scenario_id]["deviceIds"])
        if not ids.intersection(role_devices["owner"]):
            fail(f"{scenario_id} must include the owner device/account")
        if not ids.intersection(role_devices["member"]):
            fail(f"{scenario_id} must include the member device/account")
        if len(ids) < 2:
            fail(f"{scenario_id} requires two distinct physical devices")

    print("v1.00-D physical evidence: PASS")


if __name__ == "__main__":
    main()
