#!/usr/bin/env python3
"""Patch a freshly generated Flutter Android platform deterministically.

The repository intentionally does not store android/. CI/release jobs generate
Flutter's pinned template first, then this script applies the app-specific
native configuration. It fails loudly when expected template anchors drift.
"""

from __future__ import annotations

import argparse
import base64
import os
import re
import shutil
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ANDROID = ROOT / "android"
APP_GRADLE = ANDROID / "app" / "build.gradle.kts"
SETTINGS_GRADLE = ANDROID / "settings.gradle.kts"
MANIFEST = ANDROID / "app" / "src" / "main" / "AndroidManifest.xml"
MAIN_ACTIVITY = (
    ANDROID
    / "app"
    / "src"
    / "main"
    / "kotlin"
    / "com"
    / "riccardopinato"
    / "agenda_per_anna"
    / "MainActivity.kt"
)
PUBSPEC = ROOT / "pubspec.yaml"
ICON_B64 = ROOT / "assets" / "icon" / "app_icon.b64"
ICON_JPG = ROOT / "assets" / "icon" / "app_icon.jpg"
FIREBASE_CONFIG = ROOT / "firebase" / "google-services.json"
SIGNING_DIR = ROOT / ".signing"
SIGNING_FILE = SIGNING_DIR / "agenda-release.jks"


def require_file(path: Path) -> str:
    if not path.is_file():
        raise SystemExit(f"Required generated file is missing: {path.relative_to(ROOT)}")
    return path.read_text(encoding="utf-8")


def write_if_changed(path: Path, content: str) -> None:
    if path.read_text(encoding="utf-8") != content:
        path.write_text(content, encoding="utf-8")


def replace_required(content: str, old: str, new: str, label: str) -> str:
    if old not in content and new not in content:
        raise SystemExit(f"Flutter template drift: cannot find {label}")
    return content.replace(old, new, 1) if old in content else content


def configure_activity() -> None:
    source = require_file(MAIN_ACTIVITY)
    source = replace_required(
        source,
        "import io.flutter.embedding.android.FlutterActivity",
        "import io.flutter.embedding.android.FlutterFragmentActivity",
        "FlutterActivity import",
    )
    source = replace_required(
        source,
        "class MainActivity : FlutterActivity()",
        "class MainActivity : FlutterFragmentActivity()",
        "MainActivity base class",
    )
    write_if_changed(MAIN_ACTIVITY, source)


def configure_manifest() -> None:
    manifest = require_file(MANIFEST)

    permissions = [
        '<uses-permission android:name="android.permission.INTERNET" />',
        '<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />',
        '<uses-permission android:name="android.permission.USE_BIOMETRIC" />',
        '<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />',
        '<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />',
    ]
    manifest_close = re.search(r"<manifest\b[^>]*>", manifest)
    if manifest_close is None:
        raise SystemExit("Flutter template drift: <manifest> root not found")
    insert_at = manifest_close.end()
    missing = [p for p in permissions if p not in manifest]
    if missing:
        manifest = (
            manifest[:insert_at]
            + "\n    "
            + "\n    ".join(missing)
            + manifest[insert_at:]
        )

    application_match = re.search(r"<application\b[^>]*>", manifest)
    if application_match is None:
        raise SystemExit("Flutter template drift: <application> not found")
    application = application_match.group(0)
    if 'android:allowBackup=' in application:
        application = re.sub(
            r'android:allowBackup="[^"]*"',
            'android:allowBackup="false"',
            application,
        )
    else:
        application = application[:-1] + ' android:allowBackup="false">'
    manifest = (
        manifest[: application_match.start()]
        + application
        + manifest[application_match.end() :]
    )

    manifest = manifest.replace(
        'android:label="agenda_per_anna"',
        'android:label="Anna\'s Diary"',
    )

    auth_deep_link = """
              <intent-filter>
                  <action android:name="android.intent.action.VIEW" />
                  <category android:name="android.intent.category.DEFAULT" />
                  <category android:name="android.intent.category.BROWSABLE" />
                  <data
                      android:scheme="com.riccardopinato.agenda_per_anna"
                      android:host="login-callback" />
              </intent-filter>
"""
    if "com.riccardopinato.agenda_per_anna" not in manifest:
        activity_end = manifest.find("</activity>")
        if activity_end < 0:
            raise SystemExit("Flutter template drift: </activity> not found")
        manifest = (
            manifest[:activity_end]
            + auth_deep_link
            + manifest[activity_end:]
        )

    receiver_block = """
        <receiver
            android:exported="false"
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver
            android:exported="false"
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED" />
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED" />
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON" />
            </intent-filter>
        </receiver>
"""
    if "com.riccardopinato.agenda_per_anna" not in manifest:
        failures.append("auth deep link")
    if "ScheduledNotificationReceiver" not in manifest:
        if "</application>" not in manifest:
            raise SystemExit("Flutter template drift: </application> not found")
        manifest = manifest.replace(
            "</application>",
            receiver_block + "    </application>",
            1,
        )

    write_if_changed(MANIFEST, manifest)

    drawable = ANDROID / "app" / "src" / "main" / "res" / "drawable"
    drawable.mkdir(parents=True, exist_ok=True)
    (drawable / "notification_icon.xml").write_text(
        """<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="#FFFFFFFF"
        android:pathData="M12,22c1.1,0 2,-0.9 2,-2h-4c0,1.1 0.9,2 2,2zM18,16v-5c0,-3.07 -1.63,-5.64 -4.5,-6.32V3c0,-0.83 -0.67,-1.5 -1.5,-1.5S10.5,2.17 10.5,3v0.68C7.64,4.36 6,6.92 6,10v6l-2,2v1h16v-1l-2,-2z" />
</vector>
""",
        encoding="utf-8",
    )


