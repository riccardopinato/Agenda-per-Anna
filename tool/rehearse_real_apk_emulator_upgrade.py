#!/usr/bin/env python3
"""Original signed Anna APK 2127->2128: disposable emulator-only upgrade/recovery.

NO personal phone, no accounts, no real data, no signing, no uninstall after
creation, no adb -d or app data clear after synthetic guest seeding.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import subprocess
import tempfile
from pathlib import Path
from zipfile import ZipFile

PACKAGE = "com.riccardopinato.agenda_per_anna"
CANARY = "X10_ANNA_127_128_EMULATOR_SYNTHETIC_ONLY"
EXPECTED_VERSIONS = (2127, 2128)
MAESTRO_FLOW_ONBOARDING = ".maestro/journeys/onboarding.yaml"
MAESTRO_FLOW_SEED = ".maestro/release-recovery/signed127-seed-synthetic-inbox.yaml"
MAESTRO_FLOW_VERIFY = ".maestro/release-recovery/signed128-check-synthetic-inbox.yaml"


class RehearsalError(RuntimeError):
    pass


def require(ok: bool, code: str) -> None:
    if not ok:
        raise RehearsalError(code)


def cmd(*argv: str, timeout: int = 180) -> subprocess.CompletedProcess[str]:
    return subprocess.run(list(argv), text=True, capture_output=True,
                          check=False, timeout=timeout)


def run(*argv: str, timeout: int = 180) -> str:
    result = cmd(*argv, timeout=timeout)
    require(result.returncode == 0, "COMMAND_FAILED:" + argv[0] + ":" +
            (result.stderr or result.stdout)[-350:])
    return result.stdout.strip()


def adb(*argv: str) -> str:
    return run("adb", "-e", *argv)


def emulator_guard() -> dict[str, str]:
    serial = adb("get-serialno").strip()
    qemu = adb("shell", "getprop", "ro.kernel.qemu").strip()
    api = adb("shell", "getprop", "ro.build.version.sdk").strip()
    require(serial.startswith("emulator-") and qemu == "1"
            and api.isdecimal() and int(api) >= 30,
            "ONLY_DISPOSABLE_API30_PLUS_EMULATOR_ALLOWED")
    props = {
        "device_type": "EMULATOR",
        "api_level": api,
        "cpu_abi": adb("shell", "getprop", "ro.product.cpu.abilist").strip(),
        "native_bridge": adb("shell", "getprop",
                             "ro.dalvik.vm.native.bridge").strip(),
        "fingerprint": adb("shell", "getprop",
                           "ro.build.fingerprint").strip(),
    }
    require("x86_64" in props["cpu_abi"] or "arm64" in props["cpu_abi"],
            "ANDROID_EMULATOR_UNSUPPORTED_CPU")
    return props


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def inspect_local_pair(root: Path, inventory: dict, temp: Path) -> tuple[Path, Path]:
    require(inventory.get("schema_version") == 1
            and inventory.get("repository") == "riccardopinato/Agenda-per-Anna"
            and inventory.get("package_id") == PACKAGE
            and isinstance(inventory.get("releases"), list)
            and len(inventory["releases"]) == 2,
            "INVALID_ORIGIN_INVENTORY")
    apks = []
    for version, item in zip(EXPECTED_VERSIONS, inventory["releases"]):
        require(item.get("apk_version_code") == version
                and item.get("version_code") == version - 2000,
                "INVENTORY_VERSION_CHAIN_INVALID")
        zipped = root / str(item["version_code"]) / "artifact.zip"
        require(zipped.is_file() and not zipped.is_symlink()
                and zipped.stat().st_size == item["zip_size_bytes"]
                and sha256(zipped) == item["zip_sha256"], "ORIGINAL_ZIP_HASH_MISMATCH")
        with ZipFile(zipped) as archive:
            require(set(archive.namelist()) ==
                    {inventory["apk_file"], inventory["manifest_file"]},
                    "ORIGINAL_ZIP_UNEXPECTED_FILES")
            path = temp / f"anna-real-original-{version}.apk"
            with archive.open(inventory["apk_file"]) as src, path.open("wb") as dst:
                for chunk in iter(lambda: src.read(1024 * 1024), b""):
                    dst.write(chunk)
        require(path.stat().st_size == item["apk_size_bytes"]
                and sha256(path) == item["apk_sha256"], "ORIGINAL_APK_HASH_MISMATCH")
        # Independent Android inspections complement historical receipt.
        badging = run("aapt", "dump", "badging", str(path))
        m = re.search(r"(?m)^package: name='([^']+)' versionCode='(\d+)'", badging)
        require(m is not None and m.group(1) == PACKAGE
                and int(m.group(2)) == version, "APK_PACKAGE_OR_VERSION_MISMATCH")
        signature = run("apksigner", "verify", "--verbose",
                        "--print-certs", str(path))
        fingerprint = re.search(
            r"Signer #1 certificate SHA-256 digest:\s*([a-fA-F0-9]{64})",
            signature)
        require(fingerprint is not None and fingerprint.group(1).lower() ==
                inventory["expected_signing_certificate_sha256"],
                "SIGNER_FINGERPRINT_MISMATCH")
        require(re.search(
            r"Verified using v2 scheme \(APK Signature Scheme v2\):\s*true",
            signature, re.I) is not None, "APK_SIGNATURE_V2_INVALID")
        apks.append(path)
    return tuple(apks)  # type: ignore[return-value]


def installed_version() -> int:
    dump = adb("shell", "dumpsys", "package", PACKAGE)
    found = re.search(r"\bversionCode=(\d+)\b", dump)
    require(found is not None, "APP_NOT_INSTALLED_OR_INVALID_VERSION")
    return int(found.group(1))


def ensure_uninstalled() -> None:
    # Android 15 'pm path <absent package>' returns exit status 1, frequently
    # with empty stdout. This is not an ADB transport failure. Distinguish
    # absence from a preinstalled package or an offline/unreachable emulator.
    probe = cmd("adb", "-e", "shell", "pm", "path", PACKAGE)
    stdout = probe.stdout.strip()
    stderr = probe.stderr.strip()
    if probe.returncode == 0:
        require(not stdout and not stderr,
                "NONEMPTY_EMULATOR_PACKAGE_REFUSED")
        return
    require(probe.returncode == 1 and not stdout
            and (not stderr or re.search(
                r"\b(package|application)\b.*\b(not found|unknown)\b",
                stderr, re.I) is not None),
            "EMULATOR_PACKAGE_PROBE_FAILED_NOT_SAFE_TO_INSTALL")


def install_expect(apk: Path, version: int) -> None:
    out = adb("install", "-r", str(apk))
    require("Success" in out, "REAL_APK_INSTALL_DID_NOT_SUCCEED")
    require(installed_version() == version, "ACTUAL_INSTALLED_VERSION_MISMATCH")


def maestro(flow: str) -> None:
    require(Path(flow).is_file(), "MAESTRO_JOURNEY_MISSING")
    result = cmd("maestro", "test", flow, timeout=660)
    if result.returncode != 0:
        # The build is not certified; do not invent persistence on partial UI.
        raise RehearsalError(
            "REAL_APP_UI_JOURNEY_FAILED:" + Path(flow).name + ":" +
            (result.stdout + "\n" + result.stderr)[-2200:])
    print("MAESTRO_REAL_APK_UI_PASS: " + Path(flow).name)


def rehearse(root: Path, inventory: dict, head: str) -> dict:
    checked_out = run("git", "rev-parse", "HEAD")
    require(re.fullmatch(r"[a-f0-9]{40}", head) is not None
            and checked_out == head, "EXACT_REHEARSAL_HEAD_MISMATCH")
    device = emulator_guard()  # critical before any installation or launch
    ensure_uninstalled()
    with tempfile.TemporaryDirectory(prefix="anna-existing-signed-pair-") as temp:
        old, new = inspect_local_pair(root, inventory, Path(temp))
        install_expect(old, 2127)
        print("REAL_APK_OLD_INSTALL_PASS")
        maestro(MAESTRO_FLOW_ONBOARDING)
        maestro(MAESTRO_FLOW_SEED)
        print("REAL_APP_SYNTHETIC_INBOX_SEEDED_PASS")
        adb("shell", "am", "force-stop", PACKAGE)
        install_expect(new, 2128)  # NO uninstall, NO data clear
        maestro(MAESTRO_FLOW_VERIFY)
        print("REAL_APK_INPLACE_UPGRADE_PERSISTENCE_PASS")
        adb("shell", "am", "force-stop", PACKAGE)
        maestro(MAESTRO_FLOW_VERIFY)
        print("REAL_APK_PROCESS_RESTART_PERSISTENCE_PASS")
        downgrade = cmd("adb", "-e", "install", "-r", str(old))
        message = downgrade.stdout + "\n" + downgrade.stderr
        require(downgrade.returncode != 0
                and "INSTALL_FAILED_VERSION_DOWNGRADE" in message,
                "ORDINARY_RELEASE_DOWNGRADE_NOT_REJECTED")
        require(installed_version() == 2128,
                "REJECTED_DOWNGRADE_CHANGED_INSTALL")
        maestro(MAESTRO_FLOW_VERIFY)
        print("REAL_RELEASE_DOWNGRADE_REJECTED_DATA_INTACT_PASS")
        # Recovery from failed attempt is a same-version, non-destructive
        # repair/re-install, NOT a version rollback or a forward fix build.
        install_expect(new, 2128)
        maestro(MAESTRO_FLOW_VERIFY)
        print("REAL_APK_SAME_VERSION_REPAIR_PERSISTENCE_PASS")
    return {
        "schema_version": 1,
        "result": "SIGNED_REAL_APP_EMULATOR_UPGRADE_AND_REPAIR_PASS",
        "factory_sha": "c5adc147046beb7024629466d10eeb799c3c2619",
        "source_checkout_sha": checked_out,
        "runner_workflow_run_id": os.getenv("GITHUB_RUN_ID", ""),
        "original_signed_releases": [
            {"flutter_build_number": item["version_code"],
             "apk_version_code": item["apk_version_code"],
             "source_sha": item["source_sha"], "run_id": item["run_id"],
             "artifact_id": item["artifact_id"],
             "apk_sha256": item["apk_sha256"]}
            for item in inventory["releases"]],
        "device": device, "synthetic_fixture": "one_guest_inbox_note",
        "synthetic_fixture_token": CANARY,
        "checks": {
            "original_signed_apk_127_installed": True,
            "guest_onboarding_and_inbox_note_written_through_real_ui": True,
            "inplace_upgrade_2127_to_2128": True,
            "inbox_note_persisted_after_upgrade": True,
            "inbox_note_persisted_after_process_restart": True,
            "normal_downgrade_2128_to_2127_rejected": True,
            "data_intact_after_rejected_downgrade": True,
            "same_version_2128_repair_and_data_retention": True,
        },
        "physical_device_verified": False,
        "actual_user_data_tested": False,
        "signed_release_binary_downgrade_verified": False,
        "forward_fix_release_verified": False,
        "play_testing_verified": False,
        "golden_certified": False,
        "user_action_required_for_release": True,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--artifact-root", required=True, type=Path)
    parser.add_argument("--inventory", required=True, type=Path)
    parser.add_argument("--expected-head", required=True)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    inventory = json.loads(args.inventory.read_text(encoding="utf-8"))
    report = rehearse(args.artifact_root, inventory, args.expected_head)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n",
                           encoding="utf-8")
    print("PASS real signed APK emulator 2127->2128, guest Inbox retention, "
          "normal downgrade refused, same-version non-destructive repair. "
          "NO REAL PHONE / DOWNGRADE / PLAY / GOLDEN.")


if __name__ == "__main__":
    main()
