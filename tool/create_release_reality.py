#!/usr/bin/env python3
"""Create a non-secret App Factory Release Reality record for one exact artifact."""

from __future__ import annotations

import argparse
import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path


VALIDATION_LEVELS = {
    "ARTIFACT_BUILT",
    "TRUSTED_RUNTIME_VERIFIED",
    "PHYSICAL_DEVICE_VERIFIED",
    "DISTRIBUTION_VERIFIED",
    "STORE_READY",
    "PRODUCTION_RELEASED",
}


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def normalize_signing_fingerprint(value: str) -> str:
    fingerprint = value.strip().upper().replace(":", "").replace(" ", "")
    if len(fingerprint) != 64 or any(
        char not in "0123456789ABCDEF" for char in fingerprint
    ):
        raise ValueError("Signing SHA-256 fingerprint must be 64 hex characters")
    return fingerprint


def build_release_reality_record(
    *,
    project: str,
    repository: str,
    source_ref: str,
    source_sha: str,
    version: str,
    build_number: int,
    variant: str,
    package_id: str,
    artifact: Path,
    signing_fingerprint: str,
    workflow_run: str,
    distribution_channel: str,
    validation_level: str,
    validated_at: str | None = None,
) -> dict:
    if validation_level not in VALIDATION_LEVELS:
        raise ValueError(f"Unsupported validation level: {validation_level}")
    if not artifact.is_file():
        raise ValueError(f"Artifact not found: {artifact}")

    timestamp = validated_at or datetime.now(timezone.utc).isoformat()
    return {
        "schemaVersion": 1,
        "evidenceType": "release_reality",
        "project": project.strip(),
        "repository": repository.strip(),
        "version": version.strip(),
        "buildNumber": int(build_number),
        "sourceRef": source_ref.strip(),
        "sourceSha": source_sha.strip(),
        "variant": variant.strip(),
        "packageId": package_id.strip(),
        "artifactName": artifact.name,
        "artifactSha256": sha256_file(artifact),
        "signingFingerprint": normalize_signing_fingerprint(
            signing_fingerprint,
        ),
        "workflowRun": str(workflow_run).strip(),
        "distributionChannel": distribution_channel.strip(),
        "validationLevel": validation_level,
        "validatedAt": timestamp,
    }


def write_release_reality_record(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(payload, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--artifact", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--project", required=True)
    parser.add_argument("--repository", required=True)
    parser.add_argument("--source-ref", required=True)
    parser.add_argument("--source-sha", required=True)
    parser.add_argument("--version", required=True)
    parser.add_argument("--build-number", required=True, type=int)
    parser.add_argument("--variant", required=True)
    parser.add_argument("--package-id", required=True)
    parser.add_argument("--signing-sha256", required=True)
    parser.add_argument("--workflow-run-id", required=True)
    parser.add_argument("--distribution-channel", required=True)
    parser.add_argument(
        "--validation-level",
        required=True,
        choices=sorted(VALIDATION_LEVELS),
    )
    args = parser.parse_args()

    try:
        payload = build_release_reality_record(
            project=args.project,
            repository=args.repository,
            source_ref=args.source_ref,
            source_sha=args.source_sha,
            version=args.version,
            build_number=args.build_number,
            variant=args.variant,
            package_id=args.package_id,
            artifact=Path(args.artifact),
            signing_fingerprint=args.signing_sha256,
            workflow_run=args.workflow_run_id,
            distribution_channel=args.distribution_channel,
            validation_level=args.validation_level,
        )
    except ValueError as exc:
        raise SystemExit(str(exc)) from exc

    write_release_reality_record(Path(args.output), payload)


if __name__ == "__main__":
    main()
