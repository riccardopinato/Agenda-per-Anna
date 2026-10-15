#!/usr/bin/env python3
"""Create a non-secret physical-certification manifest for a signed Android APK."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

from create_release_reality import build_release_reality_record


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
    parser.add_argument("--project", default="Anna's Diary")
    parser.add_argument("--source-ref", default="unrecorded")
    parser.add_argument(
        "--package-id",
        default="com.riccardopinato.agenda_per_anna",
    )
    parser.add_argument(
        "--validation-level",
        default="ARTIFACT_BUILT",
    )
    args = parser.parse_args()

    artifact = Path(args.artifact)
    if not artifact.is_file():
        raise SystemExit(f"Artifact not found: {artifact}")

    fingerprint = args.signing_sha256.strip().upper().replace(" ", "")
    if not fingerprint:
        raise SystemExit("Signing SHA-256 fingerprint is required")

    build_number = 0
    if "+" in args.version:
        _, raw_build = args.version.rsplit("+", 1)
        if raw_build.isdigit():
            build_number = int(raw_build)

    release_reality = build_release_reality_record(
        project=args.project,
        repository=args.repository,
        source_ref=args.source_ref,
        source_sha=args.commit,
        version=args.version.split("+", 1)[0],
        build_number=build_number,
        variant=args.variant,
        package_id=args.package_id,
        artifact=artifact,
        signing_fingerprint=fingerprint,
        workflow_run=args.workflow_run_id,
        distribution_channel=args.channel,
        validation_level=args.validation_level,
    )

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
        "artifactSha256": release_reality["artifactSha256"],
        "signingCertificateSha256": fingerprint,
        "project": release_reality["project"],
        "sourceRef": release_reality["sourceRef"],
        "sourceSha": release_reality["sourceSha"],
        "version": release_reality["version"],
        "buildNumber": release_reality["buildNumber"],
        "packageId": release_reality["packageId"],
        "artifactName": release_reality["artifactName"],
        "signingFingerprint": release_reality["signingFingerprint"],
        "workflowRun": release_reality["workflowRun"],
        "distributionChannel": release_reality["distributionChannel"],
        "validationLevel": release_reality["validationLevel"],
        "validatedAt": release_reality["validatedAt"],
        "releaseReality": release_reality,
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
