import json
import tempfile
import unittest
from pathlib import Path

from PIL import Image
from compare_visual_baselines import compare


class VisualComparatorTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        root = Path(self.tmp.name)
        self.reference = root / "approved"
        self.candidate = root / "candidate"
        self.reference.mkdir()
        self.candidate.mkdir()
        self.manifest = root / "matrix.json"
        self.names = ["s" + str(i) for i in range(10)]
        self.cfg = {
            "checkpoints": self.names,
            "excluded": ["vault", "shared", "account"],
            "variants": [{"id": "test"}],
            "image_contract": {
                "per_channel_difference_threshold": 12,
                "max_changed_pixel_ratio": 0.001
            }
        }
        self._manifest()
        for name in self.names:
            filename = name + "__test.png"
            Image.new("RGB", (4, 4), (255, 255, 255)).save(self.reference / filename)
            Image.new("RGB", (4, 4), (255, 255, 255)).save(self.candidate / filename)

    def _manifest(self):
        self.manifest.write_text(json.dumps(self.cfg), encoding="utf-8")

    def test_exact_synthetic_pairs_pass(self):
        self.assertEqual(compare(self.reference, self.candidate, self.manifest), 0)

    def test_pixel_difference_fails(self):
        Image.new("RGB", (4, 4), (0, 0, 0)).save(self.candidate / "s0__test.png")
        self.assertEqual(compare(self.reference, self.candidate, self.manifest), 1)

    def test_missing_file_blocks(self):
        (self.candidate / "s0__test.png").unlink()
        self.assertEqual(compare(self.reference, self.candidate, self.manifest), 2)

    def test_unapproved_file_blocks(self):
        Image.new("RGB", (4, 4)).save(self.candidate / "vault__test.png")
        self.assertEqual(compare(self.reference, self.candidate, self.manifest), 2)

    def test_empty_variants_block(self):
        self.cfg["variants"] = []
        self._manifest()
        self.assertEqual(compare(self.reference, self.candidate, self.manifest), 2)

    def test_private_checkpoint_blocks(self):
        self.cfg["checkpoints"][0] = "vault"
        self._manifest()
        self.assertEqual(compare(self.reference, self.candidate, self.manifest), 2)


if __name__ == "__main__":
    unittest.main()
