#!/usr/bin/env python3
"""Check completeness/shape of Anna's Diary two-PWA Vision Board evidence.

This is a structural validator only; it cannot prove physical device testing.
"""
from __future__ import annotations

import argparse
import datetime as dt
import json
import re
from pathlib import Path

REQUIRED = {f"S13-{i:02d}" for i in range(1, 17)} | {
    f"PWA-{i:02d}" for i in range(1, 15)
}
PERFORMANCE = {"S13-16", "PWA-13"}
STATUS = {"NOT_VERIFIED", "NOT_MEASURED", "BLOCKED", "FAIL", "PASS"}
SHA = re.compile(r"^[0-9a-f]{40}$")
METRICS = {"coldMs", "warmMs", "saveMs", "memoryMiB"}


def _present(value: object) -> bool:
    return isinstance(value, str) and bool(value.strip())


def _timestamp(value: object) -> bool:
    if not _present(value):
        return False
    try:
        parsed = dt.datetime.fromisoformat(str(value).replace("Z", "+00:00"))
        return parsed.tzinfo is not None and parsed.utcoffset() is not None
    except ValueError:
        return False


def validate(evidence: dict, *, require_complete: bool = False) -> dict:
    if not isinstance(evidence, dict):
        raise ValueError("Evidence must be an object")
    if evidence.get("schemaVersion") != 1 or evidence.get("evidenceType") != "anna_vision_board_two_pwa_physical_qa":
        raise ValueError("Invalid evidence type/version")
    if evidence.get("repository") != "riccardopinato/Agenda-per-Anna":
        raise ValueError("Wrong repository")
    if evidence.get("factoryBaseline") != "ee72dbb1b0de2cd71bc4aac42c350853c6915159":
        raise ValueError("Wrong Factory baseline")
    if evidence.get("publishedUrl") != "https://riccardopinato.github.io/Agenda-per-Anna/":
        raise ValueError("Unexpected deployment origin")
    devices = evidence.get("devices")
    if not isinstance(devices, dict) or set(devices) != {"A", "B"}:
        raise ValueError("Expected two explicitly described PWA devices A/B")
    for key in ("A", "B"):
        item = devices[key]
        if not isinstance(item, dict) or item.get("reference") != key:
            raise ValueError(f"Invalid device {key}")

    cases = evidence.get("scenarios")
    if not isinstance(cases, list):
        raise ValueError("Missing scenarios list")
    ids = [item.get("id") if isinstance(item, dict) else None for item in cases]
    if len(ids) != len(set(ids)) or set(ids) != REQUIRED:
        raise ValueError("Duplicate, missing or unexpected scenario IDs")

    counts = {x: 0 for x in STATUS}
    for case in cases:
        case_id = case["id"]
        status = case.get("status")
        if status not in STATUS:
            raise ValueError(f"{case_id}: invalid status")
        if status == "NOT_MEASURED" and case_id not in PERFORMANCE:
            raise ValueError(f"{case_id}: NOT_MEASURED applies to performance only")
        if case.get("priority") not in ("P0", "P1"):
            raise ValueError(f"{case_id}: invalid priority")
        if case.get("devices") not in ("A", "B", "A/B"):
            raise ValueError(f"{case_id}: device scope not explicit")
        if not _present(case.get("action")) or not _present(case.get("expected")):
            raise ValueError(f"{case_id}: missing action/expected")
        counts[status] += 1
        if status in ("FAIL", "BLOCKED", "PASS"):
            if not _present(case.get("observed")) or not _present(case.get("testerRef")):
                raise ValueError(f"{case_id}: observation and tester reference required")
            if not _timestamp(case.get("testedAt")):
                raise ValueError(f"{case_id}: timezone-aware testedAt required")
        if status == "PASS":
            refs = case.get("evidenceRefs")
            if not isinstance(refs, list) or not refs or any(not _present(ref) for ref in refs):
                raise ValueError(f"{case_id}: sanitized evidence references required")
            metrics = case.get("metrics")
            if case_id in PERFORMANCE:
                if not isinstance(metrics, dict) or not METRICS.issubset(metrics):
                    raise ValueError(f"{case_id}: performance numbers missing")
                if any(isinstance(metrics[k], bool) or not isinstance(metrics[k], (int, float)) or metrics[k] <= 0 for k in METRICS):
                    raise ValueError(f"{case_id}: invalid performance numbers")
    if require_complete:
        if counts["PASS"] != len(REQUIRED):
            raise ValueError("Not all scenarios are PASS; completion is blocked")
        if evidence.get("deployedBuildVerification") != "VERIFIED":
            raise ValueError("Deployed Web build not independently identified")
        if not SHA.fullmatch(str(evidence.get("deployedBuildSha", ""))):
            raise ValueError("A verified 40-character deployment SHA is required")
        if not _present(evidence.get("operatorSignoff")):
            raise ValueError("A named or pseudonymous manual signoff is required")
        for key in ("A", "B"):
            item = devices[key]
            if item.get("installedPwaVerified") is not True or any(
                not _present(item.get(field)) for field in ("model", "osVersion", "browserVersion")
            ):
                raise ValueError(f"Device {key}: installed PWA and environment not verified")
    return counts


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("evidence", type=Path)
    parser.add_argument("--require-complete", action="store_true")
    args = parser.parse_args()
    record = json.loads(args.evidence.read_text(encoding="utf-8"))
    try:
        counts = validate(record, require_complete=args.require_complete)
    except ValueError as error:
        parser.error(str(error))
    print("STRUCTURE_VALID; physical execution NOT authenticated by this validator")
    print("Scenario statuses: " + ", ".join(f"{s}={counts[s]}" for s in sorted(counts)))


if __name__ == "__main__":
    main()
