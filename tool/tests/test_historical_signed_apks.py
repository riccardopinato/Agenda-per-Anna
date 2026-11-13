"""Fail-closed unit tests for the +127/+128 historical release artifact auditor.

All ZIP fixtures here are SYNTHETIC and do not claim a cryptographic APK PASS.
The real CI integration must call aapt and apksigner against real Actions bytes.
"""
import base64
import hashlib
import importlib.util
import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch
from zipfile import ZipFile

MODULE = Path(__file__).resolve().parents[1] / "verify_historical_signed_apks.py"
spec = importlib.util.spec_from_file_location("signed_pair", MODULE)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

REPO = "riccardopinato/Agenda-per-Anna"
CERT = "31be63155c831f062238179ec9b8f19d1c16a925bed1d526bc7e6a4712c62dc3"


def sample(root: Path, code=127):
    artifact_dir = root / str(code)
    artifact_dir.mkdir()
    source = "a" * 40
    run = 123400 + code
    artifact = 456700 + code
    fake_apk = b"test only - NOT A REAL APK" + bytes([code])
    apkhash = hashlib.sha256(fake_apk).hexdigest()
    manifest = {
        "repository": REPO, "sourceSha": source, "commit": source,
        "workflowRunId": str(run), "workflowRun": str(run),
        "packageId": "com.riccardopinato.agenda_per_anna",
        "appVersion": f"1.0.0-rc.6+{code}", "buildNumber": code,
        "artifactFile": "Anna-Diary-arm64-release.apk",
        "artifactSha256": apkhash, "channel": "direct-sideload",
        "signingCertificateSha256": CERT.upper(),
        "validationLevel": "ARTIFACT_BUILT",
        "physicalVerification": {"status": "PENDING"},
        "releaseReality": {
            "sourceSha": source, "artifactSha256": apkhash,
            "signingFingerprint": CERT.upper(),
            "packageId": "com.riccardopinato.agenda_per_anna",
            "workflowRun": str(run), "buildNumber": code,
            "validationLevel": "ARTIFACT_BUILT",
        },
    }
    path = artifact_dir / "artifact.zip"
    with ZipFile(path, "w") as zipped:
        zipped.writestr("Anna-Diary-arm64-release.apk", fake_apk)
        zipped.writestr("PHYSICAL_CERTIFICATION_MANIFEST.json", json.dumps(manifest))
    item = {
        "version_code": code, "source_sha": source,
        "run_id": run, "artifact_id": artifact,
        "zip_sha256": mod.digest(path), "zip_size_bytes": path.stat().st_size,
        "apk_sha256": apkhash, "apk_size_bytes": len(fake_apk),
    }
    inventory = {
        "repository": REPO, "package_id": "com.riccardopinato.agenda_per_anna",
        "version_name": "1.0.0-rc.6",
        "workflow_id": 303, "workflow_name": "Auto signed ARM64 release candidate",
        "artifact_name": "annas-diary-light-arm64",
        "apk_file": "Anna-Diary-arm64-release.apk",
        "manifest_file": "PHYSICAL_CERTIFICATION_MANIFEST.json",
        "channel": "direct-sideload", "expected_signing_certificate_sha256": CERT,
    }
    objects = {
        "run.json": {
            "id": run, "workflow_id": 303,
            "name": "Auto signed ARM64 release candidate",
            "repository": {"full_name": REPO},
            "head_sha": source, "head_branch": "main", "event": "workflow_run",
            "status": "completed", "conclusion": "success",
        },
        "artifact.json": {
            "id": artifact, "name": "annas-diary-light-arm64",
            "expired": False, "digest": "sha256:" + item["zip_sha256"],
            "size_in_bytes": item["zip_size_bytes"],
            "workflow_run": {"id": run, "head_sha": source},
        },
        "jobs.json": {"jobs": [
            {"name": "signed-apk / build", "conclusion": "success",
             "head_sha": source}]},
        "pubspec.json": {
            "encoding": "base64",
            "content": base64.b64encode(
                f"name: agenda_per_anna\nversion: 1.0.0-rc.6+{code}\n".encode()
            ).decode(),
        },
    }
    for name, body in objects.items():
        (artifact_dir / name).write_text(json.dumps(body))
    return inventory, item, artifact_dir


