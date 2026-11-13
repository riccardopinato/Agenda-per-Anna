#!/usr/bin/env python3
"""Read-only provenance and cryptographic identity audit for historical signed APKs.

Requires original GitHub artifact ZIPs + run/artifact/job/source API JSON and
Android build-tools aapt/apksigner. Never builds, installs, publishes or signs.
"""
from __future__ import annotations

import argparse
import base64
import hashlib
import json
import os
import re
import subprocess
import tempfile
from pathlib import Path
from zipfile import BadZipFile, ZipFile

SHA40 = re.compile(r"^[0-9a-f]{40}$")
SHA256 = re.compile(r"^[0-9a-f]{64}$")
MAX_ZIP = 100 * 1024 * 1024
MAX_APK = 100 * 1024 * 1024


class AuditError(ValueError):
    pass


def require(condition: bool, reason: str) -> None:
    if not condition:
        raise AuditError(reason)


def digest(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def command(*argv: str) -> str:
    result = subprocess.run(argv, capture_output=True, text=True, check=False, timeout=90)
    require(result.returncode == 0, "ANDROID_INSPECTOR_FAILED:" + argv[0])
    return result.stdout + "\n" + result.stderr


def load_json(path: Path) -> dict:
    require(path.is_file() and not path.is_symlink() and path.stat().st_size < 2_000_000,
            "MISSING_OR_UNSAFE_METADATA")
    value = json.loads(path.read_text(encoding="utf-8"))
    require(isinstance(value, dict), "INVALID_METADATA")
    return value


def verify_api(data: dict, item: dict, directory: Path) -> None:
    repo = data["repository"]
    run = load_json(directory / "run.json")
    artifact = load_json(directory / "artifact.json")
    jobs = load_json(directory / "jobs.json")
    source = load_json(directory / "pubspec.json")
    require(run.get("id") == item["run_id"]
            and run.get("workflow_id") == data["workflow_id"]
            and run.get("name") == data["workflow_name"]
            and run.get("repository", {}).get("full_name") == repo
            and run.get("head_sha") == item["source_sha"]
            and run.get("head_branch") == "main"
            and run.get("event") == "workflow_run"
            and run.get("status") == "completed" and run.get("conclusion") == "success",
            "RUN_PROVENANCE_MISMATCH")
    require(artifact.get("id") == item["artifact_id"]
            and artifact.get("name") == data["artifact_name"]
            and artifact.get("expired") is False
            and artifact.get("digest") == "sha256:" + item["zip_sha256"]
            and artifact.get("size_in_bytes") == item["zip_size_bytes"],
            "ARTIFACT_API_MISMATCH")
    origin = artifact.get("workflow_run")
    require(not isinstance(origin, dict)
            or (origin.get("id") == item["run_id"]
                and origin.get("head_sha") == item["source_sha"]),
            "ARTIFACT_RUN_BINDING_MISMATCH")
    require(any(job.get("name") == "signed-apk / build"
                and job.get("conclusion") == "success"
                and job.get("head_sha", item["source_sha"]) == item["source_sha"]
                for job in jobs.get("jobs", [])),
            "SIGNED_BUILD_JOB_NOT_SUCCESS")
    require(source.get("encoding") == "base64"
            and isinstance(source.get("content"), str), "SOURCE_PUBSPEC_NOT_FOUND")
    pubspec = base64.b64decode(source["content"], validate=False).decode("utf-8")
    found = re.search(r"(?m)^version:\s*(\S+)\s*$", pubspec)
    require(found is not None and found.group(1) == (
            f'{data["version_name"]}+{item["version_code"]}'),
            "SOURCE_BUILD_NUMBER_MISMATCH")


def verify_manifest(data: dict, item: dict, manifest: dict) -> None:
    required = {
        "repository": data["repository"],
        "sourceSha": item["source_sha"],
        "commit": item["source_sha"],
        "workflowRunId": str(item["run_id"]),
        "workflowRun": str(item["run_id"]),
        "packageId": data["package_id"],
        "appVersion": f'{data["version_name"]}+{item["version_code"]}',
        "buildNumber": item["version_code"],
        "artifactFile": data["apk_file"],
        "artifactSha256": item["apk_sha256"],
        "channel": data["channel"],
        "signingCertificateSha256": data["expected_signing_certificate_sha256"].upper(),
        "validationLevel": "ARTIFACT_BUILT",
    }
    for key, expected in required.items():
        require(manifest.get(key) == expected, "RELEASE_MANIFEST_MISMATCH:" + key)
    reality = manifest.get("releaseReality", {})
    for key, expected in {
        "sourceSha": item["source_sha"], "artifactSha256": item["apk_sha256"],
        "signingFingerprint": data["expected_signing_certificate_sha256"].upper(),
        "packageId": data["package_id"], "workflowRun": str(item["run_id"]),
        "buildNumber": item["version_code"], "validationLevel": "ARTIFACT_BUILT",
    }.items():
        require(reality.get(key) == expected, "RELEASE_REALITY_MISMATCH:" + key)
    require(manifest.get("physicalVerification", {}).get("status") == "PENDING",
            "PHYSICAL_VERIFICATION_MUST_REMAIN_PENDING")


def inspect_android(data: dict, item: dict, apk: Path) -> dict:
    output = command("aapt", "dump", "badging", str(apk))
    package_line = next((line for line in output.splitlines()
                         if line.startswith("package: ")), "MISSING_PACKAGE_LINE")
    print("AAPT_BINARY_PACKAGE " + package_line[:350])
    match = re.search(r"(?m)^package: name='([^']+)' versionCode='(\d+)' versionName='([^']+)'", output)
    actual_code = int(match.group(2)) if match else None
    require(match is not None
            and match.group(1) == data["package_id"]
            and actual_code == item["apk_version_code"]
            and match.group(3) == data["version_name"], "APK_BINARY_PACKAGE_VERSION_MISMATCH")
    with ZipFile(apk) as signed_apk:
        names = signed_apk.namelist()
        require(len(names) == len(set(names)), "DUPLICATE_APK_ENTRIES")
        abis = {n.split("/")[1] for n in names
                if n.startswith("lib/") and n.endswith(".so") and len(n.split("/")) == 3}
    require(abis == {"arm64-v8a"}, "APK_ABI_SCOPE_MISMATCH")
    signed = command("apksigner", "verify", "--verbose", "--print-certs", str(apk))
    match = re.search(r"Signer #1 certificate SHA-256 digest:\s*([0-9a-fA-F]{64})", signed)
    require(match is not None and match.group(1).lower()
            == data["expected_signing_certificate_sha256"], "APK_CRYPTOGRAPHIC_SIGNER_MISMATCH")
    require("Signer #2" not in signed and re.search(
        r"Verified using v2 scheme \(APK Signature Scheme v2\):\s*true", signed, re.I)
        is not None, "APK_V2_SIGNATURE_NOT_VALID")
    return {"version_code": actual_code,
            "sha256": digest(apk), "size_bytes": apk.stat().st_size,
            "signing_certificate_sha256": data["expected_signing_certificate_sha256"],
            "native_abis": sorted(abis), "apksigner_verified": True}


def verify_one(data: dict, item: dict, root: Path) -> dict:
    code = item["version_code"]
    binary_code = item.get("apk_version_code")
    require(type(binary_code) is int and binary_code > 0, "ACTUAL_BINARY_VERSIONCODE_PIN_REQUIRED")
    if binary_code != code:
        require(code == 128 and binary_code == 2127
                and item.get("version_code_discrepancy") ==
                "SOURCE_BUILD_128_VS_SIGNED_ARM64_APK_VERSION_CODE_2127_UNRESOLVED",
                "UNREVIEWED_BINARY_VERSIONCODE_DISCREPANCY")
    else:
        require("version_code_discrepancy" not in item,
                "MISLEADING_VERSIONCODE_DISCREPANCY_FLAG")
    directory = root / str(code)
    require(directory.is_dir() and not directory.is_symlink(), "ARTIFACT_DIR_MISSING")
    require(SHA40.fullmatch(item["source_sha"]) is not None
            and SHA256.fullmatch(item["apk_sha256"]) is not None
            and SHA256.fullmatch(item["zip_sha256"]) is not None, "BAD_PINNED_HASH")
    verify_api(data, item, directory)
    path = directory / "artifact.zip"
    require(path.is_file() and not path.is_symlink()
            and path.stat().st_size == item["zip_size_bytes"]
            and path.stat().st_size < MAX_ZIP
            and digest(path) == item["zip_sha256"], "EXACT_ORIGINAL_ZIP_MISMATCH")
    try:
        with ZipFile(path) as archive:
            names = archive.namelist()
            require(len(names) == 2 and set(names) == {
                data["apk_file"], data["manifest_file"]}, "ZIP_UNEXPECTED_ENTRY")
            apk_info = archive.getinfo(data["apk_file"])
            require(apk_info.file_size == item["apk_size_bytes"]
                    and 0 < apk_info.file_size <= MAX_APK, "APK_SIZE_MISMATCH")
            manifest_bytes = archive.read(data["manifest_file"])
            require(len(manifest_bytes) <= 100_000, "OVERSIZED_MANIFEST")
            manifest = json.loads(manifest_bytes)
            verify_manifest(data, item, manifest)
            with tempfile.TemporaryDirectory(prefix="anna-signed-identity-") as tmp:
                apk = Path(tmp) / data["apk_file"]
                with archive.open(apk_info) as src, apk.open("wb") as dst:
                    for chunk in iter(lambda: src.read(1024 * 1024), b""):
                        dst.write(chunk)
                require(digest(apk) == item["apk_sha256"], "APK_BYTES_HASH_MISMATCH")
                identity = inspect_android(data, item, apk)
    except (OSError, BadZipFile, KeyError, json.JSONDecodeError) as exc:
        raise AuditError("ARCHIVE_OR_MANIFEST_INVALID") from exc
    return {"source_sha": item["source_sha"], "workflow_run_id": item["run_id"],
            "artifact_id": item["artifact_id"], "artifact_zip_sha256": item["zip_sha256"],
            "apk": identity, "source_version": f'{data["version_name"]}+{code}',
            "source_build_number": code,
            "actual_binary_version_code": identity["version_code"],
            "version_code_alignment": ("MATCH" if code == identity["version_code"]
                                       else "UNRESOLVED_SOURCE_BINARY_DIVERGENCE")}


def audit(inventory: dict, directory: Path, expected_head: str) -> dict:
    actual = command("git", "rev-parse", "HEAD").strip()
    require(SHA40.fullmatch(expected_head) is not None
            and actual == expected_head, "AUDIT_CHECKOUT_SHA_MISMATCH")
    require(inventory.get("schema_version") == 1
            and inventory.get("scope") == "EXISTING_SIGNED_APK_IDENTITY_AUDIT_ONLY"
            and inventory.get("repository") == "riccardopinato/Agenda-per-Anna"
            and inventory.get("package_id") == "com.riccardopinato.agenda_per_anna"
            and isinstance(inventory.get("releases"), list)
            and [x["version_code"] for x in inventory["releases"]] == [127, 128],
            "INVENTORY_SCOPE_INVALID")
    proofs = [verify_one(inventory, item, directory) for item in inventory["releases"]]
    require(proofs[0]["apk"]["signing_certificate_sha256"]
            == proofs[1]["apk"]["signing_certificate_sha256"],
            "CROSS_VERSION_SIGNER_CHANGED")
    discrepancies = [{"source_build_number": p["source_build_number"],
                      "actual_binary_version_code": p["actual_binary_version_code"],
                      "source_sha": p["source_sha"],
                      "status": "UNRESOLVED_REQUIRES_RELEASE_ENGINEERING_REVIEW"}
                     for p in proofs if p["version_code_alignment"] != "MATCH"]
    require(len(discrepancies) == 1
            and discrepancies[0]["source_build_number"] == 128
            and discrepancies[0]["actual_binary_version_code"] == 2127,
            "EXPECTED_HISTORICAL_VERSIONCODE_DISCREPANCY_MISSING")
    return {"schema_version": 1,
            "result": "SIGNATURE_AND_ORIGINAL_BYTES_VERIFIED_VERSIONCODE_DIVERGENCE",
            "release_identity_gate": "BLOCKED_UNRESOLVED_BINARY_VERSIONCODE",
            "release_pair_update_ready": False,
            "discrepancies": discrepancies,
            "repository": inventory["repository"], "audit_checkout_sha": actual,
            "ci_run_id": os.environ.get("GITHUB_RUN_ID"),
            "physical_device_verified": False, "installed_app_verified": False,
            "personal_data_accessed": False, "rollback_on_device_executed": False,
            "release_build_generated": False, "play_verified": False,
            "golden_certified": False, "current_129_signed_apk_verified": False,
            "release_artifacts": proofs}


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--inventory", type=Path, required=True)
    parser.add_argument("--artifact-root", type=Path, required=True)
    parser.add_argument("--expected-head", required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    inventory = load_json(args.inventory)
    receipt = audit(inventory, args.artifact_root, args.expected_head)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(receipt, indent=2, sort_keys=True) + "\n",
                           encoding="utf-8")
    print("PASS: original ZIP/APK bytes, sources, signatures and signer parity. "
          "BLOCKED: +128 APK actual versionCode 2127 differs from source build 128. "
          "NOT RELEASE READY / DEVICE / DOWNGRADE / PLAY / GOLDEN.")


if __name__ == "__main__":
    main()
