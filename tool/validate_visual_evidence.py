#!/usr/bin/env python3
"""Fail-closed provenance packaging for CAP-0069 synthetic visual captures.

This validates screenshot inventory and image dimensions. It does NOT assert
that images are genuine app screenshots or approve visual differences.
"""
import argparse
import hashlib
import json
import re
import sys
from pathlib import Path


def build_manifest(capture_dir: Path, matrix_file: Path, source_sha: str,
                   fixture_file: Path) -> dict:
    from PIL import Image

    if not re.fullmatch(r"[0-9a-f]{40}", source_sha):
        raise ValueError("exact source SHA is required")
    matrix = json.loads(matrix_file.read_text(encoding="utf-8"))
    fixture = json.loads(fixture_file.read_text(encoding="utf-8"))
    if fixture.get("synthetic_only") is not True:
        raise ValueError("synthetic fixture attestation is required")
    if fixture.get("contains_user_data") is not False:
        raise ValueError("user data cannot be included")
    if fixture.get("fixture_id", "").strip() == "":
        raise ValueError("fixture_id is required")
    checkpoints = matrix["checkpoints"]
    variants = matrix["variants"]
    excluded = set(matrix.get("excluded", []))
    if len(checkpoints) != 10 or len(set(checkpoints)) != 10:
        raise ValueError("expected 10 distinct checkpoints")
    if len(variants) != 7 or len({v["id"] for v in variants}) != 7:
        raise ValueError("expected 7 distinct visual variants")
    if set(checkpoints) & excluded:
        raise ValueError("private checkpoint forbidden")
    expected = {
        f'{checkpoint}__{variant["id"]}.png': variant
        for checkpoint in checkpoints for variant in variants
    }
    if not capture_dir.is_dir() or capture_dir.is_symlink():
        raise ValueError("capture directory missing or symlink")
    found = {p.name for p in capture_dir.iterdir()}
    if found != set(expected):
        raise ValueError(
            f"missing {len(set(expected) - found)}, unexpected "
            f"{len(found - set(expected))} capture files"
        )
    records = []
    for filename, variant in sorted(expected.items()):
        path = capture_dir / filename
        if path.is_symlink() or not path.is_file():
            raise ValueError("capture file is not regular: " + filename)
        raw = path.read_bytes()
        # PNG metadata chunks can appear AFTER IDAT; Image.info on open
        # alone is insufficient to detect those. Scan the entire chunk
        # inventory and require exact termination before trusting the image.
        if not raw.startswith(b"\\x89PNG\\r\\n\\x1a\\n"):
            raise ValueError("invalid PNG signature: " + filename)
        offset = 8
        has_end = False
        while offset + 12 <= len(raw):
            chunk_length = int.from_bytes(raw[offset:offset + 4], "big")
            kind = raw[offset + 4:offset + 8]
            offset += 12 + chunk_length
            if offset > len(raw):
                raise ValueError("truncated PNG chunk: " + filename)
            if kind in (b"tEXt", b"zTXt", b"iTXt", b"eXIf"):
                raise ValueError("PNG metadata is forbidden: " + filename)
            if kind == b"IEND":
                has_end = True
                break
        if not has_end or offset != len(raw):
            raise ValueError("invalid PNG end or trailing bytes: " + filename)
        with Image.open(path) as image:
            if image.format != "PNG" or image.mode not in ("RGB", "RGBA"):
                raise ValueError("PNG RGB/RGBA required: " + filename)
            if image.size != (variant["width"], variant["height"]):
                raise ValueError("unexpected screenshot dimensions: " + filename)
            if image.info:
                raise ValueError("PNG metadata is forbidden: " + filename)
            image.verify()
        records.append({
            "filename": filename,
            "sha256": hashlib.sha256(raw).hexdigest(),
            "bytes": len(raw),
        })
    return {
        "schema_version": 1,
        "source_sha": source_sha,
        "fixture_id": fixture["fixture_id"],
        "synthetic_data_declared": True,
        "contains_user_data_declared": False,
        "screenshot_count": len(records),
        "image_evidence": records,
        "approval_status": "NOT_VERIFIED",
        "physical_visual_review": "NOT_VERIFIED",
        "scope": "CAP-0069 synthetic screenshot inventory only",
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--captures", type=Path, required=True)
    parser.add_argument("--matrix", type=Path,
                        default=Path(".maestro/applab-visual-matrix.json"))
    parser.add_argument("--fixture-attestation", type=Path, required=True)
    parser.add_argument("--source-sha", required=True)
    parser.add_argument("--output-manifest", type=Path, required=True)
    args = parser.parse_args()
    try:
        result = build_manifest(args.captures, args.matrix, args.source_sha,
                                args.fixture_attestation)
        args.output_manifest.parent.mkdir(parents=True, exist_ok=True)
        args.output_manifest.write_text(
            json.dumps(result, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
        print("PASS: 70 synthetic screenshot files inventoried; NOT APPROVED")
        return 0
    except (ValueError, OSError, KeyError, TypeError) as exc:
        print("BLOCKED: visual evidence invalid: " + str(exc), file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
