#!/bin/bash
set -e

SDK_JAR="/data/data/com.termux/files/home/.android-sdk/android.jar"
WORK_DIR="/data/data/com.termux/files/home/apk_builder"

cd "$WORK_DIR"

echo "=== Cleaning ==="
rm -rf gen bin antigravity-chat.apk antigravity-chat.apk.idsig
mkdir -p gen bin/classes

echo "=== Generating R.java ==="
aapt package -f -m -J gen -M AndroidManifest.xml -S res -I "$SDK_JAR"

echo "=== Compiling Java ==="
ecj -cp "$SDK_JAR" -d bin/classes $(find src gen -name "*.java")

echo "=== Building DEX ==="
dx --dex --output=bin/classes.dex bin/classes

echo "=== Packaging base APK ==="
aapt package -f -M AndroidManifest.xml -S res -A assets -I "$SDK_JAR" -F bin/unaligned.apk

echo "=== Adding classes.dex ==="
cd bin
aapt add unaligned.apk classes.dex
cd "$WORK_DIR"

echo "=== Aligning APK (4-byte alignment) ==="
zipalign -p -f 4 bin/unaligned.apk bin/aligned.apk
zipalign -c -v 4 bin/aligned.apk

KEYSTORE="$WORK_DIR/keystore/debug.keystore"
if [ ! -f "$KEYSTORE" ]; then
    echo "=== Creating Keystore ==="
    mkdir -p "$WORK_DIR/keystore"
    keytool -genkeypair -v -keystore "$KEYSTORE" -alias androiddebugkey -keyalg RSA -keysize 2048 -validity 10000 -startdate "-1y" -storepass android -keypass android -dname "CN=Antigravity Chat, OU=Mobile, O=Antigravity, L=Hanoi, C=VN"
fi

echo "=== Signing APK with v1, v2, v3 ==="
apksigner sign --ks "$KEYSTORE" --ks-pass pass:android --key-pass pass:android --v1-signing-enabled true --v2-signing-enabled true --v3-signing-enabled true --out antigravity-chat.apk bin/aligned.apk

echo "=== Verifying signatures ==="
apksigner verify -v antigravity-chat.apk

echo "=== APK Badging Info ==="
aapt dump badging antigravity-chat.apk | head -n 25

echo "=== SUCCESS! Built: $WORK_DIR/antigravity-chat.apk ==="
