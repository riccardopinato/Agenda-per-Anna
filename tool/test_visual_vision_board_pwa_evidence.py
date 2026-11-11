"""Structural regression tests only: not evidence of a physical PWA run."""
import copy
import json
import unittest
from pathlib import Path

from validate_vision_board_pwa_evidence import validate

TEMPLATE = Path(__file__).resolve().parents[1] / "docs/qa/vision_board_two_pwa_template.json"


class VisionBoardEvidenceShapeTests(unittest.TestCase):
    def setUp(self):
        self.data = json.loads(TEMPLATE.read_text(encoding="utf-8"))

    def test_unexecuted_template_is_structurally_valid_but_not_certified(self):
        counts = validate(self.data)
        self.assertEqual(sum(counts.values()), 30)
        self.assertEqual(counts["PASS"], 0)
        with self.assertRaisesRegex(ValueError, "Not all scenarios"):
            validate(self.data, require_complete=True)

    def test_cannot_fake_pass_without_real_evidence_fields(self):
        invalid = copy.deepcopy(self.data)
        invalid["scenarios"][0]["status"] = "PASS"
        with self.assertRaisesRegex(ValueError, "observation"):
            validate(invalid)

    def test_missing_and_duplicate_ids_fail_closed(self):
        for change in ("remove", "duplicate"):
            invalid = copy.deepcopy(self.data)
            if change == "remove":
                invalid["scenarios"].pop()
            else:
                invalid["scenarios"][-1]["id"] = invalid["scenarios"][0]["id"]
            with self.assertRaisesRegex(ValueError, "scenario IDs"):
                validate(invalid)

    def test_cannot_change_required_a_b_scope(self):
        invalid = copy.deepcopy(self.data)
        invalid["scenarios"][0]["devices"] = "A"
        with self.assertRaisesRegex(ValueError, "required device scope"):
            validate(invalid)

    def test_pass_requires_actual_both_device_coverage(self):
        invalid = copy.deepcopy(self.data)
        case = next(x for x in invalid["scenarios"] if x["id"] == "S13-01")
        case.update(
            status="PASS", observed="A only", testerRef="QA-A",
            testedAt="2026-11-11T09:00:00+01:00",
            evidenceRefs=["safe-evidence-ref"], testedOn=["A"],
        )
        with self.assertRaisesRegex(ValueError, "required device coverage"):
            validate(invalid)

    def test_performance_rejects_nonfinite_json_values(self):
        for number in (float("nan"), float("inf")):
            invalid = copy.deepcopy(self.data)
            case = next(x for x in invalid["scenarios"] if x["id"] == "PWA-13")
            case.update(
                status="PASS", observed="Measured synthetic photos", testerRef="QA-B",
                testedAt="2026-11-11T09:00:00+01:00",
                evidenceRefs=["safe-evidence-ref"], testedOn=["A", "B"],
                metrics={"coldMs": number, "warmMs": 100, "saveMs": 200, "memoryMiB": 70},
            )
            with self.assertRaisesRegex(ValueError, "invalid performance numbers"):
                validate(invalid)

    def test_performance_cannot_be_assumed(self):
        invalid = copy.deepcopy(self.data)
        p = next(x for x in invalid["scenarios"] if x["id"] == "PWA-13")
        p.update(status="PASS", observed="Measured synthetic photos", testerRef="QA-A", testedAt="2026-11-11T09:00:00+01:00", evidenceRefs=["safe-evidence-ref"], testedOn=["A", "B"])
        with self.assertRaisesRegex(ValueError, "performance numbers"):
            validate(invalid)


if __name__ == "__main__":
    unittest.main()
