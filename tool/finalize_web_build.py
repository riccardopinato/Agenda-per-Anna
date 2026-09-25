#!/usr/bin/env python3
"""Append Anna's Diary Web Push handlers to Flutter's generated service worker."""

from __future__ import annotations

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
GENERATED = ROOT / "build" / "web" / "flutter_service_worker.js"
HANDLERS = ROOT / "web_push" / "annas-diary-push-sw.js"
MARKER = 'annas-diary-push-v044'


def main() -> None:
    if not GENERATED.is_file():
        raise SystemExit("Generated Flutter service worker is missing")
    if not HANDLERS.is_file():
        raise SystemExit("Web Push service-worker handlers are missing")

    generated = GENERATED.read_text(encoding="utf-8")
    if MARKER in generated:
        print("Web Push handlers already present")
        return

    handlers = HANDLERS.read_text(encoding="utf-8")
    GENERATED.write_text(
        generated
        + "\n\n/* "
        + MARKER
        + " */\n"
        + handlers
        + "\n",
        encoding="utf-8",
    )
    print("Flutter service worker finalized with Web Push handlers")


if __name__ == "__main__":
    main()
