#!/usr/bin/env python3
"""Compare pre-approved synthetic screenshot PNGs to candidate PNGs."""
import argparse
import json
import sys
from pathlib import Path

def compare(baseline, candidate, matrix):
    try:
        from PIL import Image, ImageChops
    except ImportError:
        print("BLOCKED: Pillow dependency is missing")
        return 2
    cfg = json.loads(matrix.read_text(encoding="utf-8"))
    names = cfg["checkpoints"]
    variants = [v["id"] for v in cfg["variants"]]
    if not variants or len(set(variants)) != len(variants):
        print("BLOCKED: empty or duplicate screenshot variants")
        return 2
    if len(set(names)) != 10 or set(names) & set(cfg["excluded"]):
        print("BLOCKED: invalid or private checkpoint")
        return 2
    required = {a + "__" + b + ".png" for a in names for b in variants}
    for folder in (baseline, candidate):
        if not folder.is_dir():
            print("BLOCKED: screenshot directory missing")
            return 2
        available = {p.name for p in folder.glob("*.png")}
        if available != required:
            print("BLOCKED: missing or unapproved screenshots", len(required - available),
                  len(available - required))
            return 2
    tolerance = cfg["image_contract"]["per_channel_difference_threshold"]
    limit = cfg["image_contract"]["max_changed_pixel_ratio"]
    failures = []
    for name in sorted(required):
        with Image.open(baseline / name) as old, Image.open(candidate / name) as new:
            if old.size != new.size:
                failures.append(name + ": dimensions")
                continue
            rgb = ImageChops.difference(old.convert("RGB"), new.convert("RGB"))
            pixels = rgb.getdata()
            changed = sum(1 for p in pixels if max(p) > tolerance)
            if changed / (old.width * old.height) > limit:
                failures.append(name + ": pixel differences")
    if failures:
        print("FAIL: " + str(len(failures)) + " visual differences")
        for name in failures:
            print(name)
        return 1
    print("PASS: " + str(len(required)) + " approved synthetic screenshots")
    print("Native device verification is separate.")
    return 0

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--baseline", type=Path, required=True)
    parser.add_argument("--candidate", type=Path, required=True)
    parser.add_argument("--matrix", type=Path,
                        default=Path(".maestro/applab-visual-matrix.json"))
    args = parser.parse_args()
    try:
        return compare(args.baseline, args.candidate, args.matrix)
    except (KeyError, ValueError, OSError) as exc:
        print("BLOCKED: invalid comparison input " + str(exc), file=sys.stderr)
        return 2

if __name__ == "__main__":
    sys.exit(main())
