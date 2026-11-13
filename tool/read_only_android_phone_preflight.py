#!/usr/bin/env python3
"""Anna physical gate: read-only local ADB/APK metadata preflight.

This program NEVER installs, upgrades, uninstalls, clears, exports or restores
Android user data. It neither proves the installed signer nor verifies that a
backup is restorable. The output is a local, non-secret review receipt only.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Callable

PACKAGE = "com.riccardopinato.agenda_per_anna"
PINNED = Path(__file__).resolve().parents[1] / "docs/release_evidence/ANDROID_SIGNED_PAIR_127_128_PINNED.json"
MAX_APK = 150 * 1024 * 1024
Runner = Callable[[list[str]], str]


class PreflightError(ValueError):
    """Safe failure codes, with no device identifiers or raw tool output."""


def subprocess_runner(argv: list[str]) -> str:
    try:
        result = subprocess.run(argv, text=True, capture_output=True,
                                timeout=45, check=False)
    except (OSError, subprocess.TimeoutExpired) as exc:
        raise PreflightError("LOCAL_INSPECTOR_NOT_AVAILABLE_OR_TIMED_OUT") from exc
    if result.returncode != 0:
        raise PreflightError("LOCAL_INSPECTOR_REJECTED_COMMAND")
    return result.stdout


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def regular_file(path: Path, label: str, max_size: int | None = None) -> None:
    if path.is_symlink() or not path.is_file():
        raise PreflightError(f"{label}_MISSING_OR_SYMLINK")
    size = path.stat().st_size
    if size <= 0 or (max_size is not None and size > max_size):
        raise PreflightError(f"{label}_EMPTY_OR_UNSAFE_SIZE")


def read_pinned_identity(path: Path = PINNED) -> tuple[str, str]:
    content = json.loads(path.read_text(encoding="utf-8"))
    expected_pkg = content["package_id"]
    expected_cert = content["expected_signing_certificate_sha256"].lower()
    if expected_pkg != PACKAGE or not re.fullmatch(r"[0-9a-f]{64}", expected_cert):
        raise PreflightError("INVALID_PINNED_RELEASE_IDENTITY")
    return expected_pkg, expected_cert


def read_device(adb: str, runner: Runner) -> dict:
    output = runner([adb, "devices"])
    lines = [line.strip().split() for line in output.splitlines()[1:] if line.strip()]
    if len(lines) != 1 or len(lines[0]) < 2 or lines[0][1] != "device":
        raise PreflightError("REQUIRE_EXACTLY_ONE_AUTHORIZED_DEVICE")
    serial = lines[0][0]  # transient only; NEVER copied into receipt

    def adb_shell(*parts: str) -> str:
        return runner([adb, "-s", serial, "shell", *parts]).strip()

    qemu = adb_shell("getprop", "ro.kernel.qemu")
    hw = adb_shell("getprop", "ro.hardware").lower()
    model = adb_shell("getprop", "ro.product.model")
    version = adb_shell("getprop", "ro.build.version.release")
    abi = adb_shell("getprop", "ro.product.cpu.abi")
    if qemu == "1" or hw in {"ranchu", "goldfish", "qemu"} or "emulator" in model.lower():
        raise PreflightError("EMULATOR_NOT_ACCEPTED_AS_PHYSICAL_DEVICE")
    if not (model and version and abi):
        raise PreflightError("INCOMPLETE_DEVICE_IDENTITY")
    if abi not in ("arm64-v8a",):
        raise PreflightError("NOT_ARM64_PHYSICAL_TARGET")
    package_line = adb_shell("pm", "list", "packages", PACKAGE)
    if not re.search(r"^package:" + re.escape(PACKAGE) + r"$", package_line, re.M):
        raise PreflightError("ANNA_APP_NOT_INSTALLED_ON_THIS_DEVICE")
    package_dump = adb_shell("dumpsys", "package", PACKAGE)
    block = re.search(r"Package \[" + re.escape(PACKAGE) + r"\].*?(?=\n\s*Package \[|\Z)", package_dump, re.S)
    if not block:
        raise PreflightError("INSTALLED_PACKAGE_NOT_RESOLVED")
    code = re.search(r"\bversionCode=(\d+)\b", block.group(0))
    if not code:
        raise PreflightError("INSTALLED_VERSION_CODE_NOT_FOUND")
    return {"physical_target_detected": True, "device_model": model,
            "android_version": version, "abi": abi, "package_id": PACKAGE,
            "installed_apk_version_code": int(code.group(1)),
            "installed_signing_certificate": "NOT_VERIFIED"}


def inspect_apk(path: Path, aapt: str, apksigner: str, runner: Runner,
                expected_pkg: str, expected_cert: str) -> dict:
    regular_file(path, "CANDIDATE_APK", MAX_APK)
    badging = runner([aapt, "dump", "badging", str(path)])
    pkg = re.search(r"^package: name='([^']+)' versionCode='(\d+)' versionName='([^']+)'", badging, re.M)
    if not pkg or pkg.group(1) != expected_pkg:
        raise PreflightError("CANDIDATE_PACKAGE_OR_BADGING_MISMATCH")
    # Must be cryptographically verified. Inspecting a certificate is not proof.
    signing = runner([apksigner, "verify", "--verbose", "--print-certs", str(path)])
    certs = re.findall(r"Signer #\d+ certificate SHA-256 digest:\s*([0-9a-fA-F]{64})", signing)
    if len(certs) != 1 or certs[0].lower() != expected_cert:
        raise PreflightError("CANDIDATE_RELEASE_CERTIFICATE_MISMATCH")
    if not re.search(r"Verified using v\d+ scheme \(APK Signature Scheme v\d+\): true", signing, re.I):
        raise PreflightError("CANDIDATE_RELEASE_CRYPTOGRAPHIC_SCHEME_NOT_SHOWN")
    return {"package_id": pkg.group(1), "apk_version_code": int(pkg.group(2)),
            "apk_version_name": pkg.group(3), "apk_sha256": sha256_file(path),
            "candidate_signing_sha256": certs[0].lower(),
            "candidate_apksigner_verified": True}


def build_receipt(adb: str, aapt: str, apksigner: str,
                  candidate: Path | None, backup: Path | None,
                  runner: Runner = subprocess_runner) -> dict:
    package, cert = read_pinned_identity()
    device = read_device(adb, runner)
    receipt = {
        "schema_version": 1,
        "scope": "READ_ONLY_LOCAL_PHYSICAL_PREFLIGHT_NOT_CERTIFICATION",
        "device": device,
        "candidate": None,
        "backup": {"status": "NOT_PROVIDED", "restorability": "NOT_VERIFIED"},
        "checks": {
            "physical_device_metadata": "READ_ONLY_OBSERVED",
            "installed_signer_match": "NOT_VERIFIED",
            "data_inventory": "NOT_VERIFIED",
            "full_backup_integrity_and_restore": "NOT_VERIFIED",
            "candidate_exact_source_and_provenance": "NOT_VERIFIED",
            "in_place_update": "NOT_PERFORMED",
            "phone_user_data_retention": "NOT_VERIFIED",
            "play_testing": "NOT_VERIFIED",
        },
        "installation_authorized": False,
        "physical_qa_pass": False,
    }
    if candidate is not None:
        artifact = inspect_apk(candidate, aapt, apksigner, runner, package, cert)
        if artifact["apk_version_code"] <= device["installed_apk_version_code"]:
            raise PreflightError("CANDIDATE_NOT_NEWER_THAN_INSTALLED_APP")
        receipt["candidate"] = artifact
        receipt["checks"]["candidate_local_cryptographic_identity"] = "PASS"
    if backup is not None:
        regular_file(backup, "BACKUP")
        receipt["backup"] = {"status": "FILE_EXISTS_CHECKSUM_ONLY",
                             "sha256": sha256_file(backup),
                             "size_bytes": backup.stat().st_size,
                             "restorability": "NOT_VERIFIED"}
    return receipt


def write_receipt_exclusive(path: Path, body: str) -> None:
    """Fail closed if output exists, including backup/APK paths and hardlinks."""
    if path.is_symlink():
        raise PreflightError("OUTPUT_ALREADY_EXISTS_OR_SYMLINK")
    try:
        path.parent.mkdir(parents=True, exist_ok=True)
        with path.open("x", encoding="utf-8") as stream:
            stream.write(body)
    except FileExistsError as exc:
        raise PreflightError("OUTPUT_ALREADY_EXISTS_OR_SYMLINK") from exc
    except OSError as exc:
        raise PreflightError("OUTPUT_WRITE_FAILED") from exc


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--adb", default="adb", help="Path to local ADB; read-only shell commands")
    parser.add_argument("--aapt", default="aapt")
    parser.add_argument("--apksigner", default="apksigner")
    parser.add_argument("--candidate", type=Path, help="Optional exact stable-signed APK to inspect locally")
    parser.add_argument("--backup", type=Path, help="Optional pre-existing backup to hash (not verify restore)")
    parser.add_argument("--output", type=Path, help="Optional LOCAL JSON receipt path; never upload automatically")
    args = parser.parse_args(argv)
    try:
        receipt = build_receipt(args.adb, args.aapt, args.apksigner, args.candidate, args.backup)
    except (PreflightError, OSError, ValueError, KeyError, json.JSONDecodeError) as exc:
        code = str(exc) if isinstance(exc, PreflightError) else "PREFLIGHT_INPUT_OR_IO_ERROR"
        print(json.dumps({"status": "BLOCKED", "reason": code,
                          "installation_authorized": False, "physical_qa_pass": False}), file=sys.stdout)
        return 2
    out = json.dumps(receipt, indent=2, sort_keys=True) + "\n"
    if args.output:
        try:
            write_receipt_exclusive(args.output, out)
        except PreflightError as exc:
            print(json.dumps({"status": "BLOCKED", "reason": str(exc),
                              "installation_authorized": False, "physical_qa_pass": False}))
            return 2
        print("LOCAL_RECEIPT_WRITTEN_ONLY_NO_INSTALL_OR_CERTIFICATION")
    else:
        print(out, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