def configure_desugaring() -> None:
    gradle = require_file(APP_GRADLE)
    compile_anchor = "compileOptions {"
    desugar_line = "        isCoreLibraryDesugaringEnabled = true"
    if desugar_line not in gradle:
        if compile_anchor not in gradle:
            raise SystemExit("Flutter template drift: compileOptions block not found")
        gradle = gradle.replace(
            compile_anchor,
            compile_anchor + "\n" + desugar_line,
            1,
        )

    dependency = (
        'coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")'
    )
    if dependency not in gradle:
        gradle += (
            "\n\ndependencies {\n"
            f"    {dependency}\n"
            "}\n"
        )
    write_if_changed(APP_GRADLE, gradle)


def configure_firebase() -> bool:
    if not FIREBASE_CONFIG.is_file():
        return False

    target = ANDROID / "app" / "google-services.json"
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(FIREBASE_CONFIG, target)

    settings = require_file(SETTINGS_GRADLE)
    settings_plugin = (
        '    id("com.google.gms.google-services") version "4.4.4" apply false\n'
    )
    if "com.google.gms.google-services" not in settings:
        if "plugins {\n" not in settings:
            raise SystemExit("Flutter template drift: settings plugins block not found")
        settings = settings.replace("plugins {\n", "plugins {\n" + settings_plugin, 1)
        write_if_changed(SETTINGS_GRADLE, settings)

    app = require_file(APP_GRADLE)
    app_plugin = '    id("com.google.gms.google-services")\n'
    if "com.google.gms.google-services" not in app:
        if "plugins {\n" not in app:
            raise SystemExit("Flutter template drift: app plugins block not found")
        app = app.replace("plugins {\n", "plugins {\n" + app_plugin, 1)
        write_if_changed(APP_GRADLE, app)
    return True