class SignedPairSafetyTests(unittest.TestCase):
    def test_manifest_cross_checks_origin_and_build_number(self):
        with tempfile.TemporaryDirectory() as tmp:
            inv, item, directory = sample(Path(tmp))
            with ZipFile(directory / "artifact.zip") as z:
                manifest = json.loads(z.read(inv["manifest_file"]))
            mod.verify_manifest(inv, item, manifest)
            manifest["buildNumber"] = 999
            with self.assertRaisesRegex(mod.AuditError, "RELEASE_MANIFEST_MISMATCH"):
                mod.verify_manifest(inv, item, manifest)

    def test_api_requires_signed_build_and_exact_source(self):
        with tempfile.TemporaryDirectory() as tmp:
            inv, item, directory = sample(Path(tmp))
            mod.verify_api(inv, item, directory)
            source = json.loads((directory / "run.json").read_text())
            source["head_sha"] = "b" * 40
            (directory / "run.json").write_text(json.dumps(source))
            with self.assertRaisesRegex(mod.AuditError, "RUN_PROVENANCE_MISMATCH"):
                mod.verify_api(inv, item, directory)

    def test_api_rejects_skipped_signing_job(self):
        with tempfile.TemporaryDirectory() as tmp:
            inv, item, directory = sample(Path(tmp))
            jobs = json.loads((directory / "jobs.json").read_text())
            jobs["jobs"][0]["conclusion"] = "skipped"
            (directory / "jobs.json").write_text(json.dumps(jobs))
            with self.assertRaisesRegex(mod.AuditError, "SIGNED_BUILD_JOB_NOT_SUCCESS"):
                mod.verify_api(inv, item, directory)

    def test_api_rejects_malformed_artifact_metadata(self):
        with tempfile.TemporaryDirectory() as tmp:
            inv, item, directory = sample(Path(tmp))
            artifact = json.loads((directory / "artifact.json").read_text())
            artifact["digest"] = "sha256:" + "0" * 64
            (directory / "artifact.json").write_text(json.dumps(artifact))
            with self.assertRaisesRegex(mod.AuditError, "ARTIFACT_API_MISMATCH"):
                mod.verify_api(inv, item, directory)

    def test_archive_bytes_must_match_pinned_zip_digest(self):
        with tempfile.TemporaryDirectory() as tmp:
            inv, item, directory = sample(Path(tmp))
            path = directory / "artifact.zip"
            path.write_bytes(path.read_bytes() + b"tamper")
            with self.assertRaisesRegex(mod.AuditError, "EXACT_ORIGINAL_ZIP_MISMATCH"):
                mod.verify_one(inv, item, Path(tmp))

    def test_no_manifest_claim_can_replace_actual_apk_inspector(self):
        with tempfile.TemporaryDirectory() as tmp:
            inv, item, directory = sample(Path(tmp))
            with patch.object(mod, "inspect_android", side_effect=mod.AuditError(
                    "APK_CRYPTOGRAPHIC_SIGNER_MISMATCH")):
                with self.assertRaisesRegex(mod.AuditError, "APK_CRYPTOGRAPHIC_SIGNER_MISMATCH"):
                    mod.verify_one(inv, item, Path(tmp))

    def test_aapt_requires_exact_manifest_and_apksigner_crypto(self):
        with tempfile.TemporaryDirectory() as tmp:
            inv, item, directory = sample(Path(tmp))
            apk = Path(tmp) / "fixture.apk"
            apk.write_bytes(b"fake manifest cannot create signed APK")
            badging = ("package: name='com.riccardopinato.agenda_per_anna' "
                       "versionCode='127' versionName='1.0.0-rc.6'\n")
            with patch.object(mod, "command", return_value=badging):
                with self.assertRaises(Exception):
                    mod.inspect_android(inv, item, apk)

    def test_audit_checkout_not_synthetic_pr_merge_sha(self):
        with patch.object(mod, "command", return_value="a" * 40 + "\n"):
            with self.assertRaisesRegex(mod.AuditError, "AUDIT_CHECKOUT_SHA_MISMATCH"):
                mod.audit({}, Path("."), "b" * 40)


if __name__ == "__main__":
    unittest.main()
