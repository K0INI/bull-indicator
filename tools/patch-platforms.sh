#!/usr/bin/env bash
# Patches the CI-generated Flutter platform scaffolding (run from app/ after `flutter create`).
set -euo pipefail

echo "== patching Android =="
MANIFEST=android/app/src/main/AndroidManifest.xml
# INTERNET permission (release builds don't inherit the debug one)
grep -q 'android.permission.INTERNET' "$MANIFEST" || \
  sed -i 's|<application|<uses-permission android:name="android.permission.INTERNET"/>\n    <application|' "$MANIFEST"
# Display name
sed -i 's|android:label="bull_indicator"|android:label="Bull Indicator"|' "$MANIFEST"

# Canonical application ID (flutter create would derive com.koini.bull_indicator)
sed -i -E 's/(applicationId|namespace) = "[^"]*"/\1 = "com.koini.bullindicator"/' android/app/build.gradle.kts
KT_OLD=$(find android/app/src/main/kotlin -name MainActivity.kt)
mkdir -p android/app/src/main/kotlin/com/koini/bullindicator
sed 's/^package .*/package com.koini.bullindicator/' "$KT_OLD" > /tmp/MainActivity.kt
rm -rf android/app/src/main/kotlin/com/koini/bull_indicator
mv /tmp/MainActivity.kt android/app/src/main/kotlin/com/koini/bullindicator/MainActivity.kt

# Release signing config in build.gradle(.kts)
GRADLE_KTS=android/app/build.gradle.kts
GRADLE_GROOVY=android/app/build.gradle
if [ -f "$GRADLE_KTS" ]; then
  python3 - "$GRADLE_KTS" <<'PY'
import sys, re
p = sys.argv[1]
src = open(p).read()
if "key.properties" not in src:
    header = '''import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

'''
    src = re.sub(r'(^plugins\s*\{[^}]*\}\s*)', r'\1\n' + header, src, count=1, flags=re.M|re.S)
    signing = '''    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }
'''
    src = src.replace("    buildTypes {", signing + "    buildTypes {")
    src = re.sub(r'signingConfig\s*=\s*signingConfigs\.getByName\("debug"\)',
                 'signingConfig = if (rootProject.file("key.properties").exists()) signingConfigs.getByName("release") else signingConfigs.getByName("debug")',
                 src)
open(p, "w").write(src)
print("patched", p)
PY
elif [ -f "$GRADLE_GROOVY" ]; then
  echo "groovy gradle template found — add signing manually" >&2
  exit 1
fi

echo "== patching iOS =="
sed -i.bak -E 's/PRODUCT_BUNDLE_IDENTIFIER = com\.koini\.bullIndicator;/PRODUCT_BUNDLE_IDENTIFIER = com.koini.bullindicator;/g' ios/Runner.xcodeproj/project.pbxproj && rm -f ios/Runner.xcodeproj/project.pbxproj.bak
# Display name + encryption declaration
PLIST=ios/Runner/Info.plist
plutil_replace() { python3 - "$PLIST" "$1" "$2" <<'PY'
import sys, re
p, key, val = sys.argv[1:4]
src = open(p).read()
if f"<key>{key}</key>" in src:
    src = re.sub(rf"(<key>{key}</key>\s*<string>)[^<]*(</string>)", rf"\g<1>{val}\g<2>", src)
else:
    src = src.replace("</dict>\n</plist>", f"\t<key>{key}</key>\n\t<string>{val}</string>\n</dict>\n</plist>")
open(p, "w").write(src)
PY
}
plutil_replace CFBundleDisplayName "Bull Indicator"
# No non-exempt encryption (HTTPS only) — avoids an App Store submission question
python3 - "$PLIST" <<'PY'
import sys
p = sys.argv[1]
src = open(p).read()
if "ITSAppUsesNonExemptEncryption" not in src:
    src = src.replace("</dict>\n</plist>", "\t<key>ITSAppUsesNonExemptEncryption</key>\n\t<false/>\n</dict>\n</plist>")
open(p, "w").write(src)
PY

echo "patch-platforms done"
