"""Offline/fixture safety tests; no phone, APK build, network or user data."""
from __future__ import annotations

import importlib.util
import tempfile
import unittest
from pathlib import Path

MODULE = Path(__file__).resolve().parents[1] / "read_only_android_phone_preflight.py"
spec = importlib.util.spec_from_file_location("phone_preflight", MODULE)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
CERT = "31be63155c831f062238179ec9b8f19d1c16a925bed1d526bc7e6a4712c62dc3"
PKG = "com.riccardopinato.agenda_per_anna"


def fake_runner(*, installed=2128, newer=2129, serials="USB123\tdevice\n", qemu="0", cert=CERT, tool_failure=None):
    calls = []

    def run(args):
        calls.append(list(args))
        if any(bad in args for bad in ("install", "uninstall", "clear", "pull", "push", "restore", "backup", "-d")):
            raise AssertionError("WRITE_COMMAND_ATTEMPTED")
        if tool_failure is not None and args[0] == tool_failure:
            raise mod.PreflightError("LOCAL_INSPECTOR_REJECTED_COMMAND")
        if args == ["adb", "devices"]:
            return "List of devices attached\n" + serials
        if args[:5] == ["adb", "-s", "USB123", "shell", "getprop"]:
            return {"ro.kernel.qemu": qemu, "ro.hardware": "qcom",
                    "ro.product.model": "Test phone", "ro.build.version.release": "14",
                    "ro.product.cpu.abi": "arm64-v8a"}[args[5]] + "\n"
        if args[4:] == ["pm", "list", "packages", PKG]:
            return f"package:{PKG}\n"
        if args[4:] == ["dumpsys", "package", PKG]:
            return f"Packages:\n  Package [{PKG}] (id=42):\n    versionCode={installed} minSdk=26 targetSdk=36\n"
        if args[:3] == ["aapt", "dump", "badging"]:
            return f"package: name='{PKG}' versionCode='{newer}' versionName='1.0.0-rc.6'\n"
        if args[:4] == ["apksigner", "verify", "--verbose", "--print-certs"]:
            return ("Verifies\nVerified using v2 scheme (APK Signature Scheme v2): true\n"
                    f"Signer #1 certificate SHA-256 digest: {cert}\n")
        raise AssertionError(f"UNEXPECTED_COMMAND {args}")

    return run, calls


class ReadOnlyPhonePreflightTests(unittest.TestCase):
    def test_device_receipt_never_reports_successful_install_or_saves_serial(self):
        runner, calls = fake_runner()
        receipt = mod.build_receipt("adb", "aapt", "apksigner", None, None, runner)
        self.assertEqual(receipt["device"]["installed_apk_version_code"], 2128)
        self.assertFalse(receipt["installation_authorized"])
        self.assertFalse(receipt["physical_qa_pass"])
        self.assertNotIn("USB123", str(receipt))
        self.assertEqual(receipt["checks"]["installed_signer_match"], "NOT_VERIFIED")
        self.assertTrue(calls)

    def test_reject_unapproved_and_multiple_devices(self):
        for state in ("", "USB123\tunauthorized\n", "USB123\tdevice\nUSB999\tdevice\n"):
            runner, _ = fake_runner(serials=state)
            with self.assertRaisesRegex(mod.PreflightError, "REQUIRE_EXACTLY_ONE_AUTHORIZED_DEVICE"):
                mod.read_device("adb", runner)

    def test_reject_emulator(self):
        runner, _ = fake_runner(qemu="1")
        with self.assertRaisesRegex(mod.PreflightError, "EMULATOR_NOT_ACCEPTED"):
            mod.read_device("adb", runner)

    def test_candidate_requires_higher_binary_code_and_real_crypto(self):
        with tempfile.TemporaryDirectory() as d:
            apk = Path(d) / "candidate.apk"
            apk.write_bytes(b"SYNTHETIC FIXTURE ONLY NOT A SIGNED APK")
            runner, calls = fake_runner()
            result = mod.build_receipt("adb", "aapt", "apksigner", apk, None, runner)
            self.assertEqual(result["candidate"]["apk_version_code"], 2129)
            self.assertEqual(result["checks"]["candidate_local_cryptographic_identity"], "PASS")
            self.assertFalse(result["installation_authorized"])
            self.assertTrue(any(x[0] == "apksigner" for x in calls))
            runner, _ = fake_runner(newer=2128)
            with self.assertRaisesRegex(mod.PreflightError, "CANDIDATE_NOT_NEWER"):
                mod.build_receipt("adb", "aapt", "apksigner", apk, None, runner)
            runner, _ = fake_runner(cert="0" * 64)
            with self.assertRaisesRegex(mod.PreflightError, "CERTIFICATE_MISMATCH"):
                mod.build_receipt("adb", "aapt", "apksigner", apk, None, runner)

    def test_file_hash_is_not_backup_restore_proof(self):
        with tempfile.TemporaryDirectory() as d:
            backup = Path(d) / "private.backup"
            backup.write_bytes(b"non-empty bytes only; not proven restorable")
            runner, _ = fake_runner()
            receipt = mod.build_receipt("adb", "aapt", "apksigner", None, backup, runner)
            self.assertEqual(receipt["backup"]["status"], "FILE_EXISTS_CHECKSUM_ONLY")
            self.assertEqual(receipt["backup"]["restorability"], "NOT_VERIFIED")
            self.assertNotIn(str(backup), str(receipt))

    def test_reject_symlink_input(self):
        with tempfile.TemporaryDirectory() as d:
            real = Path(d) / "target"
            real.write_bytes(b"hello")
            link = Path(d) / "link"
            link.symlink_to(real)
            with self.assertRaisesRegex(mod.PreflightError, "SYMLINK"):
                mod.regular_file(link, "BACKUP")

    def test_output_cannot_overwrite_backup_apk_or_hardlink(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            backup = root / "backup.dat"
            backup.write_bytes(b"DO_NOT_DELETE_USER_BACKUP")
            apk = root / "candidate.apk"
            apk.write_bytes(b"DO_NOT_DELETE_SIGNED_APK")
            link = root / "backup-alias.dat"
            link.hardlink_to(backup)
            original_backup, original_apk = backup.read_bytes(), apk.read_bytes()
            for existing in (backup, apk, link):
                with self.assertRaisesRegex(mod.PreflightError, "OUTPUT_ALREADY_EXISTS"):
                    mod.write_receipt_exclusive(existing, '{"receipt": true}\n')
            self.assertEqual(backup.read_bytes(), original_backup)
            self.assertEqual(apk.read_bytes(), original_apk)
            self.assertEqual(link.read_bytes(), original_backup)
            fresh = root / "fresh-receipt.json"
            mod.write_receipt_exclusive(fresh, '{"ok": true}\n')
            self.assertEqual(fresh.read_text(), '{"ok": true}\n')
            with self.assertRaisesRegex(mod.PreflightError, "OUTPUT_ALREADY_EXISTS"):
                mod.write_receipt_exclusive(fresh, '{"replaced": true}\n')
            self.assertEqual(fresh.read_text(), '{"ok": true}\n')

    def test_fail_closed_on_inspector_failure(self):
        with tempfile.TemporaryDirectory() as d:
            apk = Path(d) / "candidate.apk"
            apk.write_bytes(b"fake")
            runner, _ = fake_runner(tool_failure="apksigner")
            with self.assertRaisesRegex(mod.PreflightError, "REJECTED_COMMAND"):
                mod.build_receipt("adb", "aapt", "apksigner", apk, None, runner)


if __name__ == "__main__":
    unittest.main()
