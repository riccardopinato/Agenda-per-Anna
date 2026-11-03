# v1.07-C2 — CAP-0069 Visual regression

The source-controlled matrix in .maestro/applab-visual-matrix.json defines ten
existing AppLab journey checkpoints and seven fixed variants (70 screenshot
pairs): EN/IT/ES/FR/PT, dark/light, five preset palettes and custom HSV,
small phone/tablet, large text and reduced motion.

Only synthetic fixtures are permitted for approved screenshot evidence.
Vault, shared private content and account screens are excluded.
The current AppLab visual policy and masks remain intact.

Once an approved baseline and candidate PNG set exist, run:

python3 tool/compare_visual_baselines.py --baseline APPROVED_DIR --candidate CANDIDATE_DIR

Requires Python and Pillow 11.3.0. The comparator rejects any missing or
unexpected PNG, mismatched image dimensions and excessive RGB pixel differences.
It never records or overwrites an approved baseline.
Synthetic comparator unit tests run in Development checks.

Status: source tool and matrix IMPLEMENTED; 70 approved baseline captures,
candidate screenshot comparisons, actual device display and physical QA
NOT VERIFIED. Do not treat comparator unit-test PASS as visual acceptance.


## Screenshot evidence collection gate (2 November 2026)

A screenshot comparison is valid only after two **independent** synthetic captures
from the actual app UI exist: a separately approved baseline and a candidate
capture. Never manufacture identical PNGs to force a PASS, and never substitute
stock images, diagrams, mocked screen paintings, personal diary captures or
screens of the Private Vault for the actual application.

1. Pin the exact source SHA and screen/environment configuration.
2. In a test-only isolated app install with **synthetic data only**, capture
   each of the ten whitelisted screen checkpoints at each of the seven
   configured variants. Capture PNGs must use
   `{checkpoint}__{variant}.png`, and sizes must match the matrix.
3. Create a fixture declaration file containing only:
   `{"fixture_id":"<test fixture reference>","synthetic_only":true,"contains_user_data":false}`.
   This is an operator declaration, **not** independent proof of data safety.
4. Validate each 70-image folder and generate SHA-256 provenance:
   `python3 tool/validate_visual_evidence.py --captures CAPTURE_DIR --fixture-attestation FIXTURE.json --source-sha 40_CHAR_SOURCE_SHA --output-manifest EVIDENCE.json`.
5. Obtain explicit human visual approval of a trustworthy baseline; record
   reviewer, approval time and the baseline evidence manifest SHA-256 in a
   separately reviewed QA record. The capture validator intentionally does
   **not** grant approval.
6. Run `python3 tool/compare_visual_baselines.py --baseline APPROVED_DIR --candidate CANDIDATE_DIR`.
   Investigate meaningful differences and repeat on the *exact new commit*.
   Compare output is not proof of user-device visual acceptance.

The evidence validator checks exact inventory, PNG signature and RGB channels,
expected dimensions, PNG metadata and source identity. It rejects screenshot
packs with any extra or missing files. Its contract is regression-tested inside
the existing Development checks workflow. It **cannot verify from bytes alone**
that a screenshot came from the app or that the fixture attestation is true.

**Status:** validator implemented; 70 baseline PNG files, approved baseline
and actual screen-capture run remain **NOT VERIFIED** until provided.