def configure_release_signing() -> None:
    required = {
        "ANDROID_KEYSTORE_BASE64": os.environ.get("ANDROID_KEYSTORE_BASE64", ""),
        "ANDROID_KEYSTORE_PASSWORD": os.environ.get("ANDROID_KEYSTORE_PASSWORD", ""),
        "ANDROID_KEY_ALIAS": os.environ.get("ANDROID_KEY_ALIAS", ""),
        "ANDROID_KEY_PASSWORD": os.environ.get("ANDROID_KEY_PASSWORD", ""),
    }
    missing = [key for key, value in required.items() if not value]
    if missing:
        raise SystemExit(
            "Release signing secrets are required: " + ", ".join(sorted(missing))
        )

    SIGNING_DIR.mkdir(parents=True, exist_ok=True)
    try:
        SIGNING_FILE.write_bytes(base64.b64decode(required["ANDROID_KEYSTORE_BASE64"]))
    except Exception as exc:
        raise SystemExit(f"Invalid ANDROID_KEYSTORE_BASE64: {exc}") from exc

    if SIGNING_FILE.stat().st_size < 100:
        raise SystemExit("Decoded Android keystore is unexpectedly small")

    gradle = require_file(APP_GRADLE)
    if 'create("agendaStable")' not in gradle:
        marker = "    buildTypes {"
        if marker not in gradle:
            raise SystemExit("Flutter template drift: buildTypes block not found")
        block = """
    signingConfigs {
        create("agendaStable") {
            storeFile = file(System.getenv("ANDROID_KEYSTORE_PATH"))
            storePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD")
            keyAlias = System.getenv("ANDROID_KEY_ALIAS")
            keyPassword = System.getenv("ANDROID_KEY_PASSWORD")
        }
    }

"""
        gradle = gradle.replace(marker, block + marker, 1)

    debug_signing = 'signingConfig = signingConfigs.getByName("debug")'
    stable_signing = 'signingConfig = signingConfigs.getByName("agendaStable")'
    if stable_signing not in gradle:
        if debug_signing not in gradle:
            raise SystemExit("Flutter template drift: release signing assignment not found")
        gradle = gradle.replace(debug_signing, stable_signing, 1)

    write_if_changed(APP_GRADLE, gradle)


def prepare_icon() -> None:
    if not ICON_B64.is_file():
        raise SystemExit("assets/icon/app_icon.b64 is missing")
    ICON_JPG.parent.mkdir(parents=True, exist_ok=True)
    try:
        ICON_JPG.write_bytes(base64.b64decode(ICON_B64.read_bytes()))
    except Exception as exc:
        raise SystemExit(f"Cannot decode app icon: {exc}") from exc

    pubspec = require_file(PUBSPEC)
    pubspec = pubspec.replace(
        "assets/icon/app_icon.png",
        "assets/icon/app_icon.jpg",
    )
    # This script prepares an Android-only generated platform. Keep the
    # repository's iOS icon configuration intact, but disable iOS generation
    # in the ephemeral CI pubspec so flutter_launcher_icons never expects an
    # ios/ directory in Android workflows.
    pubspec = replace_required(
        pubspec,
        "  ios: true",
        "  ios: false",
        "flutter_launcher_icons iOS flag",
    )
    write_if_changed(PUBSPEC, pubspec)


def verify() -> None:
    activity = require_file(MAIN_ACTIVITY)
    manifest = require_file(MANIFEST)
    gradle = require_file(APP_GRADLE)
    failures = []
    if "FlutterFragmentActivity" not in activity:
        failures.append("FlutterFragmentActivity")
    if 'android:allowBackup="false"' not in manifest:
        failures.append("allowBackup=false")
    if "ScheduledNotificationReceiver" not in manifest:
        failures.append("notification receiver")
    if "isCoreLibraryDesugaringEnabled = true" not in gradle:
        failures.append("core library desugaring")
    if not ICON_JPG.is_file() or ICON_JPG.stat().st_size == 0:
        failures.append("decoded launcher icon")
    if failures:
        raise SystemExit("Android platform verification failed: " + ", ".join(failures))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--release-signing",
        action="store_true",
        help="Require and configure stable secret-backed release signing.",
    )
    args = parser.parse_args()

    if not ANDROID.is_dir():
        raise SystemExit(
            "android/ is missing. Generate it first with Flutter 3.47.5."
        )

    configure_activity()
    configure_manifest()
    configure_desugaring()
    firebase_enabled = configure_firebase()
    if args.release_signing:
        configure_release_signing()
    prepare_icon()
    verify()

    print(
        "Android platform prepared: "
        f"firebase={'enabled' if firebase_enabled else 'disabled'}, "
        f"stable_signing={'enabled' if args.release_signing else 'disabled'}"
    )


if __name__ == "__main__":
    main()
