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
