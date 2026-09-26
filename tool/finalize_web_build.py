#!/usr/bin/env python3
"""Finalize Anna's Diary Web build without reusing Flutter's legacy cache worker."""

from __future__ import annotations

import shutil
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
BUILD_WEB = ROOT / "build" / "web"
FLUTTER_WORKER = BUILD_WEB / "flutter_service_worker.js"
PUSH_WORKER_SOURCE = ROOT / "web_push" / "annas-diary-push-sw.js"
PUSH_WORKER_TARGET = BUILD_WEB / "annas-diary-push-sw.js"
RECOVERY_SOURCE = ROOT / "web_push" / "update-recovery.html"
RECOVERY_TARGET = BUILD_WEB / "update-recovery.html"


def require_file(path: Path, label: str) -> None:
    if not path.is_file():
        raise SystemExit(f"{label} is missing: {path.relative_to(ROOT)}")


def main() -> None:
    require_file(FLUTTER_WORKER, "Generated Flutter migration service worker")
    require_file(PUSH_WORKER_SOURCE, "Dedicated Web Push service worker")
    require_file(RECOVERY_SOURCE, "Web cache recovery page")

    # Keep Flutter's generated worker untouched. On current Flutter releases it
    # is a one-shot migration worker that removes obsolete Flutter PWA caches.
    # Web Push gets its own stable worker so notification delivery is no longer
    # coupled to Flutter's deprecated PWA cache/service-worker lifecycle.
    shutil.copyfile(PUSH_WORKER_SOURCE, PUSH_WORKER_TARGET)
    shutil.copyfile(RECOVERY_SOURCE, RECOVERY_TARGET)

    print(
        "Web build finalized: dedicated Web Push worker + cache recovery page"
    )


if __name__ == "__main__":
    main()
