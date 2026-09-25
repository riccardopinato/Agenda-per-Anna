#!/usr/bin/env python3
"""Apply Anna's Diary PWA/Web Push customizations to generated Flutter web."""

from __future__ import annotations

import json
import shutil
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
WEB = ROOT / "web"
PUSH = ROOT / "web_push"


def require(path: Path) -> str:
    if not path.is_file():
        raise SystemExit(f"Missing generated web file: {path.relative_to(ROOT)}")
    return path.read_text(encoding="utf-8")


def main() -> None:
    index = WEB / "index.html"
    manifest = WEB / "manifest.json"
    html = require(index)
    manifest_data = json.loads(require(manifest))

    source = PUSH / "annas-diary-push.js"
    if not source.is_file():
        raise SystemExit(
            f"Missing Web Push source: {source.relative_to(ROOT)}"
        )
    shutil.copyfile(source, WEB / source.name)

    script_marker = '<script src="annas-diary-push.js"></script>'
    if script_marker not in html:
        addition = (
            '  <meta name="apple-mobile-web-app-capable" content="yes">\n'
            '  <meta name="apple-mobile-web-app-title" content="Anna\'s Diary">\n'
            f'  {script_marker}\n'
        )
        if "</head>" not in html:
            raise SystemExit("Flutter web template drift: </head> not found")
        html = html.replace("</head>", addition + "</head>", 1)
    index.write_text(html, encoding="utf-8")

    manifest_data["name"] = "Anna's Diary"
    manifest_data["short_name"] = "Anna's Diary"
    manifest_data["display"] = "standalone"
    manifest_data["scope"] = "."
    manifest_data["start_url"] = "."
    manifest.write_text(
        json.dumps(manifest_data, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    print("Web platform prepared: PWA + standards-based Web Push enabled")


if __name__ == "__main__":
    main()
