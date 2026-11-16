#!/usr/bin/env python3
"""Read-only, heuristic scan of local Flutter/Dart checkouts.

Findings are candidates, not proof of runtime defects. No network, no writes to
scanned repositories, no automatic fixes or promotion of capability evidence.
"""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

RULES = (
    ("deprecated_button", "LEGACY_API", re.compile(r"\b(?:RaisedButton|FlatButton|OutlineButton)\s*\(")),
    ("legacy_snackbar", "LEGACY_API", re.compile(r"\bScaffold\s*\.\s*of\s*\([^)]*\)\s*\.\s*showSnackBar\s*\(")),
    ("legacy_geolocator_instance", "LEGACY_API", re.compile(r"\bGeolocator\s*\(")),
    ("legacy_theme_field", "REVIEW", re.compile(r"\b(?:accentColor|buttonColor|hintColor)\s*:")),
    ("named_navigation", "REVIEW", re.compile(r"\bNavigator\s*\.\s*pushNamed\s*\(")),
    ("legacy_preferences", "REVIEW", re.compile(r"\bSharedPreferences\s*\.\s*getInstance\s*\(")),
    ("native_dart_io", "REVIEW", re.compile(r"\b(?:import|export)\s+['\"]dart:io['\"]")),
    ("eager_listview", "REVIEW", re.compile(r"\bListView\s*\(")),
    ("async_void_handler", "REVIEW", re.compile(r"\bvoid\s+\w+\s*\([^;{}]*\)\s*async\s*\{", re.S)),
)
SKIP_DIRS = {".git", ".dart_tool", "build", "node_modules", ".symlinks", ".fvm"}
SKIP_SUFFIXES = (".g.dart", ".freezed.dart", ".gr.dart", ".mocks.dart")


def _mask_non_code(source: str) -> str:
    """Blank strings and Dart comments, preserving character and line offsets.

    This is a conservative lexical filter, not a Dart parser. Interpolation
    inside strings is intentionally not scanned and remains a documented limit.
    """
    masked = list(source)
    length = len(source)

    def erase(first: int, end: int) -> None:
        for pos in range(first, end):
            if source[pos] != "\n":
                masked[pos] = " "

    index = 0
    while index < length:
        if source.startswith("//", index):
            end = source.find("\n", index)
            end = length if end == -1 else end
            erase(index, end)
            index = end
            continue
        if source.startswith("/*", index):
            depth = 1
            end = index + 2
            while end < length and depth:
                if source.startswith("/*", end):
                    depth += 1
                    end += 2
                elif source.startswith("*/", end):
                    depth -= 1
                    end += 2
                else:
                    end += 1
            erase(index, end)
            index = end
            continue
        if source[index] in ("'", '"'):
            quote = source[index]
            delim = quote * (3 if source.startswith(quote * 3, index) else 1)
            end = index + len(delim)
            while end < length:
                if source[end] == "\\":
                    end += 2
                elif source.startswith(delim, end):
                    end += len(delim)
                    break
                else:
                    end += 1
            erase(index, min(end, length))
            index = min(end, length)
            continue
        index += 1
    return "".join(masked)


def scan(root: Path, max_findings: int = 5000) -> dict:
    if not root.is_dir():
        raise ValueError(f"Not a local directory: {root}")
    findings = []
    scanned = 0
    skipped = 0
    truncated = False
    legacy_api_detected = False
    for path in sorted(root.rglob("*.dart")):
        rel = path.relative_to(root)
        if any(part in SKIP_DIRS for part in rel.parts) or path.name.endswith(SKIP_SUFFIXES):
            skipped += 1
            continue
        if path.is_symlink():
            skipped += 1
            continue
        try:
            content = path.read_text(encoding="utf-8")
        except (UnicodeError, OSError):
            skipped += 1
            continue
        scanned += 1
        masked = _mask_non_code(content)
        for rid, category, pattern in RULES:
            # For import paths, use raw text but require an unmasked keyword.
            haystack = content if rid == "native_dart_io" else masked
            for match in pattern.finditer(haystack):
                if rid == "native_dart_io" and masked[match.start()] == " ":
                    continue
                if category == "LEGACY_API":
                    legacy_api_detected = True
                if len(findings) >= max_findings:
                    truncated = True
                    continue  # Continue scanning for legacy APIs even after cap.
                line = content.count("\n", 0, match.start()) + 1
                snippet = content.splitlines()[line - 1].strip()[:160]
                findings.append({
                    "rule": rid, "category": category, "file": rel.as_posix(),
                    "line": line, "excerpt": snippet,
                })
    return {
        "root": str(root), "scanned_dart_files": scanned,
        "skipped_files": skipped, "truncated": truncated,
        "legacy_api_detected": legacy_api_detected,
        "findings": findings,
        "notice": "Heuristic candidates, not confirmed bugs or verified absence.",
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("checkout", nargs="+", type=Path, help="local repository directories")
    parser.add_argument("--fail-on-legacy-api", action="store_true", help="fail only on high-confidence deprecated APIs")
    parser.add_argument("--max-findings", type=int, default=5000)
    args = parser.parse_args()
    if args.max_findings < 1:
        parser.error("--max-findings must be positive")
    try:
        reports = [scan(root, max_findings=args.max_findings) for root in args.checkout]
    except ValueError as exc:
        parser.error(str(exc))
    print(json.dumps({"schema_version": 1, "reports": reports}, ensure_ascii=False, indent=2))
    return int(args.fail_on_legacy_api and any(
        report["legacy_api_detected"] for report in reports
    ))


if __name__ == "__main__":
    raise SystemExit(main())
