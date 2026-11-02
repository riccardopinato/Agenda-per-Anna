"""Fail-closed screenshot evidence packaging regression tests."""
import json
import tempfile
import unittest
from pathlib import Path
from PIL import Image, PngImagePlugin
from validate_visual_evidence import build_manifest


class VisualEvidenceContractTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.captures = self.root / "captures"
        self.captures.mkdir()
        self.matrix = self.root / "matrix.json"
        self.fixture = self.root / "fixture.json"
        self.sha = "a" * 40
        self.checkpoints = [f"screen-{i}" for i in range(10)]
        self.variants = [
            {"id": f"variant-{i}", "width": 16, "height": 18}
            for i in range(7)
        ]
        self.write_matrix()
        self.fixture.write_text(json.dumps({
            "fixture_id": "synthetic-fixture-v1",
            "synthetic_only": True,
            "contains_user_data": False,
        }), encoding="utf-8")
        for cp in self.checkpoints:
            for v in self.variants:
                Image.new("RGB", (16, 18), (255, 255, 255)).save(
                    self.captures / f'{cp}__{v["id"]}.png')

    def write_matrix(self):
        self.matrix.write_text(json.dumps({
            "checkpoints": self.checkpoints,
            "variants": self.variants,
            "excluded": ["vault", "account", "shared"],
        }), encoding="utf-8")

    def validate(self):
        return build_manifest(
            self.captures, self.matrix, self.sha, self.fixture)

    def test_complete_pack_is_not_mistaken_for_approved_baseline(self):
        result = self.validate()
        self.assertEqual(result["screenshot_count"], 70)
        self.assertEqual(result["approval_status"], "NOT_VERIFIED")
        self.assertEqual(result["physical_visual_review"], "NOT_VERIFIED")
        self.assertEqual(len(result["image_evidence"]), 70)
        self.assertTrue(all(len(r["sha256"]) == 64
                            for r in result["image_evidence"]))

    def test_missing_and_unexpected_files_block(self):
        (self.captures / "screen-0__variant-0.png").unlink()
        with self.assertRaises(ValueError):
            self.validate()
        (self.captures / "unapproved.png").write_bytes(b"invalid")
        with self.assertRaises(ValueError):
            self.validate()

    def test_mismatched_dimensions_block(self):
        Image.new("RGB", (10, 18)).save(
            self.captures / "screen-0__variant-0.png")
        with self.assertRaisesRegex(ValueError, "dimensions"):
            self.validate()

    def test_embedded_metadata_blocks(self):
        tags = PngImagePlugin.PngInfo()
        tags.add_text("Comment", "private user info")
        Image.new("RGB", (16, 18)).save(
            self.captures / "screen-0__variant-0.png", pnginfo=tags)
        with self.assertRaisesRegex(ValueError, "metadata"):
            self.validate()

    def test_private_checkpoints_and_missing_attestation_block(self):
        self.checkpoints[0] = "vault"
        self.write_matrix()
        with self.assertRaisesRegex(ValueError, "private"):
            self.validate()
        self.checkpoints[0] = "screen-0"
        self.write_matrix()
        self.fixture.write_text(json.dumps({
            "fixture_id": "synthetic-fixture-v1",
            "synthetic_only": False,
            "contains_user_data": False,
        }))
        with self.assertRaisesRegex(ValueError, "synthetic"):
            self.validate()

    def test_unpinned_source_blocks(self):
        self.sha = "main"
        with self.assertRaisesRegex(ValueError, "source SHA"):
            self.validate()


if __name__ == "__main__":
    unittest.main()
