#!/usr/bin/env bash
# Applied in CI after `flutter create .` regenerates the android/ and windows/ runners.
# Keeps the Flutter template (version-matched) and only patches what SpeediT needs:
# app label, permissions (manifest), applicationId and minSdk (Gradle).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# --- Android manifest: our permissions + label ---
if [ -d android/app/src/main ]; then
  cp tool/overlay/android/AndroidManifest.xml android/app/src/main/AndroidManifest.xml
  echo "[overlay] AndroidManifest.xml installed"
  # notification icon (a valid monochrome drawable; the adaptive launcher icon
  # cannot be used for the VPN foreground-service notification)
  mkdir -p android/app/src/main/res/drawable
  cp tool/overlay/android/res/drawable/ic_stat_speedit.xml android/app/src/main/res/drawable/ic_stat_speedit.xml
  echo "[overlay] notification icon installed"
fi

# --- Gradle: applicationId + minSdk (supports Kotlin DSL and Groovy) ---
patch_gradle() {
  local f="$1"
  [ -f "$f" ] || return 0
  # applicationId -> com.speedit.vpn
  sed -i -E 's/applicationId\s*=\s*"[^"]*"/applicationId = "com.speedit.vpn"/' "$f"
  sed -i -E 's/applicationId\s+"[^"]*"/applicationId "com.speedit.vpn"/' "$f"
  # minSdk -> 24 (flutter_v2ray / mobile_scanner safe floor)
  sed -i -E 's/minSdk\s*=\s*flutter\.minSdkVersion/minSdk = 24/' "$f"
  sed -i -E 's/minSdkVersion\s+flutter\.minSdkVersion/minSdkVersion 24/' "$f"
  sed -i -E 's/minSdk\s*=\s*[0-9]+/minSdk = 24/' "$f"
  # targetSdk -> 33 (Android 14/15 foreground-service + notification rules kill the
  # VPN service on targetSdk 34+; flutter_v2ray's service is tuned for <=33)
  sed -i -E 's/targetSdk\s*=\s*flutter\.targetSdkVersion/targetSdk = 33/' "$f"
  sed -i -E 's/targetSdkVersion\s+flutter\.targetSdkVersion/targetSdkVersion 33/' "$f"
  sed -i -E 's/targetSdk\s*=\s*[0-9]+/targetSdk = 33/' "$f"
  echo "[overlay] patched $f"
}
patch_gradle android/app/build.gradle.kts
patch_gradle android/app/build.gradle

echo "[overlay] done"
