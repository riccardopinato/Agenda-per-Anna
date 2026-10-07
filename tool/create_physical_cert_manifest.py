#!/usr/bin/env python3
"""Create a non-secret physical-certification manifest for a signed Android APK."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--artifact", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--repository", required=True)
    parser.add_argument("--commit", required=True)
    parser.add_argument("--version", required=True)
    parser.add_argument("--variant", required=True)
    parser.add_argument("--signing-sha256", required=True)
    parser.add_argument("--workflow-run-id", required=True)
    parser.add_argument("--channel", required=True)
    args = parser.parse_args()

    artifact = Path(args.artifact)
    if not artifact.is_file():
        raise SystemExit(f"Artifact not found: {artifact}")

    fingerprint = args.signing_sha256.strip().upper().replace(" ", "")
    if not fingerprint:
        raise SystemExit("Signing SHA-256 fingerprint is required")

    payload = {
        "schemaVersion": 1,
        "evidenceType": "physical_certification_candidate",
        "repository": args.repository,
        "commit": args.commit,
        "appVersion": args.version,
        "variant": args.variant,
        "channel": args.channel,
        "workflowRunId": args.workflow_run_id,
        "artifactFile": artifact.name,
        "artifactSha256": sha256_file(artifact),
        "signingCertificateSha256": fingerprint,
        "physicalVerification": {
            "status": "PENDING",
            "deviceModel": None,
            "osVersion": None,
            "scenarios": [],
        },
    }

    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(
        json.dumps(payload, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )


if __name__ == "__main__":
    main()
