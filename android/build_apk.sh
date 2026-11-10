#!/usr/bin/env bash
# Builds the Android APK of AgIsoVirtualTerminal through the Projucer's Android Studio exporter.
# Usage: build_apk.sh [Debug|Release]
# The locations below can be overridden through the environment.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
config="${1:-Debug}"

STACK_DIR="${STACK_DIR:-$here/../../AgIsoStack-proemion}"
# JUCE 9.0.5 with 4c6f7753aa from develop, which stops the keyboard restarting on every key
JUCE_DIR="${JUCE_DIR:-/c/AgOpenGPS/JUCE-9.0.5-ime}"
GIT_VERSION_DIR="${GIT_VERSION_DIR:-/c/AgOpenGPS/AgIsoVirtualTerminal/build/_deps/git_version-src}"
# A Projucer of the same JUCE version
PROJUCER="${PROJUCER:-$JUCE_DIR/build-projucer/extras/Projucer/Projucer_artefacts/Release/Projucer.exe}"
ANDROID_SDK="${ANDROID_SDK:-$LOCALAPPDATA/Android/Sdk}"
ANDROID_JDK="${ANDROID_JDK:-$LOCALAPPDATA/Android/jdk-21}"

cd "$here"
bash generate_git_c.sh "$GIT_VERSION_DIR"
python -I make_jucer.py "$STACK_DIR" "$JUCE_DIR/modules"
"$PROJUCER" --resave AgISOVirtualTerminal.jucer

# Leaves a core free for the desktop. Gradle builds one ABI at a time, so the jobs do not add up.
jobs="${JOBS:-$(( $(nproc) > 1 ? $(nproc) - 1 : 1 ))}"
sed -i "s/\"-DCMAKE_CXX_EXTENSIONS=OFF\"/\"-DCMAKE_CXX_EXTENSIONS=OFF\", \"-DCMAKE_JOB_POOLS=compile=$jobs\", \"-DCMAKE_JOB_POOL_COMPILE=compile\"/" Builds/Android/app/build.gradle

# Gradle finds the SDK through local.properties, which wants escaped Windows paths
sdk_windows="$(cygpath -w "$ANDROID_SDK" | sed -e 's/\\/\\\\/g' -e 's/:/\\:/g')"
echo "sdk.dir=$sdk_windows" > Builds/Android/local.properties

cd Builds/Android
JAVA_HOME="$(cygpath -w "$ANDROID_JDK")" ANDROID_HOME="$(cygpath -w "$ANDROID_SDK")" ./gradlew.bat --no-daemon --max-workers=1 "assemble$config"
find . -name "*.apk" -newer local.properties
