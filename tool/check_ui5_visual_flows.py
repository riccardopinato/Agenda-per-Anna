#!/usr/bin/env python3
"""Fast, dependency-free source contract check; NEVER builds or installs APKs."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
def read(path):
    return (ROOT / path).read_text(encoding="utf-8")
def require(condition, message):
    if not condition:
        raise SystemExit(f"FAIL: {message}")

manifest = json.loads(read(".maestro/applab-journey.json"))
checkpoints = manifest["checkpoints"]
require(len(checkpoints) >= 14, "visual journey catalog unexpectedly shrank")
for entry in checkpoints:
    path = entry["flow"]
    require((ROOT / path).is_file(), f"missing visual checkpoint: {path}")
    require("appId:" in read(path), f"missing Maestro appId: {path}")
    require("\n---\n" in read(path), f"missing Maestro flow separator: {path}")

today = read(".maestro/journey/today.yaml")
home = read(".maestro/journey/home.yaml")
core = read(".maestro/journeys/core-shell.yaml")
planner = read("lib/src/planner_views.dart")
shell = read("lib/src/screens/home_inbox_search.dart")
capture = read("lib/src/unified_capture.dart")

for label in (
    "main-nav-today", "ui5-today-date-strip", "main-nav-create",
    "capture-effective-date",
):
    require(f"id: '{label}'" in today, f"Today UI5 visual flow missing {label}")
require("identifier: 'ui5-today-date-strip'" in planner,
        "Today date strip lacks stable semantics")
require("identifier: 'main-nav-create'" in shell,
        "central Create lacks stable semantics")
require("identifier: 'capture-effective-date'" in capture,
        "capture date lacks stable semantics")
require("id: 'capture-effective-date'" in core,
        "core-shell must verify real Capture date control")
require("id: 'main-nav-today'" in home and "id: 'ui5-today-date-strip'" in home,
        "historical Home return must land on UI5 Today")
for path in [".maestro/journey/today.yaml", ".maestro/journey/home.yaml"]:
    text = "\n".join(
        line for line in read(path).splitlines()
        if not line.lstrip().startswith("#")
    )
    for obsolete in ("today-focus-card", "(Cattura|Capture|Capturar|Capturer)",
                     "Pensieri e note|Thoughts and notes"):
        require(obsolete not in text, f"stale UI selector in {path}: {obsolete}")

applab = read(".github/workflows/applab.yml")
require("AppLab Source Gate" in applab, "source-only gate missing")
require("python3 tool/check_ui5_visual_flows.py" in applab,
        "source gate must run visual contract checks")
for disallowed in ("external-project-runner.yml", "flutter build apk",
                   "run_maestro: true", "android-emulator-runner"):
    require(disallowed not in applab, f"source gate invokes Android: {disallowed}")

development = read(".github/workflows/dev-checks.yml")
require("flutter analyze" in development and "flutter test" in development,
        "development source checks missing")
require("flutter build apk" not in development,
        "development workflow still builds APK")
for path in (
    ".github/workflows/android-size-audit.yml",
    ".github/workflows/android-integration.yml",
    ".github/workflows/sideload-arm64.yml",
):
    workflow = read(path)
    require("workflow_dispatch:" in workflow,
            f"manual Android dispatch unavailable: {path}")
    require("\n  push:" not in workflow and "\n  pull_request:" not in workflow,
            f"automatic Android build/test trigger remains: {path}")

print(f"PASS: {len(checkpoints)} visual flow sources, UI5 selectors, "
      "source-only AppLab and manual Android boundaries")
