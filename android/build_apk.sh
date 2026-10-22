#!/usr/bin/env bash
# Builds the Android APK of AgIsoVirtualTerminal through the Projucer's Android Studio exporter.
# Usage: build_apk.sh [Debug|Release]
# The locations below can be overridden through the environment.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
config="${1:-Debug}"

STACK_DIR="${STACK_DIR:-$here/../../AgIsoStack-proemion}"
JUCE_DIR="${JUCE_DIR:-/c/AgOpenGPS/AgIsoVirtualTerminal/build/_deps/juce-src}"
GIT_VERSION_DIR="${GIT_VERSION_DIR:-/c/AgOpenGPS/AgIsoVirtualTerminal/build/_deps/git_version-src}"
PROJUCER="${PROJUCER:?set PROJUCER to the Projucer executable}"
ANDROID_SDK="${ANDROID_SDK:-$LOCALAPPDATA/Android/Sdk}"
ANDROID_JDK="${ANDROID_JDK:-$LOCALAPPDATA/Android/jdk-21}"

cd "$here"
bash generate_git_c.sh "$GIT_VERSION_DIR"
python -I make_jucer.py "$STACK_DIR" "$JUCE_DIR/modules"
"$PROJUCER" --resave AgISOVirtualTerminal.jucer

# Gradle finds the SDK through local.properties, which wants escaped Windows paths
sdk_windows="$(cygpath -w "$ANDROID_SDK" | sed -e 's/\\/\\\\/g' -e 's/:/\\:/g')"
echo "sdk.dir=$sdk_windows" > Builds/Android/local.properties

cd Builds/Android
JAVA_HOME="$(cygpath -w "$ANDROID_JDK")" ANDROID_HOME="$(cygpath -w "$ANDROID_SDK")" ./gradlew.bat --no-daemon "assemble$config"
find . -name "*.apk" -newer local.properties
