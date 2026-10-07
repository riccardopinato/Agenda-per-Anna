#!/usr/bin/env python3
"""Validate v1.00-D physical certification evidence without inventing PASS."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

REQUIRED_SCENARIOS = {
    "DS-01", "DS-02", "DS-03", "DS-04", "DS-05", "DS-06",
    "VAULT-01", "VAULT-02", "VAULT-03", "VAULT-04",
    "NOI-01", "NOI-02", "NOI-03",
    "NATIVE-01", "NATIVE-02", "NATIVE-03",
}

HEX64 = re.compile(r"^[0-9a-fA-F]{64}$")


def fail(message: str) -> None:
    raise SystemExit(message)


def nonempty(value: object) -> bool:
    return isinstance(value, str) and bool(value.strip())


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("evidence")
    args = parser.parse_args()

    data = json.loads(Path(args.evidence).read_text(encoding="utf-8"))
    if data.get("schemaVersion") != 1:
        fail("Unsupported evidence schemaVersion")

    for key in (
        "repository",
        "commit",
        "appVersion",
        "artifactFile",
        "artifactSha256",
        "signingCertificateSha256",
        "workflowRunId",
        "channel",
    ):
        if not nonempty(str(data.get(key, ""))):
            fail(f"Missing evidence field: {key}")

    if not HEX64.fullmatch(str(data["artifactSha256"])):
        fail("artifactSha256 must be a 64-character hexadecimal digest")
    signing = str(data["signingCertificateSha256"]).replace(":", "")
    if not HEX64.fullmatch(signing):
        fail("signingCertificateSha256 must be a SHA-256 digest")

    devices = data.get("devices")
    if not isinstance(devices, list) or len(devices) < 2:
        fail("Two physical devices are required for the Noi shared-password gate")
    device_ids = set()
    for device in devices:
        if not isinstance(device, dict):
            fail("Invalid device record")
        for key in ("id", "model", "osVersion", "accountRole"):
            if not nonempty(device.get(key)):
                fail(f"Incomplete device field: {key}")
        device_ids.add(device["id"])

    scenarios = data.get("scenarios")
    if not isinstance(scenarios, list):
        fail("Missing scenarios")
    by_id = {}
    for scenario in scenarios:
        if not isinstance(scenario, dict) or not nonempty(scenario.get("id")):
            fail("Invalid scenario record")
        by_id[scenario["id"]] = scenario

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
        unknown = set(ids).difference(device_ids)
        if unknown:
            fail(f"{scenario_id} references unknown devices: {sorted(unknown)}")
        evidence_refs = scenario.get("evidenceRefs")
        if not isinstance(evidence_refs, list):
            fail(f"{scenario_id} evidenceRefs must be a list")

    for scenario_id in ("NOI-01", "NOI-02", "NOI-03"):
        if len(set(by_id[scenario_id]["deviceIds"])) < 2:
            fail(f"{scenario_id} requires two distinct physical devices")

    print("v1.00-D physical evidence: PASS")


if __name__ == "__main__":
    main()
