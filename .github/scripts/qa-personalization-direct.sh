#!/usr/bin/env bash
# QA-only. This script MUST be invoked as a single Bash command by android-emulator-runner.
# A green status from the wrapper is not sufficient: Maestro itself must exit zero.
set -Eeuo pipefail
mkdir -p qa-evidence
FLOW='.maestro/journeys/personalization-atomic.yaml'
source_sha="$(git rev-parse HEAD)"
test "$source_sha" = "${QA_SOURCE_SHA:?Missing exact PR head}"
echo "QA_ONLY_DIRECT_MAESTRO_START source_sha=$source_sha flow=$FLOW"
echo "QA_ONLY_PRODUCTION_GATE_CONCLUSION=${QA_PRODUCTION_GATE_CONCLUSION:-unknown} (not overridden)"
test -s "$QA_APK"
test -s "$FLOW"
sha256sum "$QA_APK" | tee qa-evidence/apk-sha256.txt
# Fail closed if the emulator is not responding. Do not call this an app regression.
if ! timeout 90s adb shell getprop sys.boot_completed | grep -qx '1'; then
  echo 'QA_INFRA_FAILURE: Android emulator not responsive after boot' >&2
  exit 1
fi
adb install -r -t "$QA_APK"
echo 'QA_DIRECT_MAESTRO_COMMAND_BEGIN'
set +e
timeout 900s maestro test "$FLOW" --test-output-dir qa-evidence/maestro 2>&1 | tee qa-evidence/direct-maestro.log
maestro_rc=${PIPESTATUS[0]}
set -e
if (( maestro_rc != 0 )); then
  echo "QA_DIRECT_MAESTRO_FAILURE exit_code=$maestro_rc; no runtime PASS" >&2
  exit "$maestro_rc"
fi
echo 'DIRECT_PERSONALIZATION_ATOMIC_FLOW_PASS_DIAGNOSTIC_ONLY'
