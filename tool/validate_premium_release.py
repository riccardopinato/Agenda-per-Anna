#!/usr/bin/env python3
"""Fail closed when a store release is missing Premium configuration."""

from __future__ import annotations

import os
import sys


def _value(name: str) -> str:
    return os.environ.get(name, "").strip()


def main() -> int:
    errors: list[str] = []

    if _value("ANNA_STORE_RELEASE").lower() != "true":
        errors.append("ANNA_STORE_RELEASE must be true for a store build.")

    if _value("ANNA_PREMIUM_PREVIEW").lower() != "false":
        errors.append("ANNA_PREMIUM_PREVIEW must be false for a store build.")

    api_key = _value("REVENUECAT_ANDROID_API_KEY")
    if not api_key:
        errors.append("REVENUECAT_ANDROID_API_KEY is required.")
    elif api_key.lower() in {"changeme", "todo", "placeholder", "test"}:
        errors.append("REVENUECAT_ANDROID_API_KEY looks like a placeholder.")

    entitlement = _value("REVENUECAT_PREMIUM_ENTITLEMENT") or "premium"
    if entitlement != "premium":
        errors.append(
            "REVENUECAT_PREMIUM_ENTITLEMENT must match the canonical "
            "'premium' entitlement."
        )

    if errors:
        for error in errors:
            print(f"::error title=Premium release configuration::{error}")
        return 1

    print("Premium store release configuration validated.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
