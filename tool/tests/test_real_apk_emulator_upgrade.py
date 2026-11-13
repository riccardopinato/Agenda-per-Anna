"""Offline fail-closed checks for original signed APK emulator rehearsal."""
from __future__ import annotations

import importlib.util
import json
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

PATH = Path(__file__).resolve().parents[1] / "rehearse_real_apk_emulator_upgrade.py"
spec = importlib.util.spec_from_file_location("anna_emulator_recovery", PATH)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)


class SafetyTests(unittest.TestCase):
    def test_non_emulator_is_forbidden(self):
        with patch.object(mod, "adb", side_effect=[
            "R5NREAL", "0", "35"
        ]):
            with self.assertRaisesRegex(mod.RehearsalError, "ONLY_DISPOSABLE"):
                mod.emulator_guard()

    def test_emulator_lower_than_api30_is_forbidden(self):
        with patch.object(mod, "adb", side_effect=[
            "emulator-5554", "1", "29"
        ]):
            with self.assertRaisesRegex(mod.RehearsalError, "ONLY_DISPOSABLE"):
                mod.emulator_guard()

    def test_preinstalled_app_is_blocked_before_touching_data(self):
        with patch.object(mod, "cmd", return_value=subprocess.CompletedProcess(
                [], 0, "package:/data/app/base.apk", "")):
            with self.assertRaisesRegex(mod.RehearsalError, "NONEMPTY_EMULATOR"):
                mod.ensure_uninstalled()

    def test_empty_package_with_android15_exit1_is_allowed(self):
        with patch.object(mod, "cmd", return_value=subprocess.CompletedProcess(
                [], 1, "", "")):
            mod.ensure_uninstalled()

    def test_unreachable_adb_transport_is_never_treated_as_absent(self):
        with patch.object(mod, "cmd", return_value=subprocess.CompletedProcess(
                [], 1, "", "error: device offline")):
            with self.assertRaisesRegex(mod.RehearsalError,
                                        "EMULATOR_PACKAGE_PROBE_FAILED"):
                mod.ensure_uninstalled()

    def test_install_requires_actual_version_from_package_manager(self):
        with patch.object(mod, "adb", return_value="Success"):
            with patch.object(mod, "installed_version", return_value=2127):
                with self.assertRaisesRegex(mod.RehearsalError,
                                            "ACTUAL_INSTALLED_VERSION_MISMATCH"):
                    mod.install_expect(Path("never-installed.apk"), 2128)

    def test_original_zip_and_apk_missing_fail_closed(self):
        inventory_path = Path(__file__).resolve().parents[2] / (
            "docs/release_evidence/ANDROID_SIGNED_PAIR_127_128_PINNED.json")
        inv = json.loads(inventory_path.read_text())
        with tempfile.TemporaryDirectory() as tmp:
            with self.assertRaisesRegex(mod.RehearsalError,
                                        "ORIGINAL_ZIP_HASH_MISMATCH"):
                mod.inspect_local_pair(Path(tmp), inv, Path(tmp))

    def test_real_workflow_head_must_be_exact_sha(self):
        with patch.object(mod, "run", return_value="a" * 40):
            with self.assertRaisesRegex(mod.RehearsalError,
                                        "EXACT_REHEARSAL_HEAD_MISMATCH"):
                mod.rehearse(Path("."), {}, "b" * 40)

    def test_missing_maestro_flow_cannot_be_pass(self):
        with self.assertRaisesRegex(mod.RehearsalError,
                                    "MAESTRO_JOURNEY_MISSING"):
            mod.maestro("does-not-exist/maestro.yml")

    def test_real_app_canary_not_injected_by_debug_run_as(self):
        source = PATH.read_text()
        self.assertNotIn("run-as", source)
        self.assertNotIn('adb("uninstall"', source)
        self.assertNotIn('"pm", "clear"', source)
        self.assertNotIn('"install", "-d"', source)
        self.assertIn('MAESTRO_FLOW_SEED', source)
        self.assertIn('MAESTRO_FLOW_VERIFY', source)


if __name__ == "__main__":
    unittest.main()
