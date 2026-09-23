#!/usr/bin/env python3
"""Produce a compact, diff-friendly APK size report."""

from __future__ import annotations

import argparse
import zipfile
from collections import defaultdict
from pathlib import Path


def human(size: int) -> str:
    units = ["B", "KiB", "MiB", "GiB"]
    value = float(size)
    for unit in units:
        if value < 1024 or unit == units[-1]:
            return f"{value:.2f} {unit}"
        value /= 1024
    return f"{size} B"


def group_name(path: str) -> str:
    if path.startswith("lib/"):
        return "native_libs"
    if path.startswith("assets/") or path.startswith("flutter_assets/"):
        return "flutter_assets"
    if path.startswith("res/"):
        return "android_resources"
    if path.startswith("META-INF/"):
        return "meta_inf"
    if path.endswith(".dex"):
        return "dex"
    return "other"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("apk", type=Path)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    if not args.apk.is_file():
        raise SystemExit(f"APK not found: {args.apk}")

    compressed = defaultdict(int)
    uncompressed = defaultdict(int)
    largest = []

    with zipfile.ZipFile(args.apk) as archive:
        for info in archive.infolist():
            if info.is_dir():
                continue
            group = group_name(info.filename)
            compressed[group] += info.compress_size
            uncompressed[group] += info.file_size
            largest.append((info.compress_size, info.file_size, info.filename))

    largest.sort(reverse=True)
    total = args.apk.stat().st_size

    lines = [
        f"apk={args.apk.name}",
        f"apk_bytes={total}",
        f"apk_size={human(total)}",
        "",
        "[compressed_by_group]",
    ]
    for key in sorted(compressed, key=compressed.get, reverse=True):
        lines.append(
            f"{key}={compressed[key]} ({human(compressed[key])}) "
            f"uncompressed={human(uncompressed[key])}"
        )

    lines += ["", "[largest_entries]"]
    for csize, usize, name in largest[:25]:
        lines.append(
            f"{csize:>10}  {human(csize):>10}  "
            f"raw={human(usize):>10}  {name}"
        )

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print("\n".join(lines))


if __name__ == "__main__":
    main()
